import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/ui/editor/markdown_editing_controller.dart';

void main() {
  testWidgets('Delimiters maintain normal font size and bold is styled', (tester) async {
    final focusNode = FocusNode();
    final controller = MarkdownEditingController(
      text: 'Prima **grassetto** dopo',
      baseStyle: const TextStyle(fontSize: 16, color: Colors.black),
      focusNode: focusNode,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextField(
            controller: controller,
            focusNode: focusNode,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final span = controller.buildTextSpan(
      context: tester.element(find.byType(TextField)),
      withComposing: false,
    );
    final delimiterSpans = _findDelimiterSpans(span, '**');
    expect(delimiterSpans.length, 2);
    for (final s in delimiterSpans) {
      // Delimiters MUST maintain normal font size to avoid caret jumps & disappearing text
      expect(s.style?.fontSize, equals(16.0));
      expect(s.style?.color, isNotNull);
    }

    // Bold text must have FontWeight.w700
    final boldSpan = _findTextSpan(span, 'grassetto');
    expect(boldSpan, isNotNull);
    expect(boldSpan?.style?.fontWeight, equals(FontWeight.w700));
  });

  testWidgets('Typing ** or incomplete markdown never disappears into hidden spans', (tester) async {
    final focusNode = FocusNode();
    final controller = MarkdownEditingController(
      text: 'Scrivo ** e non deve sparire',
      baseStyle: const TextStyle(fontSize: 16, color: Colors.black),
      focusNode: focusNode,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextField(
            controller: controller,
            focusNode: focusNode,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final span = controller.buildTextSpan(
      context: tester.element(find.byType(TextField)),
      withComposing: false,
    );

    final hiddenSpans = _findHiddenSpans(span);
    expect(hiddenSpans, isEmpty);
    expect(controller.text, contains('**'));
  });
}

List<TextSpan> _findDelimiterSpans(InlineSpan root, String delimiter) {
  final result = <TextSpan>[];
  void visit(InlineSpan span) {
    if (span is TextSpan) {
      if (span.text == delimiter) {
        result.add(span);
      }
      if (span.children != null) {
        for (final child in span.children!) {
          visit(child);
        }
      }
    }
  }
  visit(root);
  return result;
}

TextSpan? _findTextSpan(InlineSpan root, String text) {
  TextSpan? found;
  void visit(InlineSpan span) {
    if (span is TextSpan) {
      if (span.text == text) {
        found = span;
        return;
      }
      if (span.children != null) {
        for (final child in span.children!) {
          visit(child);
        }
      }
    }
  }
  visit(root);
  return found;
}

List<TextSpan> _findHiddenSpans(InlineSpan root) {
  final result = <TextSpan>[];
  void visit(InlineSpan span) {
    if (span is TextSpan) {
      if (span.style?.fontSize == 0.001 || span.style?.color == Colors.transparent) {
        result.add(span);
      }
      if (span.children != null) {
        for (final child in span.children!) {
          visit(child);
        }
      }
    }
  }
  visit(root);
  return result;
}
