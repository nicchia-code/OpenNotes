---
status: resolved
resolution: fix-code
refs:
  - desktop-layout
  - requirements/rules#app-window
proposal: null
task: 4kwe0lcd
origin: null
critical: false
option: 1
note: null
resolvedBy: fz9axufm
created: 2026-10-12T10:45:59.271Z
---
# Window controls drawn where the app has no window

## What happens

Su web, Android e iOS la barra superiore disegna comunque i pulsanti chiudi, riduci e ingrandisci, quando la larghezza permette l'interfaccia desktop (per esempio un tablet o una finestra del browser). Sono solo figure: toccarle non fa nulla, perché su quelle piattaforme non c'è una finestra da gestire. Su macOS lo spazio resta libero per i pulsanti nativi, come previsto.

## What should happen

Il Requisito della finestra dice che l'app disegna i pulsanti chiudi, riduci e ingrandisci **solo** su Linux e Windows, e che su macOS lascia 68 px liberi per i pulsanti nativi. Il Modello dice che su web, Android e iOS non c'è una finestra da gestire e i comandi della finestra non compaiono.

## Fix options

### Disegnare i pulsanti solo su Linux e Windows

Su web, Android e iOS la barra non mostra i pulsanti di finestra, e il titolo e i comandi della nota si spostano a sinistra. Su macOS e su Linux e Windows non cambia nulla. Costo: un controllo di piattaforma in più in un solo punto della barra, da mantenere quando si aggiungono sistemi.

### Tenere lo spazio dei pulsanti su tutte le piattaforme

Su web, Android e iOS la barra lascia libere le stesse prime posizioni di macOS, senza disegnare nulla. Così titolo e comandi restano nello stesso punto su ogni sistema. Costo: sui dispositivi touch resta una fascia vuota di 68 px, e il Requisito va esteso perché oggi lo spazio libero vale solo per macOS.

## Where in the code

lib/ui/shell/mac_title_bar.dart: blocco dei pulsanti della finestra in MacTitleBar.build, con il controllo della piattaforma
