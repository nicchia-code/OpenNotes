---
column: done
technical: false
refs:
  - note/Active
  - requirements/rules#note
  - requirements/data#note
drift: null
proposal: null
agent: false
created: 2026-10-12T14:53:09.774Z
finished: 2026-10-12T16:33:23.905Z
---
# Fix code to match the Requirements: Note list order compares modification dates as text across time zones

L'elenco delle note deve mostrare prima le fissate, poi le altre per data di modifica decrescente. Oggi l'ordinamento confronta come testo le date salvate sul dispositivo: quelle scritte localmente non hanno il fuso orario, quelle ricevute dal cloud hanno il fuso UTC («Z»). Con un fuso diverso da UTC una nota modificata da poco può finire sotto una modificata prima, e lo stesso confronto testuale sceglie il file del vault per le note che lo condividono. Quando il lavoro è finito, le date di modifica delle note vengono confrontate come istanti (o salvate tutte nello stesso formato), e l'ordine dell'elenco segue la data di modifica reale, sia per le note create sul dispositivo sia per quelle ricevute dal cloud. La stessa causa è alla base del Task sulle date inviate al cloud senza fuso: le due correzioni vanno fatte insieme, con una sola scelta di formato.
