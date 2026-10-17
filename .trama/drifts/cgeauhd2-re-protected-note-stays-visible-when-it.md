---
status: resolved
resolution: fix-code
refs:
  - note-editor/Open/note-access.RELOCKED
proposal: null
task: oaylo8ng
origin: null
critical: false
option: 1
note: null
resolvedBy: 1mjjves7
created: 2026-10-17T09:45:15.405Z
---
# Re-protected note stays visible when it was unlocked earlier in the session

## What happens

Una nota sbloccata nella sessione viene sprotetta (PROTECTION_REMOVED, editor aperto in Open) e poi di nuovo protetta con il lucchetto. Il codice non toglie la nota dall'insieme degli sblocchi di sessione: SecurityService.isNoteUnlocked resta vero, quindi il documento resta visibile senza PIN e nessun segnaposto compare. Anche lockAll, che svuoterebbe l'insieme, non ha chiamanti.

## What should happen

Subito dopo che il lucchetto è stato messo, la nota aperta torna nascosta: l'editor passa a Protected e mostra il segnaposto, come dice RELOCKED (subito dopo il lucchetto, oppure alla riapertura dell'app per una nota che era sbloccata). Il contenuto non resta visibile senza PIN.

## Fix options

### Rilucchettare subito la nota nel lock

Quando la protezione viene messa, la nota esce dall'insieme degli sblocchi di sessione, così l'editor passa a Protected. Il Model resta com'è. Costo: una chiamata in più nel percorso del lucchetto (note_actions.dart e mobile_note_editor_screen.dart).

### Usare lockAll alla messa del lucchetto

Svuotare tutti gli sblocchi di sessione quando una nota viene protetta, usando SecurityService.lockAll già esistente. Effetto: tutte le altre note sbloccate tornano nascoste, più di quanto dice il Model. Costo: cambia il comportamento per le note non coinvolte.

### Togliere l'uscita RELOCKED dal Model

Il Model dice che la nota torna nascosta alla protezione. Scegliere questa opzione significa accettare che la nota sbloccata resti leggibile senza PIN finché l'app non viene riaperta: decisione di sicurezza da approvare con una Proposal.

## Where in the code

lib/core/services/security_service.dart:46-55 (unlockNote e lockAll; lockAll non ha chiamanti); lib/ui/editor/notion_document_editor.dart:1058 (build: il segnaposto appare solo se !isNoteUnlocked); lib/ui/notes_list/note_actions.dart:75-90 e lib/ui/mobile/mobile_note_editor_screen.dart:81-100 (il lucchetto chiama toggleLock senza toccare gli sblocchi di sessione).
