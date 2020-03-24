import 'dart:async';

//import 'package:firebase_analytics/firebase_analytics.dart';
//import 'package:firebase_analytics/observer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:reddigram/screens/desktop_main.dart';
import 'package:reddigram/store/store.dart';
import 'package:reddigram/theme.dart';
import 'package:reddigram/screens/screens.dart';
import 'package:reddigram/widgets/platform_builder.dart';
import 'package:reddigram/widgets/widgets.dart';
import 'package:redux/redux.dart';
import 'package:uni_links/uni_links.dart';

class GlanceApp extends StatefulWidget {
//  static final analytics = FirebaseAnalytics();
//  static final _navObserver = FirebaseAnalyticsObserver(analytics: analytics);

  final Store<GlanceState> store;

  GlanceApp({Key key, @required this.store})
      : assert(store != null),
        super(key: key);

  @override
  _GlanceAppState createState() => _GlanceAppState();
}

class _GlanceAppState extends State<GlanceApp> {
  StreamSubscription<Uri> _linkStream;

  @override
  void initState() {
    super.initState();

    _linkStream = getUriLinksStream().listen((uri) {
      if (uri.host == 'redirect' && uri.queryParameters.containsKey('code')) {
        widget.store
            .dispatch(authenticateUserFromCode(uri.queryParameters['code']));

//        GlanceApp.analytics.logLogin(loginMethod: 'Reddit');
      }
    });
  }

  @override
  void dispose() {
    _linkStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return StoreProvider<GlanceState>(
      store: widget.store,
      child: StoreConnector<GlanceState, PreferencesState>(
        onInit: (store) => store.dispatch(loadPreferences()),
        converter: (store) => store.state.preferences,
        builder: (context, preferences) {
          return PreferencesProvider(
            preferences: preferences,
            child: StoreConnector<GlanceState, AuthStatus>(
              onInit: (store) => store.dispatch(loadUser()),
              converter: (store) => store.state.authState.status,
              builder: (context, authStatus) {
                return MaterialApp(
                  title: 'Glance',
                  theme: PreferencesProvider.of(context).theme == AppTheme.light
                      ? GlanceTheme.light()
                      : GlanceTheme.dark(),
                  routes: {
                    '/': (context) => PlatformBuilder(
                          macOS: (_) => DesktopMainScreen(),
                          windows: (_) => DesktopMainScreen(),
                          fallback: (_) => MainScreen(),
                        ),
                  },
//                  navigatorObservers: [GlanceApp._navObserver],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
