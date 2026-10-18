---
status: resolved
resolution: proposal
refs:
  - account/Signed in
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: reg9oh8m
created: 2026-10-18T16:40:10.940Z
---
# SIGNED_IN con sessione mentre l'account è già connesso non è nel Model

## What happens

Quando il servizio cloud conferma di nuovo l'accesso con una sessione mentre l'utente è già connesso, l'app riapre il canale in tempo reale e avvia una sincronizzazione completa. Il Model dell'account non prevede questa transizione dallo stato Signed in: lo stato resta connesso, ma l'effetto non è descritto.

## What should happen

Il Model dell'account dice che supabase.SIGNED_IN con sessione porta a Signed in anche se l'app non stava attendendo il ritorno dal browser, con sincronizzazione completa e canale aperto. Non distingue se l'evento arriva da Signed out, da Awaiting login o da Signed in, quindi l'effetto da Signed in va chiarito nel Model o rimosso dal codice.

## Fix options

### Aggiungere la transizione nel Model

Il Model dell'account registra supabase.SIGNED_IN con sessione anche dallo stato Signed in, con sincronizzazione completa e canale in tempo reale riaperto, come oggi fa il codice. Così il comportamento è descritto e il Model resta coerente con sync-run e realtime-channel.

### Rimuovere l'effetto dal codice

Il codice smette di riaprire il canale e di avviare una sincronizzazione quando l'evento arriva dallo stato Signed in, lasciando invariato lo stato. Il rinnovo di sessione resta gestito dagli altri Machine.

## Where in the code

lib/core/services/sync_service.dart: _setupAuthListener, ramo initialSession/signedIn con sessione
