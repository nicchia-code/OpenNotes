---
status: resolved
resolution: fix-code
refs:
  - folder/User folder
proposal: null
task: s4r6wug0
origin: km0xwwlt
critical: false
option: 1
note: null
resolvedBy: 37m9hzhb
created: 2026-10-13T05:35:09.981Z
---
# Model does not describe folder delete dropping queued creation or rename

## What happens

Quando l'utente elimina una cartella, il codice toglie dalla coda le sue creazioni e rinomine non ancora inviate e registra solo l'eliminazione. Il Model non lo dice: pending-change dice che i cambiamenti non vengono mai fusi e che gli scarti previsti sono solo quelli della sincronizzazione o del cambio di account; folder descrive solo che l'eliminazione viene messa in coda.

## What should happen

Il Task chiede di aggiornare il Model per descrivere lo scarto delle creazioni e rinomine in coda alla cartella eliminata. Il sub-agent non puo modificare il Model ne i Requirement: la modifica richiede una decisione del developer, da approvare tramite Proposal.

## Fix options

### Approvare un Proposal sul Model

Approvare un Proposal che descrive, in folder e pending-change, l'eliminazione che scarta le creazioni e rinomine in coda della cartella e lo registra come uscita dello stato Queued. Costo: una modifica del Model da approvare e allineare ai Requirement.

### Riportare il codice a conservare la creazione o la rinomina in coda

Modificare il codice perche l'eliminazione non scarti le creazioni o rinomine in coda, mantenendo il Model attuale. Costo: il comportamento implementato cambia e va verificato rispetto al Drift sdkve31p.
