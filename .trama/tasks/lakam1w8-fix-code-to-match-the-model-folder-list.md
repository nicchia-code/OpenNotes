---
column: done
technical: false
refs:
  - note-browser/Browsing
  - folder/User folder
drift: null
proposal: null
agent: false
created: 2026-10-12T10:49:44.954Z
finished: 2026-10-12T13:53:56.011Z
---
# Fix code to match the Model: Folder list not reloaded during a full sync when a remote folder change arrives

Quando una cartella cambia nel cloud (creata, rinominata o eliminata altrove) mentre una sincronizzazione completa è in corso, l'elenco delle cartelle nella barra laterale e nella schermata Cartelle deve aggiornarsi subito, come accade per le modifiche alle note. Oggi l'elenco resta com'è fino al termine della sincronizzazione. Il Model vuole che l'elenco sia ricaricato a ogni cambiamento ricevuto dal cloud. Il percorso per le note è già a posto: ricarica anche durante la sincronizzazione; quello per le cartelle no.
