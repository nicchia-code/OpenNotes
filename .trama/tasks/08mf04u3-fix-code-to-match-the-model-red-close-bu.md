---
column: done
technical: false
refs:
  - app-window/Open/user.CLOSE_WINDOW
drift: null
proposal: null
agent: false
created: 2026-10-13T10:39:31.168Z
finished: 2026-10-13T10:55:20.642Z
---
# Fix code to match the Model: Red close button closes the window before the waiting edit is written

## What happens

Su Linux e Windows il pulsante rosso dell'app chiama direttamente windowManager.close(), senza attendere la consegna e la scrittura della modifica in attesa. La consegna avviene solo tramite il cambio di stato del ciclo di vita o la richiesta di uscita dell'app, che il codice non attende prima di chiudere la finestra: la scrittura può non completarsi prima che l'app termini.

## What should happen

Il comando di chiusura su Linux e Windows deve prima consegnare e scrivere le modifiche in attesa, e solo dopo chiudere la finestra e terminare l'app, come descritto dal Model per lo stato Chiusa.

## Where in the code

lib/ui/shell/mac_title_bar.dart: onTap del pulsante rosso in build (windowManager.close()). lib/main.dart: AppLifecycleListener in _OpenNotesAppState.initState, che chiama flushOnAppLeavingForeground. lib/core/state/notes_provider.dart: flushOnAppLeavingForeground.
