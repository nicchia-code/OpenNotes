---
column: done
technical: false
refs:
  - pending-change
  - user.RETRY_SET_ASIDE_CHANGE
  - user.USE_CLOUD_VERSION
  - requirements/rules#pending-change
drift: null
proposal: 634nfp49
agent: false
created: 2026-10-17T10:33:15.023Z
finished: 2026-10-17T14:01:34.149Z
---
# Pending change queue

La coda dei cambiamenti segue la macchina `pending-change` aggiornata.

- Al più un elemento per nota o cartella: un nuovo salvataggio aggiorna quello in attesa (stessa posizione, stessa revisione di base, nuovo momento di ingresso, rifiuti azzerati, non più messo da parte); un'eliminazione definitiva prende il posto del salvataggio in attesa; le note spostate in "Note" dall'eliminazione di una cartella entrano in coda.
- Ogni rifiuto viene contato con il suo messaggio; al terzo di fila l'elemento è messo da parte e l'invio lo salta.
- "Riprova" lo rimette in coda con i rifiuti azzerati e chiede un giro; "Usa la versione del cloud", solo se il cloud ha una copia non eliminata, lo toglie e chiede un giro che scarica e applica quella copia.
- Quando il canale in tempo reale rimuove una nota perché la sua eliminazione nel cloud è più recente, le sue modifiche in attesa vengono tolte subito dalla coda, senza attendere la sincronizzazione.
- Scarti come elencati nei Requirement; a ogni accodamento, con un utente connesso, parte subito una sincronizzazione senza attenderla.

Fatto quando dieci salvataggi della stessa nota lasciano un solo elemento in coda e un elemento rifiutato tre volte non impedisce l'invio degli altri né il download.
