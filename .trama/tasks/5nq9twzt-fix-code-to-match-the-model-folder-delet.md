---
column: done
technical: false
refs:
  - folder/User folder/user.DELETE_FOLDER
drift: iwvrvwxl
proposal: null
agent: false
created: 2026-10-12T17:14:49.779Z
finished: 2026-10-12T17:16:40.403Z
---
# Fix code to match the Model: Folder deletion Model update missing before code change

## What happens

Il dispositivo elimina la cartella e la mette in coda per il cloud, come chiedono i Requirement. La Proposta di risoluzione D (rn1udowa), che doveva aggiornare il Model, non risulta più: non esistono Proposte e il Model dice ancora che le cartelle non entrano mai in coda e che l'eliminazione non vi entra. Finché il Model non cambia, il codice non può essere allineato al Model senza violare i Requirement.

## What should happen

Il Model deve dire esplicitamente che l'eliminazione di una cartella arriva al cloud, come eccezione alla regola che le cartelle non entrano mai in coda, e la cartella non deve ricomparire sui dispositivi. Senza questo cambio il Task non può essere completato.

## Chosen option

**Nuova Proposta di Model, poi codice**

Si prepara una Proposta che descrive l'eliminazione di una cartella come eccezione: arriva al cloud, la cartella non ricompare e le note restano in Note, qui e nel cloud. Dopo l'approvazione si allinea il codice. Costa un nuovo giro di Proposta, perché quella indicata come risolutiva non esiste più.

## Where in the code

Coda di sincronizzazione per le cartelle; eliminazione di una cartella utente
