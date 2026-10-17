---
column: done
technical: false
refs:
  - folder/User folder/sync-run.FINISHED
  - sync-run/Pulling
  - requirements/rules#cloud-sync
drift: null
proposal: null
agent: false
created: 2026-10-17T12:46:34.894Z
finished: 2026-10-17T15:39:11.483Z
---
# Fix code to match the Model: Folder deletion placeholder read by a full sync brings the folder back

Un segnaposto di eliminazione di una cartella (la cartella con `purged_at` valorizzato) letto dal controllo completo o dal giro deve essere trattato come eliminazione fatta altrove, come già avviene per il tempo reale e per le note nello stesso giro. Oggi il controllo completo applica il segnaposto come una cartella viva: la ricrea se manca sul dispositivo, la aggiorna se c'è, e la sua presenza nel cloud impedisce la rimozione della cartella locale. Comportamento atteso: se il dispositivo non ha una modifica in attesa della cartella più recente dell'eliminazione, la cartella locale viene eliminata e le sue note, cestinate comprese, passano in «Note» senza essere accodate; altrimenti la copia locale resta e rinascerà sul cloud. Il segnaposto non viene mai salvato come cartella.
