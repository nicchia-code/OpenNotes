---
column: done
technical: false
refs:
  - export-pdf/Idle/user.EXPORT_NOTE_AS_PDF
  - export-pdf/Print dialog open
  - export-pdf/Print dialog open/operating-system.PRINT_DIALOG_CLOSED
drift: null
proposal: null
agent: false
created: 2026-10-12T10:44:50.379Z
finished: 2026-10-12T13:54:01.783Z
---
# Fix code to match the Model: PDF export opens a second print dialog while one is open

Il Model prevede due stati: l'esportazione in Idle e la finestra di stampa aperta. Una richiesta di esportazione è accettata solo in Idle: mentre la finestra di stampa è aperta deve essere ignorata, senza aprire una seconda finestra. Quando il sistema chiude la finestra, l'esportazione torna disponibile. Oggi l'impaginazione non tiene traccia di questo stato.
