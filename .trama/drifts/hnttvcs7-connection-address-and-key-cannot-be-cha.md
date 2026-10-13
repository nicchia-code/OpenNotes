---
status: resolved
resolution: fix-code
refs:
  - cloud-connection
  - requirements/tech#General
proposal: null
task: 3izhvbvx
origin: null
critical: false
option: 1
note: null
resolvedBy: p136jufl
created: 2026-10-12T07:59:53.760Z
---
# Connection address and key cannot be changed by the user

## What happens

L'app prepara il collegamento al progetto cloud con l'indirizzo e la chiave salvati o, in loro assenza, con quelli predefiniti della build, ma non offre nessuna schermata per cambiarli. Le impostazioni cloud mostrano solo accesso e sincronizzazione, e il collegamento resta fisso fino alla chiusura dell'app.

## What should happen

Il modello dice che il collegamento, una volta pronto, **non si può cambiare né rimuovere** dall'app. I requisiti tecnici dicono invece che indirizzo e chiave di default sono **configurabili dall'utente**. Le due affermazioni non possono valere insieme: serve una decisione su quale delle due è giusta.

## Fix options

### Keep the connection fixed in the app

Il collegamento resta com'è nel codice e nel modello: nessuna schermata per cambiarlo. Si toglie dai requisiti tecnici la frase sulla configurazione da parte dell'utente. Costo: nessun lavoro nel codice; chi vuole un altro progetto deve ricompilare l'app con i valori di build.

### Let the user change the connection

Il modello si estende: nelle impostazioni cloud l'utente inserisce indirizzo e chiave, che vengono salvati e preparano di nuovo il collegamento. Costo: nuovi stati e transizioni nel modello, una schermata nuova, e la gestione del cambio di progetto con la sessione e i dati già sincronizzati.

## Where in the code

lib/ui/settings/supabase_settings_dialog.dart; lib/core/services/sync_service.dart
