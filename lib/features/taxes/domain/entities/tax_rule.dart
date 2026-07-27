class TaxRule {
  const TaxRule({
    required this.id,
    required this.name,
    required this.rateBasisPoints,
    required this.isActive,
  });
  final String id;
  final String name;
  final int rateBasisPoints;
  final bool isActive;
}
