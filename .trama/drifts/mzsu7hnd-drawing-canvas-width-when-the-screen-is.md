---
status: resolved
resolution: fix-code
refs:
  - drawing-canvas
proposal: null
task: feb3p0e3
origin: null
critical: false
option: 1
note: null
resolvedBy: g08cr3wn
created: 2026-10-12T14:47:25.308Z
---
# Drawing canvas width when the screen is short

## What happens

La tela ha sempre proporzioni 4:3 e, se lo spazio in altezza è poco (una finestra desktop bassa, un telefono in orizzontale), resta più stretta dello spazio disponibile: ai lati compaiono margini grigi, e il disegno occupa solo una parte della larghezza. Il codice mantiene il 4:3 prima della larghezza.

## What should happen

Il Model dice due cose insieme: la tela ha proporzioni 4:3, e occupa la larghezza disponibile. Quando l'altezza non basta per tutte e due, il Model non dice quale vince né se la tela può essere raggiunta scorrendo. Il requisito di dimensione dell'immagine esportata, 800×600, resta valido in ogni caso e non è in discussione.

## Fix options

### Keep 4:3 and say so in the Model

La tela resta 4:3 e centrata; sugli schermi bassi lascia margini laterali, come oggi. Per l'utente non cambia nulla e tutto il disegno resta raggiungibile senza scorrere. Il Model va precisato: la larghezza piena vale quando c'è spazio in altezza. Costo: sulle finestre basse la tela occupa meno della larghezza disponibile.

### Fill the width and scroll vertically

La tela occupa tutta la larghezza mantenendo il 4:3, e sugli schermi bassi si scorre in verticale per raggiungere la parte inferiore. Rispetta la frase del Model sulla larghezza. Costo: scorrere può confliggere con il tratto del dito o della penna, e torna il problema già risolto di una parte della tela non raggiungibile con il tocco.

### Fill the width and drop 4:3 on short screens

La tela occupa sempre tutta la larghezza e si adatta all'altezza disponibile, rinunciando al 4:3 sugli schermi bassi. Non servono scorrimenti. Costo: la tela su schermo ha un'altra proporzione rispetto all'immagine salvata, che resta 800×600; il disegno appare allungato o schiacciato rispetto al risultato finale.

## Where in the code

lib/ui/drawing/apple_pencil_canvas.dart: il layout della tela (AspectRatio dentro Expanded), che sull'altezza disponibile limita la larghezza.
