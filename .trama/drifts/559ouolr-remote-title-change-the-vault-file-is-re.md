---
status: resolved
resolution: fix-code
refs:
  - realtime-channel/Listening/supabase.REMOTE_NOTE_CHANGED
proposal: null
task: 3skcmmdw
origin: null
critical: false
option: 1
note: null
resolvedBy: g08cr3wn
created: 2026-10-12T14:50:01.471Z
---
# Remote title change: the vault file is rewritten or a new file is written

## What happens

Quando una nota cambia titolo nel cloud e sostituisce la copia locale, il file nel vault viene scritto con il nome ricavato dal nuovo titolo e il file precedente resta lì, fermo. Così la stessa nota compare in due file. Il Task ry8p38r9 risulta chiuso, ma nel codice il nome viene sempre ricalcolato dal titolo e il file non viene riusato.

## What should happen

Il Model del canale e quello della sincronizzazione dicono che il file della nota nel vault «viene riscritto». Il Model del file nel vault dice invece che una modifica del titolo, anche arrivata dal cloud, scrive un nuovo file e lascia quello vecchio come copia non più aggiornata. La decisione registrata per il download (mantenere lo stesso file) non è stata riportata nel Model. Il Requirement dice che il nome del file si ricalcola dal titolo a ogni scrittura e che la nota ricorda solo l'ultimo file scritto.

## Fix options

### Write a new file and keep the old one as orphan

Il download scrive il file con il nome del titolo ricevuto dal cloud e lascia quello vecchio come copia ferma. È ciò che il Model del file nel vault e il Requirement descrivono già. Vanno riscritte le frasi del canale e della sincronizzazione che dicono «viene riscritto», e la decisione di mantenere lo stesso file va segnata come superata.

### Rewrite the same file

Il download riscrive il file che la nota già aveva, qualunque sia il nuovo titolo, come registrato nella decisione precedente. Vanno cambiati il Model del file nel vault, che oggi lascia la copia vecchia orfana, e il codice che sceglie il nome dal titolo.

### Rename to the cloud title and remove the old file

Il download scrive il file con il nome del titolo del cloud, cancella quello vecchio e salva il nuovo percorso. Il nome segue sempre il titolo remoto e nel vault non restano copie. Un'interruzione tra la scrittura e la cancellazione può lasciare una copia senza collegamento.

## Where in the code

lib/core/services/sync_service.dart: applyRemoteNote (saveNote con il percorso precedente); lib/core/services/vault_service.dart: saveNote (nome calcolato dal titolo)
