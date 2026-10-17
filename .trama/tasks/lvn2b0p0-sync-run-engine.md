---
column: done
technical: false
refs:
  - cloud-sync
  - sync-run
  - user.SYNC_NOW
  - user.PULL_TO_REFRESH
  - requirements/rules#sync-run
drift: null
proposal: 634nfp49
agent: false
created: 2026-10-17T10:33:15.023Z
finished: 2026-10-17T15:36:20.210Z
---
# Sync run engine

La sincronizzazione segue la macchina `sync-run` aggiornata. Il riferimento alla Feature `cloud-sync` copre solo la sua descrizione riassuntiva, che è soddisfatta quando lo sono questa Task e quelle delle altre Machine della Feature.

- Una sola alla volta; le richieste arrivate durante un giro fanno partire, alla fine, un solo nuovo giro, controllo completo se una di esse lo chiedeva.
- Avvii: sessione iniziale, accesso e "Sincronizza Adesso" e trascina-per-aggiornare con controllo completo; accodamento, ritorno in primo piano, rinnovo del token, sync periodico, ricollegamento del canale, modifica in tempo reale non applicata, scelta della versione del cloud e ritorno della rete con giro incrementale.
- Stati Waiting to retry (attese crescenti, ogni avvio riprova subito e azzera la serie) e Offline (nessun tentativo automatico; richieste a mano provano comunque; controllo completo ricordato per il ritorno della rete).
- Tempi massimi di 15 s per richiesta e 2 min per giro; errori classificati nelle categorie dei Requirement e annotati nel registro.
- Passi: verifica del cambio di account (che azzera anche ultima revisione scaricata, revisioni note ed elenco degli allegati presenti sul cloud); invio della coda con revisione di base tramite `push_note`/`push_folder`, "vince l'ultima modifica" sui conflitti e sui segnaposti, rifiuti contati senza fermare il giro, elementi messi da parte saltati; eliminazioni come segnaposti; lettura incrementale per revisione (o completa); invio delle note mai sincronizzate; applicazione di cartelle e note senza riapplicare le revisioni già note; primo giro dopo l'aggiornamento con adozione delle revisioni o "vince l'ultima modifica"; caricamento dei soli allegati assenti dal cloud e download degli allegati mancanti per tutte le note; nel controllo completo rimozione delle righe locali già sincronizzate assenti dal cloud; ora dell'ultima sincronizzazione e ultima revisione scaricata salvate a ogni completamento.
- Eventi emessi come descritti nella macchina, compresi CHANGE_REJECTED, CLOUD_NOTE_REMOVED e CLOUD_FOLDER_REMOVED.

Fatto quando una modifica fatta durante un giro arriva al cloud senza altri avvii, un giro senza cambiamenti non riscrive nessuna nota, una richiesta che non risponde fa fallire il giro entro i tempi massimi e il giro successivo parte da solo.
