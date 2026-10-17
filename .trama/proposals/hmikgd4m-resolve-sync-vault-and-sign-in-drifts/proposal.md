---
status: approved
kind: resolution
drifts:
  - drift: fwx4riy5
    decision: fix-code
    option: 1
  - drift: w5pmekbh
    decision: fix-code
    option: 1
  - drift: tlbubeh0
    decision: fix-code
    option: 1
  - drift: xhfe0bj1
    decision: fix-code
    option: 3
  - drift: f2g32s8g
    decision: fix-code
    option: 1
  - drift: sjc4b5p9
    decision: proposal
base:
  cloud-sync/pending-change.md: 8bd947202ac527a3a4922e48286d184f87308ada74d9aad99fca9d5a5aff2193
  cloud-sync/sync-run.md: 5ab9c764f177fa5e14df30b382df8902a8776a06b0f8754500148619818808bd
delete: []
created: 2026-10-17T18:37:48.739Z
---
# Resolve sync, vault and sign-in Drifts

Risoluzione dei Drift su accesso, vault e sincronizzazione, secondo le risposte del developer.

- fwx4riy5 Accesso a Google irraggiungibile su desktop senza ingranaggio: correggere il codice, con una voce «Accedi» nella barra laterale quando nessun utente è connesso.
- w5pmekbh Vault file keeps the old folder of notes moved by a folder deletion: correggere il codice, riscrivendo subito la copia nel vault di ogni nota spostata nella cartella Note.
- tlbubeh0 Accesso fatto senza rete: la finestra annuncia una sincronizzazione mai partita: correggere il codice, senza annunciare alcun esito quando l'accesso non avvia una sincronizzazione.
- xhfe0bj1 A note refused by the cloud during the unsynced sweep fails the whole sync run: correggere il codice, mettendo in coda le note mai sincronizzate prima dell'invio.
- f2g32s8g A connection dropped during a cloud answer is reported as an unexpected error: correggere il codice, riconoscendo come rete ogni errore di trasporto del client HTTP.
- sjc4b5p9 Account switch leaves a queued delete of an already removed note, which the new account cannot clear: adottare le modifiche della Proposal allegata, che al cambio di account scarta senza invio anche queste cancellazioni.
