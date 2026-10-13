# Pending change

Un cambiamento locale di una nota in attesa di essere inviato al cloud: un salvataggio, che porta con sé la nota intera, oppure un'eliminazione definitiva. Nasce a ogni salvataggio o eliminazione definitiva fatti sul dispositivo (creazione, modifica, fissaggio, blocco, spostamento, cestino, ripristino, duplicazione, svuotamento del cestino, note di benvenuto), anche quando nessun utente è connesso; non nasce quando una nota arriva dal cloud. I cambiamenti non vengono mai fusi: ogni salvataggio aggiunge un elemento alla coda.

## States

### Queued (initial)
Il cambiamento attende sul dispositivo, nell'ordine in cui è nato. Se nessun utente è connesso, se una sincronizzazione è già in corso o se l'invio fallisce, resta in coda fino a una sincronizzazione successiva, senza limite di tentativi.
- `sync-run.CHANGE_SENT` → Sent: solo per questo cambiamento; viene tolto dalla coda.

### Sent (final)
Il cloud ha accettato il cambiamento.

## Events

### QUEUED
Emesso quando il cambiamento entra in coda.
