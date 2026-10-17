---
column: done
technical: false
refs:
  - account/Awaiting login
  - requirements/rules#account
drift: tlbubeh0
proposal: null
agent: false
created: 2026-10-17T18:38:45.624Z
finished: 2026-10-17T18:47:10.255Z
---
# Fix code to match the Model: Accesso fatto senza rete: la finestra annuncia una sincronizzazione mai partita

## What happens

Se il ritorno dal browser arriva mentre il dispositivo risulta senza rete, la sincronizzazione che l'accesso dovrebbe avviare non parte. La finestra delle impostazioni però passa comunque a «Sincronizzazione completata con successo.», mentre la stessa finestra mostra sotto lo stato «Offline: le modifiche verranno inviate al ritorno della rete». Il controllo completo che accompagna ogni accesso non viene ricordato per quando la rete torna.

## What should happen

Il Model dice che, dopo il ritorno, la finestra annuncia il risultato della sincronizzazione avviata dall'accesso, e che ogni accesso avvia un controllo completo. Con il dispositivo senza rete quella sincronizzazione non parte, ma il Model non dice cosa mostrare in questo caso, né che il controllo completo va ricordato per il ritorno della rete. Il messaggio di successo dichiara una sincronizzazione che non c'è stata.

## Chosen option

**Nessun esito quando l'accesso non avvia alcuna sincronizzazione**

La finestra non annuncia nessun esito per l'accesso se nessuna sincronizzazione parte. Resta visibile lo stato offline, che dice che le modifiche aspettano la rete, e il messaggio di successo compare solo quando una sincronizzazione avviata dall'accesso è davvero finita. Costo: l'utente non riceve una conferma esplicita dell'accesso in questo caso, e deve leggere lo stato offline.

## Where in the code

lib/ui/settings/supabase_settings_dialog.dart (_handleGoogleSignIn, attesa del giro dell'accesso); lib/core/services/sync_service.dart (_start, con il dispositivo senza rete)
