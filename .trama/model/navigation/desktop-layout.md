# Desktop Layout

La disposizione dell'interfaccia principale secondo la larghezza disponibile: interfaccia desktop a colonne oppure navigazione mobile a schermate. Nell'interfaccia desktop le colonne sono la barra laterale (cartelle, tag, cestino), la lista delle note e l'editor della nota selezionata, o l'avviso "Nessuna nota selezionata" se non ce n'è una. In alto una barra unica porta i comandi della finestra, il pulsante per mostrare o nascondere la barra laterale, il nome della vista corrente, i comandi di formattazione e quelli della nota (solo con una nota selezionata; nel cestino restano il menu azioni, il pulsante di protezione e quello di eliminazione) e il pulsante "Nuova nota" (nascosto nel cestino). Ricorda per tutta la sessione se l'utente ha mostrato o nascosto a mano la barra laterale, anche mentre l'interfaccia è mobile.

## States

### Starting (initial)
L'interfaccia non è ancora mostrata: l'app sta preparando l'archivio locale, l'eventuale sincronizzazione iniziale e le note di benvenuto.
- `operating-system.APP_LAUNCHED` → Auto three columns: a preparazione finita, se la larghezza è almeno 960 px.
- `operating-system.APP_LAUNCHED` → Auto two columns: a preparazione finita, se la larghezza è tra 680 e 959 px.
- `operating-system.APP_LAUNCHED` → Auto mobile: a preparazione finita, se la larghezza è sotto 680 px; segnala il passaggio all'interfaccia mobile.

### Automatic sidebar
L'utente non ha ancora mostrato né nascosto la barra laterale in questa sessione: la sua visibilità segue la larghezza.

#### Auto three columns (initial)
Interfaccia desktop con barra laterale, lista note ed editor.
- `operating-system.WINDOW_RESIZED` → Auto two columns: se la larghezza scende sotto 960 px restando almeno 680 px; la barra laterale si nasconde.
- `operating-system.WINDOW_RESIZED` → Auto mobile: se la larghezza scende sotto 680 px; segnala il passaggio all'interfaccia mobile.
- `user.TOGGLE_SIDEBAR` → Forced two columns: nasconde la barra laterale; da qui in poi la scelta dell'utente prevale sulla larghezza.

#### Auto two columns
Interfaccia desktop senza barra laterale: lista note ed editor.
- `operating-system.WINDOW_RESIZED` → Auto three columns: se la larghezza arriva ad almeno 960 px; la barra laterale ricompare.
- `operating-system.WINDOW_RESIZED` → Auto mobile: se la larghezza scende sotto 680 px; segnala il passaggio all'interfaccia mobile.
- `user.TOGGLE_SIDEBAR` → Forced three columns: mostra la barra laterale; da qui in poi la scelta dell'utente prevale sulla larghezza.

#### Auto mobile
È mostrata la navigazione mobile a schermate; la barra superiore desktop non c'è.
- `operating-system.WINDOW_RESIZED` → Auto three columns: se la larghezza torna ad almeno 960 px; segnala il ritorno all'interfaccia desktop.
- `operating-system.WINDOW_RESIZED` → Auto two columns: se la larghezza torna tra 680 e 959 px; segnala il ritorno all'interfaccia desktop.

### Sidebar forced visible
L'utente ha mostrato la barra laterale: resta visibile a qualsiasi larghezza desktop per il resto della sessione.

#### Forced three columns (initial)
Interfaccia desktop con barra laterale, lista note ed editor, anche sotto 960 px.
- `user.TOGGLE_SIDEBAR` → Forced two columns: nasconde la barra laterale.
- `operating-system.WINDOW_RESIZED` → Forced visible mobile: se la larghezza scende sotto 680 px; segnala il passaggio all'interfaccia mobile.

#### Forced visible mobile
È mostrata la navigazione mobile a schermate; la scelta di mostrare la barra laterale resta in memoria.
- `operating-system.WINDOW_RESIZED` → Forced three columns: se la larghezza torna ad almeno 680 px; segnala il ritorno all'interfaccia desktop.

### Sidebar forced hidden
L'utente ha nascosto la barra laterale: resta nascosta a qualsiasi larghezza desktop per il resto della sessione.

#### Forced two columns (initial)
Interfaccia desktop senza barra laterale, anche da 960 px in su.
- `user.TOGGLE_SIDEBAR` → Forced three columns: mostra la barra laterale.
- `operating-system.WINDOW_RESIZED` → Forced hidden mobile: se la larghezza scende sotto 680 px; segnala il passaggio all'interfaccia mobile.

#### Forced hidden mobile
È mostrata la navigazione mobile a schermate; la scelta di nascondere la barra laterale resta in memoria.
- `operating-system.WINDOW_RESIZED` → Forced two columns: se la larghezza torna ad almeno 680 px; segnala il ritorno all'interfaccia desktop.

## Events

### SWITCHED_TO_MOBILE
Emesso quando l'interfaccia parte o passa in navigazione mobile perché la larghezza è sotto 680 px.

### SWITCHED_TO_DESKTOP
Emesso quando, dalla navigazione mobile, la larghezza torna ad almeno 680 px e ricompare l'interfaccia desktop.
