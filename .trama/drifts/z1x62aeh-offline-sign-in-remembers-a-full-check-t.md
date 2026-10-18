---
status: resolved
resolution: proposal
refs:
  - sync-run
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: famz2y49
created: 2026-10-18T17:34:41.432Z
---
# Offline sign-in remembers a full check the Model does not describe

## What happens

Quando il dispositivo è offline e arriva supabase.SIGNED_IN con una sessione, il codice ricorda che al ritorno della rete serve un controllo completo e non avvia alcun giro. Nella fase Offline del Model, però, questo comportamento è descritto solo per supabase.INITIAL_SESSION: per supabase.SIGNED_IN il Model non dice nulla.

## What should happen

Il Model deve descrivere esplicitamente cosa succede a supabase.SIGNED_IN quando il dispositivo è offline, così che codice e Model coincidano.

## Fix options

### Describe SIGNED_IN offline in the Model

Aggiungere nella fase Offline la voce supabase.SIGNED_IN → Offline, solo se l'evento porta una sessione; ricorda che al ritorno della rete serve un controllo completo, come già per INITIAL_SESSION. Il codice resta com'è. Così il sign-in e l'avvio dell'app offline si comportano allo stesso modo, e il controllo completo non si perde se l'account è cambiato mentre il dispositivo era senza rete.

### Make the code ignore SIGNED_IN offline

Rimuovere dal codice il ramo che ricorda il controllo completo quando arriva SIGNED_IN offline: l'evento viene ignorato, come il Model non prevede. Il ritorno della rete darà allora un giro incrementale. Il rischio è che un cambio di account avvenuto offline non venga controllato a fondo finché non parte un controllo completo manuale o all'avvio successivo.

## Where in the code

lib/core/services/sync_service.dart: auth listener onAuthStateChange, branch for AuthChangeEvent.signedIn and initialSession when _triggers.isOffline (lines 465-479)
