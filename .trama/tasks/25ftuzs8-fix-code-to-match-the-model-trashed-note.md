---
column: done
technical: false
refs:
  - note/In trash
drift: nesjiteo
proposal: 634nfp49
agent: false
created: 2026-10-17T11:27:24.089Z
finished: 2026-10-17T11:44:44.961Z
---
# Fix code to match the Model: Trashed note deleted in the cloud has no sync outcome

## What happens

Una nota nel cestino, già sincronizzata e che il cloud non ha più, con una modifica ancora in coda: il codice non la rimuove più dal dispositivo, quindi la nota resta nel cestino e la modifica viene inviata al cloud, che la ricrea come nota nel cestino.

## What should happen

Il Model non dice cosa succede a una nota nel cestino quando il cloud non la ha più: lo stato In trash non ha nessuna transizione per la rimozione della sincronizzazione, e la regola di eliminazione scritta per le altre note non è riportata per il cestino. Non si può dedurre se la nota debba restare sul dispositivo, essere eliminata o essere ricreata sul cloud.

## Chosen option

**Lasciare la nota nel cestino senza inviarla**

La nota resta nel cestino con il suo contenuto. La modifica in coda viene scartata senza essere inviata, così il cloud non la ricrea. Il dispositivo tiene una nota che il cloud non ha più, finché l'utente non la ripristina o la elimina a mano; la sincronizzazione successiva non la tocca.

## Where in the code

lib/core/services/sync_service.dart, sincronizzazione della coda delle note
