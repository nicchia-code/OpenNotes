---
column: done
technical: false
refs:
  - note/Active/user.MOVE_NOTE_TO_TRASH
  - note/In trash/user.UNDO_MOVE_NOTE_TO_TRASH
  - note/In trash/user.RESTORE_NOTE
  - note/In trash/user.MOVE_NOTE_TO_FOLDER
drift: null
proposal: null
agent: false
created: 2026-10-12T11:25:38.571Z
finished: 2026-10-12T13:59:34.137Z
---
# Fix code to match the Model: Tag list keeps tags of notes that leave or re-enter the trash

Quando una nota va nel cestino, o ne esce per ripristino, annullamento o spostamento in una cartella, l'elenco dei tag della barra laterale deve cambiare subito: i tag di una nota nel cestino non devono più comparire, e quelli di una nota ripristinata devono tornare con il loro conteggio. Oggi questi comandi ricaricano solo l'elenco delle note e i conteggi, non l'elenco dei tag, che resta com'era fino alla prossima ricarica (per esempio una modifica del testo). Va ricaricato anche l'elenco dei tag in questi casi, come già avviene per la creazione e la duplicazione di una nota.
