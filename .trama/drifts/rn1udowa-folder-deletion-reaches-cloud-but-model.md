---
status: resolved
resolution: fix-code
refs:
  - folder/User folder/user.DELETE_FOLDER
proposal: null
task: 807q6q0u
origin: e6ntdqna
critical: false
option: 1
note: null
resolvedBy: 3tg049lq
created: 2026-10-12T14:00:23.923Z
---
# Folder deletion reaches cloud but Model forbids queuing folder changes

## What happens

Il dispositivo elimina la cartella e mette l'eliminazione in coda per il cloud; se un utente è connesso parte una sincronizzazione. Il codice fa già arrivare al cloud l'eliminazione della cartella, come previsto dai Requirement, ma il Model dice che le modifiche alle cartelle non entrano mai in coda e che l'eliminazione non viene messa in coda. La Proposta di risoluzione approvata non ha aggiornato il Model.

## What should happen

Il Model deve dire esplicitamente che l'eliminazione di una cartella arriva al cloud, come eccezione alla regola che le cartelle non entrano mai in coda. Finché il Model non cambia, il codice non può essere allineato a quella regola senza violare il Model, quindi il Task resta bloccato.

## Fix options

### Aggiornare prima il Model, poi il codice

Il Model descrive l'eliminazione di una cartella come eccezione: arriva al cloud, la cartella non ricompare su nessun dispositivo e le note restano in Note, qui e nel cloud. Serve una Proposta di modifica del Model da approvare.

### Eliminazione solo locale

L'eliminazione non entra in coda, come dice il Model. La cartella ricompare dopo ogni sincronizzazione perché il cloud la conserva; va rimosso il comportamento cloud già presente.
