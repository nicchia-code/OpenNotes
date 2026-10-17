---
column: done
technical: false
refs:
  - realtime-channel/Listening/supabase.REMOTE_NOTE_DELETED
  - requirements/rules#realtime-channel
drift: joch4ip2
proposal: null
agent: false
created: 2026-10-17T14:48:35.544Z
finished: 2026-10-17T15:40:49.817Z
---
# Fix code to match the Model: Cloud delete with a known newer revision removes the note or folder

## What happens

Quando arriva l'eliminazione di una nota o di una cartella con una revisione più vecchia di quella che il dispositivo ha già, per esempio un'eliminazione che precede un salvataggio che questo dispositivo ha già inviato e il cloud ha accettato, la copia locale viene eliminata lo stesso, purché non ci sia una modifica in attesa più recente. La nota o la cartella sparisce, insieme al suo file nel vault per una nota, finché l'eco della versione più recente non la riporta.

## What should happen

Il Model di Listening dice che, per ogni modifica, se il dispositivo conosce già quella revisione o una successiva non succede nulla. Il Requirement rules#realtime-channel dice che una modifica con revisione minore o uguale a quella nota viene ignorata, senza distinguere tra salvataggi ed eliminazioni. Oggi l'eliminazione viene confrontata solo con la data di modifica.

## Chosen option

**Check the delete revision before removing**

Prima di eliminare, confrontare la revisione del segnaposto con quella della copia locale: se la copia è già più recente, il segnaposto viene ignorato, come un'eco. Un'eliminazione più recente della versione conosciuta continua a rimuovere la nota o la cartella e a scartare le modifiche in attesa. Il dato serve già per le note e le cartelle, quindi il costo è una lettura in più, senza nuovo storage.

## Where in the code

lib/core/services/sync_service.dart: handleRemoteNoteChange e handleRemoteFolderChange chiamano _removeRemoteNote e _removeRemoteFolder, che confrontano solo updated_at con la coda locale; la revisione del segnaposto non viene letta.
