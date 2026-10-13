---
description: Usare quando si cambia il comportamento dell'editor, cioè caricamento del contenuto, salvataggio ritardato, scorciatoie Markdown, Invio/Backspace/Tab, checklist, formattazione, unione di sezioni, suggerimenti di tag, tabelle e disegni.
---
# Editor rules

## note-content-save
- La scrittura su disco parte 400 ms dopo l'ultima consegna. C'è un solo timer, condiviso da tutte le note.
- Titolo ricalcolato a ogni consegna:
  - è la prima riga del primo blocco con testo, escluse immagini e tabelle;
  - ha la precedenza un blocco di tipo `title`;
  - i blocchi fatti solo di tag vengono saltati;
  - perde i «#» iniziali e si taglia a 60 caratteri;
  - se non c'è, vale «Nuova nota».
- Tag: ogni «#nome» (lettere latine, cifre, «_», «-») all'inizio del testo o dopo uno spazio o una parentesi, sia nel testo sia nelle celle delle tabelle. Si salvano in minuscolo, senza duplicati e in ordine alfabetico.
- L'anteprima viene ricalcolata a ogni consegna: circa 90 caratteri, senza il titolo; per una nota protetta è «Questa nota è protetta».

## note-editor
- Attesa dell'editor: 300 ms. Vale per la digitazione, per Invio, per Backspace dentro una sezione e per Tab.
- Salvataggio immediato, senza attesa:
  - grassetto, corsivo, sottolineato, barrato;
  - stile dal menu «Aa»;
  - pulsante checklist e tocco sul cerchio;
  - voce del menu rapido e tag scelto o confermato;
  - unione di sezioni;
  - ogni modifica di una tabella, carattere per carattere;
  - inserimento di una tabella, di una foto o di un disegno, e rimozione di un'immagine;
  - nuova sezione creata toccando l'area vuota.
- Scorciatoie da tastiera: Ctrl/Cmd+B grassetto, Ctrl/Cmd+I corsivo, Ctrl/Cmd+U sottolineato, Ctrl/Cmd+Maiusc+X oppure Ctrl/Cmd+Alt+S barrato. Freccia su all'inizio di una parte passa alla fine della parte precedente; freccia giù alla fine passa all'inizio della successiva.
- Formattazione dei caratteri:
  - con una selezione: se ogni carattere selezionato ha già lo stile, lo toglie; altrimenti lo applica a tutta la selezione;
  - senza selezione: attiva o disattiva lo stile per il testo che verrà digitato.
- Normalizzazione degli intervalli:
  - si tagliano alla lunghezza del testo;
  - si scartano quelli vuoti o senza stile;
  - si spezzano ai confini e si fondono quelli adiacenti con gli stessi stili;
  - il testo inserito dentro un intervallo lo allarga; il testo inserito con stili attivi crea un nuovo intervallo.
- Caricamento di un contenuto JSON:
  - i blocchi di testo consecutivi (tutti tranne tabella, immagine e separatore) si fondono in un'unica sezione di testo;
  - lo stile di una riga è quello salvato; in mancanza, la prima riga di un blocco prende il tipo del blocco;
  - le righe che cominciano con «### », «## » o «# » perdono il prefisso e diventano `h3`, `h2` oppure `title` (se sono la prima riga della sezione) o `h1`;
  - i blocchi `bullet`, `numbered`, `checklist`, `quote` e `code` diventano righe di corpo con il prefisso «• », «1. », «○ »/«● » (secondo la spunta del blocco), «> » o «``` »;
  - «- [ ]» o «[ ]» diventano «○ »; «- [x]» o «[x]» diventano «● »; «- » e «* » diventano «• »;
  - gli intervalli di formattazione si ricalcolano sulle nuove posizioni;
  - un documento senza parti riceve una sezione di testo vuota.
- Caricamento di Markdown o testo semplice:
  - le righe consecutive che cominciano e finiscono con «|» formano una tabella; le righe separatrici si saltano e le righe corte si completano;
  - «### », «## » e «# » diventano intestazioni (con `title` sulla prima riga della sezione);
  - le caselle «- [ ]», «[ ]», «○ » e quelle spuntate diventano «○ »/«● »;
  - «- », «* », «• », «◦ » e «▪ » diventano il simbolo del livello di rientro;
  - la prima riga normale che non è fatta solo di tag diventa `title`; se la prima riga è fatta solo di tag, il titolo è la seconda.
- All'apertura di una sezione, i «# »–«### » rimasti a inizio riga vengono tolti e diventano `h1`–`h3`. Si scartano gli stili di riga oltre l'ultima riga.
- Unione di una sezione con quella precedente (Backspace all'inizio della sezione):
  - se la parte precedente è una tabella, un'immagine o un separatore, non si unisce nulla;
  - i testi si concatenano senza a capo e la formattazione della seconda sezione si sposta della lunghezza della prima;
  - la prima sezione conserva i suoi stili di riga, mentre quelli della seconda scalano del numero di righe della prima;
  - se la prima sezione non è vuota e non finisce con un a capo, lo stile della prima riga della seconda si perde; nei conflitti vince la prima;
  - se la prima sezione è vuota, prende tipo, spunta e stili di riga della seconda;
  - altrimenti, una prima sezione di tipo titolo o intestazione diventa corpo;
  - il cursore va nel punto di giunzione.
- Una versione remota viene caricata solo se è diversa dall'ultimo contenuto consegnato dall'editor e nessuna riga ha il focus.
- Tabelle:
  - una nuova tabella contiene «Colonna 1», «Colonna 2» / «Elemento 1», «Elemento 2»;
  - «+ Riga» aggiunge una riga in fondo e «+ Colonna» una colonna a destra;
  - «- Riga» e «- Colonna» tolgono sempre l'ultima, con un minimo di una riga e una colonna;
  - Tab passa alla cella successiva e, nell'ultima cella, aggiunge una riga; Maiusc+Tab torna alla cella precedente.
- Inserimento:
  - una tabella va dopo la parte attiva e, se la parte successiva non è testo, è seguita da una sezione vuota;
  - un'immagine va dopo la parte attiva ed è sempre seguita da una nuova sezione vuota;
  - all'apertura la parte attiva è la seconda, o la prima se ce n'è una sola.

## text-line
- Scorciatoie Markdown. Si applicano dopo ogni modifica, su ogni riga del testo, anche a testo incollato:
  - «# », «## », «### » a inizio riga → stile `h1`, `h2`, `h3`, e il prefisso viene tolto;
  - «[ ] » a inizio riga, con davanti al più «-», «*» o «•» → «○ »;
  - «[x] » o «[X] » con lo stesso schema → «● »;
  - «- » o «* » dopo un eventuale rientro, se non seguito da «[», «○» o «●» → simbolo del livello e spazio.
- Simbolo di elenco: il livello è il numero di spazi diviso 2 e i simboli si alternano a ciclo: «•», «◦», «▪».
- Invio senza Maiuscole:
  - checklist con testo → nuova riga «○ » con lo stesso rientro; checklist vuota → toglie 2 spazi di rientro (e diventa «○ ») oppure, senza rientro, toglie il simbolo;
  - elenco puntato con testo → nuova voce con il simbolo del livello; voce puntata vuota → riduce il rientro aggiornando il simbolo, oppure toglie il simbolo;
  - elenco numerato con testo → nuova voce «N+1. »; voce numerata vuota → riduce il rientro tenendo il numero, oppure toglie il numero;
  - righe `title`/`h1`/`h2`/`h3` → a capo con la nuova riga in stile corpo; se il cursore è all'inizio di una riga con testo, lo stile scende con il testo e la riga vuota sopra diventa corpo.
- Backspace con il cursore subito dopo il prefisso di una voce di checklist o puntata: se c'è rientro lo riduce di 2 spazi (la checklist diventa «○ »); altrimenti toglie il prefisso. Le voci numerate non hanno un comportamento speciale.
- Tab e Maiusc+Tab agiscono su ogni riga selezionata:
  - voci puntate, checklist e numerate guadagnano o perdono 2 spazi di rientro (il simbolo puntato si aggiorna); senza rientro, Maiusc+Tab toglie il simbolo;
  - righe normali: Tab aggiunge 2 spazi e Maiusc+Tab ne toglie fino a 2.
- Checklist:
  - il tocco conta se cade entro il prefisso più un carattere; tra due cambi fatti con un tocco devono passare almeno 250 ms;
  - il pulsante checklist alterna «○»/«●» (anche «[ ]»/«[x]») sulla riga del cursore; altrimenti mette davanti «○ » togliendo gli altri prefissi.
- Stile da «Aa» o dal menu rapido, sulle righe selezionate:
  - prima si tolgono i prefissi esistenti: «#…», simboli di elenco o checklist, «-», «*», «[ ]», «[x]», «N.», «>», «```»;
  - titolo, intestazioni e corpo diventano stile di riga;
  - elenco puntato, checklist, numerato, citazione e monospazio diventano rispettivamente il prefisso «• », «○ », «1. », «> », «``` », con stile di riga corpo.
- Stili di riga dopo una modifica:
  - le righe prima della modifica tengono il loro stile e quelle dopo scalano della differenza di righe;
  - se si inseriscono a capo all'inizio di una riga senza cancellare nulla, gli stili da quella riga in giù scendono e le nuove righe sono corpo;
  - negli altri casi la prima riga toccata tiene il proprio stile se prima del punto modificato c'era del testo; altrimenti prende lo stile dell'ultima riga toccata, o il proprio se quella non ne ha;
  - ogni riga nuova creata dalla modifica è corpo.

## editor-suggestions
- Si sta scrivendo un tag quando il testo prima del cursore finisce con «#» seguito da `[a-zA-Z0-9_-]*`, all'inizio o dopo uno spazio.
- Si mostrano al massimo 5 suggerimenti: i tag esistenti il cui nome contiene il testo digitato, senza distinguere maiuscole e minuscole. Scegliere un tag sostituisce il testo dal «#» al cursore con «#nome » e il cursore va dopo lo spazio.
- Il menu rapido compare quando il testo dell'intera sezione comincia con «/», oppure, sul telefono, quando si tocca il suo pulsante sulla barra sopra la tastiera. Scegliendo una voce si toglie dalla riga corrente «/» seguito da lettere e cifre e dagli spazi successivi, se la riga comincia con «/».

## drawing-canvas
- Spessore del tratto: 3 per la penna, 20 per la gomma. L'immagine esportata è 800×600 con sfondo bianco.
