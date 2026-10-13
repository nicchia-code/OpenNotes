---
column: done
technical: false
refs:
  - folder/User folder/user.DELETE_FOLDER
drift: is06ydqb
proposal: null
agent: false
created: 2026-10-12T11:53:12.036Z
finished: 2026-10-12T13:56:00.244Z
---
# Fix code to match the Model: Folder deletion queues the folder delete for the cloud against Model and Requirement

## What happens

Eliminando una cartella, il dispositivo accoda anche l'eliminazione della cartella stessa, che alla sincronizzazione successiva viene cancellata dal cloud. Le note spostate in «Note» restano fuori dalla coda, come dice il Model.

## What should happen

Il Model della cartella dice che l'eliminazione non viene messa in coda per il cloud, e il Model dei cambiamenti in attesa dice che nascono solo da salvataggi o eliminazioni di note. Il Requirement dice che le modifiche alle cartelle non entrano mai nella coda di sincronizzazione. Il codice fa il contrario da quando la correzione dei cambiamenti di cartella ha accodato creazione, rinomina ed eliminazione, senza aggiornare il Model. Non accodare l'eliminazione, però, non è possibile: il cloud conserverebbe la cartella e la sincronizzazione successiva la riporterebbe sul dispositivo.

## Chosen option

**Riscrivere Model e Requirement**

Il Model della cartella, il Model dei cambiamenti in attesa e il Requirement dicono che le cartelle entrano nella coda insieme alle note, quindi creazione, rinomina ed eliminazione vengono inviate alla sincronizzazione successiva. Il codice resta com'è. Costa una Proposal di Model e la riscrittura del Requirement.

## Where in the code

lib/core/state/notes_provider.dart (deleteFolder); lib/core/services/sync_service.dart (notifyFolderChanged, syncNow: ramo delle cartelle)
