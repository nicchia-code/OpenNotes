---
column: done
technical: false
refs:
  - desktop-layout.SWITCHED_TO_MOBILE
  - desktop-layout.SWITCHED_TO_DESKTOP
  - desktop-layout/Starting
  - mobile-navigation/Inactive
  - mobile-navigation/Active
drift: null
proposal: null
agent: false
created: 2026-10-17T12:09:42.737Z
finished: 2026-10-17T12:26:56.908Z
---
# Signal switches between desktop and mobile layout

Quando l'interfaccia parte o passa in navigazione mobile perché la larghezza è sotto 680 px, il sistema deve emettere l'evento di passaggio alla navigazione mobile, così che la pila di schermate riparta dalla lista note. Quando la larghezza torna ad almeno 680 px e ricompare l'interfaccia desktop, deve emettere l'evento di ritorno, così che la pila di schermate venga scartata.
