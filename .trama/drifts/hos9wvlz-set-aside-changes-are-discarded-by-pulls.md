---
status: resolved
resolution: proposal
refs:
  - pending-change/Set aside
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: famz2y49
created: 2026-10-18T17:35:48.988Z
---
# Set-aside changes are discarded by pulls and account switches, the Model does not say so

## What happens

Una modifica messa da parte viene scartata quando una sincronizzazione applica una copia più nuova della nota o della cartella dal cloud, quando la nota viene rimossa dal cloud (tempo reale o sincronizzazione), e quando cambia l'account. Il codice toglie l'elemento dalla coda anche se ha il contrassegno di messa da parte, senza avvisare l'utente.

## What should happen

Il Model dice che lo stato Messa da parte si lascia solo con Riprova, Usa la versione del cloud, un nuovo salvataggio o l'eliminazione definitiva. Il Requirement delle regole di sincronizzazione dice invece che gli scarti (copia del cloud più recente, nota o cartella eliminata nel cloud, cambio di account) valgono per qualsiasi modifica in attesa. Il Model non nomina questi scarti per lo stato Messa da parte, e il codice segue il Requirement.

## Fix options

### Add the discard exits to Set aside in the Model

Aggiungere allo stato Messa da parte del Model le transizioni di scarto per copia del cloud più recente, nota o cartella eliminata nel cloud e cambio di account, come già previsto dai Requirement. Il codice resta com'è. Così il Model descrive ciò che accade davvero, e l'utente non vede più una modifica sparire senza che il Model ne parli.

### Keep set-aside changes through pulls and account switches

Cambiare il codice affinché gli scarti di sincronizzazione e cambio di account non tocchino le modifiche messe da parte, che restano in coda fino a Riprova o Usa la versione del cloud. Costo: una modifica messa da parte può restare in coda anche quando il cloud ha già una versione più recente, e il Requirement andrebbe cambiato.

## Where in the code

lib/core/services/sync_service.dart: applyRemoteNote, _storeCloudFolder, _removeRemoteNote, _adoptAccount; lib/core/services/database_service.dart: removeSyncActionsFor
