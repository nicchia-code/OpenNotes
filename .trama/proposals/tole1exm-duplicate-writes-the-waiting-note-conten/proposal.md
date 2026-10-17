---
status: rejected
base:
  editor/note-content-save.md: 15a403738251ebd80cac79d5d3f2fc886efaeec043911eb5e908e32782be6048
delete: []
created: 2026-10-17T17:50:01.835Z
---
# Duplicate writes the waiting note content first

Il Model non dice cosa accade alla modifica ancora in attesa quando l'utente duplica una nota. Il codice la scrive prima di creare la copia, come fa per fissare, proteggere, spostare e cestinare, così la copia contiene il testo visto sullo schermo. Decisione da confermare: la duplicazione è aggiunta alle uscite dell'attesa verso Inattivo, senza altri cambiamenti.

Decisioni da verificare: la copia nasce dal testo che l'utente vede, cioè dopo la scrittura della versione in attesa; le altre uscite restano come sono.

## Already present
- `note-content-save/Waiting/user.DUPLICATE_NOTE` — `lib/ui/notes_list/note_actions.dart` (`duplicate`, consegna e scrittura prima di `duplicateNote`), `lib/core/state/notes_provider.dart` (`flushPendingContent`)
- `note-content-save/Idle/note-editor.CONTENT_CHANGED` — `lib/core/state/notes_provider.dart` (`updateNoteContent`, `flushPendingContent`)

## Feedback

Drift fi2ub1th resolved by Proposal gdnc8czu
