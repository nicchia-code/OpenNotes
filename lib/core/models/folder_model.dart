/// Represents a Folder in OpenNotes.
/// Supports nested subfolders just like Apple Notes.
class Folder {
  final String id;
  final String name;
  final String? parentId;
  final String icon;
  final bool isSystem;
  final DateTime createdAt;
  final DateTime updatedAt;
  /// Last cloud revision of this folder seen on this device; null when the device has never seen one.
  final int? cloudRevision;

  const Folder({
    required this.id,
    required this.name,
    this.parentId,
    this.icon = 'folder',
    this.isSystem = false,
    required this.createdAt,
    required this.updatedAt,
    this.cloudRevision,
  });

  Folder copyWith({
    String? id,
    String? name,
    String? parentId,
    String? icon,
    bool? isSystem,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? cloudRevision,
  }) {
    return Folder(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      icon: icon ?? this.icon,
      isSystem: isSystem ?? this.isSystem,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cloudRevision: cloudRevision ?? this.cloudRevision,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'parent_id': parentId,
      'icon': icon,
      'is_system': isSystem ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'cloud_revision': cloudRevision,
    };
  }

  factory Folder.fromMap(Map<String, dynamic> map) {
    return Folder(
      id: map['id'] as String,
      name: map['name'] as String,
      parentId: map['parent_id'] as String?,
      icon: map['icon'] as String? ?? 'folder',
      isSystem: (map['is_system'] as int? ?? 0) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      cloudRevision: map['cloud_revision'] as int?,
    );
  }

  Map<String, dynamic> toSupabaseJson(String userId) {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'parent_id': parentId,
      'icon': icon,
      'is_system': isSystem,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory Folder.fromSupabaseJson(Map<String, dynamic> json) {
    return Folder(
      id: json['id'] as String,
      name: json['name'] as String,
      parentId: json['parent_id'] as String?,
      icon: json['icon'] as String? ?? 'folder',
      isSystem: json['is_system'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      cloudRevision: json['revision'] as int?,
    );
  }

  // System folder IDs constants
  static const String allNotesId = 'system_all';
  static const String defaultNotesId = 'notes';
  static const String trashId = 'system_trash';
}
