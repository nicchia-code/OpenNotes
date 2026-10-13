---
status: approved
kind: resolution
automatic: true
drifts:
  - drift: ejiz1n2v
    decision: fix-code
    option: 1
  - drift: msjcrr4z
    decision: fix-code
    option: 1
  - drift: fcz91q99
    decision: fix-code
    option: 1
  - drift: i71xo66u
    decision: fix-code
    option: 1
  - drift: cerrfeu4
    decision: fix-code
    option: 1
  - drift: 7qptr503
    decision: fix-code
    option: 1
  - drift: lhps2n5p
    decision: fix-code
    option: 1
  - drift: jk4xujvl
    decision: fix-code
    option: 1
  - drift: nqsf733q
    decision: fix-code
    option: 1
  - drift: m3jlz8ca
    decision: fix-code
    option: 1
  - drift: rahn2hqx
    decision: fix-code
    option: 1
  - drift: mzj6nlf1
    decision: fix-code
    option: 1
  - drift: j7ta4iur
    decision: fix-code
    option: 1
base: {}
delete: []
created: 2026-10-12T17:59:56.773Z
---
# Automatic Drift resolution

Risoluzione automatica: per ogni Drift autorizzato viene scelta la prima opzione di correzione.

- D1 – Errore di scrittura del file Markdown non descritto nel Model: correzione 1, descrivere il messaggio di errore nel Model.
- D2 – Errore imprevisto all'avvio dell'accesso Google: correzione 1, mostrare «Accesso Google non completato» e restare disconnessi.
- D3 – Il rinnovo automatico della sessione avvia una sincronizzazione: correzione 1, rinnovare solo la sessione.
- D4 – Titolo rientrato nel PDF stampato come paragrafo: correzione 1, riconoscere il titolo anche se rientrato.
- D5 – Data nel PDF in UTC per le note arrivate dal cloud: correzione 1, convertire le date in ora locale alla lettura della nota.
- D6 – Modifica remota di una cartella eliminata qui: correzione 1, il canale ignora la modifica finché l'eliminazione è in coda.
- D7 – Svuotare il cestino elimina le note protette nascoste senza PIN: correzione 1, chiedere il PIN se nel cestino c'è almeno una nota protetta.
- D8 – Model dell'accesso ancora con il caso del vault: correzione 1, togliere il caso del vault dal Model dell'accesso.
- D9 – Model dell'accesso senza uscite per il lucchetto arrivato dal cloud: correzione 1, il lucchetto segue il cloud.
- D10 – Cartella eliminata nel cloud mentre offline: correzione 1, rimuovere le cartelle che il cloud non ha più.
- D11 – Cartella in coda modificata dopo l'eliminazione nel cloud: correzione 1, inviare sempre la modifica in coda.
- D12 – Salvataggio in coda di una nota con titolo di benvenuto: correzione 1, scrivere lo scarto nel Model.
- D13 – L'anteprima della nota mostra il nome del file delle immagini: correzione 1, escludere le immagini dall'anteprima.
