---
status: approved
kind: resolution
drifts:
  - drift: 59hgx4lz
    decision: proposal
  - drift: cpgukmgw
    decision: proposal
base:
  cloud-sync/account.md: cedc4a45d47675b0679938f028b4b746b2dae950b313bafcb78ca3f58640cc84
  cloud-sync/pending-change.md: 522f038e6e0c0357ff23b46483f03c991650c4fb82b8c525fa1abf54d65f4ede
delete: []
created: 2026-10-18T17:23:17.604Z
---
# Resolve sign-in confirmation and first-run queueing drifts

Risoluzione dei Drift:
- 59hgx4lz – SIGNED_IN con sessione mentre l'account è già connesso non è nel Model: il Model dell'account descrive la conferma dell'accesso arrivata da utente già connesso come un nuovo accesso, con sincronizzazione con controllo completo e canale in tempo reale riaperto (decisione: proposal).
- cpgukmgw – Primo giro dopo l'aggiornamento accoda le copie locali, il Model non lo prevede: la descrizione del cambiamento in attesa include la nascita di un salvataggio dal primo giro dopo l'aggiornamento, quando la copia locale vince sul cloud (decisione: proposal).
