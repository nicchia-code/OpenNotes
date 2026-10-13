---
column: done
technical: false
refs:
  - account/Signed out/user.SIGN_IN_WITH_GOOGLE
  - requirements/rules#cloud-connection
drift: null
proposal: llyxqjwk
agent: false
created: 2026-10-12T19:46:11.396Z
finished: 2026-10-13T05:11:56.683Z
---
# Fix code to match the Model: sign-in names the missing build variable

Quando il collegamento al cloud non è pronto perché la build non fornisce l'indirizzo, la chiave o entrambi, l'accesso Google resta Signed out e mostra il testo esatto che nomina ciò che manca: «Cloud non configurato: manca SUPABASE_URL.», «Cloud non configurato: manca SUPABASE_ANON_KEY.», oppure «Cloud non configurato: mancano SUPABASE_URL e SUPABASE_ANON_KEY.»; è lo stesso testo dell'avviso all'avvio. Oggi l'accesso mostra sempre «Supabase non è ancora configurato», senza dire quale variabile manca. Se invece le variabili sono presenti ma la preparazione del collegamento fallisce, l'accesso continua a mostrare «Supabase non è ancora configurato». Il lavoro dipende dalla rilevazione delle variabili mancanti descritta nell'altro task del Proposal («no embedded Supabase address or key»).
