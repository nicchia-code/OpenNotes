---
status: resolved
resolution: fix-code
refs:
  - requirements/rules#app-window
proposal: null
task: fqi4qfyg
origin: 5i3mimps
critical: false
option: 1
note: null
resolvedBy: yvoxqf2h
created: 2026-10-17T07:30:22.837Z
---
# Linux window keeps the compositor title bar on COSMIC

## What happens

Su Linux in sessione Wayland, su COSMIC, la finestra mostra ancora la barra del titolo del compositore, anche se l'app chiede una finestra senza barra del titolo di sistema. Il toolkit grafico dell'app non trasmette questa richiesta al compositore: il compositore disegna la propria barra.

## What should happen

Su Linux la barra del titolo di sistema non compare mai, né quella del compositore né quella del toolkit, almeno su COSMIC, Hyprland, GNOME e KDE in Wayland. L'app non disegna angoli, bordi né ombre.

## Fix options

### Negotiate the decoration with the compositor

Il runner Linux chiede al compositore la decorazione lato client con il protocollo xdg-decoration, e lo fa sulla finestra GTK già creata. Resta Wayland nativo e nessuna ombra. Costo: GTK 3 non espone pubblicamente il riferimento al toplevel, quindi il codice dipende da dettagli interni di GDK, da verificare su COSMIC.

### Run the app through XWayland on Linux

All'avvio il runner forza il backend X11 di GTK, così la finestra è gestita da XWayland e la decorazione si toglie con l'API pubblica di GTK. Costo: l'app non gira più in Wayland nativo su Linux, con possibili differenze di scala frazionaria e di input. Il comportamento di COSMIC con questi hint va verificato.

### Client decorations with no shadow

Il runner imposta una barra del titolo GTK vuota e rimuove con CSS ombra e angoli della decorazione lato client. Resta Wayland nativo. Costo: un elemento GTK resta nella finestra, e non è dimostrato che COSMIC smetta di disegnare la propria barra, perché la richiesta non passa dal protocollo xdg-decoration.

## Where in the code

linux/runner/my_application.cc (creazione della finestra GTK), lib/main.dart (WindowOptions con titleBarStyle hidden)
