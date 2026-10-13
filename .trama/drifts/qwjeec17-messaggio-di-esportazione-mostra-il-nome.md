---
status: resolved
resolution: fix-code
refs:
  - export-markdown-file/Choosing destination/operating-system.FILE_SAVE_DIALOG_CLOSED
proposal: null
task: 89izk6tm
origin: null
critical: false
option: 1
note: null
resolvedBy: xnzq15fv
created: 2026-10-12T08:24:31.768Z
---
# Messaggio di esportazione mostra il nome proposto con altra estensione

## What happens

Dopo il salvataggio il messaggio di conferma riprende il nome proposto dal titolo, con estensione .md, quando il nome scelto dall'utente nella finestra di salvataggio non termina con .md (per esempio **Diario.txt**), anche se il sistema restituisce il nome reale del file. Il messaggio quindi non corrisponde al file scritto.

## What should happen

Il Model dice che, dopo la scelta della posizione, l'app mostra un breve messaggio con il **nome del file esportato**. La correzione precedente, chiusa, ha previsto di usare il nome con cui il file è stato salvato e il nome proposto solo quando il sistema non ne restituisce uno leggibile: l'estensione .md non fa parte di questa regola, perché un nome leggibile non va scartato solo perché ha un'altra estensione.

## Fix options

### Accettare qualsiasi nome con estensione

Il messaggio mostra il nome restituito dalla finestra di salvataggio quando contiene un'estensione qualunque, per esempio **.txt**. Il nome proposto resta solo per i riferimenti senza nome leggibile, come gli identificativi opachi di alcuni sistemi Android. Costo: un nome digitato senza estensione, come *Idee*, continua a mostrare il nome proposto.

### Mostrare sempre il nome restituito dal sistema

Il messaggio mostra il nome con cui il file è stato salvato ogni volta che il sistema lo restituisce in forma leggibile, anche senza estensione. Il nome proposto resta solo per i riferimenti opachi. Costo: bisogna distinguere in modo affidabile gli identificativi opachi dai nomi veri, e la regola può variare tra piattaforme.

### Riscrivere il Model sul nome proposto

Il codice resta com'è e il Model dice che il messaggio riprende il nome proposto dal titolo. Costo: se l'utente cambia nome o estensione nella finestra di salvataggio, il messaggio non corrisponde al file salvato; la differenza resta visibile finché il Model non cambia.

## Where in the code

lib/ui/notes_list/note_actions.dart, ramo di esportazione in Markdown: messaggio dopo la finestra di salvataggio e funzione che ricava il nome leggibile dal riferimento restituito (accetta solo nomi che finiscono in .md)
