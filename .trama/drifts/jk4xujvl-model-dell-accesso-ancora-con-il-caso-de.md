---
status: resolved
resolution: fix-code
refs:
  - note-access/Unprotected
  - requirements/data#vault-file
proposal: null
task: gx5g8vji
origin: null
critical: false
option: 1
note: null
resolvedBy: oasankgu
created: 2026-10-12T17:50:35.113Z
---
# Model dell'accesso ancora con il caso del vault dopo la sua Drift

## What happens

L'app scrive la copia Markdown delle note nel vault ma non le rilegge mai: nessuna nota nasce protetta da un file del vault. Il codice non cambia.

## What should happen

Il Model dell'accesso dice ancora che le note che arrivano protette dal vault nascono con il lucchetto. La Drift gj6o3a5s è stata risolta togliendo questo caso dalla nota, ma la descrizione dello stato Unprotected non è stata aggiornata.

## Fix options

### Togliere il caso del vault dal Model dell'accesso

Lo stato Unprotected descrive solo le note protette arrivate dal cloud o già protette sul dispositivo, come deciso sulla Drift gj6o3a5s. Il codice resta uguale. Costo: una modifica di poche righe nel Model dell'accesso alla nota.

### Far leggere il vault all'app

L'app rilegge i file del vault e le note con il lucchetto nel file nascono protette. Il Model del vault cambia da mai riletto, e serve una regola per i file già presenti. Costo: più lavoro e rischio di sovrascrivere modifiche non ancora sincronizzate.

## Where in the code

lib/core/services/vault_service.dart (solo scrittura, nessuna lettura)
