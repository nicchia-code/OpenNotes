---
status: approved
base:
  navigation/app-window.md: d1f6ead0dfb897e88acc34d93e0e784ae607d9876b0ffd67e0ec0e24fc8d0154
  requirements/rules/navigation.md: fa749c2ce2e3afe27992303cd1909ed4c6a549aeaed5081d793571a83cd8d3df
  requirements/tech/general.md: a55c2e2b7537842d56a3b0668ddd6bd865390be4ec9f5b1d82f0fff2fc10dd6a
delete: []
request: 2026-10-17T22-56-31
created: 2026-10-17T21:03:20.035Z
label: macOS window startup
---
# Show desktop window when the interface is ready

Su macOS l'app parte senza errori ma la finestra non compare: il MainMenu.xib la crea nascosta (visibleAtLaunch=NO), il motore Flutter su macOS parte solo quando la finestra compare, quindi il codice che dovrebbe mostrarla non gira mai.

Decisioni prese nell'intervista:
- La finestra compare quando l'interfaccia è pronta (prima schermata disegnata), allo stesso modo su Linux, macOS e Windows, non più mentre l'app si prepara.
- Nessun comportamento nuovo se la preparazione all'avvio fallisce.
- Su macOS si usa lo schema ufficiale di window_manager: finestra del xib visibile come nel template Flutter, nascosta subito dal plugin e mostrata dall'app.
