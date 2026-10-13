---
status: resolved
resolution: fix-code
refs:
  - sync-run/Idle
  - pending-change/Queued
proposal: null
task: pd70d8kn
origin: null
critical: false
option: 1
note: null
resolvedBy: fz9axufm
created: 2026-10-12T10:47:47.278Z
---
# Folder changes start a sync run, the Model covers only notes

## What happens

Ogni modifica di cartella (creazione, rinomina, eliminazione) entra in una coda locale e avvia subito una sincronizzazione, se un utente è connesso, come fa una nota. Nel Diagramma nessuna Transition per le cartelle fa partire la sincronizzazione, e la coda descritta riguarda solo le note.

## What should happen

Il Feature dice che entrano in coda le modifiche delle note; il Model della sincronizzazione invia "i cambiamenti in coda" senza dire quali sono, e il Diagramma di Idle non ha nessun evento di cartella. Il Model dovrebbe dire se le cartelle passano dalla coda e se fanno partire una sincronizzazione.

## Fix options

### Record folder changes in the Model

Le modifiche di cartella entrano in coda e avviano la sincronizzazione come quelle delle note, e il Model lo dichiara: nel Feature, nella coda e nelle Transition di Idle. Il comportamento del codice resta com'è: le cartelle arrivano al cloud subito. Costo: una Proposal sul Feature, sulla coda e sulla sincronizzazione.

### Send folder changes only with the next run

Le modifiche di cartella restano in coda senza far partire una sincronizzazione: arrivano al cloud alla prossima, avviata da una nota o dal pulsante. Il Diagramma di Idle resta quello attuale. Costo: una cartella creata o rinominata può restare solo sul dispositivo a lungo, il codice va cambiato e il Model della coda va completato con le cartelle.

## Where in the code

lib/core/services/sync_service.dart: notifyFolderChanged
