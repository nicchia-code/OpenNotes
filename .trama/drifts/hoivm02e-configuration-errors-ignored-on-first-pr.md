---
status: resolved
resolution: fix-code
refs:
  - cloud-connection/Configuring
proposal: null
task: a2jszjf4
origin: null
critical: false
option: 1
note: null
resolvedBy: 3pikg137
created: 2026-10-12T07:24:47.546Z
---
# Configuration errors ignored on first preparation

## What happens

Quando la preparazione del collegamento al progetto cloud fallisce, l'errore viene sempre ignorato, anche al primo tentativo. L'app passa quindi a **Configured** e salva indirizzo e chiave, ma il collegamento non è utilizzabile: le sincronizzazioni partono senza effetto e non compare alcuna segnalazione.

## What should happen

L'errore va ignorato solo se il collegamento era già stato preparato durante questa esecuzione. In ogni altro caso la preparazione fallisce e l'app resta **Not configured**, con il segnale di occupato tolto e l'utente non avvisato.

## Fix options

### Ignorare l'errore solo se il collegamento era già pronto

Il tentativo di preparazione viene ignorato solo quando il collegamento risulta già preparato in questa esecuzione; negli altri casi l'errore porta a **Not configured**, come previsto dal Model. Nessun costo per l'utente: al primo errore il cloud resta spento fino al riavvio successivo.

### Verificare il collegamento prima di dichiararlo pronto

Dopo la preparazione l'app controlla che il collegamento al progetto sia davvero disponibile; se non lo è, resta **Not configured**. Il controllo è una verifica in più sul percorso di avvio, ma tiene la regola del Model senza distinguere il caso già preparato.

## Where in the code

lib/core/services/sync_service.dart, metodo initializeSupabase: la chiamata a Supabase.initialize è dentro un catch che registra solo un messaggio di debug.
