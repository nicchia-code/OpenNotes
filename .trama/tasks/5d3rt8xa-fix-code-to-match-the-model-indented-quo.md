---
column: done
technical: false
refs:
  - text-line/Quote
  - text-line/Monospace
drift: null
proposal: null
agent: false
created: 2026-10-12T11:42:45.179Z
finished: 2026-10-12T14:04:40.521Z
---
# Fix code to match the Model: Indented quote and monospace lines reload with a second sign

Una citazione o un monospazio rientrato con Tab, per esempio « > testo» o «  ``` codice», resta del suo tipo, come da decisione sul Tab. Però al caricamento della nota il segno viene aggiunto una seconda volta davanti alla riga: «>   > testo» e «```   ``` codice». Il Modello dice che una riga caricata parte nel tipo che si ricava dal contenuto: la riga deve riapparire com'è, con il suo rientro e un solo segno, come già avviene per le righe senza rientro.
