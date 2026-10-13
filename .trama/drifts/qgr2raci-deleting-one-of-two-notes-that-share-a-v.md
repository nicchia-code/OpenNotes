---
status: resolved
resolution: fix-code
refs:
  - vault-file/Written/note.PERMANENTLY_DELETED
proposal: null
task: asg9mk7q
origin: null
critical: false
option: 1
note: null
resolvedBy: 3tg049lq
created: 2026-10-12T14:15:14.655Z
---
# Deleting one of two notes that share a vault file leaves the deleted note's text in the file

## What happens

Quando una di due note che condividono lo stesso file del vault viene eliminata definitivamente, il file non viene cancellato e resta com'è. Contiene l'ultimo salvataggio, che può essere quello della nota eliminata: il testo di una nota eliminata definitivamente resta nel vault, sotto il nome dell'altra nota, finché questa non viene salvata di nuovo.

L'altra nota resta nell'elenco, ma la sua copia nel vault non è la sua.

## What should happen

Il Model dice che, quando il file non viene cancellato, resta la copia della nota che rimane sul dispositivo. Il requisito sulla cancellazione dice che il file si toglie solo se nessun'altra nota lo usa. Il testo della nota eliminata non dovrebbe quindi restare nel vault: la copia deve essere quella della nota viva.

## Fix options

### Riscrivere il file con la nota che resta

Quando il file resta perché un'altra nota lo usa, la cancellazione lo riscrive con il testo attuale della nota che resta sul dispositivo. Nel vault non resta alcun testo di note eliminate e la copia è sempre quella di una nota viva. Costo: una scrittura in più a ogni cancellazione di una nota condivisa; se restano più note che usano il file, va scelto quale copia tenere (per esempio la più recente) e la regola va scritta nel Model.

### Lasciare il file com'è, e descriverlo nel Model

Il file resta com'è anche dopo la cancellazione e il Model dice che può contenere il testo della nota eliminata, fino al prossimo salvataggio dell'altra nota. Nessuna scrittura in più. Costo: il testo di una nota eliminata definitivamente resta nel vault, in contrasto con l'idea di eliminazione definitiva, e l'altra nota non ha la sua copia finché non viene salvata.

## Where in the code

lib/core/state/notes_provider.dart (_purgeNotes); lib/core/services/vault_service.dart (deleteNoteFileIfUnused)
