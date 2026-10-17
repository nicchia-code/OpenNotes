---
status: resolved
resolution: fix-code
refs:
  - realtime-channel/Open/supabase.SIGNED_OUT
  - realtime-channel/Closed
proposal: null
task: fbfy9lor
origin: null
critical: false
option: 1
note: null
resolvedBy: uo2rau9q
created: 2026-10-17T12:45:10.774Z
---
# Changes received before sign-out keep being applied after it

## What happens

Quando l'utente esce, il canale viene chiuso, ma le modifiche remote già ricevute e ancora in attesa di essere applicate continuano ad applicarsi al dispositivo, anche dopo l'uscita o dopo un accesso con un altro account. Possono quindi comparire note o cartelle dell'account precedente.

## What should happen

Il Model dice che in Closed non viene ricevuta nessuna modifica remota e che le note locali restano all'uscita, ma non dice cosa succede alle modifiche già ricevute e non ancora applicate quando il canale si chiude, né se un cambio di account le scarta. Il Requirement chiede il controllo completo all'accesso, quindi scartarle non fa perdere dati.

## Fix options

### Discard the pending remote changes on close

Alla chiusura del canale la coda delle modifiche ricevute viene svuotata, senza applicarle. Costo: le modifiche scartate arrivano solo con la sincronizzazione successiva, che al nuovo accesso è un controllo completo.

### Check the account before each change

Ogni modifica ricevuta viene applicata solo se l'utente connesso è ancora quello del canale che l'ha ricevuta; le altre vengono scartate. Costo: un controllo in più per ogni modifica e una regola nuova nel codice di applicazione.

### Let the sign-out wait for the queue

L'uscita attende che le modifiche già ricevute siano applicate, e solo dopo chiude il canale. Costo: l'uscita può richiedere più tempo quando la coda è lunga; con coda vuota non cambia nulla.

## Where in the code

lib/core/services/sync_service.dart: ramo signedOut di _setupAuthListener (unsubscribe e _realtimeChannel = null) e _setupRealtimeSubscription, dove la coda RealtimeChangeQueue non viene svuotata né fermata alla chiusura.
