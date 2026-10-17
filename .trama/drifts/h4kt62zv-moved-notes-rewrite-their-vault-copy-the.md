---
status: resolved
resolution: proposal
refs:
  - note/Unpinned/folder.DELETED
  - note/Unpinned/supabase.REMOTE_FOLDER_DELETED
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: 4bde0hn9
created: 2026-10-17T19:27:21.880Z
---
# Moved notes rewrite their vault copy, the note Model says they do not

## What happens

Quando una cartella viene eliminata, sul dispositivo o perché l'eliminazione arriva dal cloud, le sue note, anche quelle nel cestino, passano nella cartella Note e la copia di ciascuna nel vault viene riscritta con la cartella nuova. Il Model della nota dice invece che la copia non viene riscritta.

## What should happen

Il Model della nota dice che, quando una cartella viene eliminata, le note passano nella cartella Note senza aggiornare la data di modifica e senza riscrivere il file nell'archivio Markdown. La correzione della Drift w5pmekbh, che ha fatto riscrivere le copie, non è ancora entrata nel Model.

## Fix options

### Keep the rewrite and say it in the Model

Il Model della nota dice che la copia di ogni nota spostata viene riscritta con la cartella nuova, come già fa il codice. Il vault mostra sempre la cartella vera, anche dopo un'eliminazione. Costo: il Model cambia nelle transizioni della nota che seguono un'eliminazione di cartella; la modifica è nella Proposal collegata a questa Drift, da approvare insieme.

### Follow the Model and keep the old folder in the vault

Il codice smette di riscrivere le copie quando una cartella viene eliminata, come dice il Model. Il vault mostra la cartella di prima finché la nota non viene salvata di nuovo. Costo: torna il difetto della Drift w5pmekbh, cioè la copia nel vault con la cartella sbagliata, e la correzione di quella Drift va annullata.

## Where in the code

lib/core/state/notes_provider.dart (deleteFolder); lib/core/services/sync_service.dart (_removeRemoteFolder, _rewriteNotesMovedFrom)
