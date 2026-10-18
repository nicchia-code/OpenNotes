# Operating System

Il sistema operativo del dispositivo: avvia l'app, la avvisa quando lascia il primo piano e quando torna visibile, segnala quando la rete va e viene, comunica lo spazio disponibile per la finestra e gestisce le finestre di sistema per condividere, salvare e stampare.

## Events

### APP_LAUNCHED
Il sistema operativo avvia l'app.

### APP_LEAVING_FOREGROUND
L'app va in secondo piano o sta per chiudersi, anche perché l'utente ha chiuso la finestra desktop.

### APP_RETURNED_TO_FOREGROUND
L'app torna visibile: su mobile torna in primo piano, su desktop la finestra viene ripristinata dopo essere stata ridotta a icona.

### NETWORK_AVAILABLE
Il sistema segnala che il dispositivo ha di nuovo una connessione di rete.

### NETWORK_LOST
Il sistema segnala che il dispositivo non ha nessuna connessione di rete, anche all'avvio dell'app.

### SHARE_SHEET_CLOSED
Il foglio di condivisione del sistema si chiude, dopo la condivisione o l'annullamento.

### FILE_SAVE_DIALOG_CLOSED
La finestra di salvataggio del sistema si chiude, con una posizione scelta (e il file scritto, oppure la scrittura non riuscita) oppure annullata.

### PRINT_DIALOG_CLOSED
La finestra di stampa del sistema si chiude, dopo stampa, salvataggio o annullamento.

### WINDOW_RESIZED
Cambia la larghezza disponibile per l'app (finestra ridimensionata, schermo ruotato).
