---
column: done
technical: false
refs:
  - account/Awaiting login/user.SIGN_IN_WITH_GOOGLE
drift: w6tbnosx
proposal: null
agent: false
created: 2026-10-17T18:07:16.484Z
finished: 2026-10-17T18:08:53.226Z
---
# Fix code to match the Model: Sign-in restart is blocked while the browser is awaited

## What happens

Mentre il browser è aperto sull'accesso Google, il pulsante **Accedi con Google** della finestra delle impostazioni è disattivato e mostra «Accesso in corso...»: l'utente non può ricominciare l'accesso da quella finestra. Per riprovare deve chiuderla e riaprirla; la finestra riaperta è vuota, senza la riga «Apertura browser per autenticazione Google...», e il pulsante è di nuovo premibile.

## What should happen

Il Model dice che, mentre l'app attende il ritorno dal browser, una nuova richiesta di accesso con Google **ricomincia il tentativo da capo**, come dallo stato senza accesso, e che la finestra continua a mostrare «Apertura browser per autenticazione Google...». Nella finestra aperta questa richiesta non può essere fatta.

## Chosen option

**Add a retry link next to the waiting line**

Il pulsante resta com'è, come indicatore di attesa, e accanto alla riga di stato compare **«Riprova l'accesso»**, che ricomincia il tentativo. Costo: un controllo in più nella finestra; il pulsante principale continua a non rispondere durante l'attesa, come oggi, e la riga di stato deve restare leggibile accanto al nuovo controllo.

## Where in the code

lib/ui/settings/supabase_settings_dialog.dart (_handleGoogleSignIn, pulsante di accesso con Google)
