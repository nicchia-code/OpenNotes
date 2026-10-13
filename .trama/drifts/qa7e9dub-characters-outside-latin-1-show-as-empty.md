---
status: resolved
resolution: fix-code
refs:
  - export-pdf/Idle/user.EXPORT_NOTE_AS_PDF
proposal: null
task: uwihrytg
origin: null
critical: false
option: 1
note: null
resolvedBy: g08cr3wn
created: 2026-10-12T14:49:55.979Z
---
# Characters outside Latin-1 show as empty boxes in the PDF

## What happens

Una nota con virgolette curve, trattini lunghi, simbolo dell'euro, lettere di altri alfabeti o emoji esce nel PDF con un riquadro vuoto al posto di ciascuno di quei caratteri. Il resto del testo è corretto e il documento si apre comunque.

## What should happen

Il Model e il Requirement dicono che il PDF impagina il testo della nota, ma non dicono quali caratteri deve mostrare né con quale carattere. Con il font predefinito del PDF, per le lingue e i simboli fuori dal Latin-1 il testo non è leggibile, e la nota non viene esportata come l'utente se la aspetta.

## Fix options

### Incorporare un font Unicode

Il PDF usa un font con tutti i caratteri, incluso in un file dei font dell'app. Mostra ogni carattere della nota come nell'editor. Costo: un file di font in più nell'app, più peso del pacchetto.

### Sostituire i caratteri mancanti

Virgolette, trattini, euro e simili diventano equivalenti ASCII, gli altri caratteri diventano « ? ». Nessun file in più, ma il testo nel PDF non è identico alla nota e le lingue non latine restano illeggibili.

### Dichiarare i caratteri mancanti

Nessuna modifica al codice: il Model e il Requirement scrivono che i caratteri fuori dal Latin-1 compaiono come riquadri vuoti. Costo zero, ma il documento resta difettoso per molte note reali.

## Where in the code

lib/core/services/pdf_export_service.dart: pw.Text senza font e senza fontFallback; il tema predefinito del pacchetto pdf usa Helvetica, che copre solo il Latin-1
