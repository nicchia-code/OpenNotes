---
column: done
technical: false
refs:
  - desktop-layout.SWITCHED_TO_MOBILE
  - desktop-layout.SWITCHED_TO_DESKTOP
  - mobile-navigation/Inactive
  - mobile-navigation/Active
drift: null
proposal: null
agent: false
created: 2026-10-17T18:11:59.557Z
finished: 2026-10-17T18:22:13.577Z
---
# Fix code to match the Model: Layout switch events reach no mobile navigation

Il Model dice che il passaggio tra interfaccia desktop e interfaccia mobile è un evento che la navigazione mobile riceve: passando a mobile la pila di schermate riparte dalla lista note con le Cartelle sotto, passando al desktop la pila viene scartata. Oggi il codice emette il passaggio come segnale verso un ascoltatore opzionale che nessuno collega nell'app: la navigazione mobile si costruisce solo dalla larghezza della finestra. Fare in modo che il passaggio arrivi davvero alla navigazione mobile come evento, con lo stesso effetto descritto nel Model, anche quando la finestra cambia larghezza più volte.
