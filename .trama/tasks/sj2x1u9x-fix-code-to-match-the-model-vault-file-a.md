---
column: done
technical: false
refs:
  - vault-file/Orphaned
drift: n5vedxka
proposal: null
agent: false
created: 2026-10-12T07:38:53.711Z
finished: 2026-10-12T07:52:36.150Z
---
# Fix code to match the Model: Vault file: a title returning to an orphaned file name overwrites it

## What happens

Quando il titolo di una nota cambia, la sua vecchia copia nel vault resta com'è e diventa orfana. Se in seguito il titolo torna al nome di quella copia, l'app riscrive il file orfano con il contenuto attuale della nota, che quindi torna a essere aggiornato.

## What should happen

Il modello dice che una copia orfana è definitiva: non corrisponde più a nessuna versione futura della nota e non viene più aggiornata. Dice però anche che una nota che ottiene il nome di un file esistente lo sovrascrive. Non è chiaro se il ritorno della nota al proprio vecchio nome conti come una nota nuova, cioè come una sovrascrittura, o se il file orfano debba restare intatto.

## Chosen option

**Il ritorno riprende il file orfano**

La nota che torna al vecchio titolo riscrive la copia orfana, come oggi. Il modello va chiarito: una copia orfana può tornare attiva se la nota riprende quel nome. Nessun costo nel codice; la copia precedente viene persa, ma è sempre la stessa nota.

## Where in the code

lib/core/services/vault_service.dart, metodo saveNote; chiamato da lib/core/state/notes_provider.dart a ogni salvataggio.
