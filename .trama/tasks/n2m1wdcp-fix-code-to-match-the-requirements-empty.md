---
column: done
technical: false
refs:
  - export-pdf/Idle/user.EXPORT_NOTE_AS_PDF
drift: null
proposal: null
agent: false
created: 2026-10-12T14:49:42.662Z
finished: 2026-10-12T16:27:43.580Z
---
# Fix code to match the Requirements: Empty heading line in the PDF export takes no heading height

Nel PDF di una nota, un'intestazione vuota (« # », « ## » o « ### » senza testo) viene impaginata con il solo spazio di padding attorno, perché il testo vuoto non occupa alcuna altezza di riga: il corpo passa da 16 punti invece dell'altezza di riga del titolo, 18, 15 o 13 punti in grassetto. Il Requirement dice che un segno vuoto conserva il suo aspetto e che un'intestazione vuota resta un'intestazione: l'intestazione deve occupare la sua riga, come le caselle e i punti vuoti che occupano il cerchio o il punto. Correggere in lib/core/services/pdf_export_service.dart, ramo delle intestazioni, in modo che il testo vuoto abbia l'altezza della riga dello stile di intestazione.
