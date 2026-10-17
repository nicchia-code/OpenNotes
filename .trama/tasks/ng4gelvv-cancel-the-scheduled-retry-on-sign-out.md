---
column: done
technical: false
refs:
  - sync-run/Waiting to retry/supabase.SIGNED_OUT
  - requirements/rules#sync-run
drift: null
proposal: null
agent: false
created: 2026-10-17T12:11:41.868Z
finished: 2026-10-17T12:38:45.669Z
---
# Cancel the scheduled retry on sign-out

Quando l'utente esce dall'account mentre un nuovo tentativo è programmato, il tentativo viene annullato e la sincronizzazione torna in riposo, senza attesa residua né giro fatto partire dal tentativo cancellato; i cambiamenti restano in coda. Oggi il tentativo programmato resta in piedi: al successivo accesso il giro si somma a quello già in attesa, lo stato continua a mostrare l'attesa e la sincronizzazione periodica ritarda.
