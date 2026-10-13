---
column: done
technical: true
refs:
  - requirements/rules#text-line
drift: i2s8qzie
proposal: null
agent: false
created: 2026-10-12T10:59:40.591Z
finished: 2026-10-12T11:04:13.361Z
---
# Fix code to match the Requirements: Joined body line takes the style of the empty line before it

## What happens

Il Task descrive due regole che si contraddicono. La prima dice che, quando una riga in corpo viene unita con Backspace alla riga vuota in fondo alla sezione precedente, la riga vuota mantiene il proprio stile. La descrizione del problema dice invece che proprio questo oggi trasforma in intestazione una riga unita in corpo, e che è sbagliato. Non si può seguire entrambe.

## What should happen

La regola per la riga unita con uno stile è chiara: vince sulla riga vuota. Per la riga unita in corpo, il Requisito Stili di riga dopo una modifica non è abbastanza preciso da scegliere tra le due frasi del Task: serve una decisione su quale stile resta nella riga unita.

## Chosen option

**La riga unita in corpo resta in corpo**

Se la riga unita ha uno stile, vince sulla riga vuota. Se è in corpo, la riga resta in corpo anche quando la riga vuota precedente è un'intestazione. Coerente con il problema descritto e con il caso in cui la sezione precedente è vuota. Costa una frase in più nel Requisito e cambia la frase letterale del Task.
