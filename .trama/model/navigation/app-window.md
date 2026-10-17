# App Window

La finestra dell'app sui sistemi desktop (Linux, macOS, Windows), senza la barra del titolo di sistema, nemmeno sui desktop Linux il cui compositore la aggiungerebbe da solo. Su web, Android e iOS non c'è una finestra da gestire e resta nascosta.

## States

### Hidden (initial)
La finestra non è ancora visibile; resta nascosta anche mentre l'app si prepara.
- `operating-system.APP_LAUNCHED` → Open: solo su Linux, macOS e Windows; prepara la finestra senza barra del titolo di sistema, nella dimensione iniziale, centrata e con la dimensione minima, la tiene nascosta finché l'app ha finito di prepararsi e l'interfaccia è disegnata, poi la mostra e le dà il focus.

### Open
La finestra è visibile, senza barra del titolo di sistema. La barra superiore dell'interfaccia desktop fa da maniglia; nell'interfaccia mobile quella barra non c'è e nemmeno i comandi della finestra. Se un sistema disegna comunque la propria barra del titolo, la barra superiore dell'app resta com'è.
- `user.DRAG_WINDOW` → Open: sposta la finestra seguendo il trascinamento.
- `user.TOGGLE_WINDOW_MAXIMIZED` → Open: se la finestra non è ingrandita la ingrandisce, altrimenti la riporta alla dimensione normale.
- `user.MINIMIZE_WINDOW` → Open: solo su Linux e Windows; riduce la finestra a icona.
- `user.RESIZE_WINDOW` → Open: solo su Linux e solo se la finestra non è ingrandita, a schermo intero o affiancata a tassello dal sistema; cambia la dimensione della finestra seguendo il trascinamento del bordo o dell'angolo afferrato, senza scendere sotto la dimensione minima.
- `user.CLOSE_WINDOW` → Closed: su Linux e Windows dal pulsante rosso dell'app, su macOS dal pulsante di chiusura nativo; prima le modifiche in attesa vengono consegnate e scritte, poi chiude la finestra e termina l'app.

### Closed (final)
