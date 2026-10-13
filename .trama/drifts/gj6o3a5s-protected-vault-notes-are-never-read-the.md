---
status: resolved
resolution: fix-code
refs:
  - note-access/Unprotected
  - requirements/data#vault-file
proposal: null
task: xhjsbm28
origin: null
critical: false
option: 1
note: null
resolvedBy: ke2oiwmu
created: 2026-10-12T15:07:39.131Z
---
# Protected vault notes are never read: the app never rereads the vault

## What happens

L'app scrive la copia Markdown di ogni nota nel vault, ma non rilegge mai i file del vault: nessuna nota entra nell'app da un file. Quindi nessuna nota nasce protetta perché il suo file ha il lucchetto.

## What should happen

Il Model della nota dice che le note che arrivano protette dal vault nascono con il lucchetto. Il Model del vault dice invece che l'app non rilegge mai il vault, e i Requirement sulla lettura dei file descrivono un campo di protezione da leggere. Le due descrizioni non possono valere insieme.

## Fix options

### Togliere il caso del vault dalla nota

Le note protette arrivano solo dal cloud o restano protette se lo erano sul dispositivo. Il codice non cambia. Costa: si aggiornano la descrizione della nota e i Requirement sulla lettura dei file del vault, che diventano inutili. Nessun dato salvato viene toccato.

### Far leggere il vault all'app

L'app rilegge i file del vault e le note con il lucchetto nel file arrivano protette. Costa: serve un lettore dei file Markdown, una regola per i file di note già presenti, e il Model del vault va cambiato da mai riletto. Più lavoro e rischio di sovrascrivere modifiche non ancora sincronizzate.

## Where in the code

lib/core/services/vault_service.dart: solo scrittura del file, nessuna lettura
