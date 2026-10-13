---
column: done
technical: false
refs:
  - account/Awaiting login/supabase.OAUTH_REDIRECT_RECEIVED
  - requirements/rules#account
drift: null
proposal: null
agent: false
created: 2026-10-12T07:25:17.451Z
finished: 2026-10-12T10:26:13.078Z
---
# Register the opennotes login-callback app link

Il ritorno dall'accesso Google deve riportare l'app come previsto dallo stato Awaiting login: su telefono e tablet, e su desktop quando la porta 3000 non è disponibile, il browser deve poter aprire l'app sul collegamento opennotes://login-callback. Oggi questo collegamento non è registrato in nessuna piattaforma, quindi il sistema non sa quale app aprire e l'accesso non si completa. Quando è fatto, il ritorno tramite collegamento porta all'utente connesso e la finestra delle impostazioni mostra la sua email.
