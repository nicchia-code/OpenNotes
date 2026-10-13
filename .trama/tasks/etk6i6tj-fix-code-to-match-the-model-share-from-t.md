---
column: done
technical: false
refs:
  - export-markdown-share/Idle/user.SHARE_NOTE
  - note-content-save/Waiting
drift: null
proposal: null
agent: false
created: 2026-10-12T14:48:04.677Z
finished: 2026-10-12T16:36:41.456Z
---
# Fix code to match the Model: Share from the mobile note menu sends the saved copy, not the text just typed

Il menu azioni dell'editor mobile (il pulsante ⋯) prende la nota dai dati salvati nel database, non dalla versione in memoria che l'editor mostra. Per circa 400 ms dopo l'ultima modifica il database non contiene ancora il testo appena digitato: Condividi, e insieme a lui Duplica ed Esporta dallo stesso menu, lavora quindi su un testo vecchio. Quando il lavoro è finito, il menu azioni dell'editor mobile usa la versione della nota in memoria, quella aggiornata a ogni modifica, così Condividi produce il Markdown di ciò che l'utente vede anche mentre il salvataggio è in attesa. Stato, fissaggio, protezione, cartella e cestino restano letti dalla versione corrente.
