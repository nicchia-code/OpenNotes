---
status: resolved
resolution: fix-code
refs:
  - text-line/In document
  - requirements/rules#text-line
proposal: null
task: luxeptsr
origin: null
critical: false
option: 1
note: null
resolvedBy: 37m9hzhb
created: 2026-10-13T05:46:23.799Z
---
# Aa style and checklist button strip any number of hash signs, not only # ## ###

## What happens

Scegliendo uno stile dal menu Aa (per esempio Corpo) oppure premendo il pulsante checklist su una riga che comincia con quattro o più cancelletti seguiti da spazio, il programma toglie anche quei cancelletti. Una riga «#### Riunione» diventa «Riunione» e il testo scritto dall'utente va perso.

## What should happen

Il Model dice che lo stile toglie solo i segni iniziali seguiti da spazio: «# », «## », «### », i simboli di elenco, i cerchi di checklist, «- », «* », «> » e i numeri con punto. I Requirements elencano le stesse scorciatoie. Un cancelletto ripetuto quattro volte non è un prefisso di nessuno di questi tipi, quindi deve restare nel testo.

## Fix options

### Togliere solo uno, due o tre cancelletti

Il menu Aa e il pulsante checklist tolgono «# », «## » e «### » seguiti da spazio, e nient'altro. Una riga con quattro o più cancelletti resta com'è e lo stile scelto si applica al testo intero. Costo: una piccola modifica al riconoscimento del prefisso, nei due punti che lo tolgono, più una prova con «#### » su Corpo e su checklist.

### Un solo riconoscimento dei prefissi

La regola dei prefissi viene scritta in un unico punto, usato dal menu Aa, dal pulsante checklist e dal menu di blocco, così che la lista dei segni resti uguale in tutti i comandi. Il comportamento è lo stesso dell'opzione precedente. Costo: un piccolo riordino del codice che tocca i punti dove oggi il prefisso è riconosciuto.

## Where in the code

lib/ui/editor/rich_text_editing_controller.dart: removeLinePrefixes e applyLinePrefix, dove l'espressione del prefisso accetta « #+ »
