import 'dart:async';

import 'package:reddigram/api/api.dart';
import 'package:reddigram/store/store.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

ThunkAction<GlanceState> fetchSubscriptions([Completer completer]) {
  return (Store<GlanceState> store) {
    apiRepository.fetchSubscriptions().then((subreddits) async {
      final subredditsCompleter = Completer();
      store.dispatch(
          fetchSubreddits(subreddits, completer: subredditsCompleter));
      await subredditsCompleter.future;

      store.dispatch(FetchedSubscriptions(subreddits));

      store.dispatch(fetchSuggestedSubscriptions());
    }).whenComplete(() => completer?.complete());
  };
}

ThunkAction<GlanceState> subscribeSubreddit(String id) {
  return (Store<GlanceState> store) {
    apiRepository.subscribeSubreddit(id).then((_) {
      store.dispatch(SubscribedSubreddit(id));
      store.dispatch(fetchFreshFeed(SubredditDefault.newSubscribed));
      store.dispatch(fetchFreshFeed(SubredditDefault.bestSubscribed));
    });
  };
}

ThunkAction<GlanceState> unsubscribeSubreddit(String id) {
  return (Store<GlanceState> store) {
    apiRepository.unsubscribeSubreddit(id).then((_) {
      store.dispatch(UnsubscribedSubreddit(id));
      store.dispatch(fetchFreshFeed(SubredditDefault.newSubscribed));
      store.dispatch(fetchFreshFeed(SubredditDefault.bestSubscribed));
    });
  };
}

class FetchedSubscriptions {
  final List<String> subreddits;

  FetchedSubscriptions(this.subreddits);
}

class SubscribedSubreddit {
  final String name;

  SubscribedSubreddit(this.name);
}

class UnsubscribedSubreddit {
  final String name;

  UnsubscribedSubreddit(this.name);
}
