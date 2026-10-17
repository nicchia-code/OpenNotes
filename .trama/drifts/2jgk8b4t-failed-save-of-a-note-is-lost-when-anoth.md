---
status: resolved
resolution: proposal
refs:
  - note-content-save/Waiting
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: tqf85in9
created: 2026-10-17T17:18:18.942Z
---
# Failed save of a note is lost when another note is edited meanwhile

## What happens

Se la scrittura di una nota fallisce mentre un'altra nota ha già una modifica in attesa, la modifica che non è stata salvata va persa. L'utente vede l'avviso «Nota non salvata: il salvataggio verrà ritentato», ma quella nota non viene più riscritta: alla prossima lettura dell'elenco torna la versione salvata, sia nell'elenco sia nell'editor. Succede quando l'utente passa a un'altra nota e scrive subito, e la scrittura della nota precedente fallisce dopo.

## What should happen

Una modifica non scritta deve restare in attesa e venire ritentata alla consegna successiva o al passaggio in secondo piano, come dice l'avviso e come deciso per il fallimento di una scrittura. Il Model non descrive il fallimento. Quando una modifica di un'altra nota prende il posto dell'attesa, la modifica non riuscita non deve andare persa.

## Fix options

### Keep the failed version waiting next to the newer one

Ogni nota può avere una modifica in attesa: quando una scrittura fallisce, la versione non scritta resta in attesa accanto a quella più recente e viene ritentata alla consegna successiva o al passaggio in secondo piano. Il passaggio immediato alla nota nuova non cambia. Costo: più versioni in attesa insieme e più scritture da ritentare quando disco o database non rispondono.

### Retry the failed version once before the newer one waits

Quando una scrittura fallisce mentre un'altra nota ha già una modifica in attesa, la versione non scritta viene riprovata subito, una volta, prima che la nuova modifica parta la sua attesa. Se fallisce di nuovo, resta in attesa come oggi. Costo: un tentativo in più nel passaggio tra note, proprio quando l'errore può persistere, e la nuova attesa parte qualche istante dopo.

## Where in the code

lib/core/state/notes_provider.dart: updateNoteContent (scrittura immediata della versione di un'altra nota), flushPendingContent e il ramo catch di _writeContent, dove _pendingContent ??= pending scarta la versione non riuscita se ne esiste già una più recente.
