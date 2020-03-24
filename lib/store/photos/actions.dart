import 'package:reddigram/api/api.dart';
import 'package:reddigram/models/models.dart';
import 'package:reddigram/store/store.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

ThunkAction<GlanceState> upvote(Photo photo) {
  return (Store<GlanceState> store) {
    redditRepository
        .upvote(photo.id)
        .then((_) => store.dispatch(PhotoUpvoted(photo.id)));
  };
}

ThunkAction<GlanceState> cancelUpvote(Photo photo) {
  return (Store<GlanceState> store) {
    redditRepository
        .cancelUpvote(photo.id)
        .then((_) => store.dispatch(PhotoUpvoteCanceled(photo.id)));
  };
}

class FetchedPhotos {
  final List<Photo> photos;

  FetchedPhotos(this.photos);
}

class PhotoUpvoted {
  final String id;

  PhotoUpvoted(this.id);
}

class PhotoUpvoteCanceled {
  final String id;

  PhotoUpvoteCanceled(this.id);
}
