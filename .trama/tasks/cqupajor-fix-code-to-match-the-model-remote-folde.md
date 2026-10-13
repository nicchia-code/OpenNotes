---
column: done
technical: false
refs:
  - folder/User folder/supabase.REMOTE_FOLDER_DELETED
drift: nh24mh69
proposal: null
agent: false
created: 2026-10-13T12:30:31.832Z
finished: 2026-10-13T12:33:07.412Z
---
# Fix code to match the Model: Remote folder deletion moves the open folder view to All notes

## What happens

Quando una cartella viene eliminata su un altro dispositivo, la modifica arriva dal cloud e la cartella sparisce qui: le sue note passano in «Note», come previsto. Se però la cartella era aperta nella barra laterale o nella schermata Cartelle, la vista non resta su di essa: si apre «Tutte le note». Per le eliminazioni fatte su questo dispositivo la vista che si sposta su «Tutte le note» è corretta, come dice il Model.

## What should happen

Il Model della cartella dice che l'eliminazione ricevuta dal cloud non emette DELETED, quindi una vista aperta su quella cartella resta su di essa. La vista delle note passa a «Tutte le note» solo dopo un'eliminazione fatta sul dispositivo, perché solo folder.DELETED la porta lì. Il codice non distingue le due origini, quindi non segue il Model in questo caso.

## Chosen option

**Mantenere la vista sulla cartella eliminata**

La vista resta selezionata sulla cartella eliminata e mostra un elenco vuoto, con le note già spostate in «Note». Serve distinguere l'eliminazione ricevuta dal cloud da quella fatta qui, nel ricaricamento delle cartelle, e non cambiare la selezione in quel caso. Costo: l'elenco resta vuoto finché l'utente non sceglie un'altra vista; nessuna modifica al Model.

## Where in the code

lib/core/state/notes_provider.dart (refreshFolders, selezione della vista); lib/core/services/sync_service.dart (handleRemoteFolderChange, ramo di eliminazione)
