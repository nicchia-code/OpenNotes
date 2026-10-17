---
column: done
technical: true
refs:
  - requirements/ui#sync-run
drift: fwx4riy5
proposal: null
agent: false
created: 2026-10-17T18:38:45.607Z
finished: 2026-10-17T19:10:38.262Z
---
# Fix code to match the Requirements: Accesso a Google irraggiungibile su desktop senza ingranaggio

## What happens

Sulla barra laterale desktop l'ingranaggio viene tolto e l'indicatore compare solo con un utente connesso. Chi non ha ancora effettuato l'accesso non vede più nessun comando per aprire la finestra del cloud, e quindi non può accedere con Google né avviare la sincronizzazione.

## What should happen

Il Requirement dice che l'indicatore prende il posto dell'ingranaggio, ma che non compare senza utente connesso. Le due cose insieme lasciano il desktop senza un punto d'accesso per l'accesso, che la finestra del cloud gestisce. Il Model non dice come si accede senza utente connesso.

## Chosen option

**Voce «Accedi» nella barra laterale**

Quando nessun utente è connesso compare nella barra laterale un comando testuale «Accedi», che apre la stessa finestra delle impostazioni del cloud. Con un utente connesso resta solo l'indicatore di stato. Costo: un elemento in più nella barra laterale, visibile finché non si accede.

## Where in the code

lib/ui/sidebar/sidebar_view.dart; lib/ui/sync/sync_status_indicator.dart
