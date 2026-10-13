import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/core/models/folder_model.dart';
import 'package:open_notes/ui/notes_list/folder_picker.dart';

void main() {
  testWidgets('orphans go last as a tree, siblings ignore case, indent by depth', (
    tester,
  ) async {
    final date = DateTime(2024);
    Folder folder(String id, String name, [String? parentId]) => Folder(
      id: id,
      name: name,
      parentId: parentId,
      createdAt: date,
      updatedAt: date,
    );
    final folders = [
      folder('a', 'Lavoro'),
      folder('b', 'beta', 'a'),
      folder('c', 'Alfa', 'a'),
      folder('r', 'Casa'),
      folder('z', 'zeta', 'gone'),
      folder('m', 'Mid', 'z'),
      folder('n', 'Anna', 'gone2'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.linux),
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showFolderPicker(context, folders, 'none'),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
    expect(
      tiles.map((tile) => (tile.title! as Text).data),
      ['Casa', 'Lavoro', 'Alfa', 'beta', 'Anna', 'zeta', 'Mid'],
    );
    expect(
      tiles.map((tile) => tile.contentPadding!.resolve(TextDirection.ltr).left),
      [16.0, 16.0, 36.0, 36.0, 16.0, 16.0, 36.0],
    );
  });
}
