# Pending change

Un cambiamento locale di una nota o di una cartella in attesa di essere inviato al cloud: il salvataggio di una nota, che porta con sé la nota intera, l'eliminazione definitiva di una nota, oppure la creazione, la rinomina o l'eliminazione di una cartella. Nasce a ogni salvataggio o eliminazione definitiva di una nota fatti sul dispositivo (creazione, modifica, fissaggio, blocco, spostamento, cestino, ripristino, duplicazione, svuotamento del cestino) e a ogni creazione, rinomina o eliminazione di una cartella dell'utente, anche quando nessun utente è connesso. Non nasce quando una nota o una cartella arriva dal cloud, quando le note di una cartella eliminata passano nella cartella "Note", né per i salvataggi di una nota di benvenuto mai sincronizzata, il cui destino viene deciso dalla sincronizzazione. I cambiamenti non vengono mai fusi: ogni salvataggio aggiunge un elemento alla coda.

## States

### Queued (initial)
Il cambiamento attende sul dispositivo, nell'ordine in cui è nato, e ricorda il momento in cui è entrato in coda. Se nessun utente è connesso, se una sincronizzazione è già in corso o se l'invio fallisce, resta in coda fino a una sincronizzazione successiva, senza limite di tentativi.
- `sync-run.CHANGE_SENT` → Sent: solo per questo cambiamento; viene tolto dalla coda.
- `sync-run.CHANGE_DISCARDED` → Discarded: solo per questo cambiamento; viene tolto dalla coda senza essere inviato.
- `sync-run.PREVIOUS_ACCOUNT_NOTE_REMOVED` → Discarded: solo se il cambiamento riguarda la nota rimossa per il cambio di account; viene tolto dalla coda senza essere inviato e la modifica va persa.

### Sent (final)
Il cloud ha accettato il cambiamento.

### Discarded (final)
Il cambiamento è stato tolto dalla coda senza raggiungere il cloud. L'utente non viene avvisato.

## Events

### QUEUED
Emesso quando il cambiamento entra in coda.
