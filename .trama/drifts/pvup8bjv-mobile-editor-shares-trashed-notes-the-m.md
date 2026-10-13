---
status: resolved
resolution: fix-code
refs:
  - export-markdown-share/Idle/user.SHARE_NOTE
proposal: null
task: cjicfd6i
origin: null
critical: false
option: 1
note: null
resolvedBy: yv0225l5
created: 2026-10-12T12:03:07.465Z
---
# Mobile editor shares trashed notes, the Model leaves the trash out

## What happens

Sul telefono, una nota nel cestino aperta dall'elenco mostra il pulsante di condivisione nell'editor; toccandolo il foglio di condivisione si apre con il testo della nota, come per una nota attiva. Il menu di una nota nel cestino non offre invece la condivisione.

## What should happen

Il Model dice che la condivisione si avvia da una nota attiva, e la descrizione della Feature la esclude esplicitamente per il cestino: una nota nel cestino non si condivide. Il pulsante di condivisione dell'editor mobile non prevede questa esclusione.

## Fix options

### Nascondere il pulsante per le note nel cestino

Il pulsante di condivisione dell'editor non compare quando la nota è nel cestino, come già accade nel menu. Per condividere una nota occorre ripristinarla prima. Non cambia il Model e costa solo una verifica nell'editor mobile.

### Ammettere la condivisione dal cestino

Il pulsante resta e la condivisione funziona anche per le note nel cestino. Il Model e la descrizione della Feature vanno cambiati per dirlo, e il menu di una nota nel cestino resterebbe diverso dall'editor. Costa una modifica del Model e una verifica del comportamento.

## Where in the code

lib/ui/mobile/mobile_note_editor_screen.dart (pulsante di condivisione nella barra superiore); lib/ui/shell/adaptive_app_shell.dart (apertura dell'editor dal cestino); lib/ui/notes_list/note_action_menu.dart (voci per una nota nel cestino)
