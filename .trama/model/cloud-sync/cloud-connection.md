# Cloud connection

Il collegamento dell'app al progetto cloud, definito da un indirizzo del progetto e da una chiave pubblica forniti al momento della compilazione dell'app; non esistono valori predefiniti e nulla viene salvato sul dispositivo. Ce n'è uno per installazione e viene preparato a ogni avvio.

## States

### Not configured (initial)
Il collegamento non è pronto: accesso, sincronizzazione e canale in tempo reale non sono disponibili.
- `operating-system.APP_LAUNCHED` → Configuring: solo se la build fornisce sia l'indirizzo sia la chiave. Segnala l'app come occupata in sincronizzazione.
- `operating-system.APP_LAUNCHED` → Not configured: se la build non fornisce l'indirizzo, la chiave o entrambi; mostra una volta l'avviso di cloud non configurato, che nomina ciò che manca. L'app resta pienamente usabile sul dispositivo.

### Configuring
Il collegamento viene preparato con indirizzo e chiave privati degli spazi iniziali e finali. Se era già stato preparato durante questa esecuzione, l'errore viene ignorato e si prosegue come se fosse riuscito.
- `CONFIGURED` → Configured: comincia ad ascoltare i cambi di stato dell'account e toglie il segnale di occupato.
- `CONFIGURATION_FAILED` → Not configured: toglie il segnale di occupato; l'utente non viene avvisato.

### Configured
Il collegamento è pronto e resta tale fino alla chiusura dell'app. L'app non offre modo di cambiarlo o rimuoverlo.

## Events

### CONFIGURED
Emesso quando il collegamento è pronto. Se in quel momento un utente risulta già connesso da una sessione precedente, viene aperto il canale in tempo reale e viene chiesta una sincronizzazione, che però è ignorata perché il segnale di occupato è ancora attivo. Alla fine l'app ricarica cartelle, tag ed elenco delle note.

### CONFIGURATION_FAILED
Emesso quando la preparazione fallisce in modo imprevisto.
