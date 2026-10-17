---
column: done
technical: false
refs:
  - sync-run/Offline
drift: null
proposal: null
agent: false
created: 2026-10-17T12:50:11.373Z
finished: 2026-10-17T14:50:58.246Z
---
# Fix code to match the Model: Offline device still starts sync attempts

# Comportamento atteso
Quando il dispositivo non ha rete non parte nessun tentativo automatico: né alla perdita della rete, né al ritorno in primo piano, né alla fine di un giro fallito. Le richieste fatte a mano (Sincronizza Adesso, trascina-per-aggiornare) provano comunque. Un giro fallito con la rete assente passa a Offline e non a Waiting to retry.

# Stato attuale
Ogni segnale del sistema avvia un giro, anche la perdita della rete e il ritorno in primo piano senza rete. Un giro fallito programma sempre un nuovo tentativo, anche con la rete assente: il dispositivo offline ritenta a intervalli fino a 60 s.

# Fatto quando
Con la rete assente, perderla, tornare in primo piano o finire un giro fallito non avvia alcun giro e non programma alcun tentativo; il ritorno della rete avvia il giro, controllo completo se ne era stato ricordato uno.
