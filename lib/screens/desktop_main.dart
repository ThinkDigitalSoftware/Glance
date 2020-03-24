import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:reddigram/screens/screens.dart';
import 'package:reddigram/store/store.dart';
import 'package:reddigram/widgets/desktop/desktop_drawer.dart';
import 'package:reddigram/widgets/desktop/desktop_layout.dart';
import 'package:reddigram/widgets/widgets.dart';

class DesktopMainScreen extends StatefulWidget {
  static final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  _DesktopMainScreenState createState() => _DesktopMainScreenState();
}

class _DesktopMainScreenState extends State<DesktopMainScreen> {
  static const _TAB_POPULAR = 0;
  static const _TAB_BEST = 1; // ignore: unused_field
  static const _TAB_NEWEST = 2; // ignore: unused_field
  static const _TAB_SUBSCRIPTIONS = 3;

  final feedKeys = List.generate(3, (i) => GlobalKey<InfiniteListState>());

  final _pageController = PageController();
  int _currentTab = _TAB_POPULAR;

  @override
  Widget build(BuildContext context) {
    final subheadTheme = Theme.of(context).textTheme.subhead;

    final subscribeCTA = GestureDetector(
      onTap: () => _changeTab(_TAB_SUBSCRIPTIONS),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('No', style: subheadTheme),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(
                  Icons.short_text,
                  size: 28.0,
                ),
              ),
              Text('yet.', style: subheadTheme)
            ],
          ),
          const SizedBox(height: 12.0),
          const Text('Subscribe to something!'),
        ],
      ),
    );

    final itemsPlaceholder = ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, i) => PhotoListItem.placeholder(),
    );

    return Scaffold(
      key: DesktopMainScreen.scaffoldKey,
      body: DesktopLayout(
        leftPanel: DesktopDrawer(
          onOptionSelected: (String option) {
            _changeTab(SubredditDefault.values.indexOf(option));
          },
        ),
        content: StoreConnector<GlanceState, bool>(
          onInit: (store) =>
              store.dispatch(fetchFreshFeed(SubredditDefault.popular)),
          converter: (store) => store.state.subscriptions.isNotEmpty,
          builder: (context, anySubs) => PageView(
            physics: const NeverScrollableScrollPhysics(),
            controller: _pageController,
            children: [
              FeedTab(
                feedName: SubredditDefault.popular,
                infiniteListKey: feedKeys[0],
                placeholder: itemsPlaceholder,
              ),
              FeedTab(
                feedName: SubredditDefault.bestSubscribed,
                infiniteListKey: feedKeys[1],
                placeholder: anySubs ? itemsPlaceholder : subscribeCTA,
              ),
              FeedTab(
                feedName: SubredditDefault.newSubscribed,
                infiniteListKey: feedKeys[2],
                placeholder: anySubs ? itemsPlaceholder : subscribeCTA,
              ),
              const SubscriptionsTab(),
            ],
          ),
        ),
      ),
    );
  }

  void _changeTab(int tab) {
    setState(() {
      _currentTab = tab;
      _pageController.animateToPage(
        tab,
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    });
  }
}
