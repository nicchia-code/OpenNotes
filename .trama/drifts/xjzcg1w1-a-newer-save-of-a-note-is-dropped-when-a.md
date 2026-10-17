---
status: resolved
resolution: fix-code
refs:
  - pending-change/Queued
  - requirements/rules#pending-change
proposal: null
task: wb0p050k
origin: null
critical: false
option: 1
note: null
resolvedBy: gdnc8czu
created: 2026-10-17T17:50:38.567Z
---
# A newer save of a note is dropped when a send finds the note deleted in the cloud

## What happens

Quando l'invio di una modifica trova la nota già eliminata nel cloud, la nota viene tolta dal dispositivo insieme a tutte le modifiche in coda. Se l'utente ha salvato di nuovo la nota mentre la modifica precedente era in invio, la nuova versione sostituisce quella in coda, ed è più recente della cancellazione del cloud: anche lei viene persa, senza avviso e senza mai arrivare al cloud.

## What should happen

Il Model dice che una modifica in coda esce senza essere inviata solo perché il cloud vince su di lei (sync-run.CHANGE_DISCARDED, solo per quella modifica). Il Requirement dice che una modifica viene scartata quando la cancellazione nel cloud è più recente di lei. Una modifica più recente della cancellazione deve restare in coda e tornare sul cloud, come già accade quando la cancellazione arriva dal download o dal tempo reale.

## Fix options

### Tenere la modifica più recente e inviarla

La nota resta sul dispositivo con la modifica più recente, che viene inviata nella stessa sincronizzazione e riporta la nota nel cloud. Vengono tolte solo le modifiche più vecchie della cancellazione. È lo stesso comportamento del download e del tempo reale. Costo: un controllo in più nel percorso di invio e un test per il caso di un salvataggio fatto durante l'invio.

### Tenere la nota tolta e inviare la modifica più tardi

La nota viene tolta dal dispositivo come oggi, ma la modifica più recente resta in coda e alla sincronizzazione successiva riporta la nota nel cloud. Fino a quel momento la nota non compare qui, anche se l'utente l'ha modificata da poco. Costo: la nota sparisce dalla vista per un giro di sincronizzazione, e il Model resta invariato.

## Where in the code

lib/core/services/sync_service.dart: _sendQueuedNote, ramo della copia del cloud eliminata (rimozione senza ora dell'eliminazione); confrontare con _removeRemoteNote chiamato con l'ora della cancellazione nel download (_applyCloudNotes) e nel tempo reale, che invece tiene le modifiche più recenti.
