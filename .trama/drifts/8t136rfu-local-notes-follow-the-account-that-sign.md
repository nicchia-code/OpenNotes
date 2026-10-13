---
status: resolved
resolution: fix-code
refs:
  - account
  - cloud-sync
proposal: null
task: o8vud9ml
origin: null
critical: false
option: 1
note: null
resolvedBy: p136jufl
created: 2026-10-12T08:00:55.175Z
---
# Local notes follow the account that signs in

## What happens

Le note del dispositivo non sono legate a un account. Quando si accede con un altro account Google, le note non ancora sincronizzate e le modifiche in coda vengono caricate nell'account appena connesso, anche se le ha scritte un altro utente; le note già sincronizzate non si spostano e restano legate al primo account.

## What should happen

Il modello dice che ogni utente vede sul cloud solo le proprie righe, ma non dice che cosa succede alle note del dispositivo quando cambia l'account: non è scritto se restano, passano al nuovo account o vengono tolte.

## Fix options

### Il dispositivo parte dal nuovo account

Prima del cambio, le note non sincronizzate vengono caricate nell'account precedente. Poi, al nuovo accesso, il dispositivo mostra solo le note di quell'account, scaricate dal cloud, e toglie le altre. Nessuna nota viene perduta, ma le note locali già sincronizzate spariscono dal dispositivo fino al ritorno dell'account precedente.

### Le note locali passano al nuovo account

Tutte le note non ancora sincronizzate e le modifiche in attesa vanno al nuovo account, come oggi. Il dispositivo resta com'è e nessuna nota viene tolta, ma il nuovo utente riceve sul cloud note scritte da un altro, e il modello deve dirlo esplicitamente.

### Le note locali restano sul dispositivo

Le note del dispositivo non vengono più caricate con un account diverso da quello che le ha ricevute: le modifiche restano sul dispositivo finché non torna quell'account. Il cloud resta pulito, ma le copie di account diversi possono divergere e l'utente deve sapere che alcune note non sono salvate nel nuovo account.

## Where in the code

lib/core/services/sync_service.dart (syncNow: coda e note non sincronizzate con user.id corrente); lib/core/services/auth_service.dart (signOut lascia le note locali)
