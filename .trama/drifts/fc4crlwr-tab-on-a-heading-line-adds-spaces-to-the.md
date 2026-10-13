---
status: resolved
resolution: fix-code
refs:
  - text-line/Heading
proposal: null
task: fyxr1x6a
origin: null
critical: false
option: 1
note: null
resolvedBy: g08cr3wn
created: 2026-10-12T14:53:34.868Z
---
# Tab on a heading line adds spaces to the heading text

## What happens

Con il cursore su una riga di titolo o intestazione, Tab aggiunge due spazi all'inizio del testo e Maiusc+Tab li toglie. La riga resta un titolo o un'intestazione, ma il testo visibile comincia rientrato.

## What should happen

Il Model descrive Tab per il corpo, le voci, le citazioni e il monospazio, ma per lo stato Heading non descrive nessuna azione di Tab. I Requirements applicano Tab alle righe normali e alle voci, senza citare titoli e intestazioni. Il rientro serve a stare prima di un simbolo, e le righe di titolo non ne hanno: non è scritto se Tab debba fare qualcosa.

## Fix options

### Tab non fa nulla sulle intestazioni

Con Tab o Maiusc+Tab la riga di titolo o intestazione resta com'è, perché il rientro si applica solo alle righe con un simbolo o alle righe di corpo. Il Model e i Requirements non chiedono altro. Costo: su una selezione mista le righe di corpo rientrano e quelle di intestazione no.

### Tab rientra anche le intestazioni

Tab aggiunge due spazi anche alla riga di titolo o intestazione, come oggi, e lo stile resta. Il Model va completato con una transizione Tab per Title, Heading 1, Heading 2 e Heading 3. Costo: il testo visibile si sposta, e il rientro va previsto anche al caricamento delle note.

## Where in the code

lib/ui/editor/rich_text_editing_controller.dart, handleTabKey (ramo delle righe normali)
