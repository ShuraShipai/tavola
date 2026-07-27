enum KitchenTicketStatus { queued, preparing, ready, served, cancelled }

extension KitchenTicketStatusX on KitchenTicketStatus {
  String get label => switch (this) {
    KitchenTicketStatus.queued => 'New',
    KitchenTicketStatus.preparing => 'Preparing',
    KitchenTicketStatus.ready => 'Ready',
    KitchenTicketStatus.served => 'Served',
    KitchenTicketStatus.cancelled => 'Cancelled',
  };

  KitchenTicketStatus? get next => switch (this) {
    KitchenTicketStatus.queued => KitchenTicketStatus.preparing,
    KitchenTicketStatus.preparing => KitchenTicketStatus.ready,
    KitchenTicketStatus.ready => KitchenTicketStatus.served,
    KitchenTicketStatus.served || KitchenTicketStatus.cancelled => null,
  };

  String get nextAction => switch (this) {
    KitchenTicketStatus.queued => 'Start preparing',
    KitchenTicketStatus.preparing => 'Mark ready',
    KitchenTicketStatus.ready => 'Mark served',
    KitchenTicketStatus.served || KitchenTicketStatus.cancelled => '',
  };
}

class KitchenTicketItem {
  const KitchenTicketItem({
    required this.id,
    required this.name,
    required this.quantity,
    this.notes,
  });

  final String id;
  final String name;
  final num quantity;
  final String? notes;
}

class KitchenTicket {
  const KitchenTicket({
    required this.id,
    required this.restaurantId,
    required this.orderId,
    required this.orderNumber,
    required this.orderType,
    required this.status,
    required this.createdAt,
    required this.items,
    this.tableLabel,
    this.notes,
  });

  final String id;
  final String restaurantId;
  final String orderId;
  final int orderNumber;
  final String orderType;
  final KitchenTicketStatus status;
  final DateTime createdAt;
  final List<KitchenTicketItem> items;
  final String? tableLabel;
  final String? notes;
}
