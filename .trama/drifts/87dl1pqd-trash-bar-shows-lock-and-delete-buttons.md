---
status: resolved
resolution: fix-code
refs:
  - desktop-layout
  - note/In trash
proposal: null
task: ps6i7ioy
origin: null
critical: false
option: 1
note: null
resolvedBy: fz9axufm
created: 2026-10-12T10:46:02.750Z
---
# Trash bar shows lock and delete buttons the Model leaves out

## What happens

Nel cestino la barra superiore mostra, oltre al menu azioni, il pulsante del lucchetto e il pulsante di eliminazione della nota. Il pulsante di eliminazione registra di nuovo la data di eliminazione della nota; il lucchetto protegge o sblocca la nota senza farla uscire dal cestino.

## What should happen

La descrizione di desktop-layout dice che i comandi della nota compaiono solo con una nota selezionata e fuori dal cestino, e che nel cestino ne resta solo il menu azioni. La Machine delle note, però, dice che dal pulsante di protezione della barra desktop si protegge o sblocca una nota nel cestino, e che il comando di eliminazione della barra riporta la nota nel cestino. Le due descrizioni non coincidono.

## Fix options

### Aggiornare la descrizione di desktop-layout

Nel cestino la barra mostra il menu azioni, il lucchetto e il pulsante di eliminazione, come già fa il codice e come dice la Machine delle note. Costo: una frase da riscrivere nel Modello di desktop-layout; il codice e il lavoro già fatto sul lucchetto nel cestino restano uguali.

### Lasciare solo il menu azioni nel cestino

Nel cestino la barra mostra soltanto il menu azioni, come scrive la descrizione di desktop-layout. Costo: si tolgono il lucchetto e il pulsante di eliminazione dalla barra del cestino, annullando il lavoro già fatto; la Machine delle note va cambiata, perché la protezione e l'eliminazione dalla barra nel cestino non esistono più, salvo che il menu azioni le offra.

## Where in the code

lib/ui/shell/mac_title_bar.dart: ramo della barra con nota selezionata nel cestino in MacTitleBar.build; lib/ui/shell/adaptive_app_shell.dart: _onDelete
