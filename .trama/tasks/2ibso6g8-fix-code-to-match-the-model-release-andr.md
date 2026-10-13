---
column: done
technical: false
refs:
  - account/Awaiting login/supabase.OAUTH_REDIRECT_RECEIVED
  - requirements/rules#account
drift: null
proposal: null
agent: false
created: 2026-10-12T08:23:35.433Z
finished: 2026-10-12T10:32:12.930Z
---
# Fix code to match the Model: Release Android build cannot reach the cloud to finish sign-in

Nella build di rilascio Android l'app deve poter raggiungere il servizio cloud: quando il ritorno dall'accesso Google porta un codice o un token, la sessione viene ottenuta e l'utente risulta connesso (Signed in), come nelle build di debug. Oggi il permesso di rete è dichiarato solo nei manifest di debug e profile, non in quello principale, quindi lo scambio della sessione non può completarsi nella build di rilascio.
