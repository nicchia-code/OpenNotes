---
column: done
technical: false
refs:
  - account/Awaiting login
  - requirements/rules#account
drift: 89w5h3g4
proposal: null
agent: false
created: 2026-10-17T19:46:55.451Z
finished: 2026-10-17T19:51:10.003Z
---
# Fix code to match the Model: Sign-in window waits for the whole sync chain, the Requirement waits for the first run

## What happens

Dopo l'accesso con Google la finestra delle impostazioni resta su "Accesso completato! Sincronizzazione in corso..." finché non si chiude l'intera catena di sincronizzazioni: se il giro avviato dall'accesso ne fa partire un altro, l'esito viene annunciato solo alla fine anche di quel secondo giro.

## What should happen

Il Requirement dice che la finestra attende la fine del giro avviato dall'accesso e che, se quel giro ne fa partire un altro, conta il primo: l'esito del primo giro va annunciato alla sua fine, senza attendere il giro successivo, che prosegue e si vede nello stato della sincronizzazione.

## Chosen option

**Announce at the end of the first run**

Il motore di sincronizzazione segnala la fine del primo giro avviato dall'accesso, e la finestra annuncia l'esito in quel momento. Un giro successivo, partito da una richiesta arrivata durante il primo, continua senza bloccare la finestra e si vede solo nella riga di stato della sincronizzazione. Costo: un segnale in più nel motore, da tenere coerente con il ciclo dei giri.

## Where in the code

lib/core/services/sync_service.dart: the sign-in run (_signInRun, signInRun) and the run loop (_start, _runLoop); lib/ui/settings/supabase_settings_dialog.dart: _handleGoogleSignIn, the wait for the sign-in run.
