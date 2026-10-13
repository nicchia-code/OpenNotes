---
column: done
technical: false
refs:
  - cloud-connection
  - requirements/tech#General
drift: hnttvcs7
proposal: null
agent: false
created: 2026-10-12T08:09:28.318Z
finished: 2026-10-12T08:10:48.962Z
---
# Fix code to match the Model: Connection address and key cannot be changed by the user

## What happens

L'app prepara il collegamento al progetto cloud con l'indirizzo e la chiave salvati o, in loro assenza, con quelli predefiniti della build, ma non offre nessuna schermata per cambiarli. Le impostazioni cloud mostrano solo accesso e sincronizzazione, e il collegamento resta fisso fino alla chiusura dell'app.

## What should happen

Il modello dice che il collegamento, una volta pronto, **non si può cambiare né rimuovere** dall'app. I requisiti tecnici dicono invece che indirizzo e chiave di default sono **configurabili dall'utente**. Le due affermazioni non possono valere insieme: serve una decisione su quale delle due è giusta.

## Chosen option

**Keep the connection fixed in the app**

Il collegamento resta com'è nel codice e nel modello: nessuna schermata per cambiarlo. Si toglie dai requisiti tecnici la frase sulla configurazione da parte dell'utente. Costo: nessun lavoro nel codice; chi vuole un altro progetto deve ricompilare l'app con i valori di build.

## Where in the code

lib/ui/settings/supabase_settings_dialog.dart; lib/core/services/sync_service.dart
