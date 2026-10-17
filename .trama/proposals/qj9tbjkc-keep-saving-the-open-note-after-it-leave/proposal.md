---
status: rejected
base:
  model/editor/note-content-save.md: new
  editor/note-content-save.md: 15a403738251ebd80cac79d5d3f2fc886efaeec043911eb5e908e32782be6048
  editor/note-editor.md: 81eb538ff1efd243799a3918b7fefe1c19ccfa092fa63740fb02f4b7dc019866
delete: []
created: 2026-10-17T17:54:37.298Z
---
# Record that edits stop being saved once the open note leaves the list

Il Model dell'editor mobile dice che, quando la nota aperta esce dall'elenco caricato (spostata in un'altra cartella, ripristinata dal cestino o sparita dai dati), l'editor resta aperto e la nota resta modificabile. Il Model del salvataggio dice però che una modifica per una nota fuori dall'elenco caricato non viene accettata. Il codice segue questo secondo Model: le modifiche fatte dopo l'uscita dall'elenco non vengono salvate, e nessun avviso compare.

Questa Proposal non cambia il comportamento: aggiunge all'editor la regola già in vigore nel codice e nel Model del salvataggio, così il Model dell'editor non lascia intendere il contrario.

Decisione da confermare dallo sviluppatore: accettare questa regola, oppure cambiare il codice perché le modifiche vengano salvate, cosa che richiede di cambiare anche il Model del salvataggio.

## Already present
- `note-editor/Open`
- `note-editor/Closed/note-selection.SELECTED_NOTE_CHANGED`
- `note-editor/Protected/note-access.UNLOCKED`
- `note-editor/Protected/note-access.PROTECTION_REMOVED`
- `note-editor/Protected/note-selection.SELECTED_NOTE_CHANGED`

## Feedback

Drift tcykpi7p resolved by Proposal gdnc8czu
