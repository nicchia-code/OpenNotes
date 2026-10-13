---
status: resolved
resolution: fix-code
refs:
  - account/Signed out/user.SIGN_IN_WITH_GOOGLE
proposal: null
task: uwzwt22d
origin: null
critical: false
option: 1
note: null
resolvedBy: oasankgu
created: 2026-10-12T17:49:31.744Z
---
# Errore imprevisto all'avvio dell'accesso Google mostra il testo grezzo e torna disconnesso

## What happens

Se l'avvio dell'accesso Google fallisce per una ragione diversa dal browser che non si apre, per esempio un errore del servizio cloud, l'app torna disconnessa. La finestra delle impostazioni mostra il testo tecnico dell'errore, preceduto da «Errore:». L'app non resta in attesa del ritorno dal browser.

## What should happen

Il Model dice che, negli altri casi, l'app passa in **Awaiting login** e attende il ritorno dal browser. Non prevede un messaggio per questo errore e non dice cosa succede quando il browser non è stato aperto, perché in quel caso non arriverà alcun ritorno da attendere.

## Fix options

### Mostrare «Accesso Google non completato» e restare disconnessi

Il caso diventa uguale a quello del browser che non si apre: l'app resta **Signed out** e la finestra mostra «Accesso Google non completato.». Il dettaglio tecnico resta solo nel registro di debug. Il Model aggiunge una riga per questo caso. Costo: l'utente non sa perché l'accesso è fallito, ma può riprovare subito.

### Restare in attesa del ritorno, come scritto nel Model

L'app resta in **Awaiting login** come dice il Model. Nessun browser è aperto, quindi nessun ritorno arriverà: la finestra continua a mostrare l'errore e l'app attende finché l'utente non riprova. Un accesso confermato dal cloud in quel frattempo verrebbe trattato come risposta a un tentativo mai partito. Il Model resta invariato.

### Mantenere il testo tecnico e completare il Model

L'app torna **Signed out** con il testo tecnico dell'errore, come oggi. Il Model viene completato con questo caso, così il comportamento è scritto. Costo: il messaggio è tecnico e in inglese, spiega poco a chi usa l'app, e ogni errore diverso produce un testo diverso.

## Where in the code

lib/core/services/auth_service.dart, signInWithGoogle (il ramo che ripropaga l'errore); lib/ui/settings/supabase_settings_dialog.dart, _handleGoogleSignIn
