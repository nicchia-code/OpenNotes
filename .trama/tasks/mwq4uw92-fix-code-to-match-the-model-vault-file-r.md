---
column: done
technical: false
refs:
  - vault-file
  - requirements/data#vault-file
drift: 6smkq5dc
proposal: null
agent: false
created: 2026-10-12T14:57:05.717Z
finished: 2026-10-12T14:58:52.853Z
---
# Fix code to match the Model: Vault file reading rules exist, but the Model says the app never rereads the vault

## What happens

Il sistema scrive la copia Markdown di ogni nota nel vault, ma nel codice c'è anche una lettura di quei file: legge l'intestazione, il titolo, i tag e le date, accetta i nomi di campo alternativi e ignora le intestazioni malformate. Nessun flusso dell'app chiama questa lettura: la usano solo i test. Per l'utente non cambia nulla, ma la lettura resta come codice che nessuno esegue.

## What should happen

Il Model dice che il vault non viene mai riletto dall'app. Il Requirement dei dati per il vault descrive invece in dettaglio come leggere un file: campi alternativi, intestazione malformata, valori mancanti, tag uniti dal corpo. Nessun flusso applica queste regole. Model e Requirement non sono d'accordo su che cosa l'app faccia con il vault, quindi va deciso quale dei due cambiare.

## Chosen option

**Remove the reading rules**

Si tolgono dal Requirement le regole di lettura e il codice di lettura non usato. Il Model resta com'è: l'app scrive il vault e non lo rilegge mai. Nessun cambiamento per l'utente, il codice si accorcia e non restano regole da mantenere. Se un giorno servirà importare, le regole si scriveranno allora.

## Where in the code

lib/core/services/vault_service.dart (parseMarkdownFile, readNote); usato solo da test/vault_test.dart
