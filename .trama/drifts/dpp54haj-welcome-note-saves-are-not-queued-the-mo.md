---
status: resolved
resolution: proposal
refs:
  - pending-change
  - sync-run/Sending unsynced notes
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: ccg944lf
created: 2026-10-12T12:05:48.341Z
---
# Welcome-note saves are not queued, the Model says they are born in the queue

## What happens

Creare la nota di benvenuto e fissarla non crea alcun cambiamento in coda, finché la nota non è mai stata sincronizzata: la nota resta sul dispositivo e la decisione spetta alla sincronizzazione. Anche le modifiche successive a una nota di benvenuto mai sincronizzata non vengono accodate.

## What should happen

Il Model dei cambiamenti in attesa dice che nascono cambiamenti anche dalle note di benvenuto, e il Model della nota descrive i due salvataggi di quella nota come cambiamenti. Nel Drift 6tbds6iq si è scelto di tenere le note di benvenuto fuori dalla coda, e lì si diceva che il Model andava cambiato: il Model non è stato aggiornato.

## Fix options

### Remove welcome notes from the births in the Model

Il Model dei cambiamenti in attesa smette di elencare le note di benvenuto tra le nascite, e il Model della nota dice che i loro salvataggi non accodano nulla. La sincronizzazione decide il destino della nota, come già scritto nel Model della sincronizzazione. Il codice resta com'è. Costa una Proposal di Model; se il cloud ha già note, la nota di benvenuto modificata prima dell'accesso viene scartata insieme alla nota.

### Queue welcome-note saves and skip them when sending

Ogni salvataggio di una nota di benvenuto entra in coda come le altre modifiche. Quando la coda parte, se il cloud ha già almeno una nota, la modifica di benvenuto viene tolta senza invio, come chiede il Requirement sulle note di benvenuto. Costa un controllo sul cloud nel passo della coda, per ogni elemento di benvenuto, e il Model della coda va cambiato per dirlo.

## Where in the code

lib/core/services/sync_service.dart (notifyNoteChanged: ritorno anticipato per le note di benvenuto mai sincronizzate; syncNow: passo delle note mai sincronizzate); lib/core/state/notes_provider.dart (createNote, togglePin); lib/main.dart (creazione delle note di benvenuto)
