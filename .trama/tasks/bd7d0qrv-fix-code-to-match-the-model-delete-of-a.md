---
column: done
technical: false
refs:
  - pending-change/Queued
  - requirements/rules#sync-run
drift: dc2dwepj
proposal: null
agent: false
created: 2026-10-12T18:23:16.143Z
finished: 2026-10-12T18:26:37.219Z
---
# Fix code to match the Model: Delete of a note whose save is being sent: code and Model disagree

## What happens

Se una nota viene eliminata definitivamente mentre il suo salvataggio è ancora in invio al cloud, il risultato dipende da com'era la nota nel cloud. Se il cloud non la aveva ancora, l'app la cancella subito dal cloud, nella stessa sincronizzazione. Se il cloud la aveva già, l'eliminazione resta in coda; alla sincronizzazione successiva il salvataggio appena inviato risulta più recente dell'eliminazione, che quindi viene scartata, e la nota torna sul dispositivo con il download.

## What should happen

Il Model dice che un'eliminazione in coda viene scartata se il cloud è stato modificato dopo il momento in cui è entrata in coda, e che la nota torna sul dispositivo. Un salvataggio inviato mentre l'eliminazione è in coda è una modifica successiva, quindi il Model non fa eccezioni per le note nuove nel cloud: la nota deve tornare in entrambi i casi. Il requisito della sincronizzazione dice lo stesso.

## Chosen option

**Delete wins: remove the note from the cloud at once**

Un'eliminazione fatta mentre il salvataggio è in invio vince in entrambi i casi: la nota viene cancellata dal cloud e non torna sul dispositivo. Il Model e il requisito ricevono una regola per questo caso, che oggi è descritto come scarto. Costo: l'utente non rivede una nota che ha eliminato; per le note già nel cloud il codice va cambiato per cancellarle subito, come già fa per le nuove.

## Where in the code

lib/core/services/sync_service.dart, syncNow: ramo dei salvataggi di note in coda, subito dopo l'invio (controllo dell'eliminazione in coda durante il caricamento).
