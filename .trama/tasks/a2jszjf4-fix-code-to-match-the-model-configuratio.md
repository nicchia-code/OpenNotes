---
column: done
technical: false
refs:
  - cloud-connection/Configuring
drift: hoivm02e
proposal: null
agent: false
created: 2026-10-12T07:38:53.680Z
finished: 2026-10-12T07:43:00.058Z
---
# Fix code to match the Model: Configuration errors ignored on first preparation

## What happens

Quando la preparazione del collegamento al progetto cloud fallisce, l'errore viene sempre ignorato, anche al primo tentativo. L'app passa quindi a **Configured** e salva indirizzo e chiave, ma il collegamento non è utilizzabile: le sincronizzazioni partono senza effetto e non compare alcuna segnalazione.

## What should happen

L'errore va ignorato solo se il collegamento era già stato preparato durante questa esecuzione. In ogni altro caso la preparazione fallisce e l'app resta **Not configured**, con il segnale di occupato tolto e l'utente non avvisato.

## Chosen option

**Ignorare l'errore solo se il collegamento era già pronto**

Il tentativo di preparazione viene ignorato solo quando il collegamento risulta già preparato in questa esecuzione; negli altri casi l'errore porta a **Not configured**, come previsto dal Model. Nessun costo per l'utente: al primo errore il cloud resta spento fino al riavvio successivo.

## Where in the code

lib/core/services/sync_service.dart, metodo initializeSupabase: la chiamata a Supabase.initialize è dentro un catch che registra solo un messaggio di debug.
