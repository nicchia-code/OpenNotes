import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/note_model.dart';

/// Service to generate Apple Notes-styled formatted PDF documents.
class PdfExportService {
  static Future<void> exportNoteToPdf(Note note) async {
    final pdf = pw.Document();
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
          final lines = note.content.split('\n');
          bool skippedFirstLine = false;

          for (final rawLine in lines) {
            final line = rawLine.trimRight();
            if (line.isEmpty) {
              widgets.add(pw.SizedBox(height: 8));
              continue;
            }

            if (!skippedFirstLine && line.trim() == note.title) {
              skippedFirstLine = true;
              continue;
            }

            // Headings
            if (line.startsWith('# ')) {
              widgets.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 12, bottom: 4),
                  child: pw.Text(
                    line.substring(2).trim(),
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              );
            } else if (line.startsWith('## ')) {
              widgets.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 10, bottom: 4),
                  child: pw.Text(
                    line.substring(3).trim(),
                    style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              );
            } else if (line.startsWith('### ')) {
              widgets.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 8, bottom: 4),
                  child: pw.Text(
                    line.substring(4).trim(),
                    style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              );
            } else if (line.startsWith('- [ ] ') || line.startsWith('- [x] ') || line.startsWith('- [X] ')) {
              // Checklist item
              final isChecked = !line.startsWith('- [ ] ');
              final text = line.substring(6).trim();
              widgets.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 3),
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
            } else if (line.startsWith('- ') || line.startsWith('* ')) {
              // Bullet item
              widgets.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
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
                          line.substring(2).trim(),
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

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${note.title}.pdf',
    );
  }
}
