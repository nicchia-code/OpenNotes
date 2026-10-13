---
column: done
technical: false
refs:
  - requirements/rules#cloud-connection
  - cloud-connection/Not configured/operating-system.APP_LAUNCHED
  - cloud-connection
drift: null
proposal: llyxqjwk
agent: false
created: 2026-10-12T19:46:08.886Z
finished: 2026-10-13T05:11:04.671Z
---
# Fix code to match the Model: launch notice for missing build variables

Quando il lavoro è finito, all'avvio una variabile mancante (non passata, vuota o fatta solo di spazi) lascia il collegamento non configurato e l'app resta usabile in locale, senza preparare il cloud. Compare una sola volta una barra temporanea in basso, con lo stesso stile degli altri messaggi globali, con uno di questi testi: «Cloud non configurato: manca SUPABASE_URL.», «Cloud non configurato: manca SUPABASE_ANON_KEY.», oppure, se mancano entrambe, «Cloud non configurato: mancano SUPABASE_URL e SUPABASE_ANON_KEY.». Con entrambe le variabili presenti la preparazione parte senza barra.
