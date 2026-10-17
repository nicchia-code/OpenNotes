---
status: resolved
resolution: fix-code
refs:
  - pending-change/Queued
  - requirements/rules#cloud-sync
proposal: null
task: zxgetxa4
origin: null
critical: false
option: 1
note: null
resolvedBy: tqf85in9
created: 2026-10-17T17:21:05.621Z
---
# Folder delete is queued after its row is removed, without its cloud revision

## What happens

Eliminando una cartella che non ha altre modifiche in attesa, l'eliminazione entra in coda dopo che la cartella è già stata tolta dal dispositivo, quindi senza la revisione del cloud su cui si basa. Alla sincronizzazione il cloud risponde con un conflitto e decide il confronto delle ore: se l'ultima modifica del cloud non è strettamente anteriore all'eliminazione, l'eliminazione viene scartata e la cartella torna. Succede, per esempio, se un altro dispositivo ha l'orologio avanti.

## What should happen

Ogni elemento in coda registra la revisione del cloud su cui si basa, vuota solo se il dispositivo non ha mai visto la riga. L'eliminazione di una cartella già sincronizzata deve quindi partire da quella revisione, e il cloud non deve scartarla per l'ora di una modifica che il dispositivo aveva già visto.

## Fix options

### Queue the delete while the folder row still exists

L'eliminazione viene accodata prima di togliere la riga della cartella, così prende la revisione registrata. Il resto del percorso non cambia: le note spostate restano accodate come ora. Costo: lo spostamento di una chiamata in un solo punto, più un test sul caso di cartella senza modifiche in attesa.

### Pass the seen revision with the delete

Prima di togliere la cartella il dispositivo legge la revisione registrata e la passa esplicitamente alla coda per l'eliminazione. Costo: un parametro in più nella chiamata di accodamento, usato solo dalle eliminazioni di cartelle, e un controllo che la revisione non sia vuota quando la cartella era sincronizzata.

## Where in the code

lib/core/state/notes_provider.dart: deleteFolder (la cartella viene tolta prima dell'accodamento della sua eliminazione); lib/core/services/sync_service.dart: notifyFolderChanged; lib/core/services/database_service.dart: queueSyncAction (revisione di base presa dalla riga della cartella).
