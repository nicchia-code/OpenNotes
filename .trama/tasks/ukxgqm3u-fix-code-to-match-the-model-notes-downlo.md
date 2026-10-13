---
column: done
technical: false
refs:
  - sync-run/Pulling
  - requirements/rules#sync-run
drift: s9yln81k
proposal: null
agent: false
created: 2026-10-12T14:20:57.132Z
finished: 2026-10-12T14:24:52.790Z
---
# Fix code to match the Model: Notes downloaded before folders, so notes of new cloud folders land in Notes

## What happens

Il download scarica prima le note e solo dopo le cartelle. Una nota che sta in una cartella che il dispositivo non ha ancora finisce in «Note», anche se la sua cartella esiste nel cloud. Resta lì fino alla sincronizzazione successiva.

## What should happen

Prima ogni cartella del cloud sovrascrive quella locale, poi per ogni nota si decide dove metterla. L'ordine è fisso: le cartelle prima delle note, così ogni nota trova la sua cartella già sul dispositivo.

## Chosen option

**Scaricare prima le cartelle**

Spostare il download delle cartelle prima di quello delle note, come nel Model. Ogni nota trova la sua cartella al primo download, senza passaggi in più. Costo: nessuno di rilievo, è solo un cambio di ordine.

## Where in the code

lib/core/services/sync_service.dart, funzione syncNow, passi di download delle note e delle cartelle, in quest'ordine.
