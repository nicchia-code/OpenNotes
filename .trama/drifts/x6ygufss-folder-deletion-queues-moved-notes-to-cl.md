---
status: resolved
resolution: fix-code
refs:
  - folder/User folder/user.DELETE_FOLDER
proposal: null
task: 59mfpbei
origin: ry8lis4b
critical: false
option: 1
note: null
resolvedBy: ck9mt4x5
created: 2026-10-12T11:47:14.397Z
---
# Folder deletion queues moved notes to cloud against Model

## What happens

Quando una cartella viene eliminata, le sue note passano in «Note» ma il cloud non riceve questo spostamento: la sincronizzazione successiva scarica la copia del cloud, più recente, e riporta la nota nella cartella eliminata. Per la correzione scelta («Il cloud segue l'eliminazione») il cloud dovrebbe ricevere lo spostamento prima dell'eliminazione, cosa che il Model vieta.

## What should happen

Il Model dice che le note passano in «Note» senza cambiare la data e senza essere messe in coda per il cloud, e che l'eliminazione non viene messa in coda. La regola «Le modifiche alle cartelle non entrano mai nella coda» non copre lo spostamento delle note. Il Drift risolto (n7t68c63) ha scelto questa opzione, ma la Proposal m16unv7j è solo di correzione del codice: il Model non è ancora riscritto, quindi il codice non può seguirlo senza contraddire il Model.

## Fix options

### Riscrivere il Model prima del codice

Il Model della sincronizzazione e della cartella viene riscritto: lo spostamento delle note nella cartella «Note» entra nella coda del cloud prima dell'eliminazione, anche per le note nel cestino. Il cloud riceve una data nuova e gli altri dispositivi vedono le note in «Note». Costa una nuova Proposal di Model e un cambio di comportamento del cloud.

### Tenere il Model e collocare le note orfane in Note

Il download colloca in «Note» ogni nota la cui cartella non esiste sul dispositivo, senza toccare il cloud né la coda. Il Model non cambia. Costo: il cloud continua a indicare la cartella eliminata finché la nota non viene modificata; è l'opzione già implementata per il Task s9mfxock.

## Where in the code

lib/core/services/sync_service.dart (syncNow, applyRemoteNote)
