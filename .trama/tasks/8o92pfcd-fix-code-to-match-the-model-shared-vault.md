---
column: done
technical: false
refs:
  - vault-file/Written/note.PERMANENTLY_DELETED
drift: mx60i5cd
proposal: null
agent: false
created: 2026-10-12T14:57:05.723Z
finished: 2026-10-12T15:03:16.173Z
---
# Fix code to match the Model: Shared vault file: the Model does not say whose copy stays when several notes remain

## What happens

Quando una nota viene eliminata definitivamente e restano sul dispositivo due o più note scritte nello stesso file, il sistema riscrive il file con il contenuto della nota modificata più di recente tra quelle rimaste. Il file non viene cancellato, ma il suo testo cambia in base a questa scelta.

## What should happen

Il Model dice che, se un'altra nota resta scritta nello stesso file, il file non viene cancellato e resta la copia di quella nota. Parla di una sola nota rimasta. Non dice quale nota scegliere quando ne restano due o più, per esempio tre note con lo stesso titolo di cui una viene eliminata. Il testo conservato nel vault dipende da questa scelta, quindi il Model deve deciderla.

## Chosen option

**Most recently edited note**

Il file prende il contenuto della nota modificata più di recente tra quelle rimaste, come fa oggi. È una regola semplice e prevedibile dalla data di modifica, senza nuovi dati da ricordare. Può però mostrare nel file la versione di una nota più vecchia se era stata l'ultima a scrivere quel file.

## Where in the code

lib/core/services/vault_service.dart (deleteNoteFileIfUnused, con il commento sulla scelta della nota più recente)
