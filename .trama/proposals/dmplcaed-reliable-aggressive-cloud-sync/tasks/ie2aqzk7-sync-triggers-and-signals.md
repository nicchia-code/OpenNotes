---
technical: false
refs:
- operating-system
- time
- requirements/tech#General
---
# Sync triggers and signals

L'app riceve i segnali che fanno partire la sincronizzazione da sola.

- APP_RETURNED_TO_FOREGROUND: su mobile al ritorno in primo piano, su desktop al ripristino della finestra ridotta a icona (`window_manager`).
- NETWORK_AVAILABLE e NETWORK_LOST da `connectivity_plus`, anche allo stato iniziale all'avvio; su Android il manifest dichiara `ACCESS_NETWORK_STATE`.
- SYNC_INTERVAL_ELAPSED: 60 s dopo la fine dell'ultimo giro, solo con un utente connesso e l'app visibile (desktop: finestra aperta e non ridotta a icona, anche senza focus; mobile: in primo piano); non scatta durante l'attesa di un nuovo tentativo né senza rete.
- SYNC_RETRY_DUE: alla fine dell'attesa programmata dopo un giro fallito (2 s, 5 s, 15 s, 30 s, poi 60 s).
- Le altre voci del Requirement tecnico generale aggiunte da questo cambiamento (migrazioni Supabase, canale realtime con callback di stato) sono coperte dalle Task di schema e del canale; qui si aggiunge la dipendenza `connectivity_plus`.

Fatto quando, con un utente connesso, riportare l'app in primo piano, riattivare la rete o lasciare passare un minuto con l'app visibile fa partire un giro, e togliere la rete non produce tentativi.
