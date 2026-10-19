---
status: approved
base:
  actors/user.md: 8f2bcb0d8af20f8335895b3b3e7d40a890b4a26a985f584f1c35e6f31562b054
  editor/note-editor.md: eb4712dcce93b040ed873590f791ebf5263692ba600bf8fd96ddb9c8242217cb
  requirements/rules/editor.md: 84f05aa6b684e605e8d41be3e9bd3d498e81e5f609ac2f75652ec896f17afd98
  requirements/data/editor.md: fd532310be9bce8d31068081ec474c35c498aedafa9c5e7305975880d6f0b552
  requirements/ui/editor.md: new
  requirements/tech/general.md: fb21faa2b5fb6a1d3210101899716d7e6d3c57a990242b9cbd39f7392cc3f75d
  specs.yaml: new
delete: []
request: 2026-10-19T16-37-06
created: 2026-10-19T14:48:52.321Z
label: Incolla immagini
---
# Incollare immagini

Oggi Ctrl/Cmd+V incolla solo testo: un'immagine negli appunti (screenshot, «Copia immagine» del browser) non entra nella nota. La richiesta chiede di poter incollare immagini.

Decisioni prese nell'intervista:
- Si incolla con Ctrl/Cmd+V e con la voce «Incolla» del menu contestuale (tasto destro su desktop, pressione prolungata su mobile); niente inserimento dalla tastiera Android.
- L'immagine va dove la mette «Inserisci immagine»: dopo la parte attiva, seguita da una sezione di testo vuota con il focus; salvataggio immediato.
- Se gli appunti contengono anche testo semplice vince il testo; l'immagine si incolla solo senza testo.
- Funziona solo nelle sezioni di testo: in una cella di tabella si incolla solo testo e l'immagine viene ignorata.
- Solo dati immagine: i file copiati nel Finder o in Esplora risorse non si incollano come immagini.
- Formato: PNG, JPEG, GIF e WebP restano come sono, gli altri formati diventano PNG.
- Le immagini con il lato lungo oltre 2048 px si rimpiccioliscono mantenendo le proporzioni, nello stesso formato (JPEG con qualità 85); una WebP rimpicciolita diventa PNG; le GIF non si rimpiccioliscono.
- Se l'immagine non si può salvare compare l'avviso in basso «Immagine non incollata» e la nota non cambia.
- Libreria per gli appunti: `super_clipboard`; ridimensionamento e ricodifica con la libreria `image`.

Scelte dell'agente da verificare:
- Un JPEG incollato si salva con estensione `jpg`.
- Le nuove tecnologie sono scritte anche nelle Specs, che il progetto finora non aveva: contengono solo il linguaggio, Flutter e le due nuove librerie; le altre restano nei Requirements `tech`.

## Already present
- `specs#languages` — Dart con vincolo SDK `^3.11.4` in `pubspec.yaml`
