import 'dart:async';

import 'package:reddigram/api/api.dart';
import 'package:reddigram/store/store.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _refreshTokenKey = 'reddit_refresh_token';

Future<void> _loadFeeds(Store<GlanceState> store) {
  // Fetch all feeds after we have info if user is authenticated or not.
  final bestCompleter = Completer();
  store.dispatch(fetchFreshFeed(SubredditDefault.bestSubscribed,
      completer: bestCompleter));
  final newCompleter = Completer();
  store.dispatch(
      fetchFreshFeed(SubredditDefault.newSubscribed, completer: newCompleter));

  return Future.wait([
    bestCompleter.future,
    newCompleter.future,
  ]);
}

void _loadUserData(Store<GlanceState> store, String redditAccessToken) {
  final futures = <Future>[];

  futures.add(redditRepository
      .username()
      .then((username) => store.dispatch(SetUsername(username))));

  final subscriptionsCompleter = Completer();
  futures.add(subscriptionsCompleter.future);
  futures.add(apiRepository.useApi(redditAccessToken).then(
        (_) => store.dispatch(fetchSubscriptions(subscriptionsCompleter)),
        onError: (_) => subscriptionsCompleter.complete(),
      ));

  Future.wait(futures).then((_) async => await _loadFeeds(store)).then(
        (_) => store.dispatch(SetAuthStatus(AuthStatus.authenticated)),
        onError: (_) => store.dispatch(SetAuthStatus(AuthStatus.guest)),
      );
}

ThunkAction<GlanceState> loadUser() {
  return (Store<GlanceState> store) {
    SharedPreferences.getInstance().then((prefs) async {
      final refreshToken = prefs.getString(_refreshTokenKey);

      if (refreshToken != null) {
        store.dispatch(SetAuthStatus(AuthStatus.authenticating));

        final tokens = await redditRepository.refreshAccessToken(refreshToken);
        _loadUserData(store, tokens.accessToken);
      } else {
        apiRepository.useLocal();
        final subscriptionsCompleter = Completer();
        store.dispatch(fetchSubscriptions(subscriptionsCompleter));
        await subscriptionsCompleter.future;
        await _loadFeeds(store);

        store.dispatch(SetAuthStatus(AuthStatus.guest));
      }
    });
  };
}

ThunkAction<GlanceState> authenticateUserFromCode(String code) {
  return (Store<GlanceState> store) async {
    store.dispatch(SetAuthStatus(AuthStatus.authenticating));

    final tokens = await redditRepository.retrieveTokens(code);
    SharedPreferences.getInstance().then(
        (prefs) => prefs.setString(_refreshTokenKey, tokens.refreshToken));

    _loadUserData(store, tokens.accessToken);
  };
}

ThunkAction<GlanceState> signUserOut() {
  return (Store<GlanceState> store) async {
    store.dispatch(SetAuthStatus(AuthStatus.signingOut));

    redditRepository.clearTokens();
    SharedPreferences.getInstance()
        .then((prefs) => prefs.remove(_refreshTokenKey));
    store.dispatch(SetUsername(null));

    apiRepository.useLocal();

    final subscriptionsCompleter = Completer();
    store.dispatch(fetchSubscriptions(subscriptionsCompleter));
    await subscriptionsCompleter.future;

    _loadFeeds(store)
        .whenComplete(() => store.dispatch(SetAuthStatus(AuthStatus.guest)));
  };
}

class SetUsername {
  final String username;

  SetUsername(this.username);
}

class SetAuthStatus {
  final AuthStatus status;

  SetAuthStatus(this.status);
}
