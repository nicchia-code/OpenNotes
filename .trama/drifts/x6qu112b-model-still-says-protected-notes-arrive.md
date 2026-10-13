---
status: resolved
resolution: fix-code
refs:
  - note-access/Unprotected
proposal: null
task: zenxdbff
origin: null
critical: false
option: 1
note: null
resolvedBy: 37m9hzhb
created: 2026-10-13T05:23:12.212Z
---
# Model still says protected notes arrive from the vault, which the app never reads

## What happens

L'app scrive la copia Markdown di ogni nota nel vault e non rilegge mai quei file: nessuna nota entra nell'app da un file, quindi nessuna nasce protetta per il suo file. Il Model dell'accesso dice però che le note che arrivano protette dal vault nascono con il lucchetto. Il Drift gj6o3a5s, chiuso, ha deciso di togliere questo caso, ma la frase è rimasta nel Model.

## What should happen

Lo stato Unprotected del Model dell'accesso dovrebbe descrivere solo le note protette che arrivano dalla sincronizzazione o che erano già protette sul dispositivo, come deciso nel Drift gj6o3a5s. Il Model del vault dice che l'app non rilegge mai il vault, e le due descrizioni non possono valere insieme.

## Fix options

### Remove the vault case from the note (recommended)

Si toglie «o dal vault» dalla descrizione dello stato Unprotected, come già deciso con il Drift gj6o3a5s. Il codice non cambia. Costo: una frase del Model, nessun effetto per l'utente.

### Read the vault back to set the lock

Si aggiunge la lettura dell'intestazione dei file del vault, così una nota può nascere protetta da un file. Costo: il vault diventa una fonte di dati, contro il Model del vault, e la scelta del Drift gj6o3a5s va riaperta; si riscrivono anche le regole di lettura nei Requirement.

## Where in the code

lib/core/services/vault_service.dart (solo scrittura del file, nessuna lettura)
