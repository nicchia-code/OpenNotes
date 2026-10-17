---
status: resolved
resolution: fix-code
refs:
  - sync-run/Running
proposal: null
task: eweukixh
origin: null
critical: false
option: 1
note: null
resolvedBy: uo2rau9q
created: 2026-10-17T12:50:17.653Z
---
# Sign-out during a sync run: the Model does not say what the run does

## What happens

Se l'utente esce mentre un giro è in corso, il giro prosegue con il collegamento ormai senza sessione. Le sue richieste successive vanno al cloud come utente anonimo; se il giro fallisce dopo l'uscita viene programmato un nuovo tentativo che non viene annullato, e lo stato resta in attesa anche da uscito. Il controllo che rimuove le note sincronizzate assenti dal cloud può usare un elenco letto senza sessione: se il cloud risponde con un elenco vuoto, le note sincronizzate del dispositivo vengono rimosse (effetto non verificato).

## What should happen

Il Model dice che l'uscita riporta a Idle e annulla il tentativo programmato, ma solo dallo stato Waiting to retry (supabase.SIGNED_OUT). Nello stato Running non c'è nessuna transizione per l'uscita: il Model non dice se il giro si ferma, finisce o non programma nulla, né cosa accade alle letture già in corso. Il Requirement non lo dice. È un caso non coperto che cambia le note conservate sul dispositivo.

## Fix options

### Fermare il giro all'uscita

Prima di ogni passo verso il cloud il giro controlla che la sessione ci sia; se manca si ferma, non programma tentativi e lascia la coda com'è. Costo: il giro interrotto non completa i passi che restano; la coda viene inviata al prossimo accesso.

### Terminare il giro senza letture né rimozioni

Il giro arriva in fondo, ma se la sessione manca non legge il cloud, non rimuove nulla e non programma tentativi. Costo: richieste inutili fino alla fine del giro; il controllo di rimozione va condizionato alla lettura riuscita.

### Non programmare tentativi dopo l'uscita

Quando un giro fallisce e l'utente non è più connesso, non si programma nessun tentativo. Costo: il rischio di rimuovere note con un elenco vuoto resta, perché le letture restano come sono.

## Where in the code

lib/core/services/sync_service.dart: ramo signedOut di _setupAuthListener (cancelRetry non tocca il giro in corso), syncNow (lettura del cloud, controllo delle note sincronizzate assenti dal cloud, ramo catch con scheduleRetry).
