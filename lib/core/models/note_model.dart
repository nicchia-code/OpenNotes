import 'dart:convert';
import 'style_span.dart';
export 'style_span.dart';

/// Represents a single Note in OpenNotes.
/// Compatible with Apple Notes data structure and Markdown storage.
class Note {
  final String id;
  final String title;
  final String content;
  final String folderId;
  final List<String> tags;
  final bool isPinned;
  final bool isLocked;
  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? syncedAt;
  final String? filePath;
  final String? cachedSnippet;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    this.folderId = 'notes',
    this.tags = const [],
    this.isPinned = false,
    this.isLocked = false,
    this.isDeleted = false,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    this.syncedAt,
    this.filePath,
    this.cachedSnippet,
  });

  /// Derives title and preview snippet from content (supports JSON blocks or text).
  static String extractTitle(String rawContent, [String defaultTitle = 'Nuova nota']) {
    final trimmed = rawContent.trim();
    if (trimmed.startsWith('[')) {
      try {
        final list = jsonDecode(trimmed) as List<dynamic>;
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            final type = item['type'] as String?;
            final text = (item['text'] as String?)?.trim() ?? '';
            if (type == 'title' && text.isNotEmpty) {
              final firstLine = text.split('\n').first.trim().replaceFirst(RegExp(r'^#+\s*'), '');
              return firstLine.length > 60 ? firstLine.substring(0, 60).trim() : firstLine;
            }
            if (text.isNotEmpty && type != 'image' && type != 'table') {
              final firstLine = text.split('\n').first.trim().replaceFirst(RegExp(r'^#+\s*'), '');
              return firstLine.length > 60 ? firstLine.substring(0, 60).trim() : firstLine;
            }
          }
        }
      } catch (_) {}
      return defaultTitle;
    }

    final lines = rawContent.split('\n');
    for (final line in lines) {
      final t = line.trim();
      if (t.isNotEmpty) {
        final cleaned = t.replaceFirst(RegExp(r'^#+\s*'), '').trim();
        if (cleaned.isNotEmpty) {
          return cleaned.length > 60 ? cleaned.substring(0, 60).trim() : cleaned;
        }
      }
    }
    return defaultTitle;
  }

  /// Extracts a short preview snippet from content (ignoring first line/title)
  static String extractSnippet(String rawContent, {bool isLocked = false}) {
    if (isLocked) {
      return 'Questa nota è protetta';
    }

    final trimmed = rawContent.trim();
    if (trimmed.startsWith('[')) {
      try {
        final list = jsonDecode(trimmed) as List<dynamic>;
        final buffer = StringBuffer();
        bool skippedTitle = false;

        for (final item in list) {
          if (item is Map<String, dynamic>) {
            final type = item['type'] as String?;
            final text = (item['text'] as String?)?.trim() ?? '';
            if (!skippedTitle && (type == 'title' || type == 'h1')) {
              skippedTitle = true;
              continue;
            }
            if (text.isNotEmpty) {
              if (buffer.isNotEmpty) buffer.write(' ');
              buffer.write(text);
              if (buffer.length > 90) break;
            }
          }
        }
        final res = buffer.toString().trim();
        if (res.isNotEmpty) return res;
      } catch (_) {}
    }

    final lines = rawContent.split('\n');
    bool skippedTitle = false;
    final buffer = StringBuffer();

    for (final line in lines) {
      final t = line.trim();
      if (t.isEmpty) continue;
      if (!skippedTitle) {
        skippedTitle = true;
        continue;
      }
      final cleanLine = t
          .replaceAll(RegExp(r'^[#\-*+>\d\.]+\s*'), '')
          .replaceAll(RegExp(r'^[•○●]\s*'), '')
          .replaceAll(RegExp(r'\[[ xX]\]'), '')
          .replaceAll('**', '')
          .replaceAll('*', '')
          .replaceAll('`', '')
          .trim();
      if (cleanLine.isNotEmpty) {
        if (buffer.isNotEmpty) buffer.write(' ');
        buffer.write(cleanLine);
        if (buffer.length > 90) break;
      }
    }

    final result = buffer.toString();
    return result.isEmpty ? 'Nessun testo aggiuntivo' : result;
  }

  /// Extracts a short preview snippet from content (ignoring first line/title)
  String get snippet => cachedSnippet ?? extractSnippet(content, isLocked: isLocked);

  /// Exports the note's structured content to standard clean Markdown (.md)
  String toMarkdown() {
    final trimmed = content.trim();
    if (!trimmed.startsWith('[')) {
      // Already plain markdown / text
      return content
          .replaceAllMapped(RegExp(r'(^|\n)○\s*'), (m) => '${m.group(1)}- [ ] ')
          .replaceAllMapped(RegExp(r'(^|\n)●\s*'), (m) => '${m.group(1)}- [x] ')
          .replaceAllMapped(RegExp(r'(^|\n)•\s*'), (m) => '${m.group(1)}- ');
    }

    try {
      final list = jsonDecode(trimmed) as List<dynamic>;
      final buffer = StringBuffer();

      for (final item in list) {
        if (item is! Map<String, dynamic>) continue;

        final type = item['type'] as String? ?? 'paragraph';
        final rawText = item['text'] as String? ?? '';
        final isChecked = item['isChecked'] as bool? ?? false;
        final rawSpans = (item['spans'] as List<dynamic>?) ?? [];

        // Reconstruct formatted span text
        String blockFormatted = rawText;
        if (rawSpans.isNotEmpty) {
          final spans = rawSpans.map((s) => StyleSpan.fromJson(s as Map<String, dynamic>)).toList();
          final boundaries = <int>{0, rawText.length};
          for (final s in spans) {
            if (s.start >= 0 && s.start <= rawText.length) boundaries.add(s.start);
            if (s.end >= 0 && s.end <= rawText.length) boundaries.add(s.end);
          }
          final sorted = boundaries.toList()..sort();
          final spanBuf = StringBuffer();
          for (int i = 0; i < sorted.length - 1; i++) {
            final segStart = sorted[i];
            final segEnd = sorted[i + 1];
            if (segStart >= segEnd) continue;
            final segText = rawText.substring(segStart, segEnd);

            bool isBold = false;
            bool isItalic = false;
            bool isStrikethrough = false;

            for (final s in spans) {
              if (s.start <= segStart && s.end >= segEnd) {
                if (s.isBold) isBold = true;
                if (s.isItalic) isItalic = true;
                if (s.isStrikethrough) isStrikethrough = true;
              }
            }

            String chunk = segText;
            if (isBold) chunk = '**$chunk**';
            if (isItalic) chunk = '*$chunk*';
            if (isStrikethrough) chunk = '~~$chunk~~';
            spanBuf.write(chunk);
          }
          blockFormatted = spanBuf.toString();
        }

        switch (type) {
          case 'title':
            buffer.writeln(blockFormatted.isEmpty ? '' : '# $blockFormatted');
            break;
          case 'h1':
            buffer.writeln('# $blockFormatted');
            break;
          case 'h2':
            buffer.writeln('## $blockFormatted');
            break;
          case 'h3':
            buffer.writeln('### $blockFormatted');
            break;
          case 'checklist':
            buffer.writeln('- [${isChecked ? 'x' : ' '}] $blockFormatted');
            break;
          case 'bullet':
            buffer.writeln('- $blockFormatted');
            break;
          case 'numbered':
            buffer.writeln('1. $blockFormatted');
            break;
          case 'quote':
            buffer.writeln('> $blockFormatted');
            break;
          case 'divider':
            buffer.writeln('---');
            break;
          case 'image':
            buffer.writeln('![]($rawText)');
            break;
          case 'table':
            final tableDataRaw = item['tableData'] as List<dynamic>?;
            if (tableDataRaw != null && tableDataRaw.isNotEmpty) {
              final rows = tableDataRaw.map((r) => (r as List<dynamic>).map((c) => c.toString()).toList()).toList();
              int maxCols = 1;
              for (final r in rows) {
                if (r.length > maxCols) maxCols = r.length;
              }
              for (final r in rows) {
                while (r.length < maxCols) {
                  r.add('');
                }
              }
              final header = rows.first;
              buffer.writeln('| ${header.join(' | ')} |');
              buffer.writeln('| ${List.filled(maxCols, '---').join(' | ')} |');
              for (int r = 1; r < rows.length; r++) {
                buffer.writeln('| ${rows[r].join(' | ')} |');
              }
              buffer.writeln();
            }
            break;
          default:
            final paraFormatted = blockFormatted
                .replaceAllMapped(RegExp(r'(^|\n)○\s*'), (m) => '${m.group(1)}- [ ] ')
                .replaceAllMapped(RegExp(r'(^|\n)●\s*'), (m) => '${m.group(1)}- [x] ')
                .replaceAllMapped(RegExp(r'(^|\n)•\s*'), (m) => '${m.group(1)}- ');
            buffer.writeln(paraFormatted);
            break;
        }
      }

      return buffer.toString().trimRight();
    } catch (_) {
      return content;
    }
  }

  /// Extracts tags formatted as #tag from content (supports both JSON blocks and plain Markdown)
  static List<String> extractTagsFromContent(String text) {
    final set = <String>{};
    final tagRegex = RegExp(r'(?<=^|[\s\(\[\{])#([a-zA-Z0-9_\-]+)');

    final trimmed = text.trim();
    if (trimmed.startsWith('[')) {
      try {
        final list = jsonDecode(trimmed) as List<dynamic>;
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            final blockText = item['text'] as String?;
            if (blockText != null && blockText.isNotEmpty) {
              for (final m in tagRegex.allMatches(blockText)) {
                final tag = m.group(1);
                if (tag != null && tag.isNotEmpty) {
                  set.add(tag.toLowerCase());
                }
              }
            }
            if (item['tableData'] is List) {
              for (final row in (item['tableData'] as List)) {
                if (row is List) {
                  for (final cell in row) {
                    final cellText = cell?.toString() ?? '';
                    for (final m in tagRegex.allMatches(cellText)) {
                      final tag = m.group(1);
                      if (tag != null && tag.isNotEmpty) {
                        set.add(tag.toLowerCase());
                      }
                    }
                  }
                }
              }
            }
          }
        }
        return set.toList()..sort();
      } catch (_) {}
    }

    for (final m in tagRegex.allMatches(text)) {
      final tag = m.group(1);
      if (tag != null && tag.isNotEmpty) {
        set.add(tag.toLowerCase());
      }
    }
    return set.toList()..sort();
  }

  Note copyWith({
    String? id,
    String? title,
    String? content,
    String? folderId,
    List<String>? tags,
    bool? isPinned,
    bool? isLocked,
    bool? isDeleted,
    DateTime? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? syncedAt,
    String? filePath,
    String? cachedSnippet,
  }) {
    final nextContent = content ?? this.content;
    final nextIsLocked = isLocked ?? this.isLocked;
    final snippetNeedsUpdate = content != null || isLocked != null;

    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: nextContent,
      folderId: folderId ?? this.folderId,
      tags: tags ?? this.tags,
      isPinned: isPinned ?? this.isPinned,
      isLocked: nextIsLocked,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      filePath: filePath ?? this.filePath,
      cachedSnippet: snippetNeedsUpdate
          ? extractSnippet(nextContent, isLocked: nextIsLocked)
          : (cachedSnippet ?? this.cachedSnippet),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'folder_id': folderId,
      'tags': jsonEncode(tags),
      'is_pinned': isPinned ? 1 : 0,
      'is_locked': isLocked ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
      'deleted_at': deletedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'synced_at': syncedAt?.toIso8601String(),
      'file_path': filePath,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    List<String> parsedTags = [];
    if (map['tags'] != null) {
      if (map['tags'] is String) {
        try {
          final decoded = jsonDecode(map['tags'] as String);
          if (decoded is List) {
            parsedTags = decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {}
      } else if (map['tags'] is List) {
        parsedTags = (map['tags'] as List).map((e) => e.toString()).toList();
      }
    }

    return Note(
      id: (map['id'] as String?) ?? '',
      title: map['title'] as String? ?? 'Nuova nota',
      content: map['content'] as String? ?? '',
      folderId: map['folder_id'] as String? ?? 'notes',
      tags: parsedTags,
      isPinned: (map['is_pinned'] as int? ?? 0) == 1,
      isLocked: (map['is_locked'] as int? ?? 0) == 1,
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
      deletedAt: map['deleted_at'] != null ? DateTime.tryParse(map['deleted_at'] as String) : null,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      syncedAt: map['synced_at'] != null ? DateTime.tryParse(map['synced_at'] as String) : null,
      filePath: map['file_path'] as String?,
      cachedSnippet: Note.extractSnippet(
        map['content'] as String? ?? '',
        isLocked: (map['is_locked'] as int? ?? 0) == 1,
      ),
    );
  }

  /// Converts Note to Supabase Postgres JSON
  Map<String, dynamic> toSupabaseJson(String userId) {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'content': content,
      'folder_id': folderId,
      'tags': tags,
      'is_pinned': isPinned,
      'is_locked': isLocked,
      'is_deleted': isDeleted,
      'deleted_at': deletedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Note.fromSupabaseJson(Map<String, dynamic> json) {
    List<String> parsedTags = [];
    if (json['tags'] is List) {
      parsedTags = (json['tags'] as List).map((e) => e.toString()).toList();
    }
    return Note(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Nuova nota',
      content: json['content'] as String? ?? '',
      folderId: json['folder_id'] as String? ?? 'notes',
      tags: parsedTags,
      isPinned: json['is_pinned'] as bool? ?? false,
      isLocked: json['is_locked'] as bool? ?? false,
      isDeleted: json['is_deleted'] as bool? ?? false,
      deletedAt: json['deleted_at'] != null ? DateTime.tryParse(json['deleted_at'] as String) : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      syncedAt: DateTime.now(),
      cachedSnippet: Note.extractSnippet(
        json['content'] as String? ?? '',
        isLocked: json['is_locked'] as bool? ?? false,
      ),
    );
  }
}
