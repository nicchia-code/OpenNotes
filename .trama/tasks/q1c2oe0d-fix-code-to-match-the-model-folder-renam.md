---
column: done
technical: false
refs:
  - folder/User folder/user.DELETE_FOLDER
drift: 4i67nuae
proposal: null
agent: false
created: 2026-10-12T15:18:03.654Z
finished: 2026-10-12T15:19:09.192Z
---
# Fix code to match the Model: Folder renamed offline then deleted comes back after sync

## What happens

Se una cartella viene rinominata senza connessione e poi eliminata prima della sincronizzazione, alla sincronizzazione la rinomina parte per prima e aggiorna la cartella nel cloud. Il cloud risulta così cambiato dopo l'eliminazione: l'eliminazione viene scartata, la cartella torna con il nuovo nome e le sue note tornano dentro, come se l'eliminazione non ci fosse stata.

## What should happen

Il Model dice che l'eliminazione di una cartella viene scartata se il cloud l'ha modificata dopo l'eliminazione. Non dice cosa succede quando l'unica modifica successiva è la rinomina fatta dallo stesso dispositivo prima dell'eliminazione: con l'ordine dei cambiamenti, l'eliminazione più recente dovrebbe restare.

## Chosen option

**Tolgo dalla coda le modifiche della cartella eliminata**

Quando l'utente elimina una cartella, le creazioni e le rinomine ancora in coda per quella cartella vengono tolte dalla coda. Alla sincronizzazione arriva solo l'eliminazione, che resta. Costa poco: la rinomina fatta offline si perde, ma la cartella è comunque eliminata, e le note restano in «Note» come oggi.

## Where in the code

lib/core/state/notes_provider.dart (deleteFolder); lib/core/services/sync_service.dart (syncNow, ramo delle cartelle)
