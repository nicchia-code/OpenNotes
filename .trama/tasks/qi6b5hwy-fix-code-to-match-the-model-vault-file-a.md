---
column: done
technical: false
refs:
  - vault-file/Written
  - requirements/rules#vault-file
drift: 6v943fjn
proposal: null
agent: false
created: 2026-10-12T10:59:40.526Z
finished: 2026-10-12T11:02:49.954Z
---
# Fix code to match the Model: Vault file: a renamed note keeps its first file name, against the Model

## What happens

Quando il titolo di una nota cambia, l'app riscrive lo stesso file di prima e non ne crea uno nuovo: il file mantiene il nome del primo salvataggio, anche se non corrisponde più al titolo, e nel vault resta un solo file per nota. Alla cancellazione definitiva il file viene rimosso, perché l'app ricorda dove l'ha scritto. Nel vault non resta nessuna copia ferma.

## What should happen

Il Modello dice che un cambio di titolo scrive una copia nuova con il nome attuale e lascia la vecchia ferma, come **Orphaned**; alla cancellazione definitiva la copia resta nel vault, perché la nota non ricorda il file. Il requisito sul nome dice che il nome si ricalcola dal titolo a ogni scrittura e che la posizione non viene memorizzata. La soluzione approvata in 79zmy0bw («Il file segue il titolo») chiede un altro comportamento, con il vecchio file rimosso al cambio di titolo: il codice non lo fa, e il compito tjltyuy2 risulta concluso comunque. Modello e requisiti non riflettono né il codice né quella decisione.

## Chosen option

**Il file segue il titolo**

Ogni cambio di titolo scrive la nota nel file con il nuovo nome e rimuove quello vecchio. Nel vault c'è un solo file per nota, sempre allineato al titolo, e la cancellazione definitiva lo rimuove. Costa: l'app deve ricordare dove ha scritto ogni nota, il Modello e la regola sul nome vanno riscritti, e le copie già lasciate dai cambi precedenti restano dove sono.

## Where in the code

lib/core/services/vault_service.dart, metodo saveNote (riuso del percorso salvato); lib/core/state/notes_provider.dart e lib/core/services/sync_service.dart, cancellazione con deleteNoteFile.
