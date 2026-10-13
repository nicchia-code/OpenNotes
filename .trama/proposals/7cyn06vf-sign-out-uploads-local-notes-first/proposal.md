---
status: rejected
base:
  model/cloud-sync/account.md: new
  cloud-sync/account.md: fe84045a7fb14c9de74510e6578a37d997b21d97a328dbdfd9c867d52bb1bacc
delete: []
created: 2026-10-12T10:45:57.469Z
---
# Sign-out uploads local notes first

Il codice non disconnette l'account finché la coda dei cambiamenti e le note mai sincronizzate non sono caricate sul cloud: prima della disconnessione viene eseguita una sincronizzazione, e se restano elementi non caricati la disconnessione viene annullata con un messaggio. È la scelta presa con la Drift sulle note locali e l'account (opzione «Il dispositivo parte dal nuovo account»), ma il Model dice solo che la disconnessione chiude la sessione e lascia le note sul dispositivo. Questa Proposal aggiunge il caricamento e l'annullamento alla Transition user.SIGN_OUT dello stato Signed in.

Decisioni:
- Il caricamento precede la chiusura della sessione e la finestra mostra «Caricamento delle note locali sul cloud...».
- Se un cambiamento o una nota non può essere caricato, l'account resta connesso e la finestra mostra «Non è stato possibile caricare le note sul cloud: disconnessione annullata.».
- Quando la disconnessione riesce, la coda è vuota per costruzione: le note locali restano sul dispositivo.
- Assunzione da verificare: la disconnessione annullata anche quando non c'è connessione, come oggi nel codice.

## Feedback

Drift 4ayj8yov resolved by Proposal fz9axufm
