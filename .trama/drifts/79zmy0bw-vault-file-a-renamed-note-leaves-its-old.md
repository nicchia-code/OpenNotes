---
status: resolved
resolution: fix-code
refs:
  - vault-file/Written
  - requirements/rules#vault-file
proposal: null
task: tjltyuy2
origin: null
critical: false
option: 1
note: null
resolvedBy: p136jufl
created: 2026-10-12T08:01:12.962Z
---
# Vault file: a renamed note leaves its old copy in the vault

## What happens

Quando il titolo di una nota cambia, l'app scrive la nota in un nuovo file con il nuovo nome e lascia il vecchio file com'è, fermo all'ultimo salvataggio. Dopo più cambi di titolo il vault contiene più copie della stessa nota, tutte tranne l'ultima ferme. Anche eliminando la nota definitivamente la copia resta nel vault, perché l'app non ricorda dove l'ha scritta.

## What should happen

Il Modello descrive questo comportamento come **Orphaned**: la copia vecchia resta nel vault e non viene più aggiornata, e oggi la copia non viene mai rimossa. Non dice però se è la regola voluta o un limite da correggere. Il requisito sul nome del file dice che la posizione non viene memorizzata, mentre il requisito dei dati prevede un percorso del file facoltativo nella nota, e il compito in coda «Keep and remove the Markdown file of each note» chiede un solo file per nota, rimosso alla cancellazione. Questi documenti non sono coerenti tra loro.

## Fix options

### Il file segue il titolo

Il cambio di titolo scrive la nota nel nuovo file e rimuove quello vecchio: nel vault c'è un solo file per nota, che resta allineato alla nota, e la cancellazione definitiva lo rimuove. Costa: l'app deve ricordare dove ha scritto ogni nota, la regola sulla posizione del file va cambiata, e le copie orfane già lasciate dai cambi precedenti restano dove sono.

### Il file ha un nome fisso

Il nome del file viene scelto alla prima scrittura e non cambia più col titolo: un solo file per nota, senza bisogno di ricordare percorsi nei cambi di titolo. Costa: il nome del file può non corrispondere al titolo attuale, la regola sul nome del file va cambiata, e la cancellazione definitiva deve comunque ricordare il file per rimuoverlo.

### Il vecchio file resta, come nel Modello

Ogni cambio di titolo crea una copia nuova e le vecchie restano per sempre, come descrive il Modello. Costa: il vault accumula copie ferme della stessa nota e la cancellazione non le rimuove mai. Il compito in coda «Keep and remove the Markdown file of each note» va tolto o riscritto.

## Where in the code

lib/core/services/vault_service.dart, metodo saveNote, che calcola il nome del file dal titolo a ogni salvataggio; chiamato da lib/core/state/notes_provider.dart e lib/core/services/sync_service.dart.
