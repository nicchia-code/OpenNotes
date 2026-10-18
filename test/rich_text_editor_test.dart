import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:open_notes/core/models/note_model.dart';
import 'package:open_notes/core/services/database_service.dart';
import 'package:open_notes/core/services/security_service.dart';
import 'package:open_notes/core/services/sync_service.dart';
import 'package:open_notes/core/services/vault_service.dart';
import 'package:open_notes/core/state/notes_provider.dart';
import 'package:open_notes/ui/editor/notion_document_editor.dart';
import 'package:open_notes/ui/editor/rich_text_editing_controller.dart';
import 'package:open_notes/ui/shell/mac_title_bar.dart';
import 'package:provider/provider.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('it_IT', null);
  });

  group('RichTextEditingController Unit Tests', () {
    test('a line symbol moves the formatting of its line once', () {
      final ctrl = RichTextEditingController(
        text: '• alpha\nbeta',
        baseStyle: const TextStyle(),
        spans: [StyleSpan(start: 8, end: 12, isBold: true)],
      );
      addTearDown(ctrl.dispose);

      ctrl.removeLinePrefixes(0, 0);
      expect(ctrl.text, 'alpha\nbeta');
      expect(ctrl.spans.single.start, 6);
      expect(ctrl.spans.single.end, 10);

      ctrl.selection = const TextSelection.collapsed(offset: 6);
      ctrl.applyLinePrefix('○ ');
      expect(ctrl.text, 'alpha\n○ beta');
      expect(ctrl.spans.single.start, 8);
      expect(ctrl.spans.single.end, 12);
    });

    test(
      'RichTextEditingController applies and removes bold style span on selection',
      () {
        final ctrl = RichTextEditingController(
          text: 'Hello Apple Notes World',
          baseStyle: const TextStyle(fontSize: 15),
        );

        // Select "Apple Notes" (index 6 to 17)
        ctrl.selection = const TextSelection(baseOffset: 6, extentOffset: 17);
        ctrl.toggleBold();

        expect(ctrl.spans.length, 1);
        expect(ctrl.spans.first.start, 6);
        expect(ctrl.spans.first.end, 17);
        expect(ctrl.spans.first.isBold, isTrue);

        // Export to markdown produces clean asterisks
        expect(ctrl.toMarkdown(), 'Hello **Apple Notes** World');

        // Toggling bold again on the same selection removes it
        ctrl.toggleBold();
        expect(ctrl.spans.where((s) => s.isBold).isEmpty, isTrue);
        expect(ctrl.toMarkdown(), 'Hello Apple Notes World');
      },
    );

    test(
      'RichTextEditingController supports multiple overlapping styles (Bold + Italic + Underline)',
      () {
        final ctrl = RichTextEditingController(
          text: 'Super Note',
          baseStyle: const TextStyle(fontSize: 15),
        );

        ctrl.selection = const TextSelection(
          baseOffset: 0,
          extentOffset: 5,
        ); // "Super"
        ctrl.toggleBold();
        ctrl.toggleItalic();
        ctrl.toggleUnderline();

        expect(ctrl.spans.length, 1);
        final span = ctrl.spans.first;
        expect(span.isBold, isTrue);
        expect(span.isItalic, isTrue);
        expect(span.isUnderline, isTrue);
        expect(ctrl.toMarkdown(), '***Super*** Note');
      },
    );

    test(
      'RichTextEditingController supports multi-line selection across bullets and paragraphs',
      () {
        final docText =
            'Titolo Nota\n• Primo bullet\n• Secondo bullet\nParagrafo finale';
        final ctrl = RichTextEditingController(
          text: docText,
          baseStyle: const TextStyle(fontSize: 15),
        );

        // Select across both bullets: from "Primo" (index 14) to "Secondo bullet" (index 46)
        final start = docText.indexOf('Primo');
        final end = docText.indexOf('Secondo bullet') + 'Secondo bullet'.length;
        ctrl.selection = TextSelection(baseOffset: start, extentOffset: end);

        ctrl.toggleBold();

        expect(ctrl.spans.length, 1);
        expect(ctrl.spans.first.isBold, isTrue);
        expect(ctrl.spans.first.start, start);
        expect(ctrl.spans.first.end, end);

        final exported = ctrl.toMarkdown();
        expect(exported.contains('**Primo bullet\n• Secondo bullet**'), isTrue);
      },
    );

    test(
      'RichTextEditingController handleEnterKey auto-continues and exits lists',
      () {
        final ctrl = RichTextEditingController(
          text: 'Titolo\n• Primo elemento',
          baseStyle: const TextStyle(fontSize: 15),
        );

        // Place cursor at end of bullet item
        ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);
        final handled = ctrl.handleEnterKey();

        expect(handled, isTrue);
        expect(ctrl.text, 'Titolo\n• Primo elemento\n• ');
        expect(ctrl.selection.baseOffset, ctrl.text.length);

        // Press Enter again on the empty bullet -> exits bullet list
        final exited = ctrl.handleEnterKey();
        expect(exited, isTrue);
        expect(ctrl.text, 'Titolo\n• Primo elemento\n');
      },
    );

    test(
      'handleEnterKey at the start of a list item splits it after its marker',
      () {
        final bullet = RichTextEditingController(
          text: 'Titolo\n• Primo',
          baseStyle: const TextStyle(fontSize: 15),
        );
        bullet.selection = const TextSelection.collapsed(offset: 7);
        expect(bullet.handleEnterKey(), isTrue);
        expect(bullet.text, 'Titolo\n• \n• Primo');
        expect(bullet.selection.baseOffset, 12);

        final checklist = RichTextEditingController(
          text: 'Titolo\n○ Compito',
          baseStyle: const TextStyle(fontSize: 15),
        );
        checklist.selection = const TextSelection.collapsed(offset: 7);
        expect(checklist.handleEnterKey(), isTrue);
        expect(checklist.text, 'Titolo\n○ \n○ Compito');
        expect(checklist.selection.baseOffset, 12);

        final numbered = RichTextEditingController(
          text: 'Titolo\n1. Primo',
          baseStyle: const TextStyle(fontSize: 15),
        );
        numbered.selection = const TextSelection.collapsed(offset: 7);
        expect(numbered.handleEnterKey(), isTrue);
        expect(numbered.text, 'Titolo\n1. \n2. Primo');
        expect(numbered.selection.baseOffset, 14);
      },
    );

    test('Enter and Tab treat a dash or asterisk without a space as text', () {
      final dash = RichTextEditingController(
        text: 'Titolo\n-5 gradi',
        baseStyle: const TextStyle(fontSize: 15),
      );
      dash.selection = TextSelection.collapsed(offset: dash.text.length);
      expect(dash.handleEnterKey(), isFalse);
      expect(dash.text, 'Titolo\n-5 gradi');

      final star = RichTextEditingController(
        text: 'Titolo\n*Nota',
        baseStyle: const TextStyle(fontSize: 15),
      );
      star.selection = TextSelection.collapsed(offset: star.text.length);
      expect(star.handleEnterKey(), isFalse);

      final tab = RichTextEditingController(
        text: 'Titolo\n-5 gradi',
        baseStyle: const TextStyle(fontSize: 15),
      );
      tab.selection = const TextSelection.collapsed(offset: 9);
      expect(tab.handleTabKey(), isTrue);
      expect(tab.text, 'Titolo\n  -5 gradi');
    });

    test('removeLinePrefixes strips every stacked symbol of a line', () {
      final ctrl = RichTextEditingController(
        text: 'Titolo\n> 1. testo\n- > citata\n-5 gradi',
        baseStyle: const TextStyle(fontSize: 15),
      );
      ctrl.removeLinePrefixes(1, 3);
      expect(ctrl.text, 'Titolo\ntesto\ncitata\n-5 gradi');
    });

    test('RichTextEditingController handleEnterKey on a heading line', () {
      final empty = RichTextEditingController(
        text: '',
        baseStyle: const TextStyle(fontSize: 15),
        lineStyles: {0: BlockType.h1},
      );
      empty.selection = const TextSelection.collapsed(offset: 0);
      expect(empty.handleEnterKey(), isTrue);
      expect(empty.text, '\n');
      expect(empty.getLineStyle(0), BlockType.paragraph);
      expect(empty.getLineStyle(1), BlockType.paragraph);
      expect(empty.selection.baseOffset, 1);

      final withText = RichTextEditingController(
        text: 'Titolo',
        baseStyle: const TextStyle(fontSize: 15),
        lineStyles: {0: BlockType.h1},
      );
      withText.selection = const TextSelection.collapsed(offset: 0);
      expect(withText.handleEnterKey(), isTrue);
      expect(withText.text, '\nTitolo');
      expect(withText.getLineStyle(0), BlockType.paragraph);
      expect(withText.getLineStyle(1), BlockType.h1);

      for (final text in ['• ', '○ ', '• Titolo']) {
        final symbol = RichTextEditingController(
          text: text,
          baseStyle: const TextStyle(fontSize: 15),
          lineStyles: {0: BlockType.h2},
        );
        symbol.selection = TextSelection.collapsed(offset: text.length);
        expect(symbol.handleEnterKey(), isTrue);
        expect(symbol.text, '$text\n');
        expect(symbol.getLineStyle(0), BlockType.h2);
        expect(symbol.getLineStyle(1), BlockType.paragraph);
      }
    });

    test(
      'Backspace joining a body line to a heading-empty line keeps the heading of the first line',
      () {
        final ctrl = RichTextEditingController(
          text: 'Titolo\n\nCorpo',
          baseStyle: const TextStyle(fontSize: 15),
          lineStyles: {0: BlockType.title, 1: BlockType.h1},
        );
        // Backspace at the start of "Corpo" joins it with the empty line above
        ctrl.value = const TextEditingValue(
          text: 'Titolo\nCorpo',
          selection: TextSelection.collapsed(offset: 7),
        );
        expect(ctrl.text, 'Titolo\nCorpo');
        expect(ctrl.getLineStyle(0), BlockType.title);
        expect(ctrl.getLineStyle(1), BlockType.h1);
      },
    );

    test(
      'Backspace joining a heading line to a heading-empty line keeps the joined style',
      () {
        final ctrl = RichTextEditingController(
          text: 'Titolo\n\nSotto',
          baseStyle: const TextStyle(fontSize: 15),
          lineStyles: {0: BlockType.title, 1: BlockType.h1, 2: BlockType.h2},
        );
        // Backspace at the start of "Sotto" joins it with the empty h1 line above
        ctrl.value = const TextEditingValue(
          text: 'Titolo\nSotto',
          selection: TextSelection.collapsed(offset: 7),
        );
        expect(ctrl.getLineStyle(0), BlockType.title);
        expect(ctrl.getLineStyle(1), BlockType.h2);
      },
    );

    test(
      'RichTextEditingController auto-converts typed checklist shortcuts and handleEnterKey continues/exits checklist',
      () {
        final ctrl = RichTextEditingController(
          text: 'Titolo\n',
          baseStyle: const TextStyle(fontSize: 15),
        );

        // 1. Type "- [ ] "
        ctrl.value = const TextEditingValue(
          text: 'Titolo\n- [ ] Primo compito',
          selection: TextSelection.collapsed(offset: 26),
        );
        expect(ctrl.text, 'Titolo\n○ Primo compito');

        // 2. Press Enter -> continues with ○
        ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);
        final handled = ctrl.handleEnterKey();
        expect(handled, isTrue);
        expect(ctrl.text, 'Titolo\n○ Primo compito\n○ ');

        // 3. Press Enter again on empty checklist -> exits to clean newline
        final exited = ctrl.handleEnterKey();
        expect(exited, isTrue);
        expect(ctrl.text, 'Titolo\n○ Primo compito\n');

        // 4. Toggle checklist to checked ● and export to Markdown
        final circlePos = ctrl.text.indexOf('○');
        ctrl.toggleChecklistAtOffset(circlePos);
        expect(ctrl.text, 'Titolo\n● Primo compito\n');
        expect(ctrl.toMarkdown(), 'Titolo\n- [x] Primo compito\n');
      },
    );

    test(
      'RichTextEditingController keeps a checkbox without a following space as plain text for Enter, Tab, Backspace, button and tap',
      () {
        final ctrl = RichTextEditingController(
          text: 'Titolo\n[ ]testo',
          baseStyle: const TextStyle(fontSize: 15),
        );

        // Enter after plain text does not create a checklist item
        ctrl.selection = const TextSelection.collapsed(offset: 15);
        expect(ctrl.handleEnterKey(), isFalse);

        // Tab only adds the indentation to the text
        expect(ctrl.handleTabKey(), isTrue);
        expect(ctrl.text, 'Titolo\n  [ ]testo');
        expect(ctrl.handleTabKey(outdent: true), isTrue);
        expect(ctrl.text, 'Titolo\n[ ]testo');

        // Backspace right after the box does not delete it
        ctrl.selection = const TextSelection.collapsed(offset: 10);
        expect(ctrl.handleBackspaceKey(), isFalse);
        expect(ctrl.text, 'Titolo\n[ ]testo');

        // Tap on the box does not check it
        expect(ctrl.toggleChecklistAtOffset(8), isFalse);
        expect(ctrl.text, 'Titolo\n[ ]testo');

        // The checklist button puts a circle in front without treating the box as an item
        ctrl.selection = const TextSelection.collapsed(offset: 10);
        ctrl.toggleChecklistAtCursor();
        expect(ctrl.text, 'Titolo\n○ [ ]testo');
      },
    );

    test(
      'RichTextEditingController turns typed quote, monospace and numbered prefixes into line types',
      () {
        final ctrl = RichTextEditingController(
          text: 'Titolo\n',
          baseStyle: const TextStyle(fontSize: 15),
        );

        ctrl.value = const TextEditingValue(
          text: 'Titolo\n> Citata',
          selection: TextSelection.collapsed(offset: 15),
        );
        expect(ctrl.text, 'Titolo\n> Citata');
        expect(ctrl.getLineStyle(1), BlockType.quote);

        ctrl.value = const TextEditingValue(
          text: 'Titolo\n> Citata\n```codice',
          selection: TextSelection.collapsed(offset: 25),
        );
        expect(ctrl.text, 'Titolo\n> Citata\n```codice');
        expect(ctrl.getLineStyle(2), BlockType.code);

        ctrl.value = const TextEditingValue(
          text: 'Titolo\n> Citata\n```codice\n3. Voce',
          selection: TextSelection.collapsed(offset: 34),
        );
        expect(ctrl.text, 'Titolo\n> Citata\n```codice\n3. Voce');
        expect(ctrl.getLineStyle(3), BlockType.numbered);
        expect(ctrl.getLineStyle(1), BlockType.quote);
        expect(ctrl.getLineStyle(2), BlockType.code);
      },
    );

    test(
      'RichTextEditingController keeps a number without a space after its dot as body text',
      () {
        final ctrl = RichTextEditingController(
          text: 'Titolo\n',
          baseStyle: const TextStyle(fontSize: 15),
        );

        ctrl.value = const TextEditingValue(
          text: 'Titolo\n1.5 volte',
          selection: TextSelection.collapsed(offset: 16),
        );
        expect(ctrl.text, 'Titolo\n1.5 volte');
        expect(ctrl.getLineStyle(1), BlockType.paragraph);

        // Enter at the end of "3.14" does not start a numbered item.
        ctrl.value = const TextEditingValue(
          text: 'Titolo\n3.14',
          selection: TextSelection.collapsed(offset: 11),
        );
        expect(ctrl.handleEnterKey(), isFalse);
        expect(ctrl.text, 'Titolo\n3.14');

        // Tab adds indentation only and keeps the text.
        ctrl.value = const TextEditingValue(
          text: 'Titolo\n1.5 volte',
          selection: TextSelection.collapsed(offset: 16),
        );
        expect(ctrl.handleTabKey(), isTrue);
        expect(ctrl.text, 'Titolo\n  1.5 volte');
      },
    );

    test(
      'RichTextEditingController returns a quote, code or numbered line to body when its sign is deleted',
      () {
        final ctrl = RichTextEditingController(
          baseStyle: const TextStyle(fontSize: 15),
        );
        ctrl.value = const TextEditingValue(
          text: 'Titolo\n> Citata\n```codice\n3. Voce',
          selection: TextSelection.collapsed(offset: 34),
        );
        expect(ctrl.getLineStyle(1), BlockType.quote);
        expect(ctrl.getLineStyle(2), BlockType.code);
        expect(ctrl.getLineStyle(3), BlockType.numbered);

        // Quote sign deleted: body, the other lines keep their type
        ctrl.value = const TextEditingValue(
          text: 'Titolo\nCitata\n```codice\n3. Voce',
          selection: TextSelection.collapsed(offset: 7),
        );
        expect(ctrl.getLineStyle(1), BlockType.paragraph);
        expect(ctrl.getLineStyle(2), BlockType.code);
        expect(ctrl.getLineStyle(3), BlockType.numbered);

        // Fence deleted: body
        ctrl.value = const TextEditingValue(
          text: 'Titolo\nCitata\ncodice\n3. Voce',
          selection: TextSelection.collapsed(offset: 14),
        );
        expect(ctrl.getLineStyle(2), BlockType.paragraph);
        expect(ctrl.getLineStyle(3), BlockType.numbered);

        // Number deleted: body
        ctrl.value = const TextEditingValue(
          text: 'Titolo\nCitata\ncodice\nVoce',
          selection: TextSelection.collapsed(offset: 20),
        );
        expect(ctrl.getLineStyle(3), BlockType.paragraph);
      },
    );

    test(
      'RichTextEditingController keeps an indented numbered line numbered on Tab, Shift+Tab and Enter',
      () {
        final ctrl = RichTextEditingController(
          baseStyle: const TextStyle(fontSize: 15),
        );
        ctrl.value = const TextEditingValue(
          text: 'Titolo\n1. Voce',
          selection: TextSelection.collapsed(offset: 14),
        );
        ctrl.selection = const TextSelection.collapsed(offset: 10);
        expect(ctrl.getLineStyle(1), BlockType.numbered);

        expect(ctrl.handleTabKey(), isTrue);
        expect(ctrl.text, 'Titolo\n  1. Voce');
        expect(ctrl.getLineStyle(1), BlockType.numbered);

        expect(ctrl.handleTabKey(outdent: true), isTrue);
        expect(ctrl.text, 'Titolo\n1. Voce');
        expect(ctrl.getLineStyle(1), BlockType.numbered);

        expect(ctrl.handleTabKey(), isTrue);
        ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);
        expect(ctrl.handleEnterKey(), isTrue);
        expect(ctrl.text, 'Titolo\n  1. Voce\n  2. ');
        expect(ctrl.getLineStyle(1), BlockType.numbered);
        expect(ctrl.getLineStyle(2), BlockType.numbered);
      },
    );

    test(
      'RichTextEditingController toggles checklist only when tapping the circle',
      () {
        final ctrl = RichTextEditingController(
          text: 'Titolo\n○ Primo compito\n',
          baseStyle: const TextStyle(fontSize: 15),
        );
        final letterPos = ctrl.text.indexOf('Primo') + 2;
        expect(ctrl.toggleChecklistAtOffset(letterPos), isFalse);
        expect(ctrl.text, 'Titolo\n○ Primo compito\n');

        final circlePos = ctrl.text.indexOf('○');
        expect(ctrl.toggleChecklistAtOffset(circlePos + 1), isTrue);
        expect(ctrl.text, 'Titolo\n● Primo compito\n');
      },
    );

    test(
      'RichTextEditingController allows drag multi-line selection across bullets and checklist items',
      () {
        final docText =
            'Titolo\n• Elemento bullet\n○ Elemento checklist\n● Elemento fatto';
        final ctrl = RichTextEditingController(
          text: docText,
          baseStyle: const TextStyle(fontSize: 15),
        );

        // Select from "bullet" to "fatto"
        final start = docText.indexOf('bullet');
        final end = docText.indexOf('fatto') + 'fatto'.length;
        ctrl.selection = TextSelection(baseOffset: start, extentOffset: end);

        ctrl.toggleBold();
        expect(ctrl.spans.length, 1);
        expect(ctrl.spans.first.isBold, isTrue);
        expect(ctrl.spans.first.start, start);
        expect(ctrl.spans.first.end, end);
      },
    );

    test(
      'RichTextEditingController removes and replaces the symbol of indented lines',
      () {
        final ctrl = RichTextEditingController(
          text: 'Titolo\n  • Primo\n    ○ Secondo',
          baseStyle: const TextStyle(fontSize: 15),
        );

        // Body style (Corpo) on the indented bullet and checklist lines
        ctrl.removeLinePrefixes(1, 2);
        expect(ctrl.text, 'Titolo\n  Primo\n    Secondo');

        // Bulleted style on the indented line: one bullet, after the indent
        ctrl.selection = const TextSelection.collapsed(offset: 9);
        ctrl.applyLinePrefix('• ');
        expect(ctrl.text, 'Titolo\n  • Primo\n    Secondo');

        // Checklist button on the indented plain line
        ctrl.selection = const TextSelection.collapsed(offset: 21);
        ctrl.toggleChecklistAtCursor();
        expect(ctrl.text, 'Titolo\n  • Primo\n    ○ Secondo');
      },
    );

    test(
      'RichTextEditingController keeps hashes beyond three in the text',
      () {
        final ctrl = RichTextEditingController(
          text: '#### Riunione\n### Titolo',
          baseStyle: const TextStyle(fontSize: 15),
        );

        // Body style (Corpo) strips only "# ", "## " and "### "
        ctrl.removeLinePrefixes(0, 1);
        expect(ctrl.text, '#### Riunione\nTitolo');

        // Checklist button on the four-hash line keeps every hash
        ctrl.selection = const TextSelection.collapsed(offset: 0);
        ctrl.toggleChecklistAtCursor();
        expect(ctrl.text, '○ #### Riunione\nTitolo');
      },
    );

    test(
      'RichTextEditingController bullet style from the menu follows the indent level',
      () {
        final ctrl = RichTextEditingController(
          text: 'Uno\n  Due\n    Tre\n      Quattro',
          baseStyle: const TextStyle(fontSize: 15),
        );

        ctrl.selection = const TextSelection(baseOffset: 0, extentOffset: 31);
        ctrl.applyLinePrefix('• ', bulletByIndent: true);
        expect(ctrl.text, '• Uno\n  ◦ Due\n    ▪ Tre\n      • Quattro');
      },
    );

    test(
      'RichTextEditingController keeps every selected line when the symbols are replaced',
      () {
        final ctrl = RichTextEditingController(
          text: 'Uno\n• Due\n  ○ Tre\nQuattro',
          baseStyle: const TextStyle(fontSize: 15),
        );

        // Symbols removed from all selected lines: the selection still covers them
        ctrl.selection = const TextSelection(baseOffset: 0, extentOffset: 25);
        ctrl.removeLinePrefixes(0, 3);
        expect(ctrl.text, 'Uno\nDue\n  Tre\nQuattro');
        expect(
          ctrl.selection,
          const TextSelection(baseOffset: 0, extentOffset: 21),
        );

        // Quote style then reaches every selected line, not only the caret one
        ctrl.applyLinePrefix('> ');
        expect(ctrl.text, '> Uno\n> Due\n  > Tre\n> Quattro');
      },
    );

    test(
      'RichTextEditingController moves formatting after a new line prefix only once',
      () {
        final ctrl = RichTextEditingController(
          text: 'Titolo\nPrimo\nSecondo',
          baseStyle: const TextStyle(fontSize: 15),
        );
        // Bold on "Secondo" (13..20), below the caret line
        ctrl.spans = [StyleSpan(start: 13, end: 20, isBold: true)];

        // Checklist created on "Primo": the prefix "○ " is two characters
        ctrl.selection = const TextSelection.collapsed(offset: 8);
        ctrl.toggleChecklistAtCursor();
        expect(ctrl.text, 'Titolo\n○ Primo\nSecondo');
        expect(ctrl.spans.length, 1);
        expect(ctrl.spans.first.start, 15);
        expect(ctrl.spans.first.end, 22);
      },
    );

    test(
      'RichTextEditingController bullet from the menu moves formatting below only once',
      () {
        final ctrl = RichTextEditingController(
          text: 'Uno\nDue\nTre',
          baseStyle: const TextStyle(fontSize: 15),
        );
        ctrl.spans = [StyleSpan(start: 8, end: 11, isItalic: true)];

        ctrl.selection = const TextSelection.collapsed(offset: 0);
        ctrl.applyLinePrefix('• ');
        expect(ctrl.text, '• Uno\nDue\nTre');
        expect(ctrl.spans.first.start, 10);
        expect(ctrl.spans.first.end, 13);
      },
    );

    test('typed number, quote or fence keeps a heading line as a heading', () {
      final ctrl = RichTextEditingController(
        text: 'Titolo\n',
        baseStyle: const TextStyle(fontSize: 15),
        lineStyles: {1: BlockType.h1},
      );

      ctrl.value = const TextEditingValue(
        text: 'Titolo\n1. Riunione',
        selection: TextSelection.collapsed(offset: 18),
      );
      expect(ctrl.text, 'Titolo\n1. Riunione');
      expect(ctrl.getLineStyle(1), BlockType.h1);

      ctrl.value = const TextEditingValue(
        text: 'Titolo\n> Citazione\n```codice',
        selection: TextSelection.collapsed(offset: 29),
      );
      expect(ctrl.getLineStyle(1), BlockType.h1);
      expect(ctrl.getLineStyle(2), BlockType.code);

      final enter = RichTextEditingController(
        text: 'Titolo\n1. Riunione',
        baseStyle: const TextStyle(fontSize: 15),
        lineStyles: {1: BlockType.h1},
      );
      enter.selection = const TextSelection.collapsed(offset: 7);
      expect(enter.handleEnterKey(), isTrue);
      expect(enter.text, 'Titolo\n\n1. Riunione');
      expect(enter.getLineStyle(1), BlockType.paragraph);
      expect(enter.getLineStyle(2), BlockType.h1);
    });
  });

  group('Note Model JSON Serialization & Markdown Export Tests', () {
    test(
      'Note.toMarkdown() converts JSON blocks to clean Markdown without delimiter leakage in raw content',
      () {
        final blocks = [
          {
            'id': 'b-1',
            'type': 'title',
            'text': 'Titolo Principale',
            'spans': [],
          },
          {
            'id': 'b-2',
            'type': 'paragraph',
            'text': 'Testo con parola importante e dettaglio corsivo.',
            'spans': [
              {'start': 17, 'end': 27, 'bold': true},
              {'start': 40, 'end': 47, 'italic': true},
            ],
          },
          {
            'id': 'b-3',
            'type': 'checklist',
            'text': 'Attività completata',
            'isChecked': true,
            'spans': [],
          },
          {
            'id': 'b-4',
            'type': 'checklist',
            'text': 'Attività da fare',
            'isChecked': false,
            'spans': [],
          },
          {
            'id': 'b-5',
            'type': 'table',
            'tableData': [
              ['C1', 'C2'],
              ['V1', 'V2'],
            ],
            'spans': [],
          },
        ];

        final note = Note(
          id: 'json-note-1',
          title: 'Titolo Principale',
          content: jsonEncode(blocks),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(note.title, 'Titolo Principale');
        expect(note.snippet.contains('Testo con parola'), isTrue);

        final exportedMarkdown = note.toMarkdown();
        expect(exportedMarkdown.contains('# Titolo Principale'), isTrue);
        expect(
          exportedMarkdown.contains(
            'Testo con **parola importante** e **dettaglio**',
          ),
          isFalse,
        );
        expect(exportedMarkdown.contains('**importante**'), isTrue);
        expect(exportedMarkdown.contains('*corsivo*'), isTrue);
        expect(exportedMarkdown.contains('- [x] Attività completata'), isTrue);
        expect(exportedMarkdown.contains('- [ ] Attività da fare'), isTrue);
        expect(exportedMarkdown.contains('| C1 | C2 |'), isTrue);
      },
    );
  });

  group('NotionDocumentEditor Keyboard Shortcuts & Aa Style Tests', () {
    testWidgets(
      'NotionDocumentEditor toggles bold with CTRL+B and heading with setBlockType',
      (tester) async {
        final blocks = [
          {'id': '1', 'type': 'title', 'text': 'Nota Shortcuts', 'spans': []},
          {
            'id': '2',
            'type': 'paragraph',
            'text': 'Testo per test shortcut',
            'spans': [],
          },
        ];

        final note = Note(
          id: 'test-shortcuts',
          title: 'Nota Shortcuts',
          content: jsonEncode(blocks),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final db = DatabaseService();
        final vault = VaultService();
        final sync = SyncService(db, vault);
        final security = SecurityService();
        final provider = NotesProvider(
          dbService: db,
          vaultService: vault,
          syncService: sync,
        );
        final editorKey = GlobalKey<NotionDocumentEditorState>();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              Provider.value(value: db),
              Provider.value(value: vault),
              ChangeNotifierProvider.value(value: sync),
              ChangeNotifierProvider.value(value: security),
              ChangeNotifierProvider.value(value: provider),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: NotionDocumentEditor(key: editorKey, note: note),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap on the continuous document TextField
        final textFieldFinder = find.byType(TextField);
        expect(textFieldFinder, findsOneWidget);
        await tester.tap(textFieldFinder);
        await tester.pumpAndSettle();

        // Change block style to Heading 1 (Aa style menu)
        editorKey.currentState?.setBlockType(BlockType.h1);
        await tester.pumpAndSettle();

        final tf = tester.widget<TextField>(textFieldFinder);
        final ctrl = tf.controller as RichTextEditingController;
        expect(ctrl.text.contains('#'), isFalse);
        expect(ctrl.getLineStyle(0), BlockType.h1);

        // Change block style to Title
        editorKey.currentState?.setBlockType(BlockType.title);
        await tester.pumpAndSettle();
        expect(ctrl.text.contains('#'), isFalse);
        expect(ctrl.getLineStyle(0), BlockType.title);

        // Change block style to Paragraph (Corpo)
        editorKey.currentState?.setBlockType(BlockType.paragraph);
        await tester.pumpAndSettle();
        expect(ctrl.text.contains('#'), isFalse);
        expect(ctrl.getLineStyle(0), BlockType.paragraph);

        // Call toggleBold via editor state
        editorKey.currentState?.toggleBold();
        await tester.pumpAndSettle();

        // Call toggleItalic via editor state
        editorKey.currentState?.toggleItalic();
        await tester.pumpAndSettle();

        // Call toggleUnderline via editor state
        editorKey.currentState?.toggleUnderline();
        await tester.pumpAndSettle();

        // Verify no exceptions thrown and editor state is consistent
        expect(editorKey.currentState, isNotNull);
      },
    );

    testWidgets(
      'Command during a pending text save delivers the document at once',
      (tester) async {
        final blocks = [
          {'id': '1', 'type': 'title', 'text': 'Nota Attesa', 'spans': []},
          {'id': '2', 'type': 'paragraph', 'text': 'Testo', 'spans': []},
        ];

        final note = Note(
          id: 'test-pending-save',
          title: 'Nota Attesa',
          content: jsonEncode(blocks),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final db = DatabaseService();
        final vault = VaultService();
        final sync = SyncService(db, vault);
        final security = SecurityService();
        final provider = _RecordingNotesProvider(
          dbService: db,
          vaultService: vault,
          syncService: sync,
        );
        final editorKey = GlobalKey<NotionDocumentEditorState>();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              Provider.value(value: db),
              Provider.value(value: vault),
              ChangeNotifierProvider.value(value: sync),
              ChangeNotifierProvider.value(value: security),
              ChangeNotifierProvider<NotesProvider>.value(value: provider),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: NotionDocumentEditor(key: editorKey, note: note),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Typing starts the 300 ms wait: nothing is delivered yet
        final textField = find.byType(TextField);
        await tester.enterText(textField, 'Nota Attesa\nTesto digitato');
        await tester.pump();
        expect(provider.savedContents, isEmpty);

        // A bold command during the wait delivers the whole document at once
        final ctrl =
            tester.widget<TextField>(textField).controller
                as RichTextEditingController;
        ctrl.selection = TextSelection(
          baseOffset: ctrl.text.indexOf('digitato'),
          extentOffset: ctrl.text.length,
        );
        editorKey.currentState?.toggleBold();
        expect(provider.savedContents, hasLength(1));
        expect(provider.savedContents.single, contains('"bold":true'));
        expect(provider.savedContents.single, contains('digitato'));

        // The command ended the wait: no later delivery follows
        await tester.pump(const Duration(milliseconds: 400));
        expect(provider.savedContents, hasLength(1));
      },
    );

    testWidgets(
      'Protected note never shown: Aa style is saved as a line style, section stays paragraph',
      (tester) async {
        final blocks = [
          {
            'id': '1',
            'type': 'paragraph',
            'text': 'Prima riga\nSeconda riga',
            'spans': [],
          },
        ];

        final note = Note(
          id: 'test-protected-style',
          title: 'Nota protetta',
          content: jsonEncode(blocks),
          isLocked: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final db = DatabaseService();
        final vault = VaultService();
        final sync = SyncService(db, vault);
        final security = SecurityService();
        final provider = _RecordingNotesProvider(
          dbService: db,
          vaultService: vault,
          syncService: sync,
        );
        final editorKey = GlobalKey<NotionDocumentEditorState>();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              Provider.value(value: db),
              Provider.value(value: vault),
              ChangeNotifierProvider.value(value: sync),
              ChangeNotifierProvider.value(value: security),
              ChangeNotifierProvider<NotesProvider>.value(value: provider),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: NotionDocumentEditor(key: editorKey, note: note),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // The note is locked and never unlocked: no editor controllers exist yet
        editorKey.currentState?.setBlockType(BlockType.h1);

        expect(provider.savedContents, hasLength(1));
        final saved = jsonDecode(provider.savedContents.single) as List<dynamic>;
        expect(saved, hasLength(1));
        final section = saved.single as Map<String, dynamic>;
        expect(section['type'], 'paragraph');
        expect(section['text'], 'Prima riga\nSeconda riga');
        expect(section['lineStyles'], containsPair('1', 'h1'));
      },
    );

    testWidgets(
      'Protected note never shown: bold is saved without formatting the text',
      (tester) async {
        final blocks = [
          {
            'id': '1',
            'type': 'paragraph',
            'text': 'Prima riga\nSeconda riga',
            'spans': [],
          },
        ];

        final note = Note(
          id: 'test-protected-bold-hidden',
          title: 'Nota protetta',
          content: jsonEncode(blocks),
          isLocked: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final db = DatabaseService();
        final vault = VaultService();
        final sync = SyncService(db, vault);
        final security = SecurityService();
        final provider = _RecordingNotesProvider(
          dbService: db,
          vaultService: vault,
          syncService: sync,
        );
        final editorKey = GlobalKey<NotionDocumentEditorState>();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              Provider.value(value: db),
              Provider.value(value: vault),
              ChangeNotifierProvider.value(value: sync),
              ChangeNotifierProvider.value(value: security),
              ChangeNotifierProvider<NotesProvider>.value(value: provider),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: NotionDocumentEditor(key: editorKey, note: note),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // The locked note's text was never shown: bold only saves the document
        editorKey.currentState?.toggleBold();

        expect(provider.savedContents, hasLength(1));
        final saved = jsonDecode(provider.savedContents.single) as List<dynamic>;
        final section = saved.single as Map<String, dynamic>;
        expect(section['text'], 'Prima riga\nSeconda riga');
        expect(section['spans'], isEmpty);
      },
    );

    testWidgets(
      'Quote, monospace and numbered line types are saved with their sign',
      (tester) async {
        final blocks = [
          {
            'id': '1',
            'type': 'paragraph',
            'text': 'Titolo\n> Citata\n```codice\n1. Voce',
            'spans': [],
            'lineStyles': {'1': 'quote', '2': 'code', '3': 'numbered'},
          },
        ];

        final note = Note(
          id: 'test-saved-line-types',
          title: 'Tipi di riga',
          content: jsonEncode(blocks),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final db = DatabaseService();
        final vault = VaultService();
        final sync = SyncService(db, vault);
        final security = SecurityService();
        final provider = _RecordingNotesProvider(
          dbService: db,
          vaultService: vault,
          syncService: sync,
        );
        final editorKey = GlobalKey<NotionDocumentEditorState>();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              Provider.value(value: db),
              Provider.value(value: vault),
              ChangeNotifierProvider.value(value: sync),
              ChangeNotifierProvider.value(value: security),
              ChangeNotifierProvider<NotesProvider>.value(value: provider),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: NotionDocumentEditor(key: editorKey, note: note),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final ctrl =
            tester.widget<TextField>(find.byType(TextField)).controller
                as RichTextEditingController;
        expect(ctrl.getLineStyle(1), BlockType.quote);
        expect(ctrl.getLineStyle(2), BlockType.code);
        expect(ctrl.getLineStyle(3), BlockType.numbered);

        // A bold command delivers the document at once
        ctrl.selection = TextSelection(
          baseOffset: ctrl.text.indexOf('Voce'),
          extentOffset: ctrl.text.length,
        );
        editorKey.currentState?.toggleBold();
        expect(provider.savedContents, hasLength(1));
        final saved = jsonDecode(provider.savedContents.single) as List<dynamic>;
        final section = saved.single as Map<String, dynamic>;
        expect(section['text'], 'Titolo\n> Citata\n```codice\n1. Voce');
        expect(
          section['lineStyles'],
          {'0': 'paragraph', '1': 'quote', '2': 'code', '3': 'numbered'},
        );
      },
    );

    testWidgets(
      'Protected note reloads when a different remote version arrives',
      (tester) async {
        final db = DatabaseService();
        final vault = VaultService();
        final sync = SyncService(db, vault);
        final security = SecurityService();
        final provider = _RecordingNotesProvider(
          dbService: db,
          vaultService: vault,
          syncService: sync,
        );
        final editorKey = GlobalKey<NotionDocumentEditorState>();

        Widget build(Note note) => MultiProvider(
          providers: [
            Provider.value(value: db),
            Provider.value(value: vault),
            ChangeNotifierProvider.value(value: sync),
            ChangeNotifierProvider.value(value: security),
            ChangeNotifierProvider<NotesProvider>.value(value: provider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: NotionDocumentEditor(key: editorKey, note: note),
            ),
          ),
        );

        Note noteWith(String text) => Note(
          id: 'test-protected-remote',
          title: 'Nota protetta',
          content: jsonEncode([
            {'id': '1', 'type': 'paragraph', 'text': text, 'spans': []},
          ]),
          isLocked: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await tester.pumpWidget(build(noteWith('Versione locale')));
        await tester.pumpAndSettle();

        // Hidden note, no row focused: the different remote version is loaded
        await tester.pumpWidget(build(noteWith('Versione remota')));
        await tester.pumpAndSettle();

        editorKey.currentState?.setBlockType(BlockType.h1);

        expect(provider.savedContents, hasLength(1));
        final saved = jsonDecode(provider.savedContents.single) as List<dynamic>;
        expect(saved, hasLength(1));
        final section = saved.single as Map<String, dynamic>;
        expect(section['text'], 'Versione remota');
      },
    );

    testWidgets(
      'Remote version reloads while a table cell has the cursor and keeps the cell focus',
      (tester) async {
        final db = DatabaseService();
        final vault = VaultService();
        final sync = SyncService(db, vault);
        final security = SecurityService();
        final provider = _RecordingNotesProvider(
          dbService: db,
          vaultService: vault,
          syncService: sync,
        );
        final editorKey = GlobalKey<NotionDocumentEditorState>();

        Widget build(Note note) => MultiProvider(
          providers: [
            Provider.value(value: db),
            Provider.value(value: vault),
            ChangeNotifierProvider.value(value: sync),
            ChangeNotifierProvider.value(value: security),
            ChangeNotifierProvider<NotesProvider>.value(value: provider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: NotionDocumentEditor(key: editorKey, note: note),
            ),
          ),
        );

        Note noteWith(List<List<String>> rows) => Note(
          id: 'test-table-cell-remote',
          title: 'Nota con tabella',
          content: jsonEncode([
            {'id': 't1', 'type': 'table', 'tableData': rows},
          ]),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          build(noteWith([
            ['Colonna 1', 'Colonna 2'],
            ['Elemento 1', 'Elemento 2'],
          ])),
        );
        await tester.pumpAndSettle();

        // Cursor inside a table cell
        await tester.tap(find.widgetWithText(TextField, 'Elemento 1'));
        await tester.pumpAndSettle();

        // Different remote version arrives while the cell has the cursor
        await tester.pumpWidget(
          build(noteWith([
            ['Colonna 1', 'Colonna 2'],
            ['Remota 1', 'Remota 2'],
          ])),
        );
        await tester.pumpAndSettle();

        expect(find.text('Elemento 1'), findsNothing);
        expect(find.widgetWithText(TextField, 'Remota 1'), findsOneWidget);
        expect(
          tester
              .widget<TextField>(find.widgetWithText(TextField, 'Remota 1'))
              .focusNode
              ?.hasFocus,
          isTrue,
        );
      },
    );

    testWidgets(
      'Remote version without a focused cell shows the loaded text in the table cells',
      (tester) async {
        final db = DatabaseService();
        final vault = VaultService();
        final sync = SyncService(db, vault);
        final security = SecurityService();
        final provider = _RecordingNotesProvider(
          dbService: db,
          vaultService: vault,
          syncService: sync,
        );

        Widget build(Note note) => MultiProvider(
          providers: [
            Provider.value(value: db),
            Provider.value(value: vault),
            ChangeNotifierProvider.value(value: sync),
            ChangeNotifierProvider.value(value: security),
            ChangeNotifierProvider<NotesProvider>.value(value: provider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: NotionDocumentEditor(note: note),
            ),
          ),
        );

        Note noteWith(List<List<String>> rows) => Note(
          id: 'test-table-reload-cells',
          title: 'Nota con tabella',
          content: jsonEncode([
            {'id': 't1', 'type': 'table', 'tableData': rows},
          ]),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          build(noteWith([
            ['Colonna 1', 'Colonna 2'],
            ['Elemento 1', 'Elemento 2'],
          ])),
        );
        await tester.pumpAndSettle();

        await tester.pumpWidget(
          build(noteWith([
            ['Colonna 1', 'Colonna 2'],
            ['Remota 1', 'Remota 2'],
          ])),
        );
        await tester.pumpAndSettle();

        expect(find.widgetWithText(TextField, 'Remota 1'), findsOneWidget);
        expect(find.widgetWithText(TextField, 'Elemento 1'), findsNothing);
      },
    );

    testWidgets(
      'Remote version reloads while a text line has the cursor and keeps the caret',
      (tester) async {
        final db = DatabaseService();
        final vault = VaultService();
        final sync = SyncService(db, vault);
        final security = SecurityService();
        final provider = _RecordingNotesProvider(
          dbService: db,
          vaultService: vault,
          syncService: sync,
        );

        Widget build(Note note) => MultiProvider(
          providers: [
            Provider.value(value: db),
            Provider.value(value: vault),
            ChangeNotifierProvider.value(value: sync),
            ChangeNotifierProvider.value(value: security),
            ChangeNotifierProvider<NotesProvider>.value(value: provider),
          ],
          child: MaterialApp(
            home: Scaffold(body: NotionDocumentEditor(note: note)),
          ),
        );

        Note noteWith(String text) => Note(
          id: 'test-text-line-remote',
          title: 'Nota di testo',
          content: jsonEncode([
            {'id': '1', 'type': 'paragraph', 'text': text, 'spans': []},
          ]),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          build(noteWith('Versione locale\nSeconda riga')),
        );
        await tester.pumpAndSettle();

        // Cursor on the second line, after "Se"
        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();
        final before =
            tester.widget<TextField>(find.byType(TextField)).controller
                as RichTextEditingController;
        before.selection = const TextSelection.collapsed(offset: 18);

        // Remote version arrives while the text line has the cursor and nothing is waiting
        await tester.pumpWidget(
          build(noteWith('Versione remota\nSeconda riga')),
        );
        await tester.pumpAndSettle();

        final field = tester.widget<TextField>(find.byType(TextField));
        final after = field.controller as RichTextEditingController;
        expect(after.text, 'Versione remota\nSeconda riga');
        expect(after.selection, const TextSelection.collapsed(offset: 18));
        expect(field.focusNode?.hasFocus, isTrue);
      },
    );

    testWidgets(
      'NotionDocumentEditor strips legacy markdown # from text on load and applies line styles',
      (tester) async {
        final note = Note(
          id: 'legacy-markdown-note',
          title: 'Legacy Title',
          content: '''# Titolo Principale
## Intestazione Secondaria
### Terzo Livello
Testo normale di corpo
''',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final db = DatabaseService();
        final vault = VaultService();
        final sync = SyncService(db, vault);
        final security = SecurityService();
        final provider = NotesProvider(
          dbService: db,
          vaultService: vault,
          syncService: sync,
        );

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              Provider.value(value: db),
              Provider.value(value: vault),
              ChangeNotifierProvider.value(value: sync),
              ChangeNotifierProvider.value(value: security),
              ChangeNotifierProvider.value(value: provider),
            ],
            child: MaterialApp(
              home: Scaffold(body: NotionDocumentEditor(note: note)),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final textFieldFinder = find.byType(TextField);
        expect(textFieldFinder, findsOneWidget);
        final ctrl =
            tester.widget<TextField>(textFieldFinder).controller
                as RichTextEditingController;

        // Ensure no raw markdown '#' exists in the editable text
        expect(ctrl.text.contains('#'), isFalse);
        expect(ctrl.text.contains('Titolo Principale'), isTrue);
        expect(ctrl.text.contains('Intestazione Secondaria'), isTrue);
        expect(ctrl.text.contains('Terzo Livello'), isTrue);
        expect(ctrl.text.contains('Testo normale di corpo'), isTrue);

        // Verify line styles
        expect(ctrl.getLineStyle(0), BlockType.title);
        expect(ctrl.getLineStyle(1), BlockType.h2);
        expect(ctrl.getLineStyle(2), BlockType.h3);
        expect(ctrl.getLineStyle(3), BlockType.paragraph);
      },
    );

    testWidgets('Typing "- " in paragraph auto-converts to bullet list', (
      tester,
    ) async {
      final blocks = [
        {'id': '1', 'type': 'title', 'text': 'Nota Lista', 'spans': []},
        {'id': '2', 'type': 'paragraph', 'text': '', 'spans': []},
      ];

      final note = Note(
        id: 'test-bullet-list',
        title: 'Nota Lista',
        content: jsonEncode(blocks),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final db = DatabaseService();
      final vault = VaultService();
      final sync = SyncService(db, vault);
      final security = SecurityService();
      final provider = NotesProvider(
        dbService: db,
        vaultService: vault,
        syncService: sync,
      );
      final editorKey = GlobalKey<NotionDocumentEditorState>();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: db),
            Provider.value(value: vault),
            ChangeNotifierProvider.value(value: sync),
            ChangeNotifierProvider.value(value: security),
            ChangeNotifierProvider.value(value: provider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: NotionDocumentEditor(key: editorKey, note: note),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      // Type "- Primo elemento"
      await tester.enterText(textField, 'Nota Lista\n- Primo elemento');
      await tester.pumpAndSettle();

      // The text should now have auto-converted to bullet item
      final ctrl =
          tester.widget<TextField>(textField).controller
              as RichTextEditingController;
      expect(ctrl.text.contains('• Primo elemento'), isTrue);
    });

    test(
      'Note computes and caches snippet correctly without JSON parsing on subsequent reads',
      () {
        final blocks = [
          {'id': 'b1', 'type': 'title', 'text': 'Titolo Principale'},
          {
            'id': 'b2',
            'type': 'paragraph',
            'text': 'Questo è il testo di anteprima memorizzato in cache.',
          },
        ];
        final json = jsonEncode(blocks);

        final note = Note(
          id: 'n1',
          title: 'Titolo Principale',
          content: json,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          cachedSnippet: Note.extractSnippet(json),
        );

        expect(
          note.snippet,
          'Questo è il testo di anteprima memorizzato in cache.',
        );
        expect(note.cachedSnippet, isNotNull);

        // copyWith updates cachedSnippet when content changes
        final updated = note.copyWith(
          content: jsonEncode([
            {'id': 'b1', 'type': 'title', 'text': 'Nuovo Titolo'},
            {'id': 'b2', 'type': 'paragraph', 'text': 'Snippet aggiornato.'},
          ]),
        );
        expect(updated.snippet, 'Snippet aggiornato.');
      },
    );

    test('Plain-text snippet keeps leading numbers that are not list markers', () {
      const content = 'Titolo\n100 euro\n2024 è l\'anno\n2.5 kg\n1. voce elenco\n2) altra voce';
      expect(
        Note.extractSnippet(content),
        '100 euro 2024 è l\'anno 2.5 kg voce elenco altra voce',
      );
    });

    testWidgets('MacTitleBar adapts and does not overflow at 672px width', (
      WidgetTester tester,
    ) async {
      final db = DatabaseService();
      final vault = VaultService();
      final sync = SyncService(db, vault);
      final provider = NotesProvider(
        dbService: db,
        vaultService: vault,
        syncService: sync,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [ChangeNotifierProvider.value(value: provider)],
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 672,
                  child: MacTitleBar(
                    isSidebarVisible: true,
                    onToggleSidebar: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    test(
      'createNote appends single or multiple tags at the top when in tag view',
      () async {
        final db = DatabaseService();
        await db.init(inMemory: true);
        final tempDir = await Directory.systemTemp.createTemp(
          'opennotes_test_',
        );
        final vault = VaultService();
        await vault.init(customPath: tempDir.path);
        final sync = SyncService(db, vault);
        final provider = NotesProvider(
          dbService: db,
          vaultService: vault,
          syncService: sync,
        );

        try {
          // 1. Single tag view
          provider.selectTag('lavoro');
          expect(provider.selectedTags, contains('lavoro'));

          final noteSingle = (await provider.createNote())!;
          expect(noteSingle.content.startsWith('#lavoro'), isTrue);
          expect(noteSingle.tags, contains('lavoro'));

          // 2. Multiple tags view
          provider.toggleTag('progetto');
          expect(provider.selectedTags, containsAll(['lavoro', 'progetto']));

          final noteMultiple = (await provider.createNote())!;
          expect(noteMultiple.content.contains('#lavoro'), isTrue);
          expect(noteMultiple.content.contains('#progetto'), isTrue);
          expect(noteMultiple.tags, containsAll(['lavoro', 'progetto']));

          // 3. extractTitle skips tag line
          expect(Note.extractTitle(noteMultiple.content), 'Nuova nota');
          expect(
            Note.extractTitle('${noteMultiple.content}Titolo Effettivo\n'),
            'Titolo Effettivo',
          );
        } finally {
          await tempDir.delete(recursive: true);
        }
      },
    );

    test('createNote saves the tags written in the initial content', () async {
      final db = DatabaseService();
      await db.init(inMemory: true);
      final tempDir = await Directory.systemTemp.createTemp('opennotes_test_');
      final vault = VaultService();
      await vault.init(customPath: tempDir.path);
      final sync = SyncService(db, vault);
      final provider = NotesProvider(
        dbService: db,
        vaultService: vault,
        syncService: sync,
      );

      try {
        final created = (await provider.createNote(
          initialTitle: 'Benvenuto',
          initialContent: 'Ciao #note e #opennotes',
        ))!;
        expect(created.tags, ['note', 'opennotes']);

        final stored = await db.getNoteById(created.id);
        expect(stored!.tags, ['note', 'opennotes']);
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('createNote clears an active search so the new note is listed', () async {
      final db = DatabaseService();
      await db.init(inMemory: true);
      final tempDir = await Directory.systemTemp.createTemp('opennotes_test_');
      final vault = VaultService();
      await vault.init(customPath: tempDir.path);
      final provider = NotesProvider(
        dbService: db,
        vaultService: vault,
        syncService: SyncService(db, vault),
      );

      try {
        provider.setSearchQuery('zzz-nessun-risultato');
        await provider.refreshNotes();
        expect(provider.notes, isEmpty);

        final created = (await provider.createNote())!;
        expect(provider.searchQuery, isEmpty);
        expect(provider.selectedNoteId, created.id);
        expect(provider.notes.map((n) => n.id), contains(created.id));
        expect(provider.selectedNote, isNotNull);
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'RichTextEditingController handleTabKey indents and outdents bullet lists with Notion sub-bullet glyphs',
      () {
        final ctrl = RichTextEditingController(
          text: 'Titolo\n• Primo punto\n• Secondo punto',
          baseStyle: const TextStyle(fontSize: 15),
        );

        // Place cursor on "• Secondo punto"
        final secondPos = ctrl.text.indexOf('Secondo');
        ctrl.selection = TextSelection.collapsed(offset: secondPos);

        // 1. Press Tab -> indents to level 1 sub-bullet with hollow circle '◦'
        final handled1 = ctrl.handleTabKey(outdent: false);
        expect(handled1, isTrue);
        expect(ctrl.text, 'Titolo\n• Primo punto\n  ◦ Secondo punto');

        // 2. Press Tab again -> indents to level 2 sub-bullet with square '▪'
        final handled2 = ctrl.handleTabKey(outdent: false);
        expect(handled2, isTrue);
        expect(ctrl.text, 'Titolo\n• Primo punto\n    ▪ Secondo punto');

        // 3. Press Shift+Tab (outdent) -> decreases indent back to '  ◦ '
        final handledShift1 = ctrl.handleTabKey(outdent: true);
        expect(handledShift1, isTrue);
        expect(ctrl.text, 'Titolo\n• Primo punto\n  ◦ Secondo punto');

        // 4. Press Shift+Tab again -> decreases indent back to '• '
        final handledShift2 = ctrl.handleTabKey(outdent: true);
        expect(handledShift2, isTrue);
        expect(ctrl.text, 'Titolo\n• Primo punto\n• Secondo punto');

        // 5. Enter on sub-bullet continues with same indent and glyph, then exits on empty
        ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);
        ctrl.handleTabKey(outdent: false); // becomes '  ◦ Secondo punto'
        expect(ctrl.text.endsWith('  ◦ Secondo punto'), isTrue);

        ctrl.handleEnterKey();
        expect(ctrl.text.endsWith('  ◦ Secondo punto\n  ◦ '), isTrue);

        ctrl.handleEnterKey(); // Enter on empty sub-bullet outdents to '• '
        expect(ctrl.text.endsWith('  ◦ Secondo punto\n• '), isTrue);

        ctrl.handleEnterKey(); // Enter on empty bullet exits list
        expect(ctrl.text.endsWith('  ◦ Secondo punto\n'), isTrue);
      },
    );

    test('RichTextEditingController handleTabKey moves inline formatting once', () {
      final ctrl = RichTextEditingController(
        text: 'Titolo\nAbc def\nGhi',
        baseStyle: const TextStyle(fontSize: 15),
        spans: [
          StyleSpan(start: 11, end: 14, isBold: true),
          StyleSpan(start: 15, end: 18, isItalic: true),
        ],
      );
      ctrl.selection = const TextSelection(baseOffset: 8, extentOffset: 18);
      expect(ctrl.handleTabKey(), isTrue);
      expect(ctrl.text, 'Titolo\n  Abc def\n  Ghi');
      expect(ctrl.spans.length, 2);
      expect(ctrl.spans[0].start, 13);
      expect(ctrl.spans[0].end, 16);
      expect(ctrl.spans[0].isBold, isTrue);
      expect(ctrl.spans[1].start, 19);
      expect(ctrl.spans[1].end, 22);
      expect(ctrl.spans[1].isItalic, isTrue);
    });

    test('RichTextEditingController handleTabKey leaves heading lines unchanged', () {
      final ctrl = RichTextEditingController(
        text: 'Titolo\nIntestazione\nCorpo',
        baseStyle: const TextStyle(fontSize: 15),
      );
      ctrl.setLineStyle(1, BlockType.h1);

      ctrl.selection = const TextSelection.collapsed(offset: 10);
      expect(ctrl.handleTabKey(), isTrue);
      expect(ctrl.text, 'Titolo\nIntestazione\nCorpo');
      expect(ctrl.getLineStyle(1), BlockType.h1);

      ctrl.handleTabKey(outdent: true);
      expect(ctrl.text, 'Titolo\nIntestazione\nCorpo');
      expect(ctrl.getLineStyle(1), BlockType.h1);

      // Mixed selection: body line indents, heading line does not.
      ctrl.selection = TextSelection(baseOffset: 10, extentOffset: ctrl.text.length);
      ctrl.handleTabKey();
      expect(ctrl.text, 'Titolo\nIntestazione\n  Corpo');
      expect(ctrl.getLineStyle(1), BlockType.h1);
    });

    test(
      'RichTextEditingController handleTabKey keeps quote and monospace type after indent',
      () {
        final ctrl = RichTextEditingController(
          text: 'Titolo\n> Citazione\n```codice',
          baseStyle: const TextStyle(fontSize: 15),
        );

        ctrl.selection = TextSelection.collapsed(
          offset: ctrl.text.indexOf('Citazione'),
        );
        expect(ctrl.handleTabKey(outdent: false), isTrue);
        expect(ctrl.text, 'Titolo\n  > Citazione\n```codice');
        expect(ctrl.lineStyles[1], BlockType.quote);

        ctrl.selection = TextSelection.collapsed(
          offset: ctrl.text.indexOf('codice'),
        );
        expect(ctrl.handleTabKey(outdent: false), isTrue);
        expect(ctrl.text, 'Titolo\n  > Citazione\n  ```codice');
        expect(ctrl.lineStyles[2], BlockType.code);
      },
    );

    test(
      'RichTextEditingController handleBackspaceKey outdents and exits sub-bullets',
      () {
        final ctrl = RichTextEditingController(
          text: 'Titolo\n  ◦ Sub-item',
          baseStyle: const TextStyle(fontSize: 15),
        );

        // Cursor right after prefix "  ◦ " (offset 11: "Titolo\n" is 7, prefix is 4 -> offset 11)
        final textStart = ctrl.text.indexOf('Sub-item');
        ctrl.selection = TextSelection.collapsed(offset: textStart);

        // Backspace on "  ◦ Sub-item" at start of text outdents to "• Sub-item"
        final handled = ctrl.handleBackspaceKey();
        expect(handled, isTrue);
        expect(ctrl.text, 'Titolo\n• Sub-item');

        // Backspace at start of "• Sub-item" removes bullet to plain paragraph
        final bulletPos = ctrl.text.indexOf('Sub-item');
        ctrl.selection = TextSelection.collapsed(offset: bulletPos);
        final handled2 = ctrl.handleBackspaceKey();
        expect(handled2, isTrue);
        expect(ctrl.text, 'Titolo\nSub-item');
      },
    );

    test(
      'RichTextEditingController handleBackspaceKey does not demote headings and preserves lineStyles',
      () {
        final ctrl = RichTextEditingController(
          text: 'Titolo\nLa mia intestazione\n',
          baseStyle: const TextStyle(fontSize: 15),
          lineStyles: {
            0: BlockType.title,
            1: BlockType.h1,
            2: BlockType.paragraph,
          },
        );

        // Cursor at lineStart of H1 "La mia intestazione" (offset 7)
        ctrl.selection = const TextSelection.collapsed(offset: 7);
        final handled = ctrl.handleBackspaceKey();
        // Should not demote or intercept; normal line merge handles it
        expect(handled, isFalse);
        expect(ctrl.getLineStyle(1), BlockType.h1);

        // Delete trailing newline from line 2 back into H1
        ctrl.value = const TextEditingValue(
          text: 'Titolo\nLa mia intestazione',
          selection: TextSelection.collapsed(offset: 26),
        );
        expect(ctrl.getLineStyle(0), BlockType.title);
        expect(ctrl.getLineStyle(1), BlockType.h1);
      },
    );

    test(
      'RichTextEditingController handleBackspaceKey outdents and removes checklist checkboxes',
      () {
        final ctrl = RichTextEditingController(
          text: 'Titolo\n  ○ Sub-task',
          baseStyle: const TextStyle(fontSize: 15),
        );

        // Cursor right after prefix "  ○ " (offset 11: "Titolo\n" is 7, prefix is 4)
        ctrl.selection = const TextSelection.collapsed(offset: 11);
        final handled = ctrl.handleBackspaceKey();
        expect(handled, isTrue);
        expect(ctrl.text, 'Titolo\n○ Sub-task');

        // Backspace right after prefix "○ " (offset 9) removes checkbox to normal text
        ctrl.selection = const TextSelection.collapsed(offset: 9);
        final handled2 = ctrl.handleBackspaceKey();
        expect(handled2, isTrue);
        expect(ctrl.text, 'Titolo\nSub-task');
      },
    );

    test(
      'RichTextEditingController handleBackspaceKey outdents indented items when the cursor is right after the symbol',
      () {
        final ctrl = RichTextEditingController(
          text: 'Titolo\n  ◦ Sub-item\n  ○ Sub-task',
          baseStyle: const TextStyle(fontSize: 15),
        );

        // Cursor right after the bullet "◦" (offset 10), before its space
        ctrl.selection = const TextSelection.collapsed(offset: 10);
        expect(ctrl.handleBackspaceKey(), isTrue);
        expect(ctrl.text, 'Titolo\n• Sub-item\n  ○ Sub-task');

        // Cursor right after the circle "○" of the checklist line
        final circlePos = ctrl.text.indexOf('○') + 1;
        ctrl.selection = TextSelection.collapsed(offset: circlePos);
        expect(ctrl.handleBackspaceKey(), isTrue);
        expect(ctrl.text, 'Titolo\n• Sub-item\n○ Sub-task');
      },
    );

    test(
      'RichTextEditingController handleBackspaceKey removes symbol and space of unindented items when the cursor is right after the symbol',
      () {
        final ctrl = RichTextEditingController(
          text: 'Titolo\n• Testo\n○ Task\n● Fatto',
          baseStyle: const TextStyle(fontSize: 15),
        );

        // Cursor right after the bullet "•" (offset 8), before its space
        ctrl.selection = const TextSelection.collapsed(offset: 8);
        expect(ctrl.handleBackspaceKey(), isTrue);
        expect(ctrl.text, 'Titolo\nTesto\n○ Task\n● Fatto');
        expect(ctrl.selection, const TextSelection.collapsed(offset: 7));

        // Cursor right after the empty circle "○" of the checklist line (offset 14)
        ctrl.selection = const TextSelection.collapsed(offset: 14);
        expect(ctrl.handleBackspaceKey(), isTrue);
        expect(ctrl.text, 'Titolo\nTesto\nTask\n● Fatto');
        expect(ctrl.selection, const TextSelection.collapsed(offset: 13));

        // Cursor right after the filled circle "●" of the done checklist line
        final filledPos = ctrl.text.indexOf('●') + 1;
        ctrl.selection = TextSelection.collapsed(offset: filledPos);
        expect(ctrl.handleBackspaceKey(), isTrue);
        expect(ctrl.text, 'Titolo\nTesto\nTask\nFatto');
      },
    );

    test(
      'Note.toMarkdown exports paragraph blocks with lineStyles preserving heading markers',
      () {
        final jsonBlocks = [
          {
            'id': 'block-1',
            'type': 'paragraph',
            'text': 'Titolo\nIntestazione H1\nSotto H2\nCorpo',
            'lineStyles': {
              '0': 'title',
              '1': 'h1',
              '2': 'h2',
              '3': 'paragraph',
            },
          },
        ];

        final note = Note(
          id: 'linestyles-note',
          title: 'Titolo',
          content: jsonEncode(jsonBlocks),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final md = note.toMarkdown();
        expect(md.contains('# Titolo'), isTrue);
        expect(md.contains('# Intestazione H1'), isTrue);
        expect(md.contains('## Sotto H2'), isTrue);
        expect(md.contains('Corpo'), isTrue);
      },
    );

    test(
      'Note.toMarkdown wraps a bold run split by underline in one marker pair, spaces outside',
      () {
        Note noteWith(List<Map<String, dynamic>> spans) => Note(
          id: 'inline-run-note',
          title: 'Titolo',
          content: jsonEncode([
            {
              'id': 'block-1',
              'type': 'paragraph',
              'text': 'ciao mondo',
              'spans': spans,
            },
          ]),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(
          noteWith([
            {'start': 0, 'end': 10, 'bold': true},
            {'start': 5, 'end': 10, 'underline': true},
          ]).toMarkdown(),
          '**ciao mondo**',
        );
        expect(
          noteWith([
            {'start': 0, 'end': 5, 'bold': true},
          ]).toMarkdown(),
          '**ciao** mondo',
        );
      },
    );

    test(
      'Note.toMarkdownBody leaves out the title line of plain-text and block notes',
      () {
        final plain = Note(
          id: 'body-plain-note',
          title: 'Titolo',
          content: 'Titolo\n○ Primo\nRiga',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(plain.toMarkdownBody(), '- [ ] Primo\nRiga');

        final blocks = Note(
          id: 'body-block-note',
          title: 'Titolo',
          content: jsonEncode([
            {
              'id': 'block-1',
              'type': 'paragraph',
              'text': 'Titolo',
              'lineStyles': {'0': 'title'},
            },
            {
              'id': 'block-2',
              'type': 'paragraph',
              'text': 'Corpo',
            },
          ]),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(blocks.toMarkdownBody(), 'Corpo');
      },
    );

    test(
      'Note.toMarkdownBody drops blank lines that start the body',
      () {
        final plain = Note(
          id: 'body-leading-blank-plain',
          title: 'Titolo',
          content: 'Titolo\n\nRiga',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(plain.toMarkdownBody(), 'Riga');

        final blocks = Note(
          id: 'body-leading-blank-blocks',
          title: 'Titolo',
          content: jsonEncode([
            {
              'id': 'block-1',
              'type': 'paragraph',
              'text': 'Titolo',
              'lineStyles': {'0': 'title'},
            },
            {'id': 'block-2', 'type': 'paragraph', 'text': ''},
            {'id': 'block-3', 'type': 'paragraph', 'text': 'Corpo'},
          ]),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(blocks.toMarkdownBody(), 'Corpo');
      },
    );

    test(
      'Note.toMarkdownBody keeps the whole first line when the title is clipped',
      () {
        final longLine = '${'A' * 60} resto della riga';
        final plain = Note(
          id: 'body-clipped-title-plain',
          title: 'A' * 60,
          content: '$longLine\nSeconda riga',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(plain.title, 'A' * 60);
        expect(plain.toMarkdownBody(), '$longLine\nSeconda riga');
      },
    );

    test(
      'Note.toMarkdown removes trailing blank lines from plain-text notes',
      () {
        final note = Note(
          id: 'plain-trailing-note',
          title: 'Titolo',
          content: 'Titolo\n○ Primo\n\n\n',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(note.toMarkdown(), 'Titolo\n- [ ] Primo');
      },
    );

    test(
      'Note.toMarkdown converts list symbols in plain-text notes starting with [',
      () {
        final note = Note(
          id: 'plain-bracket-note',
          title: 'Titolo',
          content: '[1] lista\n○ Primo\n● Secondo\n• Terzo\n\n  ',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(
          note.toMarkdown(),
          '[1] lista\n- [ ] Primo\n- [x] Secondo\n- Terzo',
        );
      },
    );

    test(
      'Note.toMarkdown keeps the line after an empty list symbol on its own line in plain-text notes',
      () {
        final note = Note(
          id: 'plain-empty-item-note',
          title: 'Titolo',
          content: 'Titolo\n○\nRiga successiva\n● \nAltra\n• \nUltima',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(
          note.toMarkdown(),
          'Titolo\n- [ ] \nRiga successiva\n- [x] \nAltra\n- \nUltima',
        );
      },
    );

    test(
      'Note.toMarkdown keeps the line after an empty list symbol on its own line in block paragraphs',
      () {
        final jsonBlocks = [
          {
            'id': 'block-empty-item',
            'type': 'paragraph',
            'text': 'Titolo\n○\nRiga successiva',
            'lineStyles': {
              '0': 'title',
              '1': 'paragraph',
              '2': 'paragraph',
            },
          },
        ];

        final note = Note(
          id: 'block-empty-item-note',
          title: 'Titolo',
          content: jsonEncode(jsonBlocks),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(
          note.toMarkdown(),
          '# Titolo\n- [ ] \nRiga successiva',
        );
      },
    );

    test(
      'Note.toMarkdown turns an empty title line in a paragraph block into a heading marker',
      () {
        final jsonBlocks = [
          {
            'id': 'block-empty-title-line',
            'type': 'paragraph',
            'text': '\nCorpo',
            'lineStyles': {
              '0': 'title',
              '1': 'paragraph',
            },
          },
        ];

        final note = Note(
          id: 'block-empty-title-line-note',
          title: 'Titolo',
          content: jsonEncode(jsonBlocks),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(note.toMarkdown(), '# \nCorpo');
      },
    );

    test(
      'RichTextEditingController deleting empty heading line keeps the style of the surviving first line',
      () {
        final ctrl = RichTextEditingController(
          text: 'Titolo\n\nRiga successiva',
          baseStyle: const TextStyle(fontSize: 15),
          lineStyles: {
            0: BlockType.title,
            1: BlockType.h1,
            2: BlockType.paragraph,
          },
        );

        // User deletes the empty H1 line 1 (backspacing at offset 7)
        ctrl.value = const TextEditingValue(
          text: 'Titolo\nRiga successiva',
          selection: TextSelection.collapsed(offset: 6),
        );

        expect(ctrl.getLineStyle(0), BlockType.title);
        expect(ctrl.getLineStyle(1), BlockType.h1);
      },
    );

    test(
      'RichTextEditingController backspacing at start of line below heading merges then splits cleanly',
      () {
        final ctrl = RichTextEditingController(
          text: 'Titolo\nHeader\nRiga successiva',
          baseStyle: const TextStyle(fontSize: 15),
          lineStyles: {
            0: BlockType.title,
            1: BlockType.h1,
            2: BlockType.paragraph,
          },
        );

        // User at start of 'Riga successiva' (offset 14) presses Backspace to merge with Header
        ctrl.value = const TextEditingValue(
          text: 'Titolo\nHeaderRiga successiva',
          selection: TextSelection.collapsed(offset: 13),
        );
        expect(ctrl.getLineStyle(0), BlockType.title);
        expect(ctrl.getLineStyle(1), BlockType.h1);

        // User presses Enter to separate them again
        ctrl.value = const TextEditingValue(
          text: 'Titolo\nHeader\nRiga successiva',
          selection: TextSelection.collapsed(offset: 14),
        );
        expect(ctrl.getLineStyle(0), BlockType.title);
        expect(ctrl.getLineStyle(1), BlockType.h1);
        expect(ctrl.getLineStyle(2), BlockType.paragraph);
      },
    );

    test(
      'deleting the leading newline preserves the first surviving line style and later edits',
      () {
        final ctrl = RichTextEditingController(
          text: '\nTitolo\nCorpo',
          baseStyle: const TextStyle(fontSize: 15),
          lineStyles: {1: BlockType.title, 2: BlockType.h1},
          spans: [StyleSpan(start: 8, end: 13, isBold: true)],
        );

        ctrl.selection = const TextSelection(baseOffset: 0, extentOffset: 1);
        ctrl.value = const TextEditingValue(
          text: 'Titolo\nCorpo',
          selection: TextSelection.collapsed(offset: 0),
        );
        expect(ctrl.text, 'Titolo\nCorpo');
        expect(ctrl.getLineStyle(0), BlockType.title);
        expect(ctrl.getLineStyle(1), BlockType.h1);
        expect(ctrl.spans.single.start, 7);
        expect(ctrl.spans.single.end, 12);

        ctrl.value = const TextEditingValue(
          text: 'Titolo\nCorpo!',
          selection: TextSelection.collapsed(offset: 13),
        );
        expect(ctrl.text, 'Titolo\nCorpo!');
        expect(ctrl.spans.single.end, 12);
      },
    );

    test(
      'replacing a selection that starts at a heading line keeps the heading style',
      () {
        final ctrl = RichTextEditingController(
          text: 'Titolo\nCorpo\nFine',
          baseStyle: const TextStyle(fontSize: 15),
          lineStyles: {0: BlockType.h1},
        );

        // Select "Titolo\nC" (body last touched line) and delete it
        ctrl.selection = const TextSelection(baseOffset: 0, extentOffset: 8);
        ctrl.value = const TextEditingValue(
          text: 'orpo\nFine',
          selection: TextSelection.collapsed(offset: 0),
        );
        expect(ctrl.text, 'orpo\nFine');
        expect(ctrl.getLineStyle(0), BlockType.h1);
        expect(ctrl.getLineStyle(1), BlockType.paragraph);
      },
    );

    test(
      'deleting the first of repeated lines uses the caret location for line styles',
      () {
        final ctrl = RichTextEditingController(
          text: 'X\nX\nY',
          baseStyle: const TextStyle(fontSize: 15),
          lineStyles: {
            0: BlockType.h1,
            1: BlockType.h2,
            2: BlockType.paragraph,
          },
        );
        ctrl.selection = const TextSelection(baseOffset: 0, extentOffset: 2);
        ctrl.value = const TextEditingValue(
          text: 'X\nY',
          selection: TextSelection.collapsed(offset: 0),
        );
        expect(ctrl.getLineStyle(0), BlockType.h2);
        expect(ctrl.getLineStyle(1), BlockType.paragraph);
      },
    );

    test(
      'Enter at the start of a styled line leaves its style with the text',
      () {
        final ctrl = RichTextEditingController(
          text: 'Titolo\nCorpo',
          baseStyle: const TextStyle(fontSize: 15),
          lineStyles: {0: BlockType.title, 1: BlockType.h1},
        );
        ctrl.selection = const TextSelection.collapsed(offset: 0);
        expect(ctrl.handleEnterKey(), isTrue);
        expect(ctrl.text, '\nTitolo\nCorpo');
        expect(ctrl.getLineStyle(0), BlockType.paragraph);
        expect(ctrl.getLineStyle(1), BlockType.title);
        expect(ctrl.getLineStyle(2), BlockType.h1);
      },
    );

    test('checklist toggle on a heading line makes it a body checklist item', () {
      final ctrl = RichTextEditingController(
        text: 'Titolo\nCorpo',
        baseStyle: const TextStyle(fontSize: 15),
        lineStyles: {0: BlockType.h1, 1: BlockType.title},
      );
      ctrl.selection = const TextSelection.collapsed(offset: 2);
      ctrl.toggleChecklistAtCursor();
      expect(ctrl.text, '○ Titolo\nCorpo');
      expect(ctrl.getLineStyle(0), BlockType.paragraph);
      expect(ctrl.getLineStyle(1), BlockType.title);
    });

    test('checklist toggle on a monospace line drops the fence marker', () {
      final ctrl = RichTextEditingController(
        text: 'Titolo\n```codice',
        baseStyle: const TextStyle(fontSize: 15),
        lineStyles: {0: BlockType.title, 1: BlockType.code},
      );
      ctrl.selection = const TextSelection.collapsed(offset: 10);
      ctrl.toggleChecklistAtCursor();
      expect(ctrl.text, 'Titolo\n○ codice');
      expect(ctrl.getLineStyle(1), BlockType.paragraph);
    });

    test('checklist toggle on a monospace line drops the fence and its space', () {
      final ctrl = RichTextEditingController(
        text: 'Titolo\n``` testo',
        baseStyle: const TextStyle(fontSize: 15),
        lineStyles: {0: BlockType.title, 1: BlockType.code},
      );
      ctrl.selection = const TextSelection.collapsed(offset: 10);
      ctrl.toggleChecklistAtCursor();
      expect(ctrl.text, 'Titolo\n○ testo');
      expect(ctrl.getLineStyle(1), BlockType.paragraph);
    });

    test('checklist button keeps a hash tag and a dash number without a space', () {
      final ctrl = RichTextEditingController(
        text: 'Titolo\n#lavoro',
        baseStyle: const TextStyle(fontSize: 15),
        lineStyles: {0: BlockType.title, 1: BlockType.paragraph},
      );
      ctrl.selection = const TextSelection.collapsed(offset: 10);
      ctrl.toggleChecklistAtCursor();
      expect(ctrl.text, 'Titolo\n○ #lavoro');

      final dash = RichTextEditingController(
        text: '-5 gradi',
        baseStyle: const TextStyle(fontSize: 15),
        lineStyles: {0: BlockType.paragraph},
      );
      dash.selection = const TextSelection.collapsed(offset: 3);
      dash.toggleChecklistAtCursor();
      expect(dash.text, '○ -5 gradi');
    });

    test('checklist button removes every leading prefix of the line', () {
      final ctrl = RichTextEditingController(
        text: '• > x',
        baseStyle: const TextStyle(fontSize: 15),
        lineStyles: {0: BlockType.paragraph},
      );
      ctrl.selection = const TextSelection.collapsed(offset: 4);
      ctrl.toggleChecklistAtCursor();
      expect(ctrl.text, '○ x');
    });

    test('checklist button marks only the cursor line of a multi-line selection', () {
      final ctrl = RichTextEditingController(
        text: 'Uno\nDue\nTre',
        baseStyle: const TextStyle(fontSize: 15),
      );
      ctrl.selection = const TextSelection(baseOffset: 0, extentOffset: 7);
      ctrl.toggleChecklistAtCursor();
      expect(ctrl.text, '○ Uno\nDue\nTre');
    });

    test('legacy heading cleanup shifts spans by each removed prefix', () {
      final ctrl = RichTextEditingController(
        text: '# Titolo\n## Sotto\nCorpo',
        baseStyle: const TextStyle(fontSize: 15),
        spans: [StyleSpan(start: 18, end: 23, isBold: true)],
      );
      expect(ctrl.text, 'Titolo\nSotto\nCorpo');
      expect(ctrl.spans.single.start, 13);
      expect(ctrl.spans.single.end, 18);
    });

    test(
      'typing a list shortcut preserves the newline before the converted line',
      () {
        final ctrl = RichTextEditingController(
          text: 'Prima\n',
          baseStyle: const TextStyle(fontSize: 15),
        );
        ctrl.selection = const TextSelection.collapsed(offset: 6);
        ctrl.value = const TextEditingValue(
          text: 'Prima\n- ',
          selection: TextSelection.collapsed(offset: 8),
        );
        expect(ctrl.text, 'Prima\n• ');
        expect(ctrl.text.split('\n'), hasLength(2));
      },
    );

    test(
      'initial formatting is clipped to text bounds and valid line indexes',
      () {
        final ctrl = RichTextEditingController(
          text: 'Uno\nDue',
          baseStyle: const TextStyle(fontSize: 15),
          spans: [
            StyleSpan(start: -3, end: 3, isBold: true),
            StyleSpan(start: 4, end: 30, isItalic: true),
          ],
          lineStyles: {-1: BlockType.h1, 0: BlockType.title, 3: BlockType.h2},
        );
        expect(ctrl.spans.map((span) => (span.start, span.end)).toList(), [
          (0, 3),
          (4, 7),
        ]);
        expect(ctrl.lineStyles, {0: BlockType.title});
      },
    );

    test(
      'replacing a selected range shifts following inline spans by actual edit length',
      () {
        final ctrl = RichTextEditingController(
          text: 'Uno\nDue\nTre',
          baseStyle: const TextStyle(fontSize: 15),
          lineStyles: {0: BlockType.title, 2: BlockType.h2},
          spans: [StyleSpan(start: 8, end: 11, isBold: true)],
        );
        ctrl.selection = const TextSelection(baseOffset: 4, extentOffset: 7);
        ctrl.value = const TextEditingValue(
          text: 'Uno\nA\nTre',
          selection: TextSelection.collapsed(offset: 5),
        );
        expect(ctrl.spans.single.start, 6);
        expect(ctrl.spans.single.end, 9);
        expect(ctrl.getLineStyle(0), BlockType.title);
        expect(ctrl.getLineStyle(2), BlockType.h2);
      },
    );
  });
}

class _RecordingNotesProvider extends NotesProvider {
  _RecordingNotesProvider({
    required super.dbService,
    required super.vaultService,
    required super.syncService,
  });

  final List<String> savedContents = [];

  @override
  void updateNoteContent(String noteId, String newContent) {
    savedContents.add(newContent);
  }
}
