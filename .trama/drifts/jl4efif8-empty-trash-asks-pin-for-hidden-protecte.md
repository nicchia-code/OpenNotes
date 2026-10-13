---
status: resolved
resolution: fix-code
refs:
  - note/In trash/user.EMPTY_TRASH
  - note-access/Protected
  - requirements/rules#note-access
proposal: null
task: ls845qn9
origin: null
critical: false
option: 1
note: null
resolvedBy: 37m9hzhb
created: 2026-10-13T05:26:16.254Z
---
# Empty trash asks PIN for hidden protected notes, the Model asks only for shown ones

## What happens

Svuotando il cestino, il sistema chiede il PIN se nel cestino c'è almeno una nota protetta, anche quando un filtro di ricerca o di tag la nasconde nell'elenco. Il controllo guarda tutte le note del cestino, non solo quelle visibili.

## What should happen

Il Model dice che lo svuotamento chiede il PIN solo se tra le note mostrate nella vista Cestino ce n'è una protetta; la regola di accesso alle note protette dice la stessa cosa. La regola generale sulla protezione, però, chiede il PIN per ogni eliminazione definitiva di una nota protetta.

## Fix options

### Ask PIN for every protected note in the trash

Il PIN serve per ogni nota protetta nel cestino, anche per quelle nascoste da ricerca o tag. Si riscrivono il Model e la regola di accesso in questo senso: così resta vera la regola generale, cioè che eliminare definitivamente una nota protetta richiede sempre il PIN. Costo: un PIN in più quando un filtro nasconde note protette; l'elenco non cambia.

### Ask PIN only for the protected notes shown

Il PIN serve solo per le note protette visibili nella vista Cestino, come dice il Model. Le note protette nascoste da un filtro vengono eliminate senza PIN: è il comportamento che un Task già chiuso aveva corretto, e viola la regola generale sulla protezione. Costo: un buco nella protezione, e il controllo va cambiato per guardare solo l'elenco visibile.

## Where in the code

lib/core/state/notes_provider.dart (trashHasProtectedNote); lib/ui/notes_list/notes_list_view.dart e lib/ui/mobile/mobile_notes_list_screen.dart (conferma dello svuotamento)
