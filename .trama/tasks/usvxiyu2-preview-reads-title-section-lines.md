---
column: done
technical: false
refs:
  - note
  - requirements/rules#note
drift: null
proposal: 8ggnpu48
agent: false
created: 2026-10-17T09:32:00.266Z
finished: 2026-10-17T09:34:13.753Z
---
# Preview and title read the lines of each section

Titolo e anteprima di una nota, ricavati di nuovo dal contenuto a ogni salvataggio e a ogni lettura, seguono le regole aggiornate del documento a blocchi, dove una sezione di testo è un solo blocco con più righe.

- Titolo di un documento a blocchi: in ogni blocco conta la prima riga utile (non vuota, non di soli tag, con testo dopo aver tolto i `#` iniziali). Una sezione che comincia con una riga di soli tag e una riga vuota prende il titolo dalla riga successiva, non dal nome del tag.
- Anteprima di un documento a blocchi: salta immagini e tabelle, le righe vuote, le righe di soli tag e solo la riga del titolo; le altre righe della sezione del titolo entrano nell'anteprima, seguite da quelle delle sezioni successive. Ogni riga viene pulita come nel testo Markdown (segni di elenco, checklist, numerazione, citazione, monospazio, `**`, `*`, backtick); le righe unite con uno spazio si fermano appena il testo supera 90 caratteri.
- Una nota scritta in una sola sezione, per esempio `Spesa / ○ latte / 1. pane`, ha titolo "Spesa" e anteprima "latte pane", non più "Nessun testo aggiuntivo".
- "Nessun testo aggiuntivo" compare solo quando non resta testo, anche per un documento a blocchi senza testo, senza rileggere il JSON come testo Markdown.
- Una nota protetta mostra sempre "Questa nota è protetta"; il testo Markdown non cambia comportamento.
