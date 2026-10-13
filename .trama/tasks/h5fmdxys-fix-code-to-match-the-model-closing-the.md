---
column: done
technical: false
refs:
  - app-window/Closed
  - app-window/Open
drift: qgo39bsl
proposal: null
agent: false
created: 2026-10-12T11:27:34.858Z
finished: 2026-10-12T11:32:22.457Z
---
# Fix code to match the Model: Closing the macOS window with its native button quits the app; the Model has no macOS close

## What happens

Su macOS il pulsante di chiusura nativo chiude la finestra, e quando non ne resta nessuna l'app termina. Lo stato Chiusa non viene descritto per macOS, e il comando di chiusura del Modello vale solo per Linux e Windows.

## What should happen

Il Modello non dice cosa succede alla chiusura della finestra su macOS: il comando di chiusura è limitato a Linux e Windows e il Requisito dice solo che i pulsanti su macOS sono quelli nativi. Non si può stabilire dal Modello se la chiusura deve terminare l'app come sugli altri sistemi o lasciarla attiva come di consueto su macOS.

## Chosen option

**Terminare l'app alla chiusura, come su Linux e Windows**

Il pulsante nativo chiude la finestra e l'app, come ora; il Modello registra il caso macOS allo stato Chiusa. Costo: diverge dalla convenzione macOS, in cui l'app resta attiva senza finestre; le modifiche non ancora salvate vanno salvate prima della chiusura.

## Where in the code

macos/Runner/AppDelegate.swift
