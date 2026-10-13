---
column: done
technical: false
refs:
  - text-line/In document/user.SET_TEXT_STYLE
  - requirements/rules#text-line
drift: null
proposal: null
agent: false
created: 2026-10-12T11:42:51.480Z
finished: 2026-10-12T14:08:25.833Z
---
# Fix code to match the Model: Text style menu strips a hash, dash or angle bracket that has no space after it

Scegliere uno stile dal menu Aa su una riga che comincia con « # » senza spazio, per esempio il tag «#lavoro», oppure con «-», «*» o «>» senza spazio dopo, per esempio «-5 gradi», toglie quel carattere: il tag della nota scompare e il testo perde la prima lettera. Il Modello dice che lo stile toglie i simboli iniziali; un simbolo di elenco, di intestazione o di citazione è il segno seguito da spazio («- », «* », «# », «> »), come stabilito per Tab e Invio, e un tag «#nome» all'inizio di una riga resta un tag secondo la regola dei tag. Correggere i punti in cui si tolgono i prefissi (stile dal menu Aa e pulsante checklist) in modo che tolgano solo il segno seguito da spazio, lasciando intatti il tag e il testo che comincia con un trattino, un asterisco o un maggiore senza spazio.
