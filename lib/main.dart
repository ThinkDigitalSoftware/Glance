//import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:reddigram/app.dart';
import 'package:reddigram/store/store.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart' show thunkMiddleware;

void main() {
  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details);
//    Crashlytics.instance.recordFlutterError(details);
  };

  final store = Store<GlanceState>(
    rootReducer,
    initialState: GlanceState(),
    middleware: [
      (Store<GlanceState> store, action, NextDispatcher next) {
        debugPrint(action.toString());

        next(action);
      },
      thunkMiddleware
    ],
  );

  runApp(GlanceApp(store: store));
}
