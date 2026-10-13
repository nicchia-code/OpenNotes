---
column: done
technical: false
refs:
  - account/Signed out
drift: dgdpwcor
proposal: null
agent: false
created: 2026-10-12T11:27:34.837Z
finished: 2026-10-12T11:29:41.759Z
---
# Fix code to match the Model: Session confirmed by the cloud outside the browser wait is not in the account Model

## What happens

Quando il servizio cloud comunica che l'accesso è stato completato, l'app passa a connesso e avvia subito la sincronizzazione, anche se non stava aspettando il ritorno dal browser: lo stato disconnesso accetta questa conferma. Può succedere, per esempio, se l'app è stata riavviata durante l'accesso e il ritorno arriva dal collegamento dell'app. Nel modello la conferma di accesso porta a connesso solo dallo stato in cui l'app attende il ritorno.

## What should happen

Il modello prevede il passaggio a connesso per la conferma di accesso solo da *Awaiting login*; dallo stato disconnesso la stessa conferma non ha effetto e non esiste una transizione. Il modello non può essere seguito così come è scritto perché la sessione conservata dal servizio cloud resta valida tra un avvio e l'altro: se la conferma fosse ignorata, l'app resterebbe disconnessa pur avendo già una sessione, fino al riavvio successivo.

## Chosen option

**Add the transition to the Model**

Il modello riceve una transizione in più: da *Signed out*, la conferma di accesso del servizio cloud porta a *Signed in* e avvia la sincronizzazione. L'app resta coerente con la sessione conservata e con il ritorno dal browser. Costo: l'accesso può comparire anche senza che l'app stesse aspettando il browser, cosa che il modello oggi non descrive.

## Where in the code

lib/core/services/sync_service.dart: ascoltatore degli eventi di sessione (_setupAuthListener); lib/core/services/auth_service.dart: ritorno OAuth
