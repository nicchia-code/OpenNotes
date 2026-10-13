---
status: resolved
resolution: fix-code
refs:
  - account/Awaiting login
proposal: null
task: n11ijhje
origin: null
critical: false
option: 1
note: null
resolvedBy: fiomlg7l
created: 2026-10-13T05:21:55.149Z
---
# Settings window keeps the success message when the sign-in return fails

## What happens

Dopo che il browser si è aperto, la finestra mostra 'Accesso completato! Sincronizzazione in corso...' e poi 'Sincronizzazione completata con successo.'. Se il ritorno da Google poi fallisce, cioè porta un errore o non fornisce una sessione, l'account torna allo stato senza accesso ma la finestra conserva il messaggio di successo, accanto al pulsante Accedi con Google.

## What should happen

Il Model prescrive quei due messaggi appena il browser è aperto, ma non dice cosa mostra la finestra quando il ritorno fallisce. Così il messaggio di successo resta visibile anche quando l'account non è connesso.

## Fix options

### Mostrare l'esito reale del ritorno

La finestra aspetta l'esito del ritorno prima di annunciare il successo: se l'accesso riesce mostra 'Sincronizzazione completata con successo.', se fallisce mostra il messaggio di errore. Il Model cambia la sequenza descritta dopo l'apertura del browser. Costo: la finestra resta in attesa più a lungo, e se l'utente chiude il browser senza tornare il messaggio non cambia mai.

### Correggere il messaggio solo in caso di errore

Il Model resta com'è per il caso riuscito. In caso di errore la finestra sostituisce il messaggio di successo con l'errore, oppure con Accesso Google non completato. Costo: il messaggio di successo compare comunque per un momento, e il Model deve descrivere anche il messaggio di errore; la finestra deve ricevere l'esito del ritorno.

## Where in the code

lib/ui/settings/supabase_settings_dialog.dart (gestione dell'accesso Google)
