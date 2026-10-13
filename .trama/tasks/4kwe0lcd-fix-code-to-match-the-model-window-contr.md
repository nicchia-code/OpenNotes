---
column: done
technical: false
refs:
  - desktop-layout
  - requirements/rules#app-window
drift: 7a72hq9d
proposal: null
agent: false
created: 2026-10-12T10:59:40.503Z
finished: 2026-10-12T11:05:57.678Z
---
# Fix code to match the Model: Window controls drawn where the app has no window

## What happens

Su web, Android e iOS la barra superiore disegna comunque i pulsanti chiudi, riduci e ingrandisci, quando la larghezza permette l'interfaccia desktop (per esempio un tablet o una finestra del browser). Sono solo figure: toccarle non fa nulla, perché su quelle piattaforme non c'è una finestra da gestire. Su macOS lo spazio resta libero per i pulsanti nativi, come previsto.

## What should happen

Il Requisito della finestra dice che l'app disegna i pulsanti chiudi, riduci e ingrandisci **solo** su Linux e Windows, e che su macOS lascia 68 px liberi per i pulsanti nativi. Il Modello dice che su web, Android e iOS non c'è una finestra da gestire e i comandi della finestra non compaiono.

## Chosen option

**Disegnare i pulsanti solo su Linux e Windows**

Su web, Android e iOS la barra non mostra i pulsanti di finestra, e il titolo e i comandi della nota si spostano a sinistra. Su macOS e su Linux e Windows non cambia nulla. Costo: un controllo di piattaforma in più in un solo punto della barra, da mantenere quando si aggiungono sistemi.

## Where in the code

lib/ui/shell/mac_title_bar.dart: blocco dei pulsanti della finestra in MacTitleBar.build, con il controllo della piattaforma
