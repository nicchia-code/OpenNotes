---
status: resolved
resolution: proposal
refs:
  - account/Signed out/user.SIGN_IN_WITH_GOOGLE
proposal: null
task: null
origin: null
previous: kvrirv6e
critical: false
option: null
note: null
resolvedBy: 1mjjves7
created: 2026-10-17T09:44:49.001Z
---
# Unexpected sign-in start error ends Signed out, the Model says Awaiting login

## What happens

Se l'avvio dell'accesso Google fallisce per un errore diverso dal browser che non si apre, per esempio un errore del servizio cloud durante la preparazione, l'app resta disconnessa, la finestra mostra «Accesso Google non completato.» e nessuna attesa del ritorno resta attiva.

## What should happen

Il Model dice che, negli altri casi, l'app passa ad Awaiting login e apre il browser; Signed out → Signed out è descritto solo per il collegamento non pronto e per il browser che non si apre. Il Drift kvrirv6e, risolto, aveva deciso di descrivere questo errore nel Model, ma il testo attuale di account.md non lo contiene.

## Fix options

### Describe the unexpected start error in the Model

Il Model aggiunge da Signed out a Signed out il caso dell'errore imprevisto all'avvio, con il messaggio «Accesso Google non completato». Il codice resta com'è. Costo: una riga in più nel Model; l'utente non sa il motivo, ma può riprovare subito.

### Wait for the browser return after an unexpected start error

Dopo un errore imprevisto l'app passa ad Awaiting login e attende il ritorno dal browser, anche se il browser non è stato aperto. Costo: la finestra mostra un'attesa che non può concludersi finché l'utente non riprova.

## Where in the code

lib/core/services/auth_service.dart, signInWithGoogle (ramo catch generico, che imposta opened = false); lib/ui/settings/supabase_settings_dialog.dart, _handleGoogleSignIn
