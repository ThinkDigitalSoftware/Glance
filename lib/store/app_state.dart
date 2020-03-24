import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:reddigram/models/models.dart';
import 'package:reddigram/store/store.dart';

part 'app_state.g.dart';

abstract class GlanceState
    implements Built<GlanceState, ReddigramStateBuilder> {
  AuthState get authState;

  PreferencesState get preferences;

  /// Map of all photos in application; key is an id of a photo.
  BuiltMap<String, Photo> get photos;

  /// Map with all feeds in application. There are three reserved values:
  /// [SubredditDefault.popular], [SubredditDefault.newSubscribed], and [SubredditDefault.bestSubscribed], the rest of values
  /// are subreddits' names with correct capitalization, without "r/" prefix.
  BuiltMap<String, Feed> get feeds;

  /// Map of all subreddits in application (not only those which feed was
  /// loaded, but also all shown in badges). Key is a subreddit id.
  BuiltMap<String, Subreddit> get subreddits;

  /// Ids of subscribed subreddits.
  BuiltSet<String> get subscriptions;

  /// Ids of suggested to subscribe subreddits.
  BuiltSet<String> get suggestedSubscriptions;

  SubredditsSearchState get subredditsSearch;

  GlanceState._();

  factory GlanceState([updates(ReddigramStateBuilder b)]) {
    return _$ReddigramState
        ._(
          authState: AuthState(),
          preferences: PreferencesState(),
          photos: BuiltMap<String, Photo>(),
          feeds: BuiltMap<String, Feed>({
            SubredditDefault.popular: Feed(),
            SubredditDefault.newSubscribed: Feed(),
            SubredditDefault.bestSubscribed: Feed(),
          }),
          subreddits: BuiltMap<String, Subreddit>(),
          subscriptions: BuiltSet(),
          suggestedSubscriptions: BuiltSet(),
          subredditsSearch: SubredditsSearchState(),
        )
        .rebuild(updates);
  }
}
