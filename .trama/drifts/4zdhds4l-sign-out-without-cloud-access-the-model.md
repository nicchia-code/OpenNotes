---
status: resolved
resolution: fix-code
refs:
  - account/Signed in/user.SIGN_OUT
proposal: null
task: jnomqjcm
origin: null
critical: false
option: 1
note: null
resolvedBy: psazi867
created: 2026-10-12T16:47:04.254Z
---
# Sign-out without cloud access: the Model does not say what happens

## What happens

Quando il cloud non risponde, la disconnessione porta comunque l'app allo stato disconnesso sul dispositivo, ma l'utente vede un messaggio tecnico in rosso (« Errore: » seguito dal dettaglio dell'errore di rete) e la sessione non viene chiusa sul cloud: resta valida finché non scade. Le note locali e la coda restano sul dispositivo.

## What should happen

Il modello dice che la disconnessione chiude la sessione sul cloud e lascia note e coda sul dispositivo, ma non dice cosa accade se il cloud non è raggiungibile: né se la disconnessione avviene lo stesso, né quale messaggio mostrare, né cosa succede alla sessione sul cloud. Senza una scelta, il comportamento resta un errore tecnico che il modello non prevede.

## Fix options

### Disconnettere comunque, con un avviso chiaro

L'app si disconnette sul dispositivo anche senza rete e mostra un avviso in italiano che spiega che la sessione sul cloud non è stata chiusa e scadrà da sola. Le note e la coda restano intatte. Costo: la sessione può restare valida sul cloud per un certo tempo dopo la disconnessione, e il modello va integrato con questo caso.

### Impedire la disconnessione senza rete

La disconnessione si completa solo se il cloud risponde; altrimenti l'app resta connessa e mostra un avviso che chiede di riprovare con la rete. La sessione sul cloud viene sempre chiusa davvero. Costo: senza rete non si può uscire dall'account, che resta collegato al dispositivo anche se l'utente vuole cambiarlo.

## Where in the code

lib/core/services/auth_service.dart: signOut; lib/ui/settings/supabase_settings_dialog.dart: _handleSignOut, che mostra l'errore.
