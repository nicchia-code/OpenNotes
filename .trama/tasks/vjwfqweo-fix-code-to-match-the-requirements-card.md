---
column: done
technical: true
refs:
  - requirements/rules#note-content-save
drift: wvmpasi0
proposal: null
agent: false
created: 2026-10-12T10:59:40.538Z
finished: 2026-10-12T11:02:38.989Z
---
# Fix code to match the Requirements: Card preview repeats the title of a note without a title block

## What happens

Se la nota non ha un blocco di titolo, il titolo è la prima riga di testo, anche un semplice paragrafo. L'anteprima però parte da quella stessa riga: la card mostra il titolo e subito dopo lo ripete, per esempio «Spesa» seguito da «Spesa latte». Se più avanti nella nota c'è un'intestazione di primo livello, l'anteprima salta quella invece della prima riga.

## What should happen

Il titolo è la prima riga del primo blocco con testo, oppure il blocco di titolo se c'è. L'anteprima, circa 90 caratteri, deve escludere proprio quella riga: deve partire dal testo che segue il titolo, in ogni nota.

## Chosen option

**Saltare dall'anteprima il blocco da cui viene preso il titolo**

L'anteprima salta sempre il blocco che il titolo usa: il blocco di titolo se c'è, altrimenti la prima riga di testo, qualunque sia il suo tipo. La card mostra ogni riga una sola volta, come dice il Requirement. Costa: due regole, quella del titolo e quella dell'anteprima, da tenere allineate nello stesso punto del codice.

## Where in the code

lib/core/models/note_model.dart: Note.extractSnippet, ramo dei blocchi; il titolo viene da Note.extractTitle.
