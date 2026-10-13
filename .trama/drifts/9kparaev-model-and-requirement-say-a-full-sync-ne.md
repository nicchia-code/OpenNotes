---
status: resolved
resolution: fix-code
refs:
  - sync-run/Pulling
  - requirements/rules#sync-run
proposal: null
task: kpu8z8sl
origin: null
critical: false
option: 1
note: null
resolvedBy: 37m9hzhb
created: 2026-10-13T05:24:43.567Z
---
# Model and Requirement say a full sync never removes local folders, the code does

## What happens

Durante la sincronizzazione completa, una cartella che il cloud non ha più e che non ha modifiche in coda viene tolta dal dispositivo. Le sue note passano nella cartella Note, senza essere inviate. Succede anche alle cartelle eliminate nel cloud mentre il dispositivo era offline, quindi senza la notifica in tempo reale.

## What should happen

Il Model del download dice che le note e le cartelle presenti solo sul dispositivo non vengono toccate, e il Requirement dice che il download non elimina mai note o cartelle locali assenti dal cloud. Né l'uno né l'altro descrive la rimozione che il codice fa oggi.

## Fix options

### Keep the removal and write it in the Model and Requirement

La sincronizzazione completa continua a togliere le cartelle che il cloud non ha più, come già fa la notifica in tempo reale, e le loro note passano in Note. Il Model del download e il Requirement vanno riscritti con questa regola. Costo: una cartella eliminata altrove sparisce anche dopo lunghe assenze dalla rete, senza che l'utente la veda prima.

### Stop the removal in the full sync

Le cartelle eliminate nel cloud restano sul dispositivo finché l'utente non le elimina o non arriva la notifica in tempo reale. Il Model e il Requirement restano come sono. Costo: un dispositivo offline può mostrare cartelle che il cloud non ha più, con le note dentro.

## Where in the code

lib/core/services/sync_service.dart, syncNow, passo 4b
