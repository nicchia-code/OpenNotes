---
status: resolved
resolution: proposal
refs:
  - pending-change/Queued
  - requirements/rules#pending-change
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: ccg944lf
created: 2026-10-12T12:05:48.557Z
---
# Queued changes dropped without being sent have no exit in the Model

## What happens

Quando la coda parte, alcune modifiche vengono tolte senza essere inviate: la modifica di una nota eliminata nel cloud da un altro dispositivo; le modifiche ancora in coda delle note sincronizzate con un account precedente, quando si cambia account; la modifica di una cartella quando il cloud ha già quella cartella. La modifica sparisce senza aver raggiunto il cloud.

## What should happen

Il Model dei cambiamenti in attesa dice che l'unica uscita di una modifica in coda è Inviata, e il Requirement dice che nulla viene scartato. Il Model della sincronizzazione dice però che con un cambio di account le modifiche non ancora inviate vanno perse, e che la nota eliminata nel cloud non accoda nulla. I tre casi non hanno un'uscita propria nel Model. Il caso della modifica più vecchia del cloud è già aperto a parte.

## Fix options

### Give each drop its own outcome in the Model

Il Model della coda aggiunge un'uscita per ciascun caso in cui la modifica viene tolta senza invio, con la sua condizione, e il Requirement sulla coda elenca queste eccezioni alla regola «nessuno scarto». Il codice resta com'è, come già deciso nei Drift risolti. Costa una Proposal di Model e di Requirement; la modifica persa resta invisibile all'utente, come oggi.

### Send the dropped changes anyway

Le modifiche tolte vengono inviate comunque. Così la nota eliminata nel cloud tornerebbe, le modifiche di un account precedente finirebbero nel nuovo e la cartella già presente nel cloud verrebbe sovrascritta. Nessuna modifica si perde, ma le decisioni già prese nei Drift risolti vanno riscritte e dati di un altro account vengono esposti.

### Keep dropped changes queued until they can be sent

Le modifiche tolte restano in coda finché non possono essere inviate, senza essere scartate. La nota eliminata nel cloud e le modifiche dell'account precedente non partirebbero mai, e la coda crescerebbe. Costa una regola per liberare questi elementi quando la nota o l'account cambiano ancora, e una coda che non si svuota.

## Where in the code

lib/core/services/sync_service.dart (syncNow, passo della coda: rami delle note e della cartella; _adoptAccount: rimozione delle modifiche in coda al cambio di account)
