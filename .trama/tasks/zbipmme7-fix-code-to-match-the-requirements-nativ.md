---
column: done
technical: false
refs:
  - app-window/Hidden
  - requirements/rules#app-window
drift: null
proposal: null
agent: false
created: 2026-10-13T14:19:44.081Z
finished: 2026-10-13T14:44:36.074Z
---
# Fix code to match the Requirements: native launch window size is not 1280 × 760

La finestra iniziale deve essere 1280 × 760 px, centrata, con dimensione minima 680 × 480 px. Oggi la dimensione è impostata correttamente dal codice Flutter prima che la finestra venga mostrata, ma le impostazioni native di avvio restano diverse: 1280 × 720 px su Linux e Windows, 800 × 600 px su macOS. Quando il lavoro è fatto, ogni piattaforma desktop avvia la finestra con le dimensioni richieste dal Requisito, senza che il valore dipenda dal codice Flutter, e la dimensione minima resta quella del Requisito.
