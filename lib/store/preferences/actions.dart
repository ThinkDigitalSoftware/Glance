import 'package:reddigram/store/store.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:shared_preferences/shared_preferences.dart';

ThunkAction<ReddigramState> loadPreferences() {
  return (Store<ReddigramState> store) async {
    final prefs = await SharedPreferences.getInstance();

    store.dispatch(SetTheme(
      prefs.getString("theme") == "dark" ? AppTheme.dark : AppTheme.light,
    ));

    store.dispatch(SetShowNsfw(prefs.getBool("show_nsfw") ?? false));
  };
}

ThunkAction<ReddigramState> setTheme(AppTheme theme) {
  return (Store<ReddigramState> store) async {
    (await SharedPreferences.getInstance())
        .setString("theme", theme.toString());

    store.dispatch(SetTheme(theme));
  };
}

ThunkAction<ReddigramState> setShowNsfw(bool showNsfw) {
  return (Store<ReddigramState> store) async {
    (await SharedPreferences.getInstance()).setBool("show_nsfw", showNsfw);

    store.dispatch(SetShowNsfw(showNsfw));
  };
}

class SetTheme {
  final AppTheme theme;

  SetTheme(this.theme);
}

class SetShowNsfw {
  final bool showNsfw;

  SetShowNsfw(this.showNsfw);
}
