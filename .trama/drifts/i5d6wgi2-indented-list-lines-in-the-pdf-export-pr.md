---
status: resolved
resolution: fix-code
refs:
  - requirements/rules#export-pdf
  - export-pdf/Idle/user.EXPORT_NOTE_AS_PDF
proposal: null
task: thqdgvdf
origin: null
critical: false
option: 1
note: null
resolvedBy: m16unv7j
created: 2026-10-12T11:20:50.247Z
---
# Indented list lines in the PDF export print their symbols as text

## What happens

Una riga di elenco o di casella rientrata nel testo di una nota in formato precedente (testo semplice con rientro) esce nel PDF come paragrafo: il simbolo resta scritto («- [ ] voce», «- voce») e il rientro viene conservato, senza cerchio né punto elenco.

## What should happen

Il Requirement dice che «- », «* » e «- [ ] » a inizio riga diventano punto elenco o cerchio, ma non dice come trattare le righe rientrate, che la conversione in Markdown conserva. Il Model non lo dice. Non si può seguire alla lettera senza decidere se il rientro va mostrato.

## Fix options

### Mostrare anche le righe rientrate come elenco

Il simbolo rientrato diventa punto elenco o cerchio, con lo stesso rientro a sinistra. Costo: piccolo, nel solo livello di impaginazione del PDF.

### Appiattire tutti gli elementi allo stesso livello

Il rientro viene ignorato e ogni voce è allo stesso livello. Costo: piccolo, ma il PDF perde la struttura visiva che aveva la nota.

### Lasciare i simboli come testo

Nessuna modifica: le righe rientrate restano paragrafi con il simbolo scritto. Costo zero, ma le note in testo semplice con rientro restano poco leggibili nel PDF.
