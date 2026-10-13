---
status: resolved
resolution: fix-code
refs:
  - note/Active
  - requirements/rules#note
proposal: null
task: 5zde0bvh
origin: null
critical: false
option: 1
note: null
resolvedBy: nztyyq3m
created: 2026-10-13T06:36:52.328Z
---
# Preview of a plain-text note that starts with [ reads blocks from a mixed list

## What happens

Una nota di testo semplice che comincia con `[` contiene un elenco in cui alcuni elementi sono oggetti con testo e altri no, per esempio un numero. In questo caso l'anteprima mostra il testo preso dagli oggetti dentro quell'elenco, come se la nota fosse un documento a blocchi. Il titolo invece viene ricavato dalla riga come per ogni testo semplice, quindi titolo e anteprima non seguono la stessa lettura del contenuto.

## What should happen

Un contenuto è un documento a blocchi solo se è un elenco i cui elementi sono tutti oggetti. Ogni altro contenuto, anche un testo che comincia con `[`, è testo semplice: anteprima e titolo devono leggerlo allo stesso modo, quindi l'anteprima deve venire dalle sue righe, e se non resta testo deve dire "Nessun testo aggiuntivo".

## Fix options

### Leggere l'anteprima come testo semplice

Il controllo che decide se il contenuto è un documento a blocchi viene applicato anche all'anteprima, così un elenco con elementi che non sono tutti oggetti viene letto come testo: l'anteprima mostra le righe del testo, oppure "Nessun testo aggiuntivo". Costo: una piccola modifica alla sola lettura dell'anteprima, senza effetti su titolo, tag o contenuto salvato.

### Un solo controllo per titolo, tag, anteprima e duplicazione

Il riconoscimento del documento a blocchi viene fatto in un solo punto e usato da tutte le letture del contenuto, così titolo, anteprima, tag e duplicazione non possono più disaccordarsi. Costo: una modifica più ampia, che tocca più letture del contenuto, ma che evita discordanze future anche in altri casi.

## Where in the code

lib/core/models/note_model.dart: extractSnippet (ramo JSON), confrontato con extractTitle che già controlla che tutti gli elementi siano oggetti
