---
status: resolved
resolution: proposal
refs:
  - folder
  - sync-run
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: famz2y49
created: 2026-10-18T18:28:13.015Z
---
# Folder the cloud no longer has ignores a newer queued change

## What happens

Quando l'invio di una cartella trova che il cloud non ha più la sua riga (ramo _Gone di _sendQueuedFolder), il codice rimuove la cartella chiamando la rimozione senza un tempo di eliminazione: la regola che tiene la cartella quando una modifica in coda è più recente dell'eliminazione non si applica. Il Model dice invece che la rimozione scaricata vale "alle stesse condizioni dell'eliminazione ricevuta in tempo reale", dove la modifica in attesa più recente la fa restare e rinascere sul cloud.

## What should happen

Quando il cloud non ha più una cartella che il dispositivo aveva inviato, il comportamento deve coincidere con quello dell'eliminazione ricevuta in tempo reale, oppure il Model deve dire che in questo caso la rimozione vince sempre. Oggi il Model e il codice non dicono la stessa cosa.

## Fix options

### Usare l'ultima versione conosciuta come tempo

Nel ramo di rimozione si usa come tempo dell'eliminazione l'ultima versione che il dispositivo ha inviato o ricevuto della cartella. Così la modifica in coda più recente la tiene e il prossimo invio la reinvia al cloud, che la ricrea. Non serve un tempo dal cloud, perché la riga non esiste più.

### Il cloud vince sempre

Il Model dichiara che una cartella che il cloud non ha più viene rimossa sempre, anche con una modifica in coda più recente, e la modifica in attesa viene scartata. Il codice resta com'è. È la regola più semplice, ma va scritta nel Model perché oggi non lo dice.

### La modifica in coda ricrea la cartella

Il Model dichiara che una cartella assente dal cloud, con una modifica in coda, viene ricreata dal dispositivo con quella modifica, senza confrontare i tempi. Il codice va cambiato per tenere la cartella e reinviarla come nuova. È coerente con la regola di rinascita, ma cambia la regola per questo caso.

## Where in the code

lib/core/services/sync_service.dart: _sendQueuedFolder (ramo _Gone), _removeRemoteFolder (nessun tempo di eliminazione), _hasNewerQueuedFolderChange
