---
column: done
technical: false
refs:
  - vault-file/Written
  - requirements/rules#vault-file
drift: 79zmy0bw
proposal: null
agent: false
created: 2026-10-12T08:09:28.360Z
finished: 2026-10-12T08:12:03.488Z
---
# Fix code to match the Model: Vault file: a renamed note leaves its old copy in the vault

## What happens

Quando il titolo di una nota cambia, l'app scrive la nota in un nuovo file con il nuovo nome e lascia il vecchio file com'è, fermo all'ultimo salvataggio. Dopo più cambi di titolo il vault contiene più copie della stessa nota, tutte tranne l'ultima ferme. Anche eliminando la nota definitivamente la copia resta nel vault, perché l'app non ricorda dove l'ha scritta.

## What should happen

Il Modello descrive questo comportamento come **Orphaned**: la copia vecchia resta nel vault e non viene più aggiornata, e oggi la copia non viene mai rimossa. Non dice però se è la regola voluta o un limite da correggere. Il requisito sul nome del file dice che la posizione non viene memorizzata, mentre il requisito dei dati prevede un percorso del file facoltativo nella nota, e il compito in coda «Keep and remove the Markdown file of each note» chiede un solo file per nota, rimosso alla cancellazione. Questi documenti non sono coerenti tra loro.

## Chosen option

**Il file segue il titolo**

Il cambio di titolo scrive la nota nel nuovo file e rimuove quello vecchio: nel vault c'è un solo file per nota, che resta allineato alla nota, e la cancellazione definitiva lo rimuove. Costa: l'app deve ricordare dove ha scritto ogni nota, la regola sulla posizione del file va cambiata, e le copie orfane già lasciate dai cambi precedenti restano dove sono.

## Where in the code

lib/core/services/vault_service.dart, metodo saveNote, che calcola il nome del file dal titolo a ogni salvataggio; chiamato da lib/core/state/notes_provider.dart e lib/core/services/sync_service.dart.
