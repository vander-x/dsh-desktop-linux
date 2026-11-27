# STATUS

## Onde parei

- Build local `exit=0` com tray, ícone e **Office nativo**: AppImage de 411 MB em `dist/`.
- `verify-appimage.sh` → `cli: dump-config ok (1287 lines)` / `office: native LibreOfficeKit (linux-x64-glibc)` / `boot: window opened without fatal error`.
- App instalado e aberto: janela `deepseek-ai-dsh-desktop | DSH Local Build`, Host em `127.0.0.1`, tray registrado no `StatusNotifierWatcher` (quickshell).
- CI run `45937090392` em andamento para republicar `v0.2.2-rc.5` (release antigo removido).

## Decisões

- Office nativo entra via `pnpm add @deepseek-ai/libreoffice-kit@0.2.4` no `build.sh`, **não** no patch:
  alterar o lockfile quebraria a aplicação do patch em tags futuras.
- Seletor `linux-<arch>-glibc` corrigido no patch, para quando o upstream adotar 0.2.4 sozinho.

## Próximo passo

- Confirmar run do CI e baixar o AppImage do Release novo.
- Tarefa real de modelo: exige `DEEPSEEK_API_KEY` ou sign-in na janela.

## Pendências conhecidas

- `desktopName` não definido: aviso do electron-builder sobre WM_CLASS (janela funciona).
- `desktop login shell: /usr/bin/bash failed (timeout)` em alguns boots.
- Smoke do pnpm já estourou timeout uma vez com load average 9,7; re-executar em máquina ociosa resolveu.
