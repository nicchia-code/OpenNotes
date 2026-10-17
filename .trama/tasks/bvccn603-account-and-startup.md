---
column: done
technical: false
refs:
  - account
  - cloud-connection
  - desktop-layout/Starting
  - requirements/rules#account
  - requirements/rules#cloud-connection
drift: null
proposal: 634nfp49
agent: false
created: 2026-10-17T10:33:15.023Z
finished: 2026-10-17T11:57:30.763Z
---
# Account and startup

Avvio non bloccante e messaggi di accesso corretti.

- L'interfaccia compare senza attendere né la preparazione del collegamento al cloud né la sincronizzazione; il segnale di occupato all'avvio sparisce; il sync dell'avvio parte dalla sessione iniziale.
- Dopo l'accesso con Google la finestra delle impostazioni annuncia "Sincronizzazione completata con successo." solo alla vera fine del giro avviato dall'accesso, senza avviarne un secondo; se il giro fallisce mostra la categoria dell'errore e fra quanto avverrà il nuovo tentativo. I messaggi degli accessi non riusciti restano quelli di oggi.
- Con un utente connesso la finestra delle impostazioni offre i dati di stato descritti in `account/Signed in` (la loro presentazione è nei Requirement `ui` di `account/Signed in`, oggetto della Task Cloud settings window); "Sincronizza Adesso" fa un controllo completo.

Fatto quando l'app si apre subito anche con una rete lenta e il messaggio di successo dopo l'accesso compare solo a giro concluso.
