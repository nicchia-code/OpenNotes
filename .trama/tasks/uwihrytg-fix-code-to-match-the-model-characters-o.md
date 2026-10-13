---
column: done
technical: false
refs:
  - export-pdf/Idle/user.EXPORT_NOTE_AS_PDF
drift: qa7e9dub
proposal: null
agent: false
created: 2026-10-12T14:57:05.758Z
finished: 2026-10-12T15:00:25.845Z
---
# Fix code to match the Model: Characters outside Latin-1 show as empty boxes in the PDF

## What happens

Una nota con virgolette curve, trattini lunghi, simbolo dell'euro, lettere di altri alfabeti o emoji esce nel PDF con un riquadro vuoto al posto di ciascuno di quei caratteri. Il resto del testo è corretto e il documento si apre comunque.

## What should happen

Il Model e il Requirement dicono che il PDF impagina il testo della nota, ma non dicono quali caratteri deve mostrare né con quale carattere. Con il font predefinito del PDF, per le lingue e i simboli fuori dal Latin-1 il testo non è leggibile, e la nota non viene esportata come l'utente se la aspetta.

## Chosen option

**Incorporare un font Unicode**

Il PDF usa un font con tutti i caratteri, incluso in un file dei font dell'app. Mostra ogni carattere della nota come nell'editor. Costo: un file di font in più nell'app, più peso del pacchetto.

## Where in the code

lib/core/services/pdf_export_service.dart: pw.Text senza font e senza fontFallback; il tema predefinito del pacchetto pdf usa Helvetica, che copre solo il Latin-1
