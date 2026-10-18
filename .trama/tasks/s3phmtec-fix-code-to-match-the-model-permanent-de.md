---
column: done
technical: false
refs:
  - mobile-navigation/Editing from list/user.DELETE_NOTE_PERMANENTLY
drift: null
proposal: null
agent: false
created: 2026-10-18T19:46:27.514Z
finished: 2026-10-18T19:50:01.559Z
---
# Fix code to match the Model: Permanent delete asks the PIN again for an already unlocked note (recurring)

Eliminando definitivamente una nota protetta gia sbloccata in questa sessione dal menu azioni nel cestino, l'app chiede di nuovo il PIN dopo la conferma: confirmPermanentDelete in note_actions.dart controlla solo note.isLocked e non lo sblocco di sessione (SecurityService.isNoteUnlocked). Il Model (mobile-navigation, note/In trash, note-access) e il Requirement rules/note-lock e rules/notes chiedono il PIN solo se la nota non e gia sbloccata per la sessione. Si ripete la correzione di lx8b641j/o4es5ttq, che la regola awkl66qu aveva annullato. Correzione attesa: la conferma passa direttamente alla chiusura quando la nota non e protetta oppure e gia sbloccata; il PIN resta solo per una nota protetta non sbloccata, con l'editor aperto sul segnaposto in quel caso.
