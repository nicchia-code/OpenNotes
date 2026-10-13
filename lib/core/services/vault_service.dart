import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:yaml_writer/yaml_writer.dart';
import '../models/note_model.dart';
import 'database_service.dart';

/// Manages direct file system operations on the Markdown vault:
/// - Writing .md files with YAML Frontmatter
/// - Managing attachments/ folder for images and drawings
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

  /// Saves a note to the file named after its current title and returns that path.
  /// A title change writes a new file and leaves the old one in the vault.
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
    final titleChars = sanitizedTitle.runes.length;
    if (sanitizedTitle.startsWith('_{') || sanitizedTitle.startsWith('{') || titleChars > 50) {
      sanitizedTitle = titleChars > 50 ? String.fromCharCodes(sanitizedTitle.runes.take(50)).trim() : '';
    }
    final safeId = note.id.length >= 8 ? note.id.substring(0, 8) : note.id;
    final fileName = sanitizedTitle.isEmpty
        ? 'nota_$safeId.md'
        : '$sanitizedTitle.md';

    final filePath = p.join(targetFolder.path, fileName);
    final content = serializeNoteToMarkdown(note);
    await File(filePath).writeAsString(content);
    return filePath;
  }

  /// Removes the Markdown file a note was last written to, if it still exists.
  Future<void> deleteNoteFile(String? filePath) async {
    if (filePath == null) return;
    final file = File(filePath);
    if (await file.exists()) await file.delete();
  }

  /// Removes the Markdown file a note was last written to, unless another note still
  /// in [db] (trash included) is written to the same file. In that case the file is
  /// rewritten with the current content of that note (the most recently updated one),
  /// so the deleted note's text does not stay in the vault. [exceptNoteId] is the note
  /// being deleted, which still sits in [db] when the file goes first. Notes already
  /// removed from [db] in the same operation do not count, so the last one removed
  /// deletes the file.
  Future<void> deleteNoteFileIfUnused(DatabaseService db, String? filePath, {String? exceptNoteId}) async {
    if (filePath == null) return;
    final remaining = await db.getNotesWrittenTo(filePath, exceptNoteId: exceptNoteId);
    if (remaining.isEmpty) {
      await deleteNoteFile(filePath);
      return;
    }
    await File(filePath).writeAsString(serializeNoteToMarkdown(remaining.first));
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
}
