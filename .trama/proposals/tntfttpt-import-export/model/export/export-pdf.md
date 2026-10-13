# PDF Export

L'impaginazione di una nota in un documento PDF e la sua consegna alla finestra di stampa del sistema, da cui l'utente può stampare o salvare. Nessuna schermata dell'app offre oggi questa azione.

## States

### Idle (initial)
Nessuna esportazione PDF in corso.
- `user.EXPORT_NOTE_AS_PDF` → Print dialog open: impagina la nota con la data dell'ultima modifica, il titolo, una linea divisoria e il corpo riga per riga, e apre la finestra di stampa con il documento intitolato come la nota; non chiede il PIN nemmeno per le note protette.

### Print dialog open
La finestra di stampa del sistema mostra il documento della nota.
- `operating-system.PRINT_DIALOG_CLOSED` → Idle: l'app non distingue tra stampa, salvataggio e annullamento.
