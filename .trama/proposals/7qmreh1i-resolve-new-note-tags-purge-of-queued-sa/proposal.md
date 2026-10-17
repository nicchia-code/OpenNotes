---
status: approved
kind: resolution
drifts:
  - drift: nrki8shi
    decision: fix-code
    option: 1
  - drift: uvz083ra
    decision: proposal
  - drift: azykyvyp
    decision: proposal
  - drift: pnpdcl9j
    decision: dismissed
base:
  notes/note.md: 8b28a9eec6c89f6a52f9587a1a17475987f24508649e5c893d6b9d34d2ca680b
  cloud-sync/pending-change.md: a701df8b652244b471ceef04ea3754461dc8b5ed533efd0f37925acec253088b
  navigation/mobile-navigation.md: a5a39e7a27007cb276e1271ec2514cdd5429bc68cfdaab11ffaf1e2aed2c202b
  requirements/rules/notes.md: 0d0611844b8f4e22fd7e8c9359afecb61e84f83d6f470c4e02550fe14ae824d6
  requirements/rules/cloud-sync.md: 1f72692c4406b055995292431e1b17ebc5fa65c4622af16e2ef2a3eb5969dc14
delete: []
created: 2026-10-17T08:40:45.327Z
---
# Resolve new-note tags, purge of queued saves, protected mobile editor and checklist Enter Drifts

Risoluzione di quattro Drift.

- nrki8shi – Tags written in a new note's text are still not saved at creation: si corregge il codice (fix-code, opzione «Salvare i tag del testo alla creazione»). Alla creazione la nota salva i #tag del testo iniziale insieme a quelli del filtro attivo; il Model della nota e la regola di creazione delle note lo dicono ora esplicitamente, perché affermavano ancora che alla creazione i tag sono solo quelli del filtro attivo.
- uvz083ra – Queued saves of a synced note are dropped silently when the user deletes it permanently: si descrive il comportamento attuale (proposal). Quando l'utente elimina definitivamente una nota già sincronizzata (anche svuotando il cestino), i suoi salvataggi in coda escono dalla coda senza essere inviati; resta la cancellazione nel cloud. Il Model dei cambiamenti in attesa riceve questa uscita verso Discarded e la regola della coda la aggiunge agli scarti senza avviso.
- azykyvyp – Model still says the mobile editor closes for a protected note after trash or delete: si aggiorna il Model della navigazione mobile (proposal). Per una nota protetta e non ancora sbloccata l'editor resta sul segnaposto dopo «Sposta nel cestino» o «Elimina definitivamente», come deciso nel Drift qg0wycej.
- pnpdcl9j – Enter in a checked item: Model and Requirement disagree on the new item: chiuso senza modifiche (dismissed). La freccia del Model descrive la voce su cui si preme Invio, che resta fatta; la nuova riga è da fare, come dicono già il Model e il Requirement.
