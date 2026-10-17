---
column: done
technical: false
refs:
  - note-content-save/Waiting/user.DUPLICATE_NOTE
  - requirements/rules#note-content-save
drift: null
proposal: null
agent: false
created: 2026-10-17T19:22:38.345Z
finished: 2026-10-17T19:36:34.422Z
---
# Fix code to match the Model: Duplicate reads the note before a running content save ends

Duplicare una nota deve copiare il testo appena salvato, cioè quello visto sullo schermo. Oggi la copia legge la nota salvata subito dopo aver consegnato la versione in attesa: se una scrittura del contenuto è già in corso (partita dal tempo di attesa o da un'altra consegna), la copia può nascere dalla versione precedente. Il duplicato deve attendere le scritture in corso prima di leggere la nota, come già fanno fissaggio, blocco, cestino, ripristino e spostamento.
