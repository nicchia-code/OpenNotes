---
technical: false
refs:
- account
- cloud-connection
- desktop-layout/Starting
- requirements/rules#account
- requirements/rules#cloud-connection
---
# Account and startup

Avvio non bloccante e messaggi di accesso corretti.

- L'interfaccia compare senza attendere né la preparazione del collegamento al cloud né la sincronizzazione; il segnale di occupato all'avvio sparisce; il sync dell'avvio parte dalla sessione iniziale.
- Dopo l'accesso con Google la finestra delle impostazioni annuncia "Sincronizzazione completata con successo." solo alla vera fine del giro avviato dall'accesso, senza avviarne un secondo; se il giro fallisce mostra la categoria dell'errore e fra quanto avverrà il nuovo tentativo.
- Con un utente connesso la finestra delle impostazioni offre i dati di stato descritti in `account/Signed in` (la loro presentazione è definita dalla Proposal successiva sull'interfaccia); "Sincronizza Adesso" fa un controllo completo.

Fatto quando l'app si apre subito anche con una rete lenta e il messaggio di successo dopo l'accesso compare solo a giro concluso.
