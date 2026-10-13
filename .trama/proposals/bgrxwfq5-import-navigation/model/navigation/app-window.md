# App Window

La finestra dell'app sui sistemi desktop (Linux, macOS, Windows), senza la barra del titolo di sistema. Su web, Android e iOS non c'è una finestra da gestire e resta nascosta.

## States

### Hidden (initial)
La finestra non è ancora visibile.
- `operating-system.APP_LAUNCHED` → Open: solo su Linux, macOS e Windows; prepara la finestra senza barra del titolo di sistema, nella dimensione iniziale, centrata e con la dimensione minima, poi la mostra e le dà il focus, mentre l'app finisce di prepararsi.

### Open
La finestra è visibile. La barra superiore dell'interfaccia desktop fa da maniglia; nell'interfaccia mobile quella barra non c'è e nemmeno i comandi della finestra.
- `user.DRAG_WINDOW` → Open: sposta la finestra seguendo il trascinamento.
- `user.TOGGLE_WINDOW_MAXIMIZED` → Open: se la finestra non è ingrandita la ingrandisce, altrimenti la riporta alla dimensione normale.
- `user.MINIMIZE_WINDOW` → Open: solo su Linux e Windows; riduce la finestra a icona.
- `user.CLOSE_WINDOW` → Closed: solo su Linux e Windows; chiude la finestra e l'app.

### Closed (final)
