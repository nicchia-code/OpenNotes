import 'dart:convert';
import 'style_span.dart';
export 'style_span.dart';

enum BlockType {
  title,
  h1,
  h2,
  h3,
  paragraph,
  code,
  bullet,
  numbered,
  checklist,
  quote,
  divider,
  table,
  image,
}

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

  /// One character allowed in a tag name after `#`: letters and digits of any alphabet, `_` and `-`.
  static const tagNameChar = r'[\p{L}\p{M}\p{Nd}_\-]';

  /// Checks if a string contains only hashtags (e.g. "#lavoro #progetto")
  static bool isOnlyTags(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    final tokens = trimmed.split(RegExp(r'\s+'));
    return tokens.every(
      (token) => RegExp(r'^#(' + tagNameChar + r'+)$', unicode: true).hasMatch(token),
    );
  }

  /// Index of the JSON block the title comes from: a `title` block wins,
  /// otherwise the first text block that is not an image or table. -1 if none.
  static int _titleBlockIndex(List<dynamic> list) {
    var firstText = -1;
    for (var i = 0; i < list.length; i++) {
      final item = list[i];
      if (item is! Map<String, dynamic>) continue;
      final type = item['type'] as String?;
      final text = (item['text'] as String?)?.trim() ?? '';
      if (text.isEmpty || isOnlyTags(text) || _titleLine(text).isEmpty) continue;
      if (type == 'title') return i;
      if (firstText < 0 && type != 'image' && type != 'table') firstText = i;
    }
    return firstText;
  }

  /// First line of a block text that still has text once its leading `#` are removed; '' if none.
  static String _titleLine(String text) {
    for (final line in text.split('\n')) {
      if (_stripHashes(line).isNotEmpty) return line;
    }
    return '';
  }

  static String _stripHashes(String line) => line.trim().replaceFirst(RegExp(r'^#+\s*'), '').trim();

  /// Index of the plain-text line the title comes from, -1 if none.
  static int _titleLineIndex(List<String> lines) {
    for (var i = 0; i < lines.length; i++) {
      final t = lines[i].trim();
      if (t.isEmpty || isOnlyTags(t)) continue;
      if (t.replaceFirst(RegExp(r'^#+\s*'), '').trim().isNotEmpty) return i;
    }
    return -1;
  }

  static String _clipTitle(String text) {
    final firstLine = text
        .split('\n')
        .first
        .trim()
        .replaceFirst(RegExp(r'^#+\s*'), '')
        .trim();
    final runes = firstLine.runes;
    return runes.length > 60
        ? String.fromCharCodes(runes.take(60)).trim()
        : firstLine;
  }

  /// Derives title and preview snippet from content (supports JSON blocks or text).
  static String extractTitle(
    String rawContent, [
    String defaultTitle = 'Nuova nota',
  ]) {
    final trimmed = rawContent.trim();
    if (trimmed.startsWith('[')) {
      try {
        final list = jsonDecode(trimmed);
        // Only a list of objects is a block document (an empty list too, with no title); anything else is plain text.
        if (list is List && list.every((e) => e is Map<String, dynamic>)) {
          final index = _titleBlockIndex(list);
          if (index >= 0) {
            final text = (list[index] as Map<String, dynamic>)['text'] as String;
            return _clipTitle(_titleLine(text));
          }
          return defaultTitle;
        }
      } catch (_) {
        // Not JSON: plain text starting with '[' falls through to lines.
      }
    }

    final lines = rawContent.split('\n');
    final index = _titleLineIndex(lines);
    return index >= 0 ? _clipTitle(lines[index]) : defaultTitle;
  }

  /// Extracts a short preview snippet from content, skipping the block or
  /// line the title is taken from so the title is never repeated.
  static String extractSnippet(String rawContent, {bool isLocked = false}) {
    if (isLocked) {
      return 'Questa nota è protetta';
    }

    final trimmed = rawContent.trim();
    if (trimmed.startsWith('[')) {
      try {
        final list = jsonDecode(trimmed);
        // Same block-document test as extractTitle: only a list of objects; anything else is plain text.
        if (list is List && list.every((e) => e is Map<String, dynamic>)) {
          final titleIndex = _titleBlockIndex(list);
          final buffer = StringBuffer();
          var length = 0;

          for (var i = 0; i < list.length; i++) {
            final item = list[i];
            if (i == titleIndex || item is! Map<String, dynamic>) continue;
            if (item['type'] == 'image') continue;
            final text = (item['text'] as String?)?.trim() ?? '';
            if (text.isEmpty || isOnlyTags(text) || _titleLine(text).isEmpty) continue;
            if (length > 0) {
              buffer.write(' ');
              length++;
            }
            buffer.write(text);
            length += text.runes.length;
            if (length > 90) break;
          }
          final res = buffer.toString().trim();
          if (res.isNotEmpty) return res;
        }
      } catch (_) {}
    }

    final lines = rawContent.split('\n');
    final titleIndex = _titleLineIndex(lines);
    final buffer = StringBuffer();
    var length = 0;

    for (var i = 0; i < lines.length; i++) {
      if (i == titleIndex) continue;
      final t = lines[i].trim();
      if (t.isEmpty) continue;
      if (isOnlyTags(t)) continue;
      final cleanLine = t
          .replaceAll(RegExp(r'^[#\-*+>]+\s*'), '')
          .replaceAll(RegExp(r'^\d+[.)]\s+'), '')
          .replaceAll(RegExp(r'^[•○●◦▪]\s*'), '')
          .replaceAll(RegExp(r'\[[ xX]\]'), '')
          .replaceAll('**', '')
          .replaceAll('*', '')
          .replaceAll('`', '')
          .trim();
      if (cleanLine.isNotEmpty) {
        if (length > 0) {
          buffer.write(' ');
          length++;
        }
        buffer.write(cleanLine);
        length += cleanLine.runes.length;
        if (length > 90) break;
      }
    }

    final result = buffer.toString();
    return result.isEmpty ? 'Nessun testo aggiuntivo' : result;
  }

  /// Extracts a short preview snippet from content (ignoring first line/title)
  String get snippet =>
      cachedSnippet ?? extractSnippet(content, isLocked: isLocked);

  /// Exports the note's structured content to standard clean Markdown (.md)
  String toMarkdown() {
    final blocks = readBlocks();
    if (blocks == null) {
      // Already plain markdown / text
      return content
          .replaceAllMapped(
            RegExp(r'(^|\n)(\s*)○[ \t]*'),
            (m) => '${m.group(1)}${m.group(2)}- [ ] ',
          )
          .replaceAllMapped(
            RegExp(r'(^|\n)(\s*)●[ \t]*'),
            (m) => '${m.group(1)}${m.group(2)}- [x] ',
          )
          .replaceAllMapped(
            RegExp(r'(^|\n)(\s*)[•◦▪][ \t]*'),
            (m) => '${m.group(1)}${m.group(2)}- ',
          )
          .trimRight();
    }

    try {
      final buffer = StringBuffer();

      for (final item in blocks) {
        if (item is! Map<String, dynamic>) continue;

        final type = item['type'] as String? ?? 'paragraph';
        final rawText = item['text'] as String? ?? '';
        final isChecked = item['isChecked'] as bool? ?? false;
        final rawSpans = (item['spans'] as List<dynamic>?) ?? [];

        // Reconstruct formatted span text
        String blockFormatted = rawText;
        if (rawSpans.isNotEmpty) {
          final spans = rawSpans
              .map((s) => StyleSpan.fromJson(s as Map<String, dynamic>))
              .toList();
          final boundaries = <int>{0, rawText.length};
          for (final s in spans) {
            if (s.start >= 0 && s.start <= rawText.length)
              boundaries.add(s.start);
            if (s.end >= 0 && s.end <= rawText.length) boundaries.add(s.end);
          }
          final sorted = boundaries.toList()..sort();
          // Consecutive segments with the same styles form one run, so each
          // marker pair wraps the whole run, not every piece another style split.
          final runs = <(String, bool, bool, bool)>[];
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

            if (runs.isNotEmpty &&
                runs.last.$2 == isBold &&
                runs.last.$3 == isItalic &&
                runs.last.$4 == isStrikethrough) {
              final last = runs.removeLast();
              runs.add((last.$1 + segText, isBold, isItalic, isStrikethrough));
            } else {
              runs.add((segText, isBold, isItalic, isStrikethrough));
            }
          }
          final spanBuf = StringBuffer();
          for (final (text, isBold, isItalic, isStrikethrough) in runs) {
            // Markers wrap the text only: its edge spaces stay outside them.
            final core = text.trim();
            if (core.isEmpty) {
              spanBuf.write(text);
              continue;
            }
            final lead = text.substring(0, text.indexOf(core));
            final trail = text.substring(lead.length + core.length);
            String chunk = core;
            if (isBold) chunk = '**$chunk**';
            if (isItalic) chunk = '*$chunk*';
            if (isStrikethrough) chunk = '~~$chunk~~';
            spanBuf.write('$lead$chunk$trail');
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
              final rows = tableDataRaw
                  .map(
                    (r) =>
                        (r as List<dynamic>).map((c) => c.toString()).toList(),
                  )
                  .toList();
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
            final Map<int, String> parsedLineStyles = {};
            if (item['lineStyles'] is Map) {
              final rawMap = item['lineStyles'] as Map<String, dynamic>;
              for (final entry in rawMap.entries) {
                final lineIdx = int.tryParse(entry.key);
                if (lineIdx != null) {
                  parsedLineStyles[lineIdx] = entry.value.toString();
                }
              }
            }

            final rawLines = blockFormatted.split('\n');
            final formattedLines = <String>[];
            for (int li = 0; li < rawLines.length; li++) {
              final line = rawLines[li];
              final style = parsedLineStyles[li];
              if (style == 'title' && !line.startsWith('#')) {
                formattedLines.add(line.isEmpty ? '' : '# $line');
              } else if (style == 'h1' && !line.startsWith('#')) {
                formattedLines.add('# $line');
              } else if (style == 'h2' && !line.startsWith('#')) {
                formattedLines.add('## $line');
              } else if (style == 'h3' && !line.startsWith('#')) {
                formattedLines.add('### $line');
              } else {
                formattedLines.add(line);
              }
            }
            final linesJoined = formattedLines.join('\n');
            final paraFormatted = linesJoined
                .replaceAllMapped(
                  RegExp(r'(^|\n)(\s*)○[ \t]*'),
                  (m) => '${m.group(1)}${m.group(2)}- [ ] ',
                )
                .replaceAllMapped(
                  RegExp(r'(^|\n)(\s*)●[ \t]*'),
                  (m) => '${m.group(1)}${m.group(2)}- [x] ',
                )
                .replaceAllMapped(
                  RegExp(r'(^|\n)(\s*)[•◦▪][ \t]*'),
                  (m) => '${m.group(1)}${m.group(2)}- ',
                );
            buffer.writeln(paraFormatted);
            break;
        }
      }

      return buffer.toString().trimRight();
    } catch (_) {
      return content;
    }
  }

  /// Markdown of the body without the block or line the title comes from,
  /// so the title is never printed twice, whatever its clipping or styling.
  String toMarkdownBody() {
    // A leading blank line here would become a second blank line after the title.
    return _markdownWithoutTitle().replaceFirst(RegExp(r'^(?:[ \t]*\n)+'), '');
  }

  String _markdownWithoutTitle() {
    final blocks = readBlocks();
    if (blocks == null) {
      final lines = content.split('\n');
      final index = _titleLineIndex(lines);
      if (index < 0) return toMarkdown();
      lines.removeAt(index);
      return copyWith(content: lines.join('\n')).toMarkdown();
    }
    final index = _titleBlockIndex(blocks);
    if (index < 0) return toMarkdown();
    final body = _blockWithoutTitleLine(blocks[index] as Map<String, dynamic>);
    final result = [...blocks];
    if (body == null) {
      result.removeAt(index);
    } else {
      result[index] = body;
    }
    return copyWith(content: jsonEncode(result)).toMarkdown();
  }

  /// The block without its title line: the other lines keep their text, spans and
  /// line styles, shifted to the new line numbers. Null when no text is left.
  static Map<String, dynamic>? _blockWithoutTitleLine(Map<String, dynamic> block) {
    final text = block['text'] as String? ?? '';
    final lines = text.split('\n');
    final titleLine = lines.indexWhere((line) => _stripHashes(line).isNotEmpty);
    if (titleLine < 0) return block;
    if (lines.length == 1) return null;

    var lineStart = 0;
    for (var i = 0; i < titleLine; i++) {
      lineStart += lines[i].length + 1;
    }
    // Cut the title line with its newline; the last line takes the newline before it.
    final isLast = titleLine == lines.length - 1;
    final cutStart = isLast ? lineStart - 1 : lineStart;
    final cutEnd = isLast ? text.length : lineStart + lines[titleLine].length + 1;
    final rest = text.substring(0, cutStart) + text.substring(cutEnd);
    if (rest.trim().isEmpty) return null;

    int shift(int p) => p <= cutStart
        ? p
        : p >= cutEnd
            ? p - (cutEnd - cutStart)
            : cutStart;
    final spans = <dynamic>[];
    for (final raw in (block['spans'] as List<dynamic>?) ?? const <dynamic>[]) {
      final span = raw as Map<String, dynamic>;
      final start = shift(span['start'] as int? ?? 0);
      final end = shift(span['end'] as int? ?? 0);
      if (start < end) spans.add({...span, 'start': start, 'end': end});
    }
    final lineStyles = <String, dynamic>{};
    final rawStyles = block['lineStyles'];
    if (rawStyles is Map) {
      rawStyles.forEach((key, value) {
        final line = int.tryParse(key.toString());
        if (line == null || line == titleLine) return;
        lineStyles[line > titleLine ? '${line - 1}' : key.toString()] = value;
      });
    }
    // A dedicated title block's other lines are body text, not title.
    final type = block['type'] == 'title' ? 'paragraph' : block['type'];
    return {
      ...block,
      'type': type,
      'text': rest,
      'spans': spans,
      'lineStyles': lineStyles,
    };
  }

  /// The blocks of a block document, or null when the content is plain text.
  List<dynamic>? readBlocks() {
    try {
      final decoded = jsonDecode(content.trim());
      if (decoded is List && decoded.every((e) => e is Map<String, dynamic>)) {
        return decoded;
      }
    } catch (_) {}
    return null;
  }

  /// Extracts tags formatted as #tag from content (supports both JSON blocks and plain Markdown)
  static List<String> extractTagsFromContent(String text) {
    final set = <String>{};
    final tagRegex = RegExp(
      r'(?<=^|[\s\(\[\{])#(' + tagNameChar + r'+)',
      unicode: true,
    );

    final trimmed = text.trim();
    if (trimmed.startsWith('[')) {
      try {
        final list = jsonDecode(trimmed);
        // Only a list whose items are all objects is a block document; anything else is plain text.
        if (list is! List || !list.every((item) => item is Map<String, dynamic>)) {
          throw const FormatException('not a block list');
        }
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

  /// The stored tags, normalized: no `#`, trimmed, lowercase, sorted, no blanks.
  List<String> get storedTags {
    final stored = tags.map((t) => t.replaceAll('#', '').trim().toLowerCase());
    return stored.where((t) => t.isNotEmpty).toSet().toList()..sort();
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
    bool clearDeletedAt = false,
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
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
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
      deletedAt: map['deleted_at'] != null
          ? DateTime.tryParse(map['deleted_at'] as String)
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? (DateTime.tryParse(map['updated_at'] as String) ?? DateTime.now()).toLocal()
          : DateTime.now(),
      syncedAt: map['synced_at'] != null
          ? DateTime.tryParse(map['synced_at'] as String)
          : null,
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
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
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
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? (DateTime.tryParse(json['updated_at'] as String) ?? DateTime.now()).toLocal()
          : DateTime.now(),
      syncedAt: DateTime.now(),
      cachedSnippet: Note.extractSnippet(
        json['content'] as String? ?? '',
        isLocked: json['is_locked'] as bool? ?? false,
      ),
    );
  }
}
