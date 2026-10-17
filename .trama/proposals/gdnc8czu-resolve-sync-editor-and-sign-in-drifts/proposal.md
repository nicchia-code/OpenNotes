---
status: approved
kind: resolution
drifts:
  - drift: hoovlhvs
    decision: fix-code
    option: 1
  - drift: xjzcg1w1
    decision: fix-code
    option: 1
  - drift: fi2ub1th
    decision: proposal
  - drift: l0o9ypcy
    decision: fix-code
    option: 2
  - drift: rs0pb2jf
    decision: fix-code
    option: 1
  - drift: w6tbnosx
    decision: fix-code
    option: 2
  - drift: eriwydo7
    decision: fix-code
    option: 1
  - drift: tcykpi7p
    decision: proposal
base:
  editor/note-content-save.md: 15a403738251ebd80cac79d5d3f2fc886efaeec043911eb5e908e32782be6048
  editor/note-editor.md: 81eb538ff1efd243799a3918b7fefe1c19ccfa092fa63740fb02f4b7dc019866
  requirements/rules/editor.md: 07a6a1ef46313ec2d00bb38dbc7763e546761a9024c062d873cf4fd8688bc64a
delete: []
created: 2026-10-17T18:06:06.034Z
---
# Resolve sync, editor and sign-in drifts

Risoluzione di otto Drift secondo le risposte dello sviluppatore.

- hoovlhvs Sync failures have no readable app log: correggere il codice; gli errori di sincronizzazione e degli allegati vengono scritti in un registro su file nella cartella documenti dell'app, accanto al database.
- xjzcg1w1 A newer save of a note is dropped when a send finds the note deleted in the cloud: correggere il codice; il salvataggio più recente dell'eliminazione resta e viene inviato nello stesso giro, riportando la nota nel cloud.
- fi2ub1th Duplicate writes the waiting note content first, the Model has no such exit: il Model e i Requirements descrivono il comportamento attuale; prima di duplicare, l'editor consegna il testo e la modifica in attesa viene scritta, così la copia nasce dal testo visto sullo schermo.
- l0o9ypcy Mobile editor keeps showing a note that another device protected after it left the list: correggere il codice; l'editor mobile rilegge lo stato della nota salvata a ogni cambiamento dei dati, protezione compresa.
- rs0pb2jf Deleted folder comes back on a newer remote change: correggere il codice; il tempo reale ignora una cartella la cui eliminazione è in attesa di invio, che torna solo con il giro di sincronizzazione.
- w6tbnosx Sign-in restart is blocked while the browser is awaited: correggere il codice; accanto alla riga di attesa compare «Riprova l'accesso», che ricomincia il tentativo.
- eriwydo7 Full check owed by a cancelled retry is lost when the network drops: correggere il codice; il controllo completo dovuto viene ricordato e parte al ritorno della rete.
- tcykpi7p Edits to a note that left the list are lost while its editor stays open: si adottano le modifiche della Proposal allegata; il Model dell'editor dice che, quando la nota esce dall'elenco, l'editor mobile resta aperto ma le modifiche successive non vengono salvate.
