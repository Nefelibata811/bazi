class ShenshaItem {
  const ShenshaItem({
    required this.name,
    required this.target,
    required this.description,
    this.pillar,
  });

  final String name;
  final String target;
  final String description;
  final String? pillar;
}
