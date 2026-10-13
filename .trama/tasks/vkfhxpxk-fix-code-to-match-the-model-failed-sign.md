---
column: done
technical: false
refs:
  - account/Awaiting login
drift: jxiu29pk
proposal: null
agent: false
created: 2026-10-13T05:23:24.946Z
finished: 2026-10-13T05:25:52.971Z
---
# Fix code to match the Model: Failed sign-in return through the app link leaves the app waiting for login

## What happens

Se il ritorno da Google arriva tramite il collegamento dell'app (su telefono e tablet, oppure su computer quando la porta 3000 è occupata) e porta un errore, per esempio perché l'utente annulla l'accesso, l'app non esce dallo stato di attesa: resta in attesa di accesso e né la finestra delle impostazioni né il browser danno un esito. Lo stesso ritorno con errore sul ricevitore locale, invece, riporta l'account allo stato senza accesso.

## What should happen

Il Model descrive l'errore di ritorno solo per il ricevitore locale della porta 3000: l'account passa allo stato senza accesso e il browser mostra il messaggio. Non dice cosa succede quando lo stesso errore arriva tramite il collegamento dell'app, cioè su telefono e tablet e su computer con la porta occupata.

## Chosen option

**Tornare allo stato senza accesso con il messaggio**

Un errore ricevuto tramite il collegamento dell'app riporta l'account allo stato senza accesso, come per il ricevitore locale, e la finestra mostra il messaggio di errore. Il Model aggiunge questa transizione per il collegamento dell'app. Costo: l'app deve leggere l'errore anche quando arriva dal collegamento, non solo l'accesso riuscito; è una modifica piccola.

## Where in the code

lib/core/services/auth_service.dart (ricevitore locale e avvio dell'accesso); lib/core/services/sync_service.dart (ascolto dei cambi di stato dell'accesso)
