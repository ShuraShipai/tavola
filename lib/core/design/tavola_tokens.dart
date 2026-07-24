import 'package:flutter/material.dart';

abstract final class TavolaSpace {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 40.0;
  static const xxxl = 48.0;
  static const huge = 64.0;
}

abstract final class TavolaRadius {
  static const small = BorderRadius.all(Radius.circular(8));
  static const medium = BorderRadius.all(Radius.circular(12));
  static const large = BorderRadius.all(Radius.circular(16));
  static const extraLarge = BorderRadius.all(Radius.circular(24));
}

abstract final class TavolaSize {
  static const iconSmall = 16.0;
  static const iconMedium = 20.0;
  static const iconLarge = 24.0;
  static const touchTarget = 44.0;
  static const buttonHeight = 44.0;
  static const sidebarWidth = 264.0;
  static const topBarHeight = 72.0;
  static const maxContentWidth = 1440.0;
}

abstract final class TavolaMotion {
  static const fast = Duration(milliseconds: 150);
  static const standard = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 320);
  static const curve = Curves.easeOutCubic;
}

abstract final class TavolaOpacity {
  static const disabled = 0.38;
  static const muted = 0.6;
  static const overlay = 0.5;
}
