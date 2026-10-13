---
status: resolved
resolution: fix-code
refs:
  - cloud-connection/Not configured
proposal: null
task: tthp20pf
origin: null
critical: false
option: 1
note: null
resolvedBy: fz9axufm
created: 2026-10-12T10:45:27.837Z
---
# Sign-in possible while the cloud connection is not configured

## What happens

Quando il collegamento al cloud risulta non configurato, l'accesso con Google resta comunque disponibile: se la preparazione riesce ma il salvataggio delle impostazioni fallisce, l'utente può accedere, mentre sincronizzazione e canale in tempo reale restano fermi.

## What should happen

Il modello dice che, finché il collegamento non è pronto, accesso, sincronizzazione e canale in tempo reale **non sono disponibili**.

## Fix options

### Block sign-in until the connection is ready

Il tentativo di accesso con Google viene rifiutato finché il collegamento non è pronto, con lo stesso messaggio già usato quando il cloud non è configurato. Nel caso normale non cambia nulla per l'utente. Costo: un controllo in più, e nel caso raro di salvataggio fallito l'utente deve riprovare dopo il riavvio.

### Change the Model for the failed-save case

Si accetta che l'accesso resti possibile quando il cloud è già stato preparato ma le impostazioni non sono state salvate, e si descrive questo nel modello. Costo: il modello diventa più complesso, e l'account connesso non viene sincronizzato finché il collegamento non è pronto.

## Where in the code

lib/core/services/auth_service.dart (accesso con Google, che usa il client cloud direttamente); lib/core/services/sync_service.dart (preparazione del collegamento: il client può esistere mentre il collegamento risulta non configurato)
