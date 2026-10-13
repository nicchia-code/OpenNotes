---
column: done
technical: false
refs:
  - requirements/rules#cloud-connection
  - requirements/tech#General
  - cloud-connection
drift: null
proposal: llyxqjwk
agent: false
created: 2026-10-12T19:46:08.251Z
finished: 2026-10-13T05:09:04.079Z
---
# Fix code to match the Model: remove embedded Supabase defaults

Quando il lavoro è finito, l'app non contiene più l'indirizzo né la chiave pubblica del progetto cloud nel codice. Il collegamento al cloud prende entrambi solo dalle variabili di build SUPABASE_URL e SUPABASE_ANON_KEY. Una build che non le passa non prova mai a usare un progetto predefinito, e il valore incorporato di ciascuna viene eliminato insieme a ogni uso che ne dipende.
