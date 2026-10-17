---
status: resolved
resolution: proposal
refs:
  - note-access/Locked
  - note-access/Unlocked for session
proposal: null
task: null
origin: null
previous: nqsf733q
critical: false
option: null
note: null
resolvedBy: xqdml6er
created: 2026-10-17T11:33:21.259Z
---
# Model still has no exits for a lock that arrives with a remote version

## What happens

Quando la versione di una nota arriva dal cloud, la copia del dispositivo prende anche il suo lucchetto: una nota protetta altrove si nasconde qui con l'avviso, e una nota sbloccata altrove si mostra senza PIN. Il Model dell'accesso non ha nessuna uscita per questo caso.

## What should happen

Il Task fk7k524j è chiuso chiedendo di scrivere nel Model le uscite per la versione remota, con e senza sblocco di sessione: il Model dell'accesso non le contiene ancora. Il lucchetto segue il cloud, come deciso con i Drift ku8jqosx e dq6kgy0j.

## Fix options

### Keep following the cloud lock and write it in the Model

Il Model dell'accesso riceve le uscite per la versione remota, con e senza sblocco di sessione: una nota protetta altrove si nasconde anche qui, e una nota sbloccata altrove si mostra senza PIN. Costo: poche righe di Model; il codice resta com'è.

### Ask the PIN when the cloud removes the lock

Se la versione del cloud toglie il lucchetto, la nota resta protetta qui finché l'utente non inserisce il PIN; se lo mette, la nota si nasconde come oggi. Costo: un nuovo stato nel Model per la nota in attesa del PIN, e va deciso cosa succede se l'utente annulla la richiesta.

### Keep the local lock and ignore the cloud one

Il lucchetto resta quello del dispositivo: la versione del cloud porta il contenuto ma non lo stato di protezione. Costo: la protezione non si sincronizza, e una nota protetta altrove appare aperta qui; il Requirement sul campo del cloud va cambiato.

## Where in the code

lib/core/services/sync_service.dart, applyRemoteNote: sostituisce la nota locale con quella del cloud, lucchetto compreso
