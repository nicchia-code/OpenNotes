/// Represents a Tag used across notes in OpenNotes.
class Tag {
  final String name;
  final int count;

  const Tag({
    required this.name,
    this.count = 0,
  });

  Tag copyWith({
    String? name,
    int? count,
  }) {
    return Tag(
      name: name ?? this.name,
      count: count ?? this.count,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tag && runtimeType == other.runtimeType && name.toLowerCase() == other.name.toLowerCase();

  @override
  int get hashCode => name.toLowerCase().hashCode;
}
