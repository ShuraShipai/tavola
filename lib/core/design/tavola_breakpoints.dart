import 'package:flutter/widgets.dart';

abstract final class TavolaBreakpoints {
  static const compact = 600.0;
  static const medium = 900.0;
  static const expanded = 1200.0;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compact;
  static bool isMedium(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= compact &&
      MediaQuery.sizeOf(context).width < expanded;
  static bool isExpanded(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= expanded;
}
