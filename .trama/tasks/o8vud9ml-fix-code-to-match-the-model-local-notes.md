---
column: done
technical: false
refs:
  - account
  - cloud-sync
drift: 8t136rfu
proposal: null
agent: false
created: 2026-10-12T08:09:28.337Z
finished: 2026-10-12T08:14:42.125Z
---
# Fix code to match the Model: Local notes follow the account that signs in

## What happens

Le note del dispositivo non sono legate a un account. Quando si accede con un altro account Google, le note non ancora sincronizzate e le modifiche in coda vengono caricate nell'account appena connesso, anche se le ha scritte un altro utente; le note già sincronizzate non si spostano e restano legate al primo account.

## What should happen

Il modello dice che ogni utente vede sul cloud solo le proprie righe, ma non dice che cosa succede alle note del dispositivo quando cambia l'account: non è scritto se restano, passano al nuovo account o vengono tolte.

## Chosen option

**Il dispositivo parte dal nuovo account**

Prima del cambio, le note non sincronizzate vengono caricate nell'account precedente. Poi, al nuovo accesso, il dispositivo mostra solo le note di quell'account, scaricate dal cloud, e toglie le altre. Nessuna nota viene perduta, ma le note locali già sincronizzate spariscono dal dispositivo fino al ritorno dell'account precedente.

## Where in the code

lib/core/services/sync_service.dart (syncNow: coda e note non sincronizzate con user.id corrente); lib/core/services/auth_service.dart (signOut lascia le note locali)
