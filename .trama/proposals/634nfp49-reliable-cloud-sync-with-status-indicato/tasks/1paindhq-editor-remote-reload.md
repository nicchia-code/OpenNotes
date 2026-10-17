---
technical: false
refs:
- note-editor
---
# Editor remote reload

L'editor applica subito le versioni remote della nota aperta.

- Senza modifiche in attesa (né nell'editor né in attesa di scrittura) una versione remota diversa ricarica il documento anche se una riga ha il focus; il cursore resta nella stessa riga e posizione se esistono ancora, altrimenti va alla fine della riga più vicina; su mobile la tastiera resta aperta; i menu si chiudono.
- Con modifiche in attesa la versione remota non viene caricata: la modifica locale, più recente, la sostituirà.
- Con la nota protetta e non sbloccata il documento nascosto si ricarica alle stesse condizioni, senza più guardare il focus.

Fatto quando una modifica fatta su un altro dispositivo compare nella nota aperta mentre il cursore è in una riga, senza spostarlo.
