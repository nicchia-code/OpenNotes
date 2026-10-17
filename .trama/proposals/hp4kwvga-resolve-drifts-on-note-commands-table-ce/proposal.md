---
status: approved
kind: resolution
drifts:
  - drift: c5jd98ef
    decision: proposal
  - drift: pxe7ywy2
    decision: fix-code
    option: 1
  - drift: kr6a8mi1
    decision: proposal
  - drift: 74s806l4
    decision: fix-code
    option: 1
  - drift: vag7ogkr
    decision: proposal
  - drift: ozxekjn6
    decision: proposal
base:
  cloud-sync/pending-change.md: e3bac409c906e8ce59c4071b84a8ea6a1c135cfb28b4f585d99757625c43a725
  editor/note-content-save.md: 5017bcdb154adb9eefe7bb7af762aade1b127acf61a2b55cebe87e9684d58ff3
  editor/note-editor.md: cb3cac8ce2e3d6a2bdef9f1258fecab51e1f870835b36477ab02afbc6ef8d720
  editor/drawing-canvas.md: ba35ac4758e0a919ceb22e661ca268ee6545e3ff1db89930d010b2ae6b20dd23
  actors/user.md: 08345d9fe2cb45796970190a862726338aca526aba4f9a7230048320d3f5d4aa
  requirements/rules/editor.md: efe852db066718a006a826b9760efdf2bee384b63a943917151ec5369cfaeb24
  requirements/rules/notes.md: 4a999d0ffe08c5c277086f567529fa0d1747f779a13be19a63c2627f44be096c
  requirements/tech/general.md: a671713098c37afc979e6f426a0eca8589fb6394159df77c2855a984a63959f7
delete: []
created: 2026-10-17T13:07:22.254Z
---
# Resolve Drifts on note commands, table cells, Flutter version and drawing canvas

Risoluzione dei Drift decisi dal developer.

- c5jd98ef Account change discards unsent changes the Model no longer names in pending-change: proposal. Si adottano le modifiche della Proposal allegata iykujnxn: lo scarto dei cambiamenti in attesa delle note rimosse per il cambio di account resta nella macchina pending-change, già com'è oggi nel Model.
- pxe7ywy2 Realtime echo check compares update times, not revisions: fix-code. Il canale riconosce l'eco per revisione appena il dispositivo conserva la revisione di ogni nota e cartella.
- kr6a8mi1 Note commands write the waiting content at once, the Model has no such exit: proposal. Prima di fissare o togliere dalle fissate, proteggere o togliere la protezione, mettere nel cestino, ripristinare o spostare una nota, il testo in attesa viene consegnato e scritto subito; il comando agisce poi sulla nota appena salvata.
- 74s806l4 Remote version waits while a table cell has the cursor: fix-code. La versione remota si carica anche con il cursore in una cella, e il cursore torna nella stessa cella e posizione se esistono ancora.
- vag7ogkr Flutter version in CI and FVM differs from the Requirement: proposal. La CI fissa Flutter 3.41.6 stable, la prima 3.41 che rispetta il vincolo Dart; lo sviluppo locale usa la versione indicata in .fvmrc.
- ozxekjn6 Drawing saved on desktop with no note open is lost: proposal. La tela da disegno si apre solo dalla nota aperta: su desktop il comando compare solo con una nota selezionata fuori dal cestino.
