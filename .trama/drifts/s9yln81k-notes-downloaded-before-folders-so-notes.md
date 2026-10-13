---
status: resolved
resolution: fix-code
refs:
  - sync-run/Pulling
  - requirements/rules#sync-run
proposal: null
task: ukxgqm3u
origin: null
critical: false
option: 1
note: null
resolvedBy: 3tg049lq
created: 2026-10-12T14:16:31.714Z
---
# Notes downloaded before folders, so notes of new cloud folders land in Notes

## What happens

Il download scarica prima le note e solo dopo le cartelle. Una nota che sta in una cartella che il dispositivo non ha ancora finisce in «Note», anche se la sua cartella esiste nel cloud. Resta lì fino alla sincronizzazione successiva.

## What should happen

Prima ogni cartella del cloud sovrascrive quella locale, poi per ogni nota si decide dove metterla. L'ordine è fisso: le cartelle prima delle note, così ogni nota trova la sua cartella già sul dispositivo.

## Fix options

### Scaricare prima le cartelle

Spostare il download delle cartelle prima di quello delle note, come nel Model. Ogni nota trova la sua cartella al primo download, senza passaggi in più. Costo: nessuno di rilievo, è solo un cambio di ordine.

### Cambiare l'ordine nel Model

Mantenere le note prima delle cartelle e riscrivere la descrizione del Model e il Requirement sull'ordine. Costo: le note di cartelle appena create nel cloud arrivano in Note e vanno spostate alla sincronizzazione successiva; l'ordine fisso va perso.

## Where in the code

lib/core/services/sync_service.dart, funzione syncNow, passi di download delle note e delle cartelle, in quest'ordine.
