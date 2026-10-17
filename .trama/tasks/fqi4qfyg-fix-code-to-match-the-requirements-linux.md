---
column: done
technical: true
refs:
  - requirements/rules#app-window
drift: 0i085zsy
proposal: mju6xrov
agent: false
created: 2026-10-17T07:45:22.633Z
finished: 2026-10-17T07:53:10.957Z
---
# Fix code to match the Requirements: Linux window keeps the compositor title bar on COSMIC

## What happens

Su Linux in sessione Wayland, su COSMIC, la finestra mostra ancora la barra del titolo del compositore, anche se l'app chiede una finestra senza barra del titolo di sistema. Il toolkit grafico dell'app non trasmette questa richiesta al compositore: il compositore disegna la propria barra.

## What should happen

Su Linux la barra del titolo di sistema non compare mai, né quella del compositore né quella del toolkit, almeno su COSMIC, Hyprland, GNOME e KDE in Wayland. L'app non disegna angoli, bordi né ombre.

## Chosen option

**Negotiate the decoration with the compositor**

Il runner Linux chiede al compositore la decorazione lato client con il protocollo xdg-decoration, e lo fa sulla finestra GTK già creata. Resta Wayland nativo e nessuna ombra. Costo: GTK 3 non espone pubblicamente il riferimento al toplevel, quindi il codice dipende da dettagli interni di GDK, da verificare su COSMIC.

## Where in the code

linux/runner/my_application.cc (creazione della finestra GTK), lib/main.dart (WindowOptions con titleBarStyle hidden)
