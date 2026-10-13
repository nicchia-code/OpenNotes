---
status: resolved
resolution: fix-code
refs:
  - note-access/Protected
  - requirements/data#note-access
proposal: null
task: ky20vut6
origin: null
critical: false
option: 1
note: null
resolvedBy: psazi867
created: 2026-10-12T16:47:47.539Z
---
# Lock state from another device: the Model does not say what the note does

## What happens

Quando la versione di una nota arriva dal cloud, la copia sul dispositivo prende anche il suo stato di protezione. Se l'altro dispositivo ha protetto la nota, qui il suo contenuto compare nascosto, con l'avviso e il pulsante «Visualizza nota», anche se nessuno ha inserito il PIN qui. Se l'altro dispositivo le ha tolto il lucchetto, qui il contenuto torna visibile senza chiedere il PIN. Il dispositivo non chiede nulla e non segnala il cambio.

## What should happen

Il Modello dell'accesso alla nota descrive il lucchetto solo quando l'utente lo mette o lo toglie su questo dispositivo, con il PIN. Non dice cosa succede quando lo stato di protezione cambia per una versione arrivata dal cloud. Il Modello delle note dice solo che la versione del cloud sostituisce quella locale, senza dire come cambia ciò che l'utente vede. Il Requisito dice che il cloud conserva il lucchetto come campo della nota, ma non dice se seguirlo.

## Fix options

### Seguire il lucchetto del cloud e scriverlo nel Modello

La protezione arriva con la versione del cloud, come oggi: una nota protetta altrove si nasconde anche qui, e una nota sbloccata altrove si mostra senza PIN. Il Modello dell'accesso riceve le uscite per la versione remota, con e senza sblocco di sessione. Costo: poche righe di Modello, nessun cambiamento nel codice. Chi toglie il lucchetto da un dispositivo lo toglie anche dagli altri, senza PIN.

### Chiedere il PIN quando il cloud toglie il lucchetto

Se la versione del cloud toglie il lucchetto, la nota resta protetta qui finché l'utente non inserisce il PIN principale; se la versione del cloud lo mette, la nota si nasconde come oggi. Costo: un nuovo stato nel Modello per la nota in attesa del PIN, e una richiesta del PIN dopo la sincronizzazione. Va deciso cosa succede se l'utente annulla la richiesta.

### Tenere il lucchetto locale e ignorare quello del cloud

Il lucchetto resta quello del dispositivo: la versione del cloud porta il contenuto ma non lo stato di protezione. Costo: la protezione non si sincronizza, e una nota protetta altrove appare aperta qui. Il Requisito sul campo del cloud va cambiato, e il Modello delle note va spiegato.

## Where in the code

lib/core/services/sync_service.dart: applyRemoteNote, che sostituisce la nota locale con quella del cloud, lucchetto compreso; lib/ui/editor/notion_document_editor.dart: segnaposto della nota protetta, che segue solo lo stato della nota.
