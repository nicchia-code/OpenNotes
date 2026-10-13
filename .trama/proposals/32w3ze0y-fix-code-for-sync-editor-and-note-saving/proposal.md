---
status: approved
kind: resolution
automatic: true
drifts:
  - drift: dc2dwepj
    decision: fix-code
    option: 1
  - drift: s2kd4dbl
    decision: fix-code
    option: 1
  - drift: qfyxcqr9
    decision: fix-code
    option: 1
  - drift: sdkve31p
    decision: fix-code
    option: 1
  - drift: 5ila75hq
    decision: fix-code
    option: 1
  - drift: r3gdmwv2
    decision: fix-code
    option: 1
  - drift: vpim0xgg
    decision: fix-code
    option: 1
base: {}
delete: []
created: 2026-10-12T18:22:39.556Z
---
# Fix code for sync, editor and note-saving drifts

Risoluzione automatica: per ogni Drift autorizzato si applica la prima opzione di correzione nel codice.

- Eliminazione di una nota mentre il suo salvataggio è in invio: correggere il codice (opzione 1, l'eliminazione vince e la nota viene cancellata subito dal cloud).
- Duplicazione di una nota e testo di ricerca: correggere il codice (opzione 1, anche la duplicazione svuota il testo di ricerca, come la creazione).
- Cartella assente dal cloud rimossa dalla sincronizzazione completa: correggere il codice (opzione 1, la rimozione resta e le note passano nella cartella "Note").
- Eliminazione di una cartella e creazioni o rinomine in coda: correggere il codice (opzione 1, le creazioni e rinomine non inviate vengono tolte dalla coda).
- Menu rapido dei blocchi che resta sotto un'altra sezione: correggere il codice (opzione 1, il menu si chiude quando la sua sezione sparisce).
- Nota eliminata che ritorna dal cloud prima dell'invio della cancellazione: correggere il codice (opzione 1, si ignora il cloud per una nota con cancellazione in attesa).
- Salvataggio in attesa perso modificando un'altra nota entro 400 ms: correggere il codice (opzione 1, la modifica in attesa viene scritta subito quando cambia nota).
