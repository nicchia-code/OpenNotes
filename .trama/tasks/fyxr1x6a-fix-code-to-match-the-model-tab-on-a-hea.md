---
column: done
technical: false
refs:
  - text-line/Heading
drift: fc4crlwr
proposal: null
agent: false
created: 2026-10-12T14:57:05.782Z
finished: 2026-10-12T14:59:01.241Z
---
# Fix code to match the Model: Tab on a heading line adds spaces to the heading text

## What happens

Con il cursore su una riga di titolo o intestazione, Tab aggiunge due spazi all'inizio del testo e Maiusc+Tab li toglie. La riga resta un titolo o un'intestazione, ma il testo visibile comincia rientrato.

## What should happen

Il Model descrive Tab per il corpo, le voci, le citazioni e il monospazio, ma per lo stato Heading non descrive nessuna azione di Tab. I Requirements applicano Tab alle righe normali e alle voci, senza citare titoli e intestazioni. Il rientro serve a stare prima di un simbolo, e le righe di titolo non ne hanno: non è scritto se Tab debba fare qualcosa.

## Chosen option

**Tab non fa nulla sulle intestazioni**

Con Tab o Maiusc+Tab la riga di titolo o intestazione resta com'è, perché il rientro si applica solo alle righe con un simbolo o alle righe di corpo. Il Model e i Requirements non chiedono altro. Costo: su una selezione mista le righe di corpo rientrano e quelle di intestazione no.

## Where in the code

lib/ui/editor/rich_text_editing_controller.dart, handleTabKey (ramo delle righe normali)
