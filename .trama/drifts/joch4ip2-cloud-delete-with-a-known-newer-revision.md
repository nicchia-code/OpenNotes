---
status: resolved
resolution: fix-code
refs:
  - realtime-channel/Listening/supabase.REMOTE_NOTE_DELETED
  - requirements/rules#realtime-channel
proposal: null
task: 1yhglvur
origin: null
critical: false
option: 1
note: null
resolvedBy: awa4vyj9
created: 2026-10-17T14:11:11.060Z
---
# Cloud delete with a known newer revision removes the note or folder

## What happens

Quando arriva l'eliminazione di una nota o di una cartella con una revisione più vecchia di quella che il dispositivo ha già, per esempio un'eliminazione che precede un salvataggio che questo dispositivo ha già inviato e il cloud ha accettato, la copia locale viene eliminata lo stesso, purché non ci sia una modifica in attesa più recente. La nota o la cartella sparisce, insieme al suo file nel vault per una nota, finché l'eco della versione più recente non la riporta.

## What should happen

Il Model di Listening dice che, per ogni modifica, se il dispositivo conosce già quella revisione o una successiva non succede nulla. Il Requirement rules#realtime-channel dice che una modifica con revisione minore o uguale a quella nota viene ignorata, senza distinguere tra salvataggi ed eliminazioni. Oggi l'eliminazione viene confrontata solo con la data di modifica.

## Fix options

### Check the delete revision before removing

Prima di eliminare, confrontare la revisione del segnaposto con quella della copia locale: se la copia è già più recente, il segnaposto viene ignorato, come un'eco. Un'eliminazione più recente della versione conosciuta continua a rimuovere la nota o la cartella e a scartare le modifiche in attesa. Il dato serve già per le note e le cartelle, quindi il costo è una lettura in più, senza nuovo storage.

### Keep the time rule and ignore older deletes

Mantenere il confronto per data e ignorare un'eliminazione più vecchia dell'ultimo invio riuscito della stessa nota o cartella, ricordando per ciascuna la data di quell'invio. Non serve la revisione nel segnaposto, ma la regola dipende dagli orologi dei dispositivi e non segue quella del Requirement, che parla di revisioni.

## Where in the code

lib/core/services/sync_service.dart: handleRemoteNoteChange e handleRemoteFolderChange chiamano _removeRemoteNote e _removeRemoteFolder, che confrontano solo updated_at con la coda locale; la revisione del segnaposto non viene letta.
