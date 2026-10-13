---
status: resolved
resolution: fix-code
refs:
  - requirements/rules#app-window
  - app-window/Open
proposal: null
task: 7jngr0ie
origin: null
critical: false
option: 1
note: null
resolvedBy: fz9axufm
created: 2026-10-12T10:44:50.576Z
---
# Window buttons drawn on web, Android and iOS wide layouts

## What happens

Quando l'interfaccia desktop a colonne compare anche su web, Android o iOS (per esempio su un tablet in orizzontale o nel browser a schermo largo), la barra superiore mostra i tre pallini rosso, giallo e verde della finestra. Toccandoli non succede nulla, perché su quelle piattaforme non c'è una finestra da gestire.

## What should happen

Secondo il requisito, i pulsanti chiudi, riduci e ingrandisci sono disegnati dall'app **solo su Linux e Windows**. Su web, Android e iOS non c'è una finestra da gestire e la finestra resta nascosta. Su macOS l'app lascia invece libero lo spazio per i pulsanti nativi.

## Fix options

### Disegnare i pulsanti solo su Linux e Windows

Su web, Android e iOS la barra superiore non mostra né i pallini né lo spazio libero: parte direttamente dai comandi dell'app. È il comportamento scritto nel requisito. Costo: il margine iniziale della barra cambia su quelle piattaforme, da verificare sui tablet e nel browser a schermo largo.

### Lasciare uno spazio vuoto senza pallini

Su web, Android e iOS la barra mantiene lo stesso spazio riservato a macOS, senza disegnare i pulsanti. La disposizione dei comandi resta identica su tutte le piattaforme desktop. Costo: resta uno spazio vuoto che il requisito non prevede, e va deciso se è accettabile.

## Where in the code

lib/ui/shell/mac_title_bar.dart: i tre pulsanti della finestra sono disegnati ogni volta che la piattaforma non è macOS, anche su web, Android e iOS.
