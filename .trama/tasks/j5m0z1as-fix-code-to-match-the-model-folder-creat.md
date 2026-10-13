---
column: done
technical: false
refs:
  - pending-change
  - folder/New/user.CREATE_FOLDER
  - folder/User folder/user.RENAME_FOLDER
  - requirements/rules#folder
drift: x583dq3d
proposal: null
agent: false
created: 2026-10-12T13:51:24.582Z
finished: 2026-10-12T16:27:45.507Z
---
# Fix code to match the Model: Folder creation and rename are queued for the cloud, the Model says they are not

## What happens

Creare o rinominare una cartella sul dispositivo la mette in coda, come una nota: alla sincronizzazione successiva la cartella viene inviata al cloud. Se il cloud ha già una cartella con lo stesso identificativo, la modifica viene tolta dalla coda senza essere inviata.

## What should happen

Il Model dice che creazione e rinomina di una cartella non vengono messe in coda per il cloud, e che le modifiche alle cartelle non entrano mai nella coda di sincronizzazione. Il Model dei cambiamenti in attesa fa nascere le modifiche solo dalle note. La scelta del Drift odoeb8h7, cioè accodare anche le cartelle, chiedeva un aggiornamento del Model che non è mai stato fatto.

## Chosen option

**Update the Model so folder changes are queued**

Il Model della cartella, il Model dei cambiamenti in attesa e il Requirement sulle cartelle dicono che creazione e rinomina entrano nella coda insieme alle note, come già scelto. Il codice resta com'è. Costa una Proposal di Model e la riscrittura della regola «le cartelle non entrano mai in coda». Va deciso anche cosa succede quando il cloud ha già la cartella. L'eliminazione resta nel Drift già aperto.

## Note

Una modifica di cartella in coda sovrascrive la cartella del cloud anche se il cloud la ha già: va tolto il controllo che oggi la scarta.

## Where in the code

lib/core/state/notes_provider.dart (createFolder, renameFolder); lib/core/services/sync_service.dart (notifyFolderChanged, ramo delle cartelle in syncNow)
