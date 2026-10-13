---
column: done
technical: false
refs:
  - account/Awaiting login/supabase.OAUTH_REDIRECT_RECEIVED
  - requirements/rules#account
drift: null
proposal: null
agent: false
created: 2026-10-12T12:03:38.776Z
finished: 2026-10-12T14:06:43.371Z
---
# Register the opennotes login-callback link on Linux desktop

Sul desktop Linux, quando la porta 3000 non è disponibile, il ritorno dall'accesso Google deve riportare l'app sul collegamento opennotes://login-callback, come previsto dallo stato Awaiting login. Oggi il collegamento è registrato su Android, iOS, macOS e Windows, ma su Linux nessuna applicazione lo gestisce: il browser non sa quale app aprire e l'accesso non si completa. Il Task lk5jz6j0 è concluso senza coprire Linux. Quando è fatto, il ritorno tramite collegamento su Linux porta l'utente allo stato connesso (Signed in).
