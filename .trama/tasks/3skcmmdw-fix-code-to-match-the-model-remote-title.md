---
column: done
technical: false
refs:
  - realtime-channel/Listening/supabase.REMOTE_NOTE_CHANGED
drift: 559ouolr
proposal: null
agent: false
created: 2026-10-12T14:57:05.764Z
finished: 2026-10-12T14:58:43.133Z
---
# Fix code to match the Model: Remote title change: the vault file is rewritten or a new file is written

## What happens

Quando una nota cambia titolo nel cloud e sostituisce la copia locale, il file nel vault viene scritto con il nome ricavato dal nuovo titolo e il file precedente resta lì, fermo. Così la stessa nota compare in due file. Il Task ry8p38r9 risulta chiuso, ma nel codice il nome viene sempre ricalcolato dal titolo e il file non viene riusato.

## What should happen

Il Model del canale e quello della sincronizzazione dicono che il file della nota nel vault «viene riscritto». Il Model del file nel vault dice invece che una modifica del titolo, anche arrivata dal cloud, scrive un nuovo file e lascia quello vecchio come copia non più aggiornata. La decisione registrata per il download (mantenere lo stesso file) non è stata riportata nel Model. Il Requirement dice che il nome del file si ricalcola dal titolo a ogni scrittura e che la nota ricorda solo l'ultimo file scritto.

## Chosen option

**Write a new file and keep the old one as orphan**

Il download scrive il file con il nome del titolo ricevuto dal cloud e lascia quello vecchio come copia ferma. È ciò che il Model del file nel vault e il Requirement descrivono già. Vanno riscritte le frasi del canale e della sincronizzazione che dicono «viene riscritto», e la decisione di mantenere lo stesso file va segnata come superata.

## Where in the code

lib/core/services/sync_service.dart: applyRemoteNote (saveNote con il percorso precedente); lib/core/services/vault_service.dart: saveNote (nome calcolato dal titolo)
