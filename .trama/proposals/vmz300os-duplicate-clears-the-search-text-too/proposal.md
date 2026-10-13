---
status: rejected
base:
  model/notes/note.md: new
  model/organization/note-browser.md: new
  requirements/rules/notes.md: 3a25b815fca14b8d055393e318decffa89f5d98bee44be97a16d772a1ce8dc4d
  requirements/rules/organization.md: ab830fa3130d55ca446ee10cf4513c357c9c195b4242a000191ca1feb9d184d9
  notes/note.md: 47ca46a728945ce2ceb0aa20e5660d91f3feb70006416c90930879b23d47313b
  organization/note-browser.md: 654e88bdfe33c3800fcf6bcfc7efd2f765d73143d095aea3c4e53b42fa501e6b
delete: []
created: 2026-10-13T05:51:38.178Z
---
# Duplicate clears the search text too

Decisione dal Drift 7ndlrnrr (opzione scelta: Clear the search on duplicate too): la duplicazione svuota il testo di ricerca come la creazione, così la copia compare nell'elenco ed è selezionata. Il codice già lo fa; il Model e il Requirement dicono ancora che solo la creazione svuota la ricerca.
- Vista elenco (note-browser): duplicare svuota la ricerca come creare.
- Nota (DUPLICATE_NOTE): la duplicazione svuota il testo di ricerca.
- Requirement rules note-browser e note: stessa regola.

## Feedback

Drift qu7p7hag resolved by Proposal dbeofb0j
