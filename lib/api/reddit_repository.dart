import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:meta/meta.dart';
import 'package:package_info/package_info.dart';
import 'package:reddigram/api/api.dart';
import 'package:reddigram/api/response_models/response_models.dart';
import 'package:reddigram/consts.dart';
import 'package:reddigram/models/models.dart' as models;
import 'package:reddigram/utils/extensions.dart';
import 'package:url_launcher/url_launcher.dart';

class RedditRepository {
  Dio _client;

  RedditTokens _tokens;

  RedditRepository() {
    _client = Dio(BaseOptions(
      baseUrl: 'https://www.reddit.com',
      receiveTimeout: 5000,
    ));

    _client.interceptors.addAll([
      InterceptorsWrapper(onRequest: (options) async {
        // Refreshment of access token
        if (_tokens == null || options.path.contains('access_token')) {
          // skip if we aren't authorized
          return options;
        }

        final minuteAgo = DateTime.now().subtract(Duration(minutes: 1));
        if (_tokens.expirationTime.isBefore(minuteAgo)) {
          await refreshAccessToken();
        }

        return options;
      }),
      InterceptorsWrapper(onRequest: (options) {
        if (_tokens != null && !options.path.contains('access_token')) {
          options.headers['Authorization'] = 'Bearer ${_tokens.accessToken}';
          options.baseUrl = 'https://oauth.reddit.com';
        }

        return options;
      })
    ]);

    if (PlatformX.isMobile) {
      PackageInfo.fromPlatform().then((info) =>
          _client.options.headers['User-Agent'] =
              '${info.packageName}:${info.version} (by /u/Albert221)');
    } else {
      _client.options.headers['User-Agent'] =
          'reddigram:1.0+ (by /u/Albert221)';
    }
  }

  Future<Response> _post(String path,
      {String data, Map<String, dynamic> headers}) async {
    return _client.post(
      path,
      data: data,
      options: Options(
        headers: headers,
        contentType: 'application/x-www-form-urlencoded',
      ),
    );
  }

  Future<RedditTokens> refreshAccessToken([String refreshToken]) {
    final basicAuth =
        'Basic ' + base64.encode(utf8.encode('${GlanceConsts.oauthClientId}:'));

    return _post(
      '/api/v1/access_token',
      data: 'grant_type=refresh_token'
          '&refresh_token=${refreshToken ?? _tokens.refreshToken}',
      headers: {'Authorization': basicAuth},
    ).then((response) {
      if (_tokens == null && refreshToken != null) {
        // we will populate it with correct data in a second
        _tokens = RedditTokens(
          accessToken: '',
          refreshToken: refreshToken,
          expirationTime: DateTime.now(),
        );
      }

      return _tokens = _tokens.copyWith(
        accessToken: response.data['access_token'],
        expirationTime:
            DateTime.now().add(Duration(seconds: response.data['expires_in'])),
      );
    });
  }

  String getAccessToken() => _tokens?.accessToken;

  void clearTokens() {
    _tokens = null;
  }

  void _assertAuthorized() {
    assert(_tokens != null, 'User required.');
  }

  Future<RedditTokens> retrieveTokens(String code) async {
    final basicAuth =
        'Basic ' + base64.encode(utf8.encode('${GlanceConsts.oauthClientId}:'));

    String oauthRedirectUrl;

    if (PlatformX.isMobile) {
      oauthRedirectUrl = GlanceConsts.oauthRedirectUrl;
    } else {
      oauthRedirectUrl = GlanceConsts.desktopOauthRedirectUrl;
    }
    Response response = await _post(
      '/api/v1/access_token',
      data: 'grant_type=authorization_code&code=$code'
          '&redirect_uri=$oauthRedirectUrl',
      headers: {'Authorization': basicAuth},
    );

    _tokens = RedditTokens(
      accessToken: response.data['access_token'],
      refreshToken: response.data['refresh_token'],
      expirationTime:
          DateTime.now().add(Duration(seconds: response.data['expires_in'])),
    );
    return _tokens;
  }

  /// If [feed] equals '_EMPTY' then it always returns empty list.
  Future<List<models.Photo>> feed(String feed,
      {String after = '', int limit = 25}) async {
    if (feed == '_EMPTY') {
      return Future.value([]);
    }

    return _client
        .get('/$feed.json?after=$after&limit=$limit')
        .then((response) => serializers.deserializeWith(
            LinkListingResponse.serializer, response.data))
        .then(LinkListingPhotosMapper.map);
  }

  Future<String> username() async {
    _assertAuthorized();

    return _client.get('/api/v1/me').then((response) => response.data['name']);
  }

  Future<void> upvote(String id) async {
    _assertAuthorized();

    return _post('/api/vote', data: 'dir=1&id=$id');
  }

  Future<void> cancelUpvote(String id) async {
    _assertAuthorized();

    return _post('/api/vote', data: 'dir=0&id=$id');
  }

  Future<models.Subreddit> subreddit(String name) async {
    return _client
        .get('/r/$name/about.json')
        .then((response) => serializers.deserializeWith(
            SubredditResponse.serializer, response.data))
        .then(SubredditInfoMapper.map);
  }

  Future<List<models.Subreddit>> searchSubreddits(String query) async {
    return _client
        .get('/api/subreddit_autocomplete_v2.json?query=$query&limit=10'
            '&include_profiles=false&include_categories=false'
            '&include_over_18=on')
        .then((response) => serializers.deserializeWith(
            SubredditListResponse.serializer, response.data))
        .then(SubredditInfoMapper.mapList);
  }

  Future<List<models.Subreddit>> subredditsBulk(List<String> ids) async {
    return _client
        .get('/api/info.json?id=${ids.join(',')}')
        .then((response) => serializers.deserializeWith(
            SubredditListResponse.serializer, response.data))
        .then(SubredditInfoMapper.mapList);
  }

  Future<List<models.Subreddit>> subscribedSubreddits() async {
    _assertAuthorized();

    return _client
        .get('/subreddits/mine/subscriber?limit=100')
        .then((response) => serializers.deserializeWith(
            SubredditListResponse.serializer, response.data))
        .then(SubredditInfoMapper.mapList);
  }

  Future<String> getAccessCode() async {
    final codeCompleter = Completer<String>();

    final StreamController<String> onCode = new StreamController();
    HttpServer server =
        await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);
    server.listen((HttpRequest request) async {
//      // print("Server started");
      final String code = request.uri.queryParameters["code"];
//      // print(request.uri.pathSegments);
      request.response
        ..statusCode = 200
        ..headers.set("Content-Type", ContentType.html.mimeType)
        ..write(
            '<html><meta name="viewport" content="width=device-width, initial-scale=1.0"><body> <h2 style="text-align: center; position: absolute; top: 50%; left: 0: right: 0">Welcome to Glance</h2><h3>You can close this window<script type="javascript">window.close()</script> </h3></body></html>');
      await request.response.close();
      await server.close(force: true);
      codeCompleter.complete(code);
      await onCode.close();
    });
    return codeCompleter.future;
  }

  void launchOathPage() {
    String oauthRedirectUrl;
    if (PlatformX.isMobile) {
      oauthRedirectUrl = GlanceConsts.oauthRedirectUrl;
    } else {
      oauthRedirectUrl = GlanceConsts.desktopOauthRedirectUrl;
    }
    launch('https://www.reddit.com/api/v1/authorize'
        '?client_id=${GlanceConsts.oauthClientId}&response_type=code'
        '&state=x&scope=identity,edit,flair,history,modconfig,modflair,modlog,modposts,modwiki,mysubreddits,privatemessages,read,report,save,submit,subscribe,vote,wikiedit,wikiread&duration=permanent'
        '&redirect_uri=$oauthRedirectUrl');
  }
}

class RedditTokens {
  final String accessToken;
  final String refreshToken;
  final DateTime expirationTime;

  RedditTokens(
      {@required this.accessToken,
      @required this.refreshToken,
      @required this.expirationTime})
      : assert(accessToken != null),
        assert(refreshToken != null),
        assert(expirationTime != null);

  RedditTokens copyWith(
      {String accessToken, String refreshToken, DateTime expirationTime}) {
    return RedditTokens(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expirationTime: expirationTime ?? this.expirationTime,
    );
  }
}
