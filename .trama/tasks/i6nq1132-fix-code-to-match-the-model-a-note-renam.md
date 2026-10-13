---
column: done
technical: false
refs:
  - sync-run/Pushing changes
drift: hq9t8uit
proposal: null
agent: false
created: 2026-10-12T14:57:05.769Z
finished: 2026-10-12T14:59:12.352Z
---
# Fix code to match the Model: A note renamed to a welcome title still sends its earlier queued save

## What happens

Una nota nuova, non ancora partita verso il cloud (per esempio perché nessun utente era connesso), entra in coda con il suo titolo di partenza. Se poi l'utente le dà il titolo esatto di una nota di benvenuto, quel salvataggio non entra in coda, come previsto. Alla sincronizzazione però parte il salvataggio già accodato: la nota viene inviata con il vecchio titolo e il vecchio testo e risulta sincronizzata, anche se il cloud ha già altre note. La versione con il titolo di benvenuto arriva al cloud solo alla modifica successiva.

## What should happen

Il Model dice che una nota di benvenuto mai sincronizzata non entra in coda quando viene salvata, e che alla sincronizzazione viene eliminata invece che inviata, se il cloud ha almeno una nota. Non dice cosa succede a un salvataggio già in coda quando la nota prende quel titolo. Così la regola delle note di benvenuto può essere aggirata senza che l'utente lo sappia, e il cloud conserva una versione non più attuale della nota.

## Chosen option

**Lasciare la decisione alla sincronizzazione (recommended)**

Il salvataggio in coda di una nota mai sincronizzata che ha un titolo di benvenuto non viene inviato. Alla sincronizzazione la nota viene eliminata se il cloud ha già note, altrimenti viene inviata con il testo attuale. Il Model aggiunge una frase alla coda. Costo: una piccola modifica al passo di invio della coda; il cloud non riceve mai una versione intermedia della nota.

## Where in the code

lib/core/services/sync_service.dart: notifyNoteChanged (salvataggi di note di benvenuto) e syncNow, primo passo (invio della coda)
