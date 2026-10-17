---
column: done
technical: false
refs:
  - sync-run/Running
drift: iq0sfpit
proposal: null
agent: false
created: 2026-10-17T13:41:35.409Z
finished: 2026-10-17T15:43:40.118Z
---
# Fix code to match the Model: Sign-out during a sync run: the Model does not say what the run does

## What happens

Se l'utente esce mentre un giro è in corso, il giro prosegue con il collegamento ormai senza sessione. Le sue richieste successive vanno al cloud come utente anonimo; se il giro fallisce dopo l'uscita viene programmato un nuovo tentativo che non viene annullato, e lo stato resta in attesa anche da uscito. Il controllo che rimuove le note sincronizzate assenti dal cloud può usare un elenco letto senza sessione: se il cloud risponde con un elenco vuoto, le note sincronizzate del dispositivo vengono rimosse (effetto non verificato).

## What should happen

Il Model dice che l'uscita riporta a Idle e annulla il tentativo programmato, ma solo dallo stato Waiting to retry (supabase.SIGNED_OUT). Nello stato Running non c'è nessuna transizione per l'uscita: il Model non dice se il giro si ferma, finisce o non programma nulla, né cosa accade alle letture già in corso. Il Requirement non lo dice. È un caso non coperto che cambia le note conservate sul dispositivo.

## Chosen option

**Fermare il giro all'uscita**

Prima di ogni passo verso il cloud il giro controlla che la sessione ci sia; se manca si ferma, non programma tentativi e lascia la coda com'è. Costo: il giro interrotto non completa i passi che restano; la coda viene inviata al prossimo accesso.

## Where in the code

lib/core/services/sync_service.dart: ramo signedOut di _setupAuthListener (cancelRetry non tocca il giro in corso), syncNow (lettura del cloud, controllo delle note sincronizzate assenti dal cloud, ramo catch con scheduleRetry).
