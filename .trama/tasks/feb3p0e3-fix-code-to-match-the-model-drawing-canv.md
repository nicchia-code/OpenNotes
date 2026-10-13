---
column: done
technical: false
refs:
  - drawing-canvas
drift: mzsu7hnd
proposal: null
agent: false
created: 2026-10-12T14:57:05.705Z
finished: 2026-10-12T14:59:03.158Z
---
# Fix code to match the Model: Drawing canvas width when the screen is short

## What happens

La tela ha sempre proporzioni 4:3 e, se lo spazio in altezza è poco (una finestra desktop bassa, un telefono in orizzontale), resta più stretta dello spazio disponibile: ai lati compaiono margini grigi, e il disegno occupa solo una parte della larghezza. Il codice mantiene il 4:3 prima della larghezza.

## What should happen

Il Model dice due cose insieme: la tela ha proporzioni 4:3, e occupa la larghezza disponibile. Quando l'altezza non basta per tutte e due, il Model non dice quale vince né se la tela può essere raggiunta scorrendo. Il requisito di dimensione dell'immagine esportata, 800×600, resta valido in ogni caso e non è in discussione.

## Chosen option

**Keep 4:3 and say so in the Model**

La tela resta 4:3 e centrata; sugli schermi bassi lascia margini laterali, come oggi. Per l'utente non cambia nulla e tutto il disegno resta raggiungibile senza scorrere. Il Model va precisato: la larghezza piena vale quando c'è spazio in altezza. Costo: sulle finestre basse la tela occupa meno della larghezza disponibile.

## Where in the code

lib/ui/drawing/apple_pencil_canvas.dart: il layout della tela (AspectRatio dentro Expanded), che sull'altezza disponibile limita la larghezza.
