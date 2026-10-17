---
column: done
technical: false
refs:
  - realtime-channel/Open/supabase.SIGNED_OUT
  - realtime-channel/Closed
drift: 5l3vk4ae
proposal: null
agent: false
created: 2026-10-17T13:41:35.344Z
finished: 2026-10-17T13:52:08.327Z
---
# Fix code to match the Model: Changes received before sign-out keep being applied after it

## What happens

Quando l'utente esce, il canale viene chiuso, ma le modifiche remote già ricevute e ancora in attesa di essere applicate continuano ad applicarsi al dispositivo, anche dopo l'uscita o dopo un accesso con un altro account. Possono quindi comparire note o cartelle dell'account precedente.

## What should happen

Il Model dice che in Closed non viene ricevuta nessuna modifica remota e che le note locali restano all'uscita, ma non dice cosa succede alle modifiche già ricevute e non ancora applicate quando il canale si chiude, né se un cambio di account le scarta. Il Requirement chiede il controllo completo all'accesso, quindi scartarle non fa perdere dati.

## Chosen option

**Discard the pending remote changes on close**

Alla chiusura del canale la coda delle modifiche ricevute viene svuotata, senza applicarle. Costo: le modifiche scartate arrivano solo con la sincronizzazione successiva, che al nuovo accesso è un controllo completo.

## Where in the code

lib/core/services/sync_service.dart: ramo signedOut di _setupAuthListener (unsubscribe e _realtimeChannel = null) e _setupRealtimeSubscription, dove la coda RealtimeChangeQueue non viene svuotata né fermata alla chiusura.
