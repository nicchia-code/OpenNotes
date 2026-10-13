---
column: done
technical: false
refs:
  - sync-run/Pushing changes
  - requirements/rules#sync-run
drift: vr7mbwl3
proposal: null
agent: false
created: 2026-10-12T11:27:34.874Z
finished: 2026-10-12T14:01:29.286Z
---
# Fix code to match the Model: Offline deletion of a note removes it from the cloud even when the cloud copy is newer

## What happens

Quando una nota viene eliminata definitivamente sul dispositivo, la cancellazione resta in coda e, alla sincronizzazione, rimuove la nota dal cloud senza controllare nulla. Se nel frattempo un altro dispositivo l'ha modificata, la modifica più recente sparisce dal cloud e il dispositivo non la riceve più. Lo stesso accade per le cartelle eliminate offline.

## What should happen

Il Model dice che per un'eliminazione la nota viene cancellata sul cloud, senza confronti. Il Requirement sulle regole di sincronizzazione dice invece che per le note vince l'ultimo che ha scritto, confrontando le date, e che per le cartelle vince sempre il cloud. Una cancellazione in coda non porta con sé il momento in cui è avvenuta, quindi le due regole non si possono seguire insieme.

## Chosen option

**Let a newer cloud copy survive an offline deletion**

La cancellazione in coda registra il momento in cui è avvenuta. Se il cloud ha una versione più recente, la nota non viene tolta dal cloud e torna sul dispositivo con il download. Così vince l'ultimo che ha scritto, come da Requirement. Costo: una nota eliminata offline può tornare, e la cancellazione va registrata con la sua data.

## Where in the code

lib/core/services/sync_service.dart: syncNow, passo della coda (cancellazione delle note e delle cartelle)
