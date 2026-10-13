---
status: resolved
resolution: fix-code
refs:
  - sync-run/Pushing changes
proposal: null
task: dy8pypce
origin: sa7kcg5q
critical: false
option: 1
note: null
resolvedBy: psazi867
created: 2026-10-12T16:31:18.490Z
---
# Sent save of a note deleted before its first sync comes back

## What happens

Una nota mai sincronizzata, eliminata sul dispositivo prima della prima sincronizzazione, viene inviata intera al cloud, come il Model dice. Subito dopo, però, l'eliminazione in coda trova la nota appena caricata con una data di modifica più recente di quella dell'eliminazione: per il Model viene scartata. La nota resta nel cloud e torna sul dispositivo con il download, quindi la cancellazione non ha effetto.

## What should happen

Il Model dice che il salvataggio di una nota mai sincronizzata viene inviato e che un'eliminazione in coda viene scartata se il cloud è più recente. Insieme, questi due punti fanno tornare la nota eliminata. Il Model non dice quale delle due regole vince per questo caso, né come distinguere una nota mai sincronizzata da una già sincronizzata e poi eliminata sul dispositivo, informazione che il dispositivo non conserva più.

## Fix options

### Discard the save of a note deleted before its first sync

Come già deciso nella Drift eth1srfy: il salvataggio di una nota eliminata prima della prima sincronizzazione viene scartato e nulla arriva al cloud, né testo né allegati. Il codice resta com'è; il Model va scritto di conseguenza. Costo: il caso non viene più inviato, quindi non c'è copia della nota da recuperare altrove.

### Send the save and delete it from the cloud after

Il salvataggio viene inviato intero, con gli allegati, e l'eliminazione in coda cancella la nota dal cloud anche se il cloud è più recente, ma solo per le note mai sincronizzate. Costo: la regola di eliminazione del Model ha un'eccezione; il contenuto passa per un istante nel cloud e altri dispositivi possono riceverlo.

## Where in the code

lib/core/services/sync_service.dart: invio dei salvataggi in coda in syncNow, ramo delle eliminazioni
