---
column: done
technical: false
refs:
  - sync-run/Waiting to retry
drift: null
proposal: null
agent: false
created: 2026-10-17T12:50:12.204Z
finished: 2026-10-17T14:51:42.164Z
---
# Fix code to match the Model: A start during the retry wait does not cancel the wait

# Comportamento atteso
Un avvio che arriva durante l'attesa di un nuovo tentativo annulla l'attesa e riprova subito. Se questo tentativo riesce, lo stato torna Idle: nessun altro giro parte dal vecchio timer e la sincronizzazione periodica riprende. Se il tentativo fallisce, le attese ricominciano dalla prima (2 s). Un giro completato azzera la serie.

# Stato attuale
Un avvio non annulla l'attesa. Dopo un tentativo riuscito partito dall'attesa, l'app risulta ancora in attesa fino allo scadere del vecchio timer, che avvia un altro giro, e la sincronizzazione periodica non viene riarmata. Se anche il tentativo immediato fallisce, la serie non riparte da 2 s ma prosegue (5 s, 15 s, ...).

# Fatto quando
Dopo un avvio dall'attesa che riesce, lo stato torna Idle senza giri dal vecchio timer; dopo un avvio dall'attesa che fallisce, il tentativo successivo è fra 2 s.
