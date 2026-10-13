---
column: done
technical: false
refs:
  - note/Not yet created/user.DUPLICATE_NOTE
  - requirements/rules#note
drift: null
proposal: null
agent: false
created: 2026-10-12T14:37:22.577Z
finished: 2026-10-12T16:28:14.850Z
---
# Fix code to match the Model: Duplicate of a plain-text note that looks like a JSON list corrupts its text

Duplicando una nota di testo semplice la cui prima riga inizia con «[» e che è un elenco JSON valido ma non di soli oggetti (per esempio «[1]» o «[1, 2]»), la copia non è più testo: il contenuto diventa un elenco di blocchi con un blocco titolo inserito in testa e il testo originale va perso o resta come dato grezzo. Il Model dice che un contenuto che non è un elenco di soli oggetti è testo Markdown, quindi la copia deve avere la forma «# <titolo> (copia)» seguita dal testo originale intatto, come per ogni altra nota di testo. Quando il lavoro è finito, duplicare una nota di testo semplice che inizia con «[» produce una copia con lo stesso testo dell'originale, e la duplicazione riconosce il documento a blocchi con la stessa regola usata per titolo, anteprima ed editor.
