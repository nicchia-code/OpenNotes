---
status: resolved
resolution: proposal
refs:
  - requirements/rules#note
  - requirements/rules#note-content-save
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: ccg944lf
created: 2026-10-12T12:09:25.504Z
---
# Preview skips the title paragraph, while the notes Requirement skips only a Title or Heading 1 block

## What happens

L'anteprima di una nota non ripete il titolo: salta il blocco da cui il titolo viene preso, anche quando è un paragrafo e non un blocco Titolo. Per una nota che inizia con il paragrafo «Spesa», seguito dall'intestazione «Sezione» e dal testo «latte», l'anteprima mostra «Sezione latte».

## What should happen

Il Requirement delle note dice che l'anteprima salta i blocchi di soli tag e solo il primo blocco Titolo o Intestazione 1; per quella nota l'anteprima sarebbe «Spesa latte», con il titolo ripetuto. Il Requirement dell'editor dice invece che l'anteprima è senza il titolo, come fa il codice. I due Requirement non dicono la stessa cosa.

## Fix options

### Anteprima senza il titolo

L'anteprima continua a saltare il blocco da cui il titolo viene preso, anche se è un paragrafo. Il Requirement delle note va corretto per dirlo, come già chiede il Requirement dell'editor. Costa una modifica del Requirement da approvare; il codice non cambia.

### Ripetere il titolo se non è un blocco Titolo

L'anteprima salta solo un blocco Titolo o Intestazione 1. Una nota che prende il titolo da un paragrafo lo mostra di nuovo nell'anteprima, come scrive il Requirement delle note. Costa il titolo ripetuto nelle liste per le note senza blocco Titolo, cioè l'effetto che una correzione precedente aveva eliminato; va riscritto un test e il Requirement dell'editor va corretto.

## Where in the code

lib/core/models/note_model.dart (extractSnippet, _titleBlockIndex); test/vault_test.dart (extractSnippet keeps a later h1 when the title is earlier text)
