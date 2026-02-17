import 'package:flutter/material.dart';
import 'package:sendme_rider/AppConfig.dart';

class AppColors {
  // App Colors
  static Color mainAppColor = activeApp.color;
  static Color secondAppColor = mainAppColor.withValues(alpha: 0.4);
  static Color pickUpDropAppColor = mainAppColor.withValues(alpha: 0.65);

  // Order Status Colors
  static const Color pendingStatusColor = Color(0xffEDA941);
  static const Color doneStatusColor = Color(0xff50B092);

  // Text Colors
  static const Color textColorBold = Color(0xff000000);
  static const Color textColorLight = Color(0xff7F7F7F);
  static const Color textColorLighter = Color(0xffBDBDBD);

  // App Bar Colors
  static const Color appBarColor = Color(0xffFFFFFF);
  static const Color appBarTextColor = Color(0xff000000);

  // Color to MaterialColor
  static MaterialColor appPrimaryColor = getMaterialColor(mainAppColor);

  static MaterialColor getMaterialColor(
    Color color,
  ) => MaterialColor(color.toARGB32(), {
    50: Color.fromRGBO(color.r.toInt(), color.g.toInt(), color.b.toInt(), .1),
    100: Color.fromRGBO(color.r.toInt(), color.g.toInt(), color.b.toInt(), .2),
    200: Color.fromRGBO(color.r.toInt(), color.g.toInt(), color.b.toInt(), .3),
    300: Color.fromRGBO(color.r.toInt(), color.g.toInt(), color.b.toInt(), .4),
    400: Color.fromRGBO(color.r.toInt(), color.g.toInt(), color.b.toInt(), .5),
    500: Color.fromRGBO(color.r.toInt(), color.g.toInt(), color.b.toInt(), .6),
    600: Color.fromRGBO(color.r.toInt(), color.g.toInt(), color.b.toInt(), .7),
    700: Color.fromRGBO(color.r.toInt(), color.g.toInt(), color.b.toInt(), .8),
    800: Color.fromRGBO(color.r.toInt(), color.g.toInt(), color.b.toInt(), .9),
    900: Color.fromRGBO(color.r.toInt(), color.g.toInt(), color.b.toInt(), 1),
  });
}
