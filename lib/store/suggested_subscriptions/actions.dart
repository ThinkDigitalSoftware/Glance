import 'dart:async';

import 'package:reddigram/api/api.dart';
import 'package:reddigram/store/store.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

ThunkAction<GlanceState> fetchSuggestedSubscriptions([Completer completer]) {
  return (Store<GlanceState> store) {
    apiRepository
        .suggestedSubreddits(store.state.subscriptions.toList())
        .then((suggestions) {
      store.dispatch(FetchedSuggestedSubscriptions(suggestions));
      store.dispatch(fetchSubreddits(suggestions));
    }).whenComplete(() => completer?.complete());
  };
}

class FetchedSuggestedSubscriptions {
  final List<String> suggestedSubscriptions;

  FetchedSuggestedSubscriptions(this.suggestedSubscriptions);
}
