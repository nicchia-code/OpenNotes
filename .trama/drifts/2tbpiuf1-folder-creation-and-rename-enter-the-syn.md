---
status: resolved
resolution: proposal
refs:
  - folder/New/user.CREATE_FOLDER
  - folder/User folder/user.RENAME_FOLDER
  - requirements/rules#folder
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: ccg944lf
created: 2026-10-12T12:05:35.409Z
---
# Folder creation and rename enter the sync queue, against Model and Requirement

## What happens

Creare o rinominare una cartella sul dispositivo la salva e la mette subito in coda per l'invio al cloud, e parte una sincronizzazione. Così la nuova cartella e il nuovo nome arrivano agli altri dispositivi alla sincronizzazione successiva.

## What should happen

Il Model dice che creare o rinominare una cartella **non** la mette in coda per il cloud. Il Requirement sulle regole di organizzazione dice che le modifiche alle cartelle **non entrano mai** nella coda di sincronizzazione. Quindi, secondo i due documenti, una cartella creata o rinominata non deve partire verso il cloud con le note.

## Fix options

### Accodare creazione e rinomina e riscrivere Model e Requirement

Il comportamento attuale diventa quello voluto: creazione e rinomina vengono inviate alla sincronizzazione successiva e il Model della cartella, la coda e il Requirement delle regole lo dichiarano. Una Proposal di Model e la riscrittura del Requirement. Costo: le cartelle restano coerenti tra i dispositivi, ma la regola "mai in coda" sparisce e va riscritta anche per l'eliminazione, che resta nel Drift qwpmhpqe.

### Tenere creazione e rinomina solo sul dispositivo

Creazione e rinomina non entrano più nella coda: la cartella resta sul dispositivo e non compare sugli altri, come dice il Model oggi. Il ramo di invio delle cartelle diventa inutile per queste due operazioni e va tolto. Costo: una cartella creata o rinominata su un dispositivo non arriva mai sugli altri, a meno di una nuova scelta.

## Where in the code

lib/core/state/notes_provider.dart (createFolder, renameFolder); lib/core/services/sync_service.dart (notifyFolderChanged)
