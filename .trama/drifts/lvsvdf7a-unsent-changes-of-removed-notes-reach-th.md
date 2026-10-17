---
status: resolved
resolution: fix-code
refs:
  - pending-change/Pending/sync-run.PREVIOUS_ACCOUNT_NOTE_REMOVED
proposal: null
task: 0tr4qeq5
origin: null
previous: t40y5a9b
critical: false
option: 1
note: null
resolvedBy: awa4vyj9
created: 2026-10-17T14:11:48.029Z
---
# Unsent changes of removed notes reach the new account again

## What happens

Quando cambia l'account, le note già sincronizzate con il precedente vengono tolte dal dispositivo, ma le loro **modifiche non ancora inviate restano in coda**. Alla sincronizzazione successiva partono verso il cloud del nuovo account: il testo scritto con il precedente finisce tra i dati di chi è appena entrato. Il test del cambio di account si aspetta proprio questo invio. La stessa cosa era già stata corretta in passato e la correzione è tornata indietro.

## What should happen

Il Model della macchina **pending-change** dice che, al cambio di account, le modifiche in attesa delle note rimosse vengono **scartate senza essere inviate**, e la modifica va persa. Il Requirement dice lo stesso. Il nuovo account non deve ricevere testi scritti con il precedente.

## Fix options

### Scartare le modifiche in coda delle note rimosse

Quando le note già sincronizzate del precedente account vengono tolte per il cambio di account, anche le loro modifiche in coda vengono tolte senza essere inviate. Il nuovo account non riceve mai testi del precedente, come scritto nel Model. **Costo:** una modifica fatta offline prima del cambio va persa; nel cloud resta la versione già inviata. Il test del cambio di account va riallineato.

### Scartare le modifiche al momento dell'invio

Il giro di sincronizzazione salta e toglie dalla coda ogni modifica di una nota che non esiste più sul dispositivo, invece di inviarla. Il risultato per il nuovo account è lo stesso del Model e la rimozione delle note resta com'è. **Costo:** la coda può conservare righe di note assenti fino al giro successivo, e la regola va verificata a ogni giro.

## Where in the code

lib/core/services/sync_service.dart: _adoptAccount (le note del precedente account vengono tolte senza toccare la coda) e syncNow (invio della coda); test/sync_account_switch_test.dart (si aspetta l'invio delle modifiche del precedente account)
