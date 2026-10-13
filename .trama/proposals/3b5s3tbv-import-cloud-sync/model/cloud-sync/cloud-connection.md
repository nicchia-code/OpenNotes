# Cloud connection

Il collegamento dell'app al progetto cloud, definito da un indirizzo del progetto e da una chiave pubblica salvati sul dispositivo. Ce n'è uno per installazione e viene preparato a ogni avvio.

## States

### Not configured (initial)
Il collegamento non è pronto: accesso, sincronizzazione e canale in tempo reale non sono disponibili.
- `operating-system.APP_LAUNCHED` → Configuring: solo se l'indirizzo e la chiave salvati, oppure in loro assenza quelli predefiniti della build, non sono vuoti. Segnala l'app come occupata in sincronizzazione.

### Configuring
Il collegamento viene preparato con indirizzo e chiave privati degli spazi iniziali e finali. Se era già stato preparato durante questa esecuzione, l'errore viene ignorato e si prosegue come se fosse riuscito.
- `CONFIGURED` → Configured: salva indirizzo e chiave sul dispositivo, comincia ad ascoltare i cambi di stato dell'account e toglie il segnale di occupato.
- `CONFIGURATION_FAILED` → Not configured: toglie il segnale di occupato; l'utente non viene avvisato.

### Configured
Il collegamento è pronto e resta tale fino alla chiusura dell'app. L'app non offre modo di cambiarlo o rimuoverlo.

## Events

### CONFIGURED
Emesso quando il collegamento è pronto. Se in quel momento un utente risulta già connesso da una sessione precedente, viene aperto il canale in tempo reale e viene chiesta una sincronizzazione, che però è ignorata perché il segnale di occupato è ancora attivo. Alla fine l'app ricarica cartelle, tag ed elenco delle note.

### CONFIGURATION_FAILED
Emesso quando la preparazione o il salvataggio delle impostazioni fallisce in modo imprevisto.
