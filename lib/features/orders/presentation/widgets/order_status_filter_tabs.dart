import 'package:flutter/material.dart';

import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../domain/entities/restaurant_order.dart';
part 'order_status_filter_tabs_order_status_filter_tabs.dart';
part 'order_status_filter_tabs_filter_tab.dart';

/// Presentation state for the active-order status filter.
enum OrderStatusFilter { all, placed, preparing, ready, held }
