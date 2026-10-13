---
status: resolved
resolution: fix-code
refs:
  - vault-file/Orphaned
proposal: null
task: sj2x1u9x
origin: null
critical: false
option: 1
note: null
resolvedBy: 3pikg137
created: 2026-10-12T07:25:39.705Z
---
# Vault file: a title returning to an orphaned file name overwrites it

## What happens

Quando il titolo di una nota cambia, la sua vecchia copia nel vault resta com'è e diventa orfana. Se in seguito il titolo torna al nome di quella copia, l'app riscrive il file orfano con il contenuto attuale della nota, che quindi torna a essere aggiornato.

## What should happen

Il modello dice che una copia orfana è definitiva: non corrisponde più a nessuna versione futura della nota e non viene più aggiornata. Dice però anche che una nota che ottiene il nome di un file esistente lo sovrascrive. Non è chiaro se il ritorno della nota al proprio vecchio nome conti come una nota nuova, cioè come una sovrascrittura, o se il file orfano debba restare intatto.

## Fix options

### Il ritorno riprende il file orfano

La nota che torna al vecchio titolo riscrive la copia orfana, come oggi. Il modello va chiarito: una copia orfana può tornare attiva se la nota riprende quel nome. Nessun costo nel codice; la copia precedente viene persa, ma è sempre la stessa nota.

### Il file orfano non si tocca mai

Quando il nome è già occupato da una copia orfana, la nota scrive un file con un nome diverso, per esempio con un numero in coda. Le copie orfane restano intatte per sempre. Costa: il nome del file non dipende più solo dal titolo, quindi va cambiata anche la regola sul nome del file del vault.

## Where in the code

lib/core/services/vault_service.dart, metodo saveNote; chiamato da lib/core/state/notes_provider.dart a ogni salvataggio.
