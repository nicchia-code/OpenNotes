---
column: done
technical: false
refs:
  - note-access/Unprotected
  - requirements/data#vault-file
drift: gj6o3a5s
proposal: null
agent: false
created: 2026-10-12T15:18:03.631Z
finished: 2026-10-12T15:19:10.081Z
---
# Fix code to match the Model: Protected vault notes are never read: the app never rereads the vault

## What happens

L'app scrive la copia Markdown di ogni nota nel vault, ma non rilegge mai i file del vault: nessuna nota entra nell'app da un file. Quindi nessuna nota nasce protetta perché il suo file ha il lucchetto.

## What should happen

Il Model della nota dice che le note che arrivano protette dal vault nascono con il lucchetto. Il Model del vault dice invece che l'app non rilegge mai il vault, e i Requirement sulla lettura dei file descrivono un campo di protezione da leggere. Le due descrizioni non possono valere insieme.

## Chosen option

**Togliere il caso del vault dalla nota**

Le note protette arrivano solo dal cloud o restano protette se lo erano sul dispositivo. Il codice non cambia. Costa: si aggiornano la descrizione della nota e i Requirement sulla lettura dei file del vault, che diventano inutili. Nessun dato salvato viene toccato.

## Where in the code

lib/core/services/vault_service.dart: solo scrittura del file, nessuna lettura
