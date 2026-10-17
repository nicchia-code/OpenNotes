---
column: done
technical: false
refs:
  - app-window/Open
  - app-window/Hidden/operating-system.APP_LAUNCHED
  - requirements/rules#app-window
  - requirements/tech#General
drift: null
proposal: mju6xrov
agent: false
created: 2026-10-17T07:25:16.414Z
finished: 2026-10-17T07:53:20.681Z
---
# Hide the compositor title bar on Linux

Su COSMIC la finestra mostra la barra del titolo disegnata dal compositore sopra la barra superiore dell'app; su Hyprland non succede perché quel compositore non disegna barre. Su Linux la finestra non deve mostrare alcuna barra del titolo di sistema, né del compositore né del toolkit, almeno su COSMIC, Hyprland, GNOME e KDE in sessione Wayland.

Causa probabile, da verificare: la finestra si limita a dichiararsi senza decorazioni e non comunica al compositore che disegna lei la propria cornice, così i compositori che per default aggiungono la loro cornice (COSMIC, KDE) la disegnano comunque.

L'app non disegna angoli arrotondati, bordo od ombra propri e non cerca di rilevare i sistemi che disegnano comunque la loro barra. macOS e Windows non cambiano.

Verifica: avviare l'app su COSMIC (e, se possibile, sugli altri ambienti elencati) e controllare che compaia solo la barra superiore dell'app, che trascinarla sposti la finestra e che il doppio clic la ingrandisca e ripristini.
