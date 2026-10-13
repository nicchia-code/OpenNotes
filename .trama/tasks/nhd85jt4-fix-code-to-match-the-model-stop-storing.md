---
column: done
technical: false
refs:
  - requirements/data#cloud-connection
  - requirements/data#General
  - requirements/rules#cloud-connection
  - cloud-connection
drift: null
proposal: llyxqjwk
agent: false
created: 2026-10-12T19:46:08.522Z
finished: 2026-10-13T05:09:14.519Z
---
# Fix code to match the Model: stop storing the Supabase address and key on the device

Quando il lavoro è finito, indirizzo e chiave non vengono più salvati nelle impostazioni del dispositivo né letti da lì: all'avvio il collegamento usa solo le variabili di build. Le impostazioni scritte da versioni precedenti restano sul dispositivo, ignorate, e non vengono né lette né scritte né cancellate. Nel codice non resta alcuna lettura o scrittura di quelle impostazioni.
