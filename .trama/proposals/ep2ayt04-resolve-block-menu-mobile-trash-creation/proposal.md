---
status: approved
kind: resolution
drifts:
  - drift: gslniesx
    decision: fix-code
    option: 1
  - drift: hqaspk8d
    decision: proposal
  - drift: jqu9c1no
    decision: proposal
base:
  editor/editor-suggestions.md: 4ed1c2ff0a4c46f092c4be0c55c9acde0e48b6c2c88497d22a3036e8e5ecbc6e
  actors/user.md: 0f92ad3bec784e9c36b85050954367e97267fcecea7de8692276983d7ba61c7b
  editor/note-editor.md: 1fbb9bc5979a00587aea0a1cded4a64a5529285d762eed78068d65f25a52a43e
  navigation/mobile-navigation.md: 7488c9b1d61f67585bf53c603412f1e862da855f689ffd6d24ccc5759b9466b9
  notes/note.md: 7b26f5aadb08f3654b0275e7ba4797437cbea0ac988dcdb92a3d0f0904c933d1
  cloud-sync/sync-run.md: 1437a06d26850e2f3b29490cfa88fead8d99905ed7cbc23e28c0081792b9c5d0
  requirements/rules/editor.md: b15bb97c86b726071e0f7a268f775abd34dc42ca6630f801daefd36e47c33568
  requirements/rules/notes.md: efb982fb02e7f91fa2c36c6ed65141b71005797bd50926a7511970ea8507a577
  requirements/data/cloud-sync.md: 2006cf39483f6a900e8469f66bc410188b70fd65aa2f0f8e924f04be0ee04e81
delete: []
created: 2026-10-12T10:19:47.260Z
---
# Resolve block menu, mobile trash creation and account switch drifts

Risolve tre Drift con le scelte del developer:
- gslniesx – Block menu opening from the toolbar still missing from the Model: correggere il codice (opzione 1). Un nuovo pulsante sulla barra sopra la tastiera del telefono apre il menu rapido dei blocchi sotto la sezione corrente; il Model registra subito questa apertura, così il lavoro sul codice non si ferma di nuovo.
- hqaspk8d – New note button hidden in trash on mobile: il Model registra il comportamento attuale. Nel cestino non c'è il pulsante per creare una nota; la creazione vale solo per le altre selezioni.
- jqu9c1no – Account switch removes synced notes, missing from the note Model: il Model registra il comportamento attuale. Quando sincronizza un account diverso dall'ultimo, le note già sincronizzate con l'account precedente vengono tolte dal dispositivo con il loro file Markdown, senza toccare il cloud.
