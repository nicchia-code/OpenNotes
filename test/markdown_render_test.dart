import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Test MarkdownStyleSheet parameters', (tester) async {
    final style = MarkdownStyleSheet(
      p: const TextStyle(fontSize: 15),
      pPadding: EdgeInsets.zero,
      h1: const TextStyle(fontSize: 28),
      h1Padding: EdgeInsets.zero,
      h2: const TextStyle(fontSize: 22),
      h2Padding: EdgeInsets.zero,
      h3: const TextStyle(fontSize: 18),
      h3Padding: EdgeInsets.zero,
      strong: const TextStyle(fontWeight: FontWeight.bold),
      em: const TextStyle(fontStyle: FontStyle.italic),
      del: const TextStyle(decoration: TextDecoration.lineThrough),
      blockquote: const TextStyle(fontStyle: FontStyle.italic),
      blockquoteDecoration: const BoxDecoration(),
      blockquotePadding: EdgeInsets.zero,
      code: const TextStyle(fontFamily: 'monospace'),
      codeblockDecoration: const BoxDecoration(),
      codeblockPadding: EdgeInsets.zero,
      listBullet: const TextStyle(fontSize: 15),
      listBulletPadding: EdgeInsets.zero,
      a: const TextStyle(color: Colors.blue),
    );
    expect(style.p?.fontSize, 15);
  });
}
