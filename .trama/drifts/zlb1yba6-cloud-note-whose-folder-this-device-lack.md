---
status: resolved
resolution: fix-code
refs:
  - note/Active/sync-run.CLOUD_NOTE_APPLIED
proposal: null
task: u4djlo8z
origin: null
critical: false
option: 1
note: null
resolvedBy: g08cr3wn
created: 2026-10-12T14:53:04.341Z
---
# Cloud note whose folder this device lacks is moved to Notes

## What happens

Quando dal cloud arriva una nota che indica una cartella che sul dispositivo non esiste (per esempio perché la cartella è stata eliminata qui e l'eliminazione non è ancora arrivata al cloud), il sistema la salva nella cartella **Note**. La cartella indicata sulla nota cambia sul dispositivo, e la nota compare in Note invece di restare senza cartella.

## What should happen

Il Model dice che la versione del cloud sostituisce quella locale, e nella cartella dice che una nota può indicare una cartella che non esiste, senza vincoli: in quel caso la nota compare solo in «Tutte le note». Il Model non dice che la nota venga spostata in Note. Lo spostamento in Note è però già la regola quando una cartella viene eliminata, quindi serve decidere quale comportamento vale anche per le note ricevute dal cloud.

## Fix options

### Scrivere nel Model lo spostamento in Note

La nota ricevuta da una cartella mancante va in Note, come già accade all'eliminazione di una cartella. Il comportamento dell'app non cambia; la regola entra nel Model della nota. Costo: una Proposal sul Model. Il cambio di cartella resta sul dispositivo e non viene inviato al cloud finché la nota non viene modificata.

### Lasciare la nota nella cartella mancante

La nota conserva la cartella indicata dal cloud e compare solo in Tutte le note finché la cartella non torna. Costo: la nota non compare in nessuna cartella e l'utente può non trovarla; serve un'altra regola di visualizzazione o un avviso.

### Spostare in Note anche nel cloud

Lo spostamento in Note viene messo in coda per il cloud, così i due lato coincidono. Costo: una versione ricevuta dal cloud produce un invio, che il Model oggi esclude; la regola di sincronizzazione va cambiata e servono controlli per non riscrivere versioni più recenti.

## Where in the code

lib/core/services/sync_service.dart, applyRemoteNote (controllo della cartella prima di salvare la nota)
