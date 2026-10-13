---
column: done
technical: false
refs:
  - export-pdf/Idle/user.EXPORT_NOTE_AS_PDF
  - requirements/rules#export-pdf
drift: i71xo66u
proposal: null
agent: false
created: 2026-10-12T18:00:24.455Z
finished: 2026-10-12T18:02:19.919Z
---
# Fix code to match the Model: Titolo rientrato nel PDF stampato come paragrafo

## What happens

Una riga di intestazione rientrata, per esempio «  # Titolo» in una nota in testo semplice, esce nel PDF come paragrafo di 11 punti con il simbolo «#» scritto nel testo. Non diventa intestazione di 18, 15 o 13 punti. Il rientro delle voci di elenco e di checklist, invece, sposta la voce a destra.

## What should happen

Il Requirement dice che « # », « ## » e « ### » a inizio riga diventano intestazioni, e che il rientro sposta a destra solo le voci di elenco e di checklist. Non dice che cosa fare di una riga di intestazione rientrata, che la conversione in Markdown conserva così com'è. Il Model tace su questo caso.

## Chosen option

**Riconoscere il titolo anche se rientrato**

Il simbolo di intestazione viene riconosciuto dopo il rientro, come per le voci di elenco, e la riga diventa intestazione con lo stesso rientro. Costo: piccolo, solo nel livello di impaginazione del PDF.

## Where in the code

lib/core/services/pdf_export_service.dart: i controlli hasMarker(line, '# '), '## ' e '### ' usano la riga non rientrata, mentre gli elenchi usano bullet senza rientro.
