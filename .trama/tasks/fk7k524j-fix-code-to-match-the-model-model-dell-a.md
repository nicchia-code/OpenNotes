---
column: done
technical: false
refs:
  - note-access/Locked
  - note-access/Unlocked for session
  - requirements/data#note-access
drift: nqsf733q
proposal: null
agent: false
created: 2026-10-12T18:00:24.486Z
finished: 2026-10-12T18:06:52.116Z
---
# Fix code to match the Model: Model dell'accesso senza uscite per il lucchetto arrivato dal cloud

## What happens

Quando la versione di una nota arriva dal cloud, la copia sul dispositivo prende anche il suo lucchetto: una nota protetta altrove si nasconde qui, una sbloccata altrove si mostra senza PIN. Una nota protetta nascosta riceve la versione remota come una nota aperta. Il codice segue il cloud.

## What should happen

Il Model dell'accesso descrive il lucchetto solo quando l'utente lo mette o lo toglie su questo dispositivo, con il PIN. Non ha nessuna uscita per la versione arrivata dal cloud, né per una nota protetta nascosta. Le Drift ku8jqosx e dq6kgy0j hanno deciso che il lucchetto segue il cloud, ma il Model dell'accesso non è stato aggiornato.

## Chosen option

**Scrivere nel Model le uscite per la versione remota: il lucchetto segue il cloud**

Il Model dell'accesso riceve la versione remota con e senza sblocco di sessione, come deciso su ku8jqosx e dq6kgy0j. Il codice resta uguale. Chi toglie il lucchetto da un dispositivo lo toglie anche dagli altri, senza PIN. Costo: poche righe di Model.

## Where in the code

lib/core/services/sync_service.dart (applyRemoteNote); lib/ui/editor/notion_document_editor.dart (segnaposto della nota protetta)
