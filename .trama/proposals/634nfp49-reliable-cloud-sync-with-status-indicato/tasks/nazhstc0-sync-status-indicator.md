---
technical: false
refs:
- sync-run
- requirements/ui#sync-run
- requirements/ui#sync-run/Idle
- requirements/ui#sync-run/Running
- requirements/ui#sync-run/Waiting to retry
- requirements/ui#sync-run/Offline
---
# Sync status indicator

Indicatore dello stato della sincronizzazione accanto all'ingranaggio, nella barra laterale desktop e nella schermata Cartelle su mobile, visibile solo con un utente connesso.

- Icona e testo per ogni stato della macchina `sync-run` come nei Requirement `ui`: sincronizzato (o "Alcune modifiche non si sincronizzano" con cambiamenti messi da parte), in corso, in attesa di un nuovo tentativo con categoria e secondi mancanti, offline.
- Suggerimento con stato e ultima sincronizzazione in forma relativa; un tocco o un clic apre le impostazioni del cloud.

Fatto quando l'indicatore cambia da solo passando per tutti gli stati (togliendo la rete, facendo fallire un giro, mettendo da parte un cambiamento).
