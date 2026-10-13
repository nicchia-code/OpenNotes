---
column: done
technical: false
refs:
  - account/Signed out/user.SIGN_IN_WITH_GOOGLE
drift: kvrirv6e
proposal: null
agent: false
created: 2026-10-12T19:48:51.007Z
finished: 2026-10-12T19:50:12.150Z
---
# Fix code to match the Model: Fix code to match the Model: sign-in failures other than the browser

## What happens

Se l'avvio dell'accesso Google fallisce per una ragione diversa dal browser che non si apre, per esempio un errore del servizio cloud durante la preparazione dell'accesso, l'app resta disconnessa e la finestra mostra «Accesso Google non completato.». Il ricevitore locale viene chiuso e nessuna attesa del ritorno resta attiva. Il dettaglio dell'errore finisce solo nel registro di debug.

## What should happen

Per il Model, il ritorno a Signed out per l'accesso Google riguarda solo il collegamento non pronto e il browser che non può essere aperto. Tutti gli altri casi passano ad Awaiting login: l'app apre il browser e attende il ritorno. Il Model non descrive l'errore imprevisto durante l'avvio, che oggi porta a Signed out.

## Chosen option

**Describe the unexpected start error in the Model**

Il Model aggiunge una transizione da Signed out a Signed out per gli errori imprevisti durante l'avvio, con il messaggio «Accesso Google non completato». Il codice resta com'è. Costo: una riga in più nel Model; l'utente non sa perché l'accesso è fallito, ma può riprovare subito.

## Where in the code

lib/core/services/auth_service.dart (signInWithGoogle, ramo di errore generico); lib/ui/settings/supabase_settings_dialog.dart (_handleGoogleSignIn)
