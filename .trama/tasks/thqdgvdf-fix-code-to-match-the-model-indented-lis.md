---
column: done
technical: false
refs:
  - requirements/rules#export-pdf
  - export-pdf/Idle/user.EXPORT_NOTE_AS_PDF
drift: i5d6wgi2
proposal: null
agent: false
created: 2026-10-12T11:27:34.820Z
finished: 2026-10-12T11:28:56.295Z
---
# Fix code to match the Model: Indented list lines in the PDF export print their symbols as text

## What happens

Una riga di elenco o di casella rientrata nel testo di una nota in formato precedente (testo semplice con rientro) esce nel PDF come paragrafo: il simbolo resta scritto («- [ ] voce», «- voce») e il rientro viene conservato, senza cerchio né punto elenco.

## What should happen

Il Requirement dice che «- », «* » e «- [ ] » a inizio riga diventano punto elenco o cerchio, ma non dice come trattare le righe rientrate, che la conversione in Markdown conserva. Il Model non lo dice. Non si può seguire alla lettera senza decidere se il rientro va mostrato.

## Chosen option

**Mostrare anche le righe rientrate come elenco**

Il simbolo rientrato diventa punto elenco o cerchio, con lo stesso rientro a sinistra. Costo: piccolo, nel solo livello di impaginazione del PDF.
