---
column: done
technical: false
refs:
  - app-window/Hidden
  - requirements/rules#app-window
drift: null
proposal: null
agent: false
created: 2026-10-12T11:21:28.738Z
finished: 2026-10-12T13:55:22.370Z
---
# Fix code to match the Model: Window visible with system title bar before preparation on macOS

## What happens

Su macOS la finestra dell'app è visibile fin dall'avvio, con la barra del titolo di sistema e la dimensione predefinita della finestra nel file di interfaccia, prima che l'app la prepari. Solo dopo compaiono la barra nascosta, la dimensione 1280 × 760 e il centraggio.

## What should happen

Il Modello dice che la finestra è nascosta finché l'app non l'ha preparata: senza barra del titolo di sistema, nella dimensione iniziale, centrata, e mostrata solo a preparazione avvenuta. Il Requisito dice che la barra del titolo di sistema è nascosta.

## Where in the code

macos/Runner/Base.lproj/MainMenu.xib: la finestra principale è visibile al lancio perché non dice il contrario. Deve partire nascosta, così che sia la preparazione in lib/main.dart (show nel callback) a mostrarla.
