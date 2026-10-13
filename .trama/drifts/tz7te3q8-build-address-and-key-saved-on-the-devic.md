---
status: resolved
resolution: fix-code
refs:
  - cloud-connection/Configuring
  - requirements/rules#cloud-connection
proposal: null
task: ych9w31f
origin: null
critical: false
option: 1
note: null
resolvedBy: psazi867
created: 2026-10-12T16:47:02.048Z
---
# Build address and key saved on the device override a rebuilt app

## What happens

Al primo avvio il collegamento usa l'indirizzo e la chiave predefiniti della build e li salva sul dispositivo. Dopo, l'app resta su quei valori salvati anche se viene ricompilata con altri valori di build: un nuovo progetto non arriva agli installati, che continuano a usare il progetto di prima.

## What should happen

Il Model dice che il collegamento, quando è pronto, salva indirizzo e chiave sul dispositivo, anche quando vengono dai valori predefiniti. Il Requirement dice che i valori salvati hanno precedenza su quelli predefiniti della build. Le impostazioni cloud non permettono di cambiarli. La decisione già presa dice che chi vuole un altro progetto deve ricompilare l'app con i valori di build: questo non vale per chi ha già avviato l'app. Serve decidere se i predefiniti devono cambiare il progetto degli installati, oppure se il progetto resta fisso per installazione.

## Fix options

### Keep the build defaults in control

Il collegamento smette di salvare i valori predefiniti: resta sempre quello della build installata, così ricompilare con altri valori cambia il progetto anche sugli installati. Costo: il Model e il Requirement cambiano nel salvataggio; i valori già salvati sugli installati vanno tolti o ignorati, e serve una regola per farlo.

### Fix the project per installation

Si scrive nel Model e nel Requirement che indirizzo e chiave, una volta salvati, restano per l'installazione anche dopo una nuova build: cambiare progetto richiede di reinstallare l'app o cancellarne i dati. Costo: nessun lavoro nel codice; chi ricompila con altri valori non cambia progetto sugli installati, e la regola va detta agli sviluppatori.

## Where in the code

lib/core/services/sync_service.dart: init legge i valori salvati prima dei predefiniti; initializeSupabase salva anche i valori predefiniti.
