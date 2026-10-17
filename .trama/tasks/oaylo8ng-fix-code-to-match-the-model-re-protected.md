---
column: done
technical: false
refs:
  - note-editor/Open/note-access.RELOCKED
drift: cgeauhd2
proposal: null
agent: false
created: 2026-10-17T10:01:51.020Z
finished: 2026-10-17T10:06:04.481Z
---
# Fix code to match the Model: Re-protected note stays visible when it was unlocked earlier in the session

## What happens

Una nota sbloccata nella sessione viene sprotetta (PROTECTION_REMOVED, editor aperto in Open) e poi di nuovo protetta con il lucchetto. Il codice non toglie la nota dall'insieme degli sblocchi di sessione: SecurityService.isNoteUnlocked resta vero, quindi il documento resta visibile senza PIN e nessun segnaposto compare. Anche lockAll, che svuoterebbe l'insieme, non ha chiamanti.

## What should happen

Subito dopo che il lucchetto è stato messo, la nota aperta torna nascosta: l'editor passa a Protected e mostra il segnaposto, come dice RELOCKED (subito dopo il lucchetto, oppure alla riapertura dell'app per una nota che era sbloccata). Il contenuto non resta visibile senza PIN.

## Chosen option

**Rilucchettare subito la nota nel lock**

Quando la protezione viene messa, la nota esce dall'insieme degli sblocchi di sessione, così l'editor passa a Protected. Il Model resta com'è. Costo: una chiamata in più nel percorso del lucchetto (note_actions.dart e mobile_note_editor_screen.dart).

## Where in the code

lib/core/services/security_service.dart:46-55 (unlockNote e lockAll; lockAll non ha chiamanti); lib/ui/editor/notion_document_editor.dart:1058 (build: il segnaposto appare solo se !isNoteUnlocked); lib/ui/notes_list/note_actions.dart:75-90 e lib/ui/mobile/mobile_note_editor_screen.dart:81-100 (il lucchetto chiama toggleLock senza toccare gli sblocchi di sessione).
