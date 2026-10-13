---
status: resolved
resolution: fix-code
refs:
  - note/Not yet created/operating-system.APP_LAUNCHED
  - requirements/rules#note
proposal: null
task: 640qp7l2
origin: null
critical: false
option: 1
note: null
resolvedBy: 7lu86lzu
created: 2026-10-13T13:24:44.116Z
---
# Welcome notes are created at launch, before the first sync the Model waits for

## What happens

Al primo avvio, se l'account è connesso e il cloud contiene già delle note, le due note di benvenuto vengono create subito, prima che la sincronizzazione iniziale scarichi le note del cloud. Per tutta la durata della sincronizzazione compaiono nell'elenco, anche quella fissata in alto, e il loro salvataggio viene selezionato; solo dopo la sincronizzazione vengono eliminate. L'app decide quindi se creare le note di benvenuto senza sapere se il cloud ha già delle note.

## What should happen

Secondo il Model, all'avvio le note di benvenuto nascono solo dopo l'eventuale sincronizzazione iniziale, e soltanto se non esiste nessuna nota fuori dal cestino. Se il cloud contiene già delle note, sul dispositivo non deve comparire nessuna nota di benvenuto, nemmeno per un attimo. Anche il Requirement delle regole sulle note chiede che la decisione venga presa dopo la sincronizzazione iniziale.

## Fix options

### Wait for the first sync before deciding

All'avvio, se l'account è connesso, l'app attende la fine della sincronizzazione iniziale, poi controlla se esiste almeno una nota fuori dal cestino e crea le note di benvenuto solo in quel caso. Le note del cloud compaiono senza il passaggio intermedio. Costo: il primo elenco arriva più tardi, di quanto dura la sincronizzazione, e serve un segnale di fine anche quando la sincronizzazione fallisce, altrimenti l'avvio resterebbe in attesa.

### Decide at the end of the first sync, without blocking the list

L'elenco si mostra subito. Se l'account è connesso, la decisione sulle note di benvenuto viene rimandata alla fine della sincronizzazione iniziale, anche quando questa fallisce; senza account resta immediata, come oggi. Costo: per un attimo l'elenco può essere vuoto, e le note di benvenuto compaiono solo dopo il primo tentativo di sincronizzazione.

## Where in the code

lib/main.dart (creazione delle note di benvenuto all'avvio); lib/core/services/sync_service.dart (sincronizzazione iniziale avviata all'accesso)
