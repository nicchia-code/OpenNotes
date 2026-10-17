---
column: done
technical: false
refs:
  - user.PULL_TO_REFRESH
  - requirements/ui#user.PULL_TO_REFRESH
drift: null
proposal: 634nfp49
agent: false
created: 2026-10-17T10:33:15.023Z
finished: 2026-10-17T10:59:53.020Z
---
# Mobile pull to refresh

Trascina-per-aggiornare su mobile.

- La schermata Cartelle e la lista note hanno il controllo di aggiornamento in stile iOS di Flutter, disponibile solo con un utente connesso; il gesto avvia un controllo completo e la rotellina resta visibile fino alla fine del giro avviato dal gesto.

Fatto quando, su mobile, trascinare verso il basso una delle due schermate fa partire un controllo completo e la rotellina si chiude a giro concluso.
