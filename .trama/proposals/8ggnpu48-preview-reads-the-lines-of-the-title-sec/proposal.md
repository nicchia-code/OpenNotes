---
status: approved
base:
  requirements/rules/notes.md: a66ec9d57b66296871b0876f2abb0e0f9ed56ce6bf26398a29ccb8317c06f865
delete: []
created: 2026-10-17T08:55:16.503Z
---
# Preview reads the lines of the title section

Bug: l'anteprima delle note mostra quasi sempre "Nessun testo aggiuntivo". L'editor salva ogni sezione di testo come un solo blocco con più righe; la regola dell'anteprima salta l'intero blocco da cui viene preso il titolo, mentre il titolo usa una sola riga. Una nota scritta in una sola sezione perde così tutte le righe dopo il titolo. Collegato: una sezione che comincia con una riga di soli tag (per esempio una nota creata con un filtro per tag) prende come titolo il nome del tag.

Decisioni:
- L'anteprima salta solo la riga del titolo; le altre righe della stessa sezione e delle sezioni successive entrano nell'anteprima.
- Nei documenti a blocchi l'anteprima toglie gli stessi segni del testo Markdown (elenco, checklist, numerazione, citazione, monospazio, `**`, `*`, backtick).
- Le righe vuote e di soli tag dentro una sezione vengono saltate nell'anteprima.
- Il titolo di un documento a blocchi salta anche le righe vuote e di soli tag dentro una sezione, come nel testo Markdown.

Assunzione da verificare:
- Un documento a blocchi che non produce testo mostra direttamente "Nessun testo aggiuntivo", invece di rileggere il JSON come testo Markdown.
