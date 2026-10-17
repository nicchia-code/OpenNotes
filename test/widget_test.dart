import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/ui/notes_list/note_card.dart';
import 'package:open_notes/core/models/note_model.dart';

void main() {
  testWidgets('NoteCard renders title and indicators properly', (WidgetTester tester) async {
    final note = Note(
      id: 'n1',
      title: 'Nota di Test Apple',
      content: 'Contenuto aggiuntivo',
      tags: ['apple', 'mobile'],
      isPinned: true,
      isLocked: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: NoteCard(
            note: note,
            isSelected: false,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Nota di Test Apple'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.pin_fill), findsOneWidget);
    expect(find.text('#apple'), findsOneWidget);
  });

  testWidgets('NoteCard shows the set-aside badge only while the change is set aside', (WidgetTester tester) async {
    final note = Note(
      id: 'n2',
      title: 'Nota messa da parte',
      content: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    Widget card({required bool isSetAside}) => CupertinoApp(
          home: CupertinoPageScaffold(
            child: NoteCard(
              note: note,
              isSelected: false,
              isSetAside: isSetAside,
              onTap: () {},
            ),
          ),
        );

    await tester.pumpWidget(card(isSetAside: true));
    expect(find.byIcon(Icons.cloud_off), findsOneWidget);

    await tester.pumpWidget(card(isSetAside: false));
    expect(find.byIcon(Icons.cloud_off), findsNothing);
  });
}
