---
status: resolved
resolution: dismissed
refs:
  - export-markdown-share/Share sheet open
  - requirements/rules#export-markdown-share
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: null
created: 2026-10-12T18:41:32.601Z
---
# Model still says the shared text is the converted note, after its Drift was resolved

## What happens

Condividendo una nota, il foglio di condivisione riceve come testo il titolo, una riga vuota e poi il contenuto della nota in Markdown **senza** la riga del titolo. La Drift **ri4tdotz** è stata risolta togliendo il titolo dal corpo condiviso, e il codice lo fa.

## What should happen

Il Modello dice solo «il contenuto convertito in Markdown» e il Requisito «conversione Markdown della nota»: nessuno dei due dice che la riga del titolo va tolta. Il Modello e il Requisito dovrebbero descrivere la decisione già presa, come già avviene per il PDF, così chi legge il Modello non ricostruisce da solo che cosa viene condiviso.

## Fix options

### Descrivere la regola nel Modello e nel Requisito

Il Modello della condivisione e il Requisito dell'esportazione dicono che il testo condiviso è titolo, riga vuota e il resto della nota senza la riga del titolo. Il codice resta com'è, perché già così. Costo: una Proposal che aggiorna Modello e Requisito, coerente con la Drift risolta.

### Riportare il titolo nel corpo condiviso

Il testo condiviso torna a includere la nota convertita per intero, con il titolo come intestazione, e il titolo compare di nuovo due volte. Il codice torna alla conversione completa della nota e il Modello resta com'è. Costo: si ribalta la decisione presa sulla Drift ri4tdotz e il titolo si ripete in ogni condivisione.

## Where in the code

lib/ui/notes_list/note_actions.dart (testo della condivisione); lib/core/models/note_model.dart (toMarkdownBody)
