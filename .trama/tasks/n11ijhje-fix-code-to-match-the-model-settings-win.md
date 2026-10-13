---
column: done
technical: false
refs:
  - account/Awaiting login
drift: 3lqov4js
proposal: null
agent: false
created: 2026-10-13T05:23:24.953Z
finished: 2026-10-13T05:34:05.894Z
---
# Fix code to match the Model: Settings window keeps the success message when the sign-in return fails

## What happens

Dopo che il browser si è aperto, la finestra mostra 'Accesso completato! Sincronizzazione in corso...' e poi 'Sincronizzazione completata con successo.'. Se il ritorno da Google poi fallisce, cioè porta un errore o non fornisce una sessione, l'account torna allo stato senza accesso ma la finestra conserva il messaggio di successo, accanto al pulsante Accedi con Google.

## What should happen

Il Model prescrive quei due messaggi appena il browser è aperto, ma non dice cosa mostra la finestra quando il ritorno fallisce. Così il messaggio di successo resta visibile anche quando l'account non è connesso.

## Chosen option

**Mostrare l'esito reale del ritorno**

La finestra aspetta l'esito del ritorno prima di annunciare il successo: se l'accesso riesce mostra 'Sincronizzazione completata con successo.', se fallisce mostra il messaggio di errore. Il Model cambia la sequenza descritta dopo l'apertura del browser. Costo: la finestra resta in attesa più a lungo, e se l'utente chiude il browser senza tornare il messaggio non cambia mai.

## Where in the code

lib/ui/settings/supabase_settings_dialog.dart (gestione dell'accesso Google)
