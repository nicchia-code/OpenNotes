---
column: done
technical: false
refs:
  - export-markdown-share/Share sheet open
  - requirements/rules#export-markdown-share
drift: ri4tdotz
proposal: null
agent: false
created: 2026-10-12T17:14:49.801Z
finished: 2026-10-12T17:16:41.751Z
---
# Fix code to match the Model: Shared Markdown text repeats the note title

## What happens

Condividendo una nota, il testo che il foglio di condivisione riceve contiene due volte il titolo. Prima c'è il titolo come riga semplice, poi una riga vuota, poi il contenuto convertito in Markdown: la conversione mette il titolo in testa come intestazione, quindi compare di nuovo. Per una nota in testo semplice la prima riga, che è il titolo, compare due volte allo stesso modo.

## What should happen

Il Modello dice che il testo condiviso è titolo, riga vuota e contenuto convertito in Markdown, e il Requisito dice lo stesso. Nessuno dei due dice se la riga del titolo fa parte del contenuto da condividere. Nell'esportazione PDF il titolo è già in testa alla pagina e viene tolto dal corpo per non stamparlo due volte; la condivisione non ha questa regola.

## Chosen option

**Togliere il titolo dal corpo condiviso**

Il testo condiviso resta titolo, riga vuota e poi il resto della nota, senza la riga del titolo, come già avviene nel PDF. Il Modello e il Requisito vanno completati con questa regola. Costo: una piccola modifica a Model e Requirement, e la condivisione non contiene più il titolo in forma di intestazione.

## Where in the code

lib/ui/notes_list/note_actions.dart (testo della condivisione); lib/core/models/note_model.dart (conversione toMarkdown)
