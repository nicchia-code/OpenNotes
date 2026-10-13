---
column: done
technical: false
refs:
  - note/Not yet created/operating-system.APP_LAUNCHED
  - requirements/rules#note
drift: jo7d22oy
proposal: null
agent: false
created: 2026-10-13T13:34:05.800Z
finished: 2026-10-13T13:38:11.626Z
---
# Fix code to match the Model: Welcome notes are created at launch, before the first sync the Model waits for

## What happens

Al primo avvio, se l'account è connesso e il cloud contiene già delle note, le due note di benvenuto vengono create subito, prima che la sincronizzazione iniziale scarichi le note del cloud. Per tutta la durata della sincronizzazione compaiono nell'elenco, anche quella fissata in alto, e il loro salvataggio viene selezionato; solo dopo la sincronizzazione vengono eliminate. L'app decide quindi se creare le note di benvenuto senza sapere se il cloud ha già delle note.

## What should happen

Secondo il Model, all'avvio le note di benvenuto nascono solo dopo l'eventuale sincronizzazione iniziale, e soltanto se non esiste nessuna nota fuori dal cestino. Se il cloud contiene già delle note, sul dispositivo non deve comparire nessuna nota di benvenuto, nemmeno per un attimo. Anche il Requirement delle regole sulle note chiede che la decisione venga presa dopo la sincronizzazione iniziale.

## Chosen option

**Wait for the first sync before deciding**

All'avvio, se l'account è connesso, l'app attende la fine della sincronizzazione iniziale, poi controlla se esiste almeno una nota fuori dal cestino e crea le note di benvenuto solo in quel caso. Le note del cloud compaiono senza il passaggio intermedio. Costo: il primo elenco arriva più tardi, di quanto dura la sincronizzazione, e serve un segnale di fine anche quando la sincronizzazione fallisce, altrimenti l'avvio resterebbe in attesa.

## Where in the code

lib/main.dart (creazione delle note di benvenuto all'avvio); lib/core/services/sync_service.dart (sincronizzazione iniziale avviata all'accesso)
