---
column: done
technical: false
refs:
  - account/Signed out/user.SIGN_IN_WITH_GOOGLE
drift: msjcrr4z
proposal: null
agent: false
created: 2026-10-12T18:00:24.442Z
finished: 2026-10-12T18:02:07.122Z
---
# Fix code to match the Model: Errore imprevisto all'avvio dell'accesso Google mostra il testo grezzo e torna disconnesso

## What happens

Se l'avvio dell'accesso Google fallisce per una ragione diversa dal browser che non si apre, per esempio un errore del servizio cloud, l'app torna disconnessa. La finestra delle impostazioni mostra il testo tecnico dell'errore, preceduto da «Errore:». L'app non resta in attesa del ritorno dal browser.

## What should happen

Il Model dice che, negli altri casi, l'app passa in **Awaiting login** e attende il ritorno dal browser. Non prevede un messaggio per questo errore e non dice cosa succede quando il browser non è stato aperto, perché in quel caso non arriverà alcun ritorno da attendere.

## Chosen option

**Mostrare «Accesso Google non completato» e restare disconnessi**

Il caso diventa uguale a quello del browser che non si apre: l'app resta **Signed out** e la finestra mostra «Accesso Google non completato.». Il dettaglio tecnico resta solo nel registro di debug. Il Model aggiunge una riga per questo caso. Costo: l'utente non sa perché l'accesso è fallito, ma può riprovare subito.

## Where in the code

lib/core/services/auth_service.dart, signInWithGoogle (il ramo che ripropaga l'errore); lib/ui/settings/supabase_settings_dialog.dart, _handleGoogleSignIn
