---
column: done
technical: false
refs:
  - note/Deleted
drift: r3gdmwv2
proposal: null
agent: false
created: 2026-10-12T18:23:16.215Z
finished: 2026-10-12T18:29:22.983Z
---
# Fix code to match the Model: Deleted note comes back when a cloud copy arrives before its delete is sent

## What happens

Quando una nota viene eliminata definitivamente sul dispositivo, la cancellazione va in coda per il cloud e la nota esce subito dal dispositivo. Se nel frattempo una sincronizzazione già in corso, oppure una modifica ricevuta in tempo reale, porta la versione della stessa nota ancora presente nel cloud, la nota ricompare sul dispositivo con il suo file nell'archivio Markdown. La cancellazione in coda parte solo alla sincronizzazione successiva, e la nota resta sul dispositivo anche dopo averla inviata.

## What should happen

Secondo il Model lo stato **Eliminata** è finale: non ha transizioni in uscita. Una nota eliminata definitivamente non deve tornare sul dispositivo né nel suo archivio, per nessuna versione ricevuta dal cloud. La sua cancellazione deve arrivare al cloud e la nota deve restare fuori dal dispositivo.

## Chosen option

**Ignorare il cloud per una nota con cancellazione in attesa**

Una versione ricevuta dal cloud non viene applicata a una nota la cui cancellazione è ancora in coda: la nota resta eliminata e la cancellazione parte alla sincronizzazione successiva. Costo: se un altro dispositivo ha modificato la nota dopo l'eliminazione qui, quella modifica non arriva su questo dispositivo, come prevede lo stato finale.

## Where in the code

lib/core/services/sync_service.dart (applyRemoteNote, handleRemoteNoteChange, syncNow); lib/core/state/notes_provider.dart (_purgeNotes)
