import 'package:flutter/material.dart';

class GlanceLogo extends StatelessWidget {
  const GlanceLogo({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      'Glance',
      style: TextStyle(
        fontFamily: 'Pacifico',
        fontSize: 22.0,
        fontWeight: FontWeight.normal,
      ),
    );
  }
}
