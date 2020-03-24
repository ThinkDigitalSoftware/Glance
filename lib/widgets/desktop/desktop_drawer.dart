import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:reddigram/screens/preferences_sheet.dart';
import 'package:reddigram/store/app_state.dart';
import 'package:reddigram/store/auth/auth_state.dart';
import 'package:reddigram/store/feeds/actions.dart';
import 'package:reddigram/widgets/reddigram_logo.dart';

class DesktopDrawer extends StatefulWidget {
  final ValueChanged<String> onOptionSelected;

  const DesktopDrawer({Key key, this.onOptionSelected}) : super(key: key);

  @override
  _DesktopDrawerState createState() => _DesktopDrawerState();
}

class _DesktopDrawerState extends State<DesktopDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: <Widget>[
          AppBar(
            title: const GlanceLogo(),
            centerTitle: true,
            leading: _buildAccountLeadingIcon(context),
          ),
          ListTile(
            leading: Icon(Icons.show_chart),
            title: Text('Popular'),
            onTap: () => widget.onOptionSelected(SubredditDefault.popular),
          ),
          ListTile(
            leading: Icon(FontAwesomeIcons.rocket),
            title: Text('Best'),
            onTap: () =>
                widget.onOptionSelected(SubredditDefault.bestSubscribed),
          ),
          ListTile(
            leading: Icon(FontAwesomeIcons.certificate),
            title: Text('Your newest'),
            onTap: () =>
                widget.onOptionSelected(SubredditDefault.newSubscribed),
          ),
          ListTile(
            leading: Icon(Icons.short_text),
            title: Text('Subscriptions'),
//            onTap: () => widget.onOptionSelected(SUBSCR),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountLeadingIcon(BuildContext context) {
    return IconButton(
      icon: StoreConnector<GlanceState, bool>(
        converter: (store) =>
            store.state.authState.status == AuthStatus.authenticated,
        builder: (context, signedIn) => AnimatedContainer(
          curve: Curves.ease,
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: signedIn
                  ? Theme.of(context).buttonTheme.colorScheme.primary
                  : Colors.transparent,
              width: 3,
            ),
          ),
          child: const Icon(Icons.account_circle),
        ),
      ),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (context) => PreferencesSheet(),
        );
      },
    );
  }
}
