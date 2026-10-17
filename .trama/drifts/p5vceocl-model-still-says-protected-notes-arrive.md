---
status: resolved
resolution: proposal
refs:
  - note-access/Unprotected
proposal: null
task: null
origin: null
previous: x6qu112b
critical: false
option: null
note: null
resolvedBy: xqdml6er
created: 2026-10-17T11:33:27.831Z
---
# Model still says protected notes arrive from the vault after the fix

## What happens

L'app scrive la copia Markdown di ogni nota nel vault e non rilegge mai quei file: nessuna nota entra nell'app da un file, quindi nessuna nasce protetta per il suo file.

## What should happen

Il Drift x6qu112b ha chiuso la questione togliendo il caso «o dal vault» dallo stato Unprotected del Model dell'accesso, come deciso con il Drift gj6o3a5s; la frase è ancora nel Model e contraddice il Model del vault, che dice che l'app non rilegge mai il vault.

## Fix options

### Remove the vault case from the note

Si toglie «o dal vault» dalla descrizione dello stato Unprotected, come già deciso con il Drift gj6o3a5s. Il codice non cambia. Costo: una frase del Model, nessun effetto per l'utente.

### Read the vault back to set the lock

Si aggiunge la lettura dell'intestazione dei file del vault, così una nota può nascere protetta da un file. Costo: il vault diventa una fonte di dati, contro il Model del vault; la scelta del Drift gj6o3a5s va riaperta e si riscrivono le regole di lettura nei Requirement.

## Where in the code

lib/core/services/vault_service.dart: solo scrittura del file, nessuna lettura
