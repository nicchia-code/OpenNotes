import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';
import '../models/note_model.dart';

/// Manages direct file system operations on the Markdown vault:
/// - Writing and reading .md files with YAML Frontmatter
/// - Managing attachments/ folder for images and drawings
/// - Synchronizing with disk changes
class VaultService {
  Directory? _vaultDir;
  Directory? _attachmentsDir;

  Directory get vaultDir {
    if (_vaultDir == null) {
      throw StateError('VaultService is not initialized. Call init() first.');
    }
    return _vaultDir!;
  }

  Directory get attachmentsDir {
    if (_attachmentsDir == null) {
      throw StateError('VaultService is not initialized. Call init() first.');
    }
    return _attachmentsDir!;
  }

  /// Initializes the vault directory. Uses app documents directory/OpenNotes
  /// or a custom path if provided.
  Future<void> init({String? customPath}) async {
    if (customPath != null && customPath.isNotEmpty) {
      _vaultDir = Directory(customPath);
    } else {
      final docsDir = await getApplicationDocumentsDirectory();
      _vaultDir = Directory(p.join(docsDir.path, 'OpenNotes_Vault'));
    }

    if (!await _vaultDir!.exists()) {
      await _vaultDir!.create(recursive: true);
    }

    // Attachments directory
    _attachmentsDir = Directory(p.join(_vaultDir!.path, 'attachments'));
    if (!await _attachmentsDir!.exists()) {
      await _attachmentsDir!.create(recursive: true);
    }
  }

  /// Parses a Markdown file with YAML Frontmatter into a Note object.
  static ({Note note, String rawContent}) parseMarkdownFile(String fileContent, String filePath) {
    final frontmatterRegex = RegExp(r'^---\r?\n([\s\S]*?)\r?\n---\r?\n?');
    final match = frontmatterRegex.firstMatch(fileContent);

    Map<String, dynamic> metadata = {};
    String bodyContent = fileContent;

    if (match != null) {
      final yamlString = match.group(1) ?? '';
      try {
        final doc = loadYaml(yamlString);
        if (doc is YamlMap) {
          metadata = Map<String, dynamic>.from(doc);
        }
      } catch (e) {
        debugPrint('Error loading YAML frontmatter: $e');
      }
      bodyContent = fileContent.substring(match.end);
    }

    final id = metadata['id']?.toString() ?? p.basenameWithoutExtension(filePath);
    final title = metadata['title']?.toString() ?? Note.extractTitle(bodyContent);
    final folderId = metadata['folder_id']?.toString() ?? 'notes';
    final isPinned = metadata['pinned'] == true || metadata['is_pinned'] == true;
    final isLocked = metadata['locked'] == true || metadata['is_locked'] == true;
    final isDeleted = metadata['deleted'] == true || metadata['is_deleted'] == true;

    final combinedTags = <String>{};
    if (metadata['tags'] is List) {
      for (final e in (metadata['tags'] as List)) {
        final clean = e.toString().replaceAll('#', '').trim().toLowerCase();
        if (clean.isNotEmpty) combinedTags.add(clean);
      }
    }
    for (final t in Note.extractTagsFromContent(bodyContent)) {
      final clean = t.replaceAll('#', '').trim().toLowerCase();
      if (clean.isNotEmpty) combinedTags.add(clean);
    }
    final tags = combinedTags.toList()..sort();

    final createdAt = metadata['created_at'] != null
        ? DateTime.tryParse(metadata['created_at'].toString()) ?? DateTime.now()
        : DateTime.now();
    final updatedAt = metadata['updated_at'] != null
        ? DateTime.tryParse(metadata['updated_at'].toString()) ?? DateTime.now()
        : DateTime.now();

    final note = Note(
      id: id,
      title: title,
      content: bodyContent,
      folderId: folderId,
      tags: tags,
      isPinned: isPinned,
      isLocked: isLocked,
      isDeleted: isDeleted,
      createdAt: createdAt,
      updatedAt: updatedAt,
      filePath: filePath,
    );

    return (note: note, rawContent: bodyContent);
  }

  /// Serializes a Note to Markdown with standard YAML Frontmatter.
  static String serializeNoteToMarkdown(Note note) {
    final yamlWriter = YamlWriter();
    final frontmatterMap = {
      'id': note.id,
      'title': note.title,
      'folder_id': note.folderId,
      'tags': note.tags,
      'pinned': note.isPinned,
      'locked': note.isLocked,
      'deleted': note.isDeleted,
      'created_at': note.createdAt.toUtc().toIso8601String(),
      'updated_at': note.updatedAt.toUtc().toIso8601String(),
    };

    final yamlString = yamlWriter.write(frontmatterMap).trim();
    return '---\n$yamlString\n---\n\n${note.content}';
  }

  /// Saves or updates a note file on disk.
  Future<String> saveNote(Note note, {String? folderPath}) async {
    final targetFolder = folderPath != null ? Directory(folderPath) : vaultDir;
    if (!await targetFolder.exists()) {
      await targetFolder.create(recursive: true);
    }

    // Sanitize filename from title or use note ID
    var sanitizedTitle = note.title
        .replaceAll(RegExp(r'[\\/:*?"<>|{}\[\]]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (sanitizedTitle.startsWith('_{') || sanitizedTitle.startsWith('{') || sanitizedTitle.length > 50) {
      sanitizedTitle = sanitizedTitle.length > 50 ? sanitizedTitle.substring(0, 50).trim() : '';
    }
    final safeId = note.id.length >= 8 ? note.id.substring(0, 8) : note.id;
    final fileName = sanitizedTitle.isEmpty
        ? 'nota_$safeId.md'
        : '$sanitizedTitle.md';

    final filePath = note.filePath ?? p.join(targetFolder.path, fileName);
    final file = File(filePath);

    final content = serializeNoteToMarkdown(note);
    await file.writeAsString(content);
    return filePath;
  }

  /// Saves an image or drawing bytes to attachments/ and returns relative path.
  Future<String> saveAttachment(List<int> bytes, String extension) async {
    final fileName = 'att_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final file = File(p.join(attachmentsDir.path, fileName));
    await file.writeAsBytes(bytes);
    return 'attachments/$fileName';
  }

  /// Resolves relative attachment path to absolute File
  File resolveAttachment(String relativePath) {
    return File(p.join(vaultDir.path, relativePath));
  }

  /// Reads a note from a given file path.
  Future<Note?> readNote(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return null;
    final content = await file.readAsString();
    return parseMarkdownFile(content, filePath).note;
  }

  /// Permanently deletes a note file from disk.
  Future<void> deleteNoteFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
