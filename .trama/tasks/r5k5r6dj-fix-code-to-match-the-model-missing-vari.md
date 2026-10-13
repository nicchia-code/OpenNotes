---
column: done
technical: false
refs:
  - requirements/rules#cloud-connection
  - cloud-connection/Not configured
  - account/Signed out/user.SIGN_IN_WITH_GOOGLE
drift: null
proposal: llyxqjwk
agent: false
created: 2026-10-12T19:46:09.196Z
finished: 2026-10-13T05:11:48.210Z
---
# Fix code to match the Model: missing-variable notice on Google sign-in

Quando il lavoro è finito, con una variabile mancante il tentativo di accesso Google mostra lo stesso testo di cloud non configurato dell'avvio, che nomina la variabile o le variabili mancanti. Se le variabili ci sono ma la preparazione fallisce, l'accesso continua a mostrare «Supabase non è ancora configurato».
