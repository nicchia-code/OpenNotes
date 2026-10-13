---
status: resolved
resolution: fix-code
refs:
  - sync-run/Pushing changes
proposal: null
task: i6nq1132
origin: null
critical: false
option: 1
note: null
resolvedBy: g08cr3wn
created: 2026-10-12T14:51:27.095Z
---
# A note renamed to a welcome title still sends its earlier queued save

## What happens

Una nota nuova, non ancora partita verso il cloud (per esempio perché nessun utente era connesso), entra in coda con il suo titolo di partenza. Se poi l'utente le dà il titolo esatto di una nota di benvenuto, quel salvataggio non entra in coda, come previsto. Alla sincronizzazione però parte il salvataggio già accodato: la nota viene inviata con il vecchio titolo e il vecchio testo e risulta sincronizzata, anche se il cloud ha già altre note. La versione con il titolo di benvenuto arriva al cloud solo alla modifica successiva.

## What should happen

Il Model dice che una nota di benvenuto mai sincronizzata non entra in coda quando viene salvata, e che alla sincronizzazione viene eliminata invece che inviata, se il cloud ha almeno una nota. Non dice cosa succede a un salvataggio già in coda quando la nota prende quel titolo. Così la regola delle note di benvenuto può essere aggirata senza che l'utente lo sappia, e il cloud conserva una versione non più attuale della nota.

## Fix options

### Lasciare la decisione alla sincronizzazione (recommended)

Il salvataggio in coda di una nota mai sincronizzata che ha un titolo di benvenuto non viene inviato. Alla sincronizzazione la nota viene eliminata se il cloud ha già note, altrimenti viene inviata con il testo attuale. Il Model aggiunge una frase alla coda. Costo: una piccola modifica al passo di invio della coda; il cloud non riceve mai una versione intermedia della nota.

### Inviare il testo attuale subito

Quando la nota prende un titolo di benvenuto, il salvataggio in coda viene aggiornato con il testo corrente, così alla sincronizzazione arriva la versione attuale. Costo: la nota arriva al cloud anche quando il cloud ha già altre note, quindi la regola di eliminazione delle note di benvenuto non vale più per queste note. Il Model non cambia.

### Tenere com'è

Nessun lavoro nel codice. Il cloud riceve la versione di prima del titolo di benvenuto, e la versione attuale arriverà solo alla modifica successiva. Costo: gli altri dispositivi mostrano un titolo e un testo non più attuali, senza alcun avviso, finché la nota non viene modificata di nuovo.

## Where in the code

lib/core/services/sync_service.dart: notifyNoteChanged (salvataggi di note di benvenuto) e syncNow, primo passo (invio della coda)
