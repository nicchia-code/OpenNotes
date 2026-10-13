---
status: resolved
resolution: fix-code
refs:
  - sync-run/Pushing changes
proposal: null
task: 12gipnkd
origin: null
critical: false
option: 1
note: null
resolvedBy: fz9axufm
created: 2026-10-12T10:47:35.581Z
---
# Unsent changes of notes removed by an account switch still reach the new account

## What happens

Quando il dispositivo passa a un altro account, le note già sincronizzate con il precedente vengono tolte dal dispositivo, ma le loro modifiche non ancora inviate restano in coda. Alla sincronizzazione successiva partono verso il cloud del nuovo account: il testo scritto con il precedente finisce così tra i dati di chi è appena entrato.

## What should happen

Il Model della Note dice che, al cambio di account, le note già sincronizzate con il precedente vengono rimosse **senza accodare nulla**, e che le loro **modifiche non ancora inviate vanno perse**. Il nuovo account non deve ricevere contenuti del precedente.

## Fix options

### Drop the unsent changes of the removed notes

Quando le note già sincronizzate vengono tolte per il cambio di account, anche le loro modifiche in coda vengono scartate. Il nuovo account non riceve mai testi del precedente, come scritto nel Model. Costo: una modifica fatta offline prima del cambio va persa; resta solo la versione che era già nel cloud del precedente account.

### Send them to the new account, as the code does now

Le modifiche in coda restano e vengono inviate al cloud del nuovo account, assegnate al suo utente. Nessuna modifica si perde, ma il nuovo account riceve testo scritto con il precedente, e il Model della Note va riscritto per dirlo. Costo: una Proposal sul Model della Note e sulla sincronizzazione.

## Where in the code

lib/core/services/sync_service.dart: syncNow (coda), _adoptAccount
