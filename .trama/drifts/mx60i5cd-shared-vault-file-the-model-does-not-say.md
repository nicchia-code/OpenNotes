---
status: resolved
resolution: fix-code
refs:
  - vault-file/Written/note.PERMANENTLY_DELETED
proposal: null
task: 8o92pfcd
origin: null
critical: false
option: 1
note: null
resolvedBy: g08cr3wn
created: 2026-10-12T14:48:56.312Z
---
# Shared vault file: the Model does not say whose copy stays when several notes remain

## What happens

Quando una nota viene eliminata definitivamente e restano sul dispositivo due o più note scritte nello stesso file, il sistema riscrive il file con il contenuto della nota modificata più di recente tra quelle rimaste. Il file non viene cancellato, ma il suo testo cambia in base a questa scelta.

## What should happen

Il Model dice che, se un'altra nota resta scritta nello stesso file, il file non viene cancellato e resta la copia di quella nota. Parla di una sola nota rimasta. Non dice quale nota scegliere quando ne restano due o più, per esempio tre note con lo stesso titolo di cui una viene eliminata. Il testo conservato nel vault dipende da questa scelta, quindi il Model deve deciderla.

## Fix options

### Most recently edited note

Il file prende il contenuto della nota modificata più di recente tra quelle rimaste, come fa oggi. È una regola semplice e prevedibile dalla data di modifica, senza nuovi dati da ricordare. Può però mostrare nel file la versione di una nota più vecchia se era stata l'ultima a scrivere quel file.

### Note whose title gives the file name

Il file prende il contenuto della nota il cui titolo attuale produce proprio il nome di quel file; se nessuna la ha, si ripiega sulla più recente. Il file resta coerente con il nome che porta, ma serve un'eccezione in più e il risultato dipende dai titoli, che possono cambiare.

## Where in the code

lib/core/services/vault_service.dart (deleteNoteFileIfUnused, con il commento sulla scelta della nota più recente)
