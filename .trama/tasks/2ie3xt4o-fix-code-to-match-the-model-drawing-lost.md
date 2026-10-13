---
column: done
technical: false
refs:
  - drawing-canvas/Drawing/user.SAVE_DRAWING
drift: x2x025cn
proposal: null
agent: false
created: 2026-10-12T11:27:34.805Z
finished: 2026-10-12T11:29:26.360Z
---
# Fix code to match the Model: Drawing lost without notice when the attachment cannot be saved

## What happens

Se il salvataggio del disegno tra gli allegati fallisce, la tela si chiude comunque. Il disegno va perso senza alcun avviso all'utente e la nota non riceve l'immagine. Lo stesso accade se la conversione in immagine non produce dati.

## What should happen

Il Model dice che «Fine» esporta, salva tra gli allegati e chiude la tela (SAVE_DRAWING → Closed), e che la nota riceve l'immagine solo dopo il salvataggio (DRAWING_SAVED). Non dice cosa succede se il salvataggio fallisce: il caso non è previsto, quindi il Model non può guidare la scelta.

## Chosen option

**Keep the canvas open on failure**

La tela resta aperta con il disegno e un messaggio d'errore, così l'utente può riprovare o annullare. Non si perde nulla. Cambia il Model: il passaggio SAVE_DRAWING → Closed vale solo se il salvataggio riesce, e va aggiunto il caso di errore.

## Where in the code

Il salvataggio del disegno in Dart: la chiamata di salvataggio non è attesa, quindi l'errore non viene gestito, e la chiusura della tela avviene subito dopo.
