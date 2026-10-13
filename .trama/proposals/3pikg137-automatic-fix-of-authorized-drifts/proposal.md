---
status: approved
kind: resolution
automatic: true
drifts:
  - drift: 3jai3eb6
    decision: fix-code
    option: 1
  - drift: hoivm02e
    decision: fix-code
    option: 1
  - drift: 71ynmepj
    decision: fix-code
    option: 1
  - drift: ewxhw1h0
    decision: fix-code
    option: 1
  - drift: n36a1c1s
    decision: fix-code
    option: 1
  - drift: r0awdofi
    decision: fix-code
    option: 1
  - drift: w3xk0orr
    decision: fix-code
    option: 1
  - drift: n5vedxka
    decision: fix-code
    option: 1
  - drift: odoeb8h7
    decision: fix-code
    option: 1
  - drift: 0mxommkf
    decision: fix-code
    option: 1
  - drift: 3lshictc
    decision: fix-code
    option: 1
  - drift: wet88tr4
    decision: fix-code
    option: 1
  - drift: w1z2zzqd
    decision: fix-code
    option: 1
  - drift: 96dg7ovq
    decision: fix-code
    option: 1
  - drift: 6tbds6iq
    decision: fix-code
    option: 1
  - drift: 2qmlfqn0
    decision: fix-code
    option: 1
  - drift: w0sisdw2
    decision: fix-code
    option: 1
  - drift: xportynf
    decision: fix-code
    option: 1
  - drift: 0tiskmm2
    decision: fix-code
    option: 1
  - drift: g39d2m3i
    decision: fix-code
    option: 1
  - drift: s6goeoj0
    decision: fix-code
    option: 1
  - drift: y4sri6mj
    decision: fix-code
    option: 1
  - drift: 7jao0w40
    decision: fix-code
    option: 1
  - drift: nkmpkw76
    decision: fix-code
    option: 1
  - drift: 34jcqykq
    decision: fix-code
    option: 1
  - drift: wectbghw
    decision: fix-code
    option: 1
  - drift: e81we9ou
    decision: fix-code
    option: 1
  - drift: q2felqo7
    decision: fix-code
    option: 1
  - drift: ooydwa2p
    decision: fix-code
    option: 1
  - drift: 4ecpyiam
    decision: fix-code
    option: 1
  - drift: kdjlai9a
    decision: fix-code
    option: 1
  - drift: 2vxdka3s
    decision: fix-code
    option: 1
  - drift: bklpw0ib
    decision: fix-code
    option: 1
base: {}
delete: []
created: 2026-10-12T07:38:05.531Z
---
# Automatic fix of authorized Drifts

Risoluzione automatica: per ogni Drift autorizzato si applica la prima opzione di correzione, che va fatta nel codice.

- 3jai3eb6 – Plain-text notes keep trailing blank lines when shared as Markdown: correggere il codice (Ripulire anche il testo semplice).
- hoivm02e – Configuration errors ignored on first preparation: correggere il codice (Ignorare l'errore solo se il collegamento era già pronto).
- 71ynmepj – Exported drawing keeps transparent holes where erased: correggere il codice (Sfondo bianco sotto i tratti).
- ewxhw1h0 – Empty list item swallows the next line in Markdown export: correggere il codice (Consumare solo gli spazi dopo il simbolo).
- n36a1c1s – Tabella del menu rapido cancella tutta la sezione: correggere il codice (Togliere solo la «/» anche per la Tabella).
- r0awdofi – Plain-text notes exported without cleanup and list conversion: correggere il codice (Applicare la pulizia e la conversione anche al testo semplice).
- w3xk0orr – Menu rapido dei blocchi non si apre dalla barra: correggere il codice (Aprire il menu rapido dalla barra).
- n5vedxka – Vault file: a title returning to an orphaned file name overwrites it: correggere il codice (Il ritorno riprende il file orfano).
- odoeb8h7 – Folder changes on the device never reach the cloud: correggere il codice (Accodare anche le cartelle).
- 0mxommkf – Notes sent from the queue are sent again by the unsynced sweep: correggere il codice (Segnare la nota come sincronizzata).
- 3lshictc – Title block does not take precedence over earlier text blocks: correggere il codice (Dare precedenza al blocco Titolo).
- wet88tr4 – Cancelled unlock on duplicate opens another note: correggere il codice (Aprire la nota su cui è stato aperto il menu).
- w1z2zzqd – Editor shows stale note after leaving the list: correggere il codice (Mantenere l'ultima versione ricevuta).
- 96dg7ovq – Swipe in trash permanently deletes notes: correggere il codice (Aggiungere l'azione alla lista nel Model).
- 6tbds6iq – Queued welcome notes are sent to cloud even when it already has notes: correggere il codice (Keep welcome notes out of the queue).
- 2qmlfqn0 – Notes sent from the queue are not marked as synced: correggere il codice (Mark each note as synced when its change is accepted).
- w0sisdw2 – App start does not wait for a sync already running: correggere il codice (Wait for the sync already running).
- xportynf – Downloaded notes lose their link to the vault file: correggere il codice (Keep the local file location when replacing).
- 0tiskmm2 – Tag filter also matches longer tags: correggere il codice (Filtrare solo sui tag salvati nella nota).
- g39d2m3i – Protected note: style change saved as block type: correggere il codice (Scrivere lo stile sulla riga attiva anche da nascosto).
- s6goeoj0 – Arrow keys do not cross tables and images: correggere il codice (Far entrare il cursore nella tabella o nell'immagine).
- y4sri6mj – Active part not updated when a part is removed: correggere il codice (Ricordare la parte attiva come riferimento).
- 7jao0w40 – Remote version reloads while the note is protected: correggere il codice (Ricaricare anche la nota nascosta, come nel Modello).
- nkmpkw76 – Commands during a pending save are not in the Model: correggere il codice (Aggiungere le uscite nel Modello).
- 34jcqykq – Enter on a heading line: correggere il codice (Cursore in corpo anche su riga vuota).
- wectbghw – Checklist toggle keeps the heading style: correggere il codice (Portare la riga in corpo).
- e81we9ou – Enter at the start of a list item duplicates the symbol: correggere il codice (Dividere la voce come nel mezzo del testo).
- q2felqo7 – Text style menu leaves the symbol on indented lines: correggere il codice (Togliere il simbolo dopo il rientro).
- ooydwa2p – Old-format notes lose the indent of checklist items: correggere il codice (Conservare il rientro anche nelle checklist).
- 4ecpyiam – Old-format notes turn the first line after a table into a title: correggere il codice (Titolo solo sulla prima riga della nota).
- kdjlai9a – New note hidden by an active search leaves the editor empty: correggere il codice (Clear the search when a note is created).
- 2vxdka3s – Note list not reloaded after saving note text: correggere il codice (Rileggere l'elenco dopo ogni salvataggio).
- bklpw0ib – Duplicated note does not refresh the tag list: correggere il codice (Rileggere i tag dopo la duplicazione).
