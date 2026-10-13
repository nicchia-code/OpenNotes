---
column: done
technical: true
refs:
  - requirements/rules#note
drift: zgd5ssrh
proposal: null
agent: false
created: 2026-10-13T05:49:16.277Z
finished: 2026-10-13T05:56:57.873Z
---
# Fix code to match the Requirements: Note whose content is an empty block list is titled with the raw text

## What happens

Una nota il cui contenuto è solo l'elenco vuoto `[]` riceve come titolo il testo `[]` stesso, e nell'elenco delle note compare con quel nome. Il codice tratta questo contenuto come testo semplice, invece che come documento a blocchi senza titolo.

## What should happen

Il Requirement delle note dice che l'elenco vuoto `[]` è un documento a blocchi e non dà alcun titolo: la nota prende il titolo predefinito «Nuova nota», come ogni documento a blocchi senza titolo.

## Chosen option

**Titolo predefinito per l'elenco vuoto**

Il contenuto `[]` viene riconosciuto come documento a blocchi senza titolo: al prossimo salvataggio del contenuto la nota prende «Nuova nota». Le note già salvate con quel titolo lo mantengono finché non vengono modificate. Costa una correzione della regola del titolo e un test sulla copia di una nota vuota.

## Where in the code

lib/core/models/note_model.dart (extractTitle): l'elenco vuoto non passa dal ramo dei documenti a blocchi.
