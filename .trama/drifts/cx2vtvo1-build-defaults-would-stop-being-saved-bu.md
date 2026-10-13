---
status: resolved
resolution: fix-code
refs:
  - cloud-connection/Configuring
proposal: null
task: 50do3tji
origin: ych9w31f
critical: false
option: 1
note: null
resolvedBy: qcyswaks
created: 2026-10-12T17:16:31.852Z
---
# Build defaults would stop being saved, but the Model still requires saving them

## What happens

Il codice attuale fa quello che il Model e il Requirement dicono: al primo avvio il collegamento usa i valori della build e li salva sul dispositivo, e i valori salvati hanno precedenza sulla build. Il Task chiede invece che il collegamento non salvi più i valori della build, così che ricompilare con altri valori cambi il progetto anche sugli installati. Questo contraddice il Model, che dice di salvare indirizzo e chiave anche quando vengono dai valori predefiniti, e il Requirement sulla precedenza dei valori salvati.

## What should happen

Il Model e il Requirement devono cambiare prima del codice: il collegamento non salva più i valori predefiniti, e serve dire cosa succede ai valori già salvati sugli installati (tolti o ignorati). Finché il Model dice il contrario, il Task non può essere implementato come scritto.

## Fix options

### Aggiornare prima Model e Requirement, poi il codice

Si apre una Proposal che cambia il Model del collegamento e il Requirement sulle preferenze: il collegamento non salva più i valori della build, e la regola per i valori già salvati viene scritta esplicitamente. Solo dopo si cambia il codice. Costo: un giro di design in più, ma il Model descrive il comportamento voluto e le ricompilazioni cambiano il progetto anche sugli installati.

### Tenere il Model: valori salvati per installazione

Il Model e il Requirement restano come sono e il codice non cambia: indirizzo e chiave salvati al primo avvio restano anche dopo una nuova build. Per cambiare progetto sugli installati servono reinstallazione o cancellazione dei dati. Costo: nessun lavoro nel codice; chi ricompila con altri valori deve saperlo, e il Task viene chiuso senza modifiche.

## Where in the code

lib/core/services/sync_service.dart: init e initializeSupabase
