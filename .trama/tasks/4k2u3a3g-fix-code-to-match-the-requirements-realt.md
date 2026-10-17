---
column: done
technical: false
refs:
  - realtime-channel/Listening
  - requirements/rules#realtime-channel
drift: null
proposal: null
agent: false
created: 2026-10-17T18:13:51.699Z
finished: 2026-10-17T19:52:04.777Z
---
# Fix code to match the Requirements: Realtime change failures are not written to the app log

Quando una modifica ricevuta dal canale in tempo reale non si riesce ad applicare sul dispositivo, il dettaglio tecnico dell'errore va annotato nel registro dell'app, come gli altri errori di sincronizzazione; oggi finisce solo nei messaggi di debug, che l'utente non può leggere. Restano come sono il giro incrementale che parte subito dopo e il proseguimento delle modifiche successive nella coda. Il Task usa il registro dell'app che introducono i Task sul registro dei fallimenti di sincronizzazione (vg7f9a0g e sgc92gr1).
