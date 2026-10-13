---
column: done
technical: false
refs:
  - sync-run/Pushing changes
drift: t40y5a9b
proposal: null
agent: false
created: 2026-10-12T10:59:40.551Z
finished: 2026-10-12T11:04:48.632Z
---
# Fix code to match the Model: Unsent changes of notes removed by an account switch still reach the new account

## What happens

Quando il dispositivo passa a un altro account, le note già sincronizzate con il precedente vengono tolte dal dispositivo, ma le loro modifiche non ancora inviate restano in coda. Alla sincronizzazione successiva partono verso il cloud del nuovo account: il testo scritto con il precedente finisce così tra i dati di chi è appena entrato.

## What should happen

Il Model della Note dice che, al cambio di account, le note già sincronizzate con il precedente vengono rimosse **senza accodare nulla**, e che le loro **modifiche non ancora inviate vanno perse**. Il nuovo account non deve ricevere contenuti del precedente.

## Chosen option

**Drop the unsent changes of the removed notes**

Quando le note già sincronizzate vengono tolte per il cambio di account, anche le loro modifiche in coda vengono scartate. Il nuovo account non riceve mai testi del precedente, come scritto nel Model. Costo: una modifica fatta offline prima del cambio va persa; resta solo la versione che era già nel cloud del precedente account.

## Where in the code

lib/core/services/sync_service.dart: syncNow (coda), _adoptAccount
