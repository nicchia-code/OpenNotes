---
status: resolved
resolution: proposal
refs:
  - pending-change/Queued
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: 7qmreh1i
created: 2026-10-17T08:02:30.134Z
---
# Queued saves of a synced note are dropped silently when the user deletes it permanently

## What happens

Quando l'utente elimina definitivamente una nota già sincronizzata, i salvataggi di quella nota ancora in coda vengono tolti dalla coda subito, senza essere inviati e senza passare dalla sincronizzazione. La cancellazione accodata basta a rimuovere la nota dal cloud, ma la coda perde un'uscita che il Model non descrive.

## What should happen

Il Model dei cambiamenti in attesa ha come uscite solo Inviato e Scartato dalla sincronizzazione, più lo scarto per il cambio di account. Il Requirement elenca gli scarti senza avviso e la rimozione per eliminazione definitiva non c'è. Ogni cambiamento in coda deve uscire o inviato o scartato dalle regole della sincronizzazione.

## Fix options

### Keep the queued saves until the sync run

I salvataggi restano in coda fino alla sincronizzazione: la sincronizzazione li invia o li scarta con le sue regole, poi invia la cancellazione. Il Model e il Requirement non cambiano. Costo: qualche invio in più prima della cancellazione.

### Describe the drop in the Model

Il Model dei cambiamenti in attesa aggiunge l'uscita per la nota eliminata definitivamente con salvataggi in coda, e il Requirement la elenca tra gli scarti senza avviso. Il codice resta com'è. Costo: una Proposal di Model e di Requirement.

## Where in the code

lib/core/services/database_service.dart: permanentlyDeleteNote (202-212); lib/core/state/notes_provider.dart: _purgeNotes (614-625)
