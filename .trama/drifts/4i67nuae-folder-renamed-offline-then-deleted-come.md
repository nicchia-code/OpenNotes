---
status: resolved
resolution: fix-code
refs:
  - folder/User folder/user.DELETE_FOLDER
proposal: null
task: q1c2oe0d
origin: null
critical: false
option: 1
note: null
resolvedBy: ke2oiwmu
created: 2026-10-12T15:10:18.084Z
---
# Folder renamed offline then deleted comes back after sync

## What happens

Se una cartella viene rinominata senza connessione e poi eliminata prima della sincronizzazione, alla sincronizzazione la rinomina parte per prima e aggiorna la cartella nel cloud. Il cloud risulta così cambiato dopo l'eliminazione: l'eliminazione viene scartata, la cartella torna con il nuovo nome e le sue note tornano dentro, come se l'eliminazione non ci fosse stata.

## What should happen

Il Model dice che l'eliminazione di una cartella viene scartata se il cloud l'ha modificata dopo l'eliminazione. Non dice cosa succede quando l'unica modifica successiva è la rinomina fatta dallo stesso dispositivo prima dell'eliminazione: con l'ordine dei cambiamenti, l'eliminazione più recente dovrebbe restare.

## Fix options

### Tolgo dalla coda le modifiche della cartella eliminata

Quando l'utente elimina una cartella, le creazioni e le rinomine ancora in coda per quella cartella vengono tolte dalla coda. Alla sincronizzazione arriva solo l'eliminazione, che resta. Costa poco: la rinomina fatta offline si perde, ma la cartella è comunque eliminata, e le note restano in «Note» come oggi.

### Confronto l'eliminazione con il cloud prima di questa sincronizzazione

La sincronizzazione legge la data di modifica della cartella nel cloud prima di inviare le modifiche della stessa corsa, e scarta l'eliminazione solo se un altro dispositivo l'ha cambiata dopo. Le modifiche di questo dispositivo non bloccano più l'eliminazione. Costa una lettura in più per cartella e una regola da spiegare nel Model.

### Lascio il comportamento e lo scrivo nel Model

Il Model dice che conta la data di modifica nel cloud al momento della sincronizzazione, anche se la modifica l'ha inviata questo dispositivo. Il codice resta com'è: una cartella eliminata può tornare dopo una rinomina fatta offline. Costa un Model più complesso e un comportamento che l'utente può trovare strano.

## Where in the code

lib/core/state/notes_provider.dart (deleteFolder); lib/core/services/sync_service.dart (syncNow, ramo delle cartelle)
