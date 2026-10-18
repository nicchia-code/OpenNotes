---
status: resolved
resolution: proposal
refs:
  - folder/Deleted
  - requirements/rules#folder
proposal: null
task: null
origin: null
previous: rs0pb2jf
critical: false
option: null
note: null
resolvedBy: 2ckxa2av
created: 2026-10-18T19:48:54.318Z
---
# Deleted folder comes back on a newer remote change (recurring, realtime path again)

## What happens

Una cartella eliminata qui, la cui eliminazione non è ancora arrivata al cloud, torna subito quando dal cloud arriva una modifica fatta dopo l'eliminazione: il canale in tempo reale riporta la cartella e l'eliminazione in coda viene tolta, senza aspettare la sincronizzazione.

## What should happen

Una cartella eliminata è finale: il canale in tempo reale non la riporta. Torna solo con la sincronizzazione, e solo se il cloud l'ha cambiata dopo l'eliminazione, con il download (drift rs0pb2jf, risolta con la modifica del codice).

## Fix options

### Il canale in tempo reale ignora la cartella eliminata (recommended)

Una modifica ricevuta in tempo reale per una cartella con eliminazione in coda non viene applicata; la cartella torna solo con la sincronizzazione, come descrive il Model. Il codice è da riportare a quello deciso con la Drift rs0pb2jf.

### Il Model ammette il ritorno dal canale in tempo reale

Il Model e il Requirement dicono che una modifica in tempo reale più recente riporta la cartella eliminata subito. Il codice resta com'è e la regola va scritta nel Model.

### Il canale chiede una sincronizzazione

Una modifica in tempo reale per una cartella eliminata qui avvia un giro di sincronizzazione, che applica la regola della data. Il risultato è quello del primo caso, ma passa dal giro, come il Model descrive.

## Where in the code

lib/core/services/sync_service.dart: handleRemoteFolderChange (ramo delle modifiche remote, che chiama _storeCloudFolder) e _storeCloudFolder (ramo dell'eliminazione in coda, che la rimuove quando la copia del cloud non è più vecchia).
