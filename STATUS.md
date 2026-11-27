# STATUS

## Onde parei

- Repo `~/Projects/dsh-desktop-linux` com `patches/linux-x64.patch` (12 arquivos), workflow diário,
  `scripts/build.sh` e `install.sh`.
- AppImage construído localmente em `.build/upstream/apps/desktop/.desktop-build/targets/linux-x64/unsigned-artifacts/`.
- Smoke empacotado (pnpm, koffi, sharp, html, pty, search) passa quando roda sob `runtime/bin/node`.
- App abre (`--no-sandbox`) sem erro de política; avisos: probe do shell de login (bash timeout) e zsh ausente.

## Próximo passo

- Rodar `build13` e confirmar `exit=0` + smoke empacotado verde no log.
- Testar anexo de imagem dentro do app (o caminho que estourava com sharp no Electron).
- Publicar: criar repo no GitHub e rodar o workflow `build-appimage`.

## Pendências conhecidas

- `desktop login shell: /usr/bin/bash failed (timeout)` — investigar se afeta terminal.
- `command-management.ts` procura `runtime/primary-runtime/dependencies/node/bin/node`, que o runtime
  preparado não cria; a instalação do comando `dsh` pelo app pode falhar.
