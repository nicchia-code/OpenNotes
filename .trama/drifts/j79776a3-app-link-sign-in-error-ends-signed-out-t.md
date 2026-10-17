---
status: resolved
resolution: proposal
refs:
  - account/Awaiting login
proposal: null
task: null
origin: null
previous: jxiu29pk
critical: false
option: null
note: null
resolvedBy: 1mjjves7
created: 2026-10-17T09:44:48.997Z
---
# App-link sign-in error ends Signed out, the Model does not say so

## What happens

Se il ritorno da Google arriva tramite il collegamento dell'app (telefono, tablet, o computer con porta 3000 occupata) e porta un errore, per esempio perché l'utente annulla, l'app esce dall'attesa e torna Signed out: la finestra mostra «Accesso Google non completato.». Il Model non descrive questa uscita.

## What should happen

Il Model descrive il ritorno con errore solo per il ricevitore locale della porta 3000; non dice cosa succede quando lo stesso errore arriva tramite il collegamento dell'app. Il Drift jxiu29pk, risolto, aveva deciso di aggiungere questa transizione, ma il testo attuale di account.md non la contiene.

## Fix options

### Add the app-link error exit to the Model

Il Model aggiunge da Awaiting login a Signed out il caso del ritorno con errore tramite collegamento dell'app, con il messaggio di errore nella finestra. Il codice resta com'è. Costo: una riga in più nel Model.

### Stay in Awaiting login and say so in the settings window

L'app resta in attesa come oggi, ma la finestra dice che l'accesso non è stato completato e che si può riprovare. Costo: l'account resta in attesa fino al nuovo tentativo e la finestra deve ricevere l'errore arrivato dal collegamento.

## Where in the code

lib/core/services/sync_service.dart, ascoltatore dei cambi di sessione (onError, che imposta _awaitingLogin = false e _signInError); lib/core/services/auth_service.dart (ricevitore locale e avvio dell'accesso)
