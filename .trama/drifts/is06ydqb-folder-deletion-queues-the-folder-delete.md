---
status: resolved
resolution: fix-code
refs:
  - folder/User folder/user.DELETE_FOLDER
proposal: null
task: fz6fdbib
origin: null
critical: false
option: 1
note: null
resolvedBy: ck9mt4x5
created: 2026-10-12T11:51:36.032Z
---
# Folder deletion queues the folder delete for the cloud against Model and Requirement

## What happens

Eliminando una cartella, il dispositivo accoda anche l'eliminazione della cartella stessa, che alla sincronizzazione successiva viene cancellata dal cloud. Le note spostate in «Note» restano fuori dalla coda, come dice il Model.

## What should happen

Il Model della cartella dice che l'eliminazione non viene messa in coda per il cloud, e il Model dei cambiamenti in attesa dice che nascono solo da salvataggi o eliminazioni di note. Il Requirement dice che le modifiche alle cartelle non entrano mai nella coda di sincronizzazione. Il codice fa il contrario da quando la correzione dei cambiamenti di cartella ha accodato creazione, rinomina ed eliminazione, senza aggiornare il Model. Non accodare l'eliminazione, però, non è possibile: il cloud conserverebbe la cartella e la sincronizzazione successiva la riporterebbe sul dispositivo.

## Fix options

### Riscrivere Model e Requirement

Il Model della cartella, il Model dei cambiamenti in attesa e il Requirement dicono che le cartelle entrano nella coda insieme alle note, quindi creazione, rinomina ed eliminazione vengono inviate alla sincronizzazione successiva. Il codice resta com'è. Costa una Proposal di Model e la riscrittura del Requirement.

### Togliere l'accodamento dell'eliminazione

La cartella viene eliminata solo sul dispositivo e non si accoda nulla. Il cloud però conserva la cartella, quindi alla sincronizzazione successiva torna sul dispositivo con le sue note, contro il Model della sincronizzazione che fa sovrascrivere le cartelle locali da quelle del cloud. Questa opzione non regge senza cambiare anche quel Model.

## Where in the code

lib/core/state/notes_provider.dart (deleteFolder); lib/core/services/sync_service.dart (notifyFolderChanged, syncNow: ramo delle cartelle)
