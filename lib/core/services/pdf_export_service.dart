import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/note_model.dart';

/// Service to generate Apple Notes-styled formatted PDF documents.
class PdfExportService {
  static bool _printDialogOpen = false;

  /// Opens the print dialog for [note]. Requests made while a print dialog is
  /// already open are ignored, so only one dialog is ever shown at a time.
  /// A protected note opens the dialog only when [confirmPin] returns true.
  static Future<void> exportNoteToPdf(
    Note note, {
    required Future<bool> Function() confirmPin,
  }) async {
    if (_printDialogOpen) return;
    _printDialogOpen = true;
    try {
      if (note.isLocked && !await confirmPin()) return;
      await _openPrintDialog(note);
    } finally {
      _printDialogOpen = false;
    }
  }

  static Future<void> _openPrintDialog(Note note) async {
    final pdf = await _buildDocument(note);

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${note.title}.pdf',
    );
  }

  /// The PDF bytes of [note], as the print dialog receives them.
  @visibleForTesting
  static Future<Uint8List> buildPdfBytes(Note note) async => (await _buildDocument(note)).save();

  static Future<pw.Document> _buildDocument(Note note) async {
    final pdf = pw.Document(theme: await _unicodeTheme());
    final dateFormat = DateFormat('d MMMM yyyy, HH:mm', 'it_IT');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          final widgets = <pw.Widget>[];

          // Apple Notes Header Date
          widgets.add(
            pw.Text(
              dateFormat.format(note.updatedAt),
              style: pw.TextStyle(
                color: PdfColors.grey700,
                fontSize: 10,
                fontWeight: pw.FontWeight.normal,
              ),
            ),
          );
          widgets.add(pw.SizedBox(height: 8));

          // Title
          widgets.add(
            pw.Text(
              note.title,
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
            ),
          );
          widgets.add(pw.SizedBox(height: 16));
          widgets.add(pw.Divider(color: PdfColors.grey300, thickness: 0.5));
          widgets.add(pw.SizedBox(height: 16));

          // Body text parsing
          final lines = note.toMarkdownBody().split('\n');

          for (final rawLine in lines) {
            final line = rawLine.trimRight();
            if (line.isEmpty) {
              widgets.add(pw.SizedBox(height: 8));
              continue;
            }
            // List items keep their indentation
            final bullet = line.trimLeft();
            final indent = (line.length - bullet.length) * 4.0;

            // Headings
            if (hasMarker(bullet, '# ')) {
              widgets.add(
                pw.Padding(
                  padding: pw.EdgeInsets.fromLTRB(indent, 12, 0, 4),
                  child: pw.Text(
                    headingText(bullet, '# '),
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              );
            } else if (hasMarker(bullet, '## ')) {
              widgets.add(
                pw.Padding(
                  padding: pw.EdgeInsets.fromLTRB(indent, 10, 0, 4),
                  child: pw.Text(
                    headingText(bullet, '## '),
                    style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              );
            } else if (hasMarker(bullet, '### ')) {
              widgets.add(
                pw.Padding(
                  padding: pw.EdgeInsets.fromLTRB(indent, 8, 0, 4),
                  child: pw.Text(
                    headingText(bullet, '### '),
                    style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              );
            } else if (hasMarker(bullet, '- [ ] ') || hasMarker(bullet, '- [x] ') || hasMarker(bullet, '- [X] ')) {
              // Checklist item
              final isChecked = !hasMarker(bullet, '- [ ] ');
              final text = afterMarker(bullet, '- [ ] ');
              widgets.add(
                pw.Padding(
                  padding: pw.EdgeInsets.fromLTRB(indent, 3, 0, 3),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 12,
                        height: 12,
                        margin: const pw.EdgeInsets.only(top: 2, right: 8),
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          border: pw.Border.all(
                            color: isChecked ? PdfColors.amber800 : PdfColors.grey500,
                            width: 1.5,
                          ),
                          color: isChecked ? PdfColors.amber800 : null,
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          text,
                          style: pw.TextStyle(
                            fontSize: 11,
                            color: isChecked ? PdfColors.grey600 : PdfColors.black,
                            decoration: isChecked ? pw.TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else if (hasMarker(bullet, '- ') || hasMarker(bullet, '* ')) {
              // Bullet item
              widgets.add(
                pw.Padding(
                  padding: pw.EdgeInsets.fromLTRB(indent, 2, 0, 2),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 4,
                        height: 4,
                        margin: const pw.EdgeInsets.only(top: 6, right: 8, left: 4),
                        decoration: const pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          afterMarker(bullet, '- '),
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              // Regular paragraph
              widgets.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Text(
                    line,
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ),
              );
            }
          }

          return widgets;
        },
      ),
    );
    return pdf;
  }

  /// Text uses embedded Unicode fonts instead of the built-in Helvetica, which
  /// only covers Latin-1. The color emoji font is a fallback for emoji.
  static Future<pw.ThemeData> _unicodeTheme() async {
    final base = pw.Font.ttf(await rootBundle.load('assets/fonts/DejaVuSans.ttf'));
    final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/DejaVuSans-Bold.ttf'));
    final emoji = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoColorEmoji.ttf'));
    return pw.ThemeData.withFont(base: base, bold: bold, fontFallback: [emoji]);
  }
}

/// Whether [line] carries [marker] (for example `- `), also when the marker
/// has no text after it: trimming the line drops the trailing space.
bool hasMarker(String line, String marker) =>
    line == marker.trimRight() || line.startsWith(marker);

/// The text after [marker], or empty when the marker stands alone.
String afterMarker(String line, String marker) =>
    line.length <= marker.length ? '' : line.substring(marker.length).trim();

/// The heading text after [marker]. An empty heading gets a non-breaking space:
/// an empty text has no line, so it would take no heading height.
String headingText(String line, String marker) {
  final text = afterMarker(line, marker);
  return text.isEmpty ? '\u00A0' : text;
}
