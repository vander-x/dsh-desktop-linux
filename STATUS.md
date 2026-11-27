# STATUS

## Onde parei

Ciclo completo fechado e verificado:

- `scripts/build.sh dsh-v0.2.2-rc.5` → `exit=0` (após reboot, `/tmp` limpo)
- `scripts/verify-appimage.sh dist/*.AppImage` → `cli: dump-config ok (1287 lines)` / `office: native LibreOfficeKit (linux-x64-glibc)` / `boot: window opened without error fatal` / `exit=0`
- AppImage em `dist/`: 411 MB (`430.040.289` bytes)
- Release publicado pelo CI (`v0.2.2-rc.5`, asset de 430 MB, digest `beeba970…`); hash local difere por não ser build bit-reprodutível
- App instalado: `~/.local/opt/dsh-desktop/dsh.AppImage`, launcher `~/.local/bin/dsh-desktop`, entrada `.desktop`, ícone 1024px
- Tray registrado no `StatusNotifierWatcher` do quickshell; janela `deepseek-ai-dsh-desktop`

## Causa das falhas intermitentes

`/tmp` é tmpfs de 5,3 GB e enchia durante empacotamento (`ETIMEDOUT`, `Host readiness exceeded 120s`, `write -122`). `build.sh` agora exporta `TMPDIR="$ROOT/.build/tmp"`.

## Próximo passo

- Tarefa real de modelo: precisa de `DEEPSEEK_API_KEY` em `~/.local/share/dsh/.env` ou sign-in na janela. Sem isso o runtime para em `MISSING_CREDENTIAL`.
- Opcional: `desktopName`/`syncDesktopName` para o aviso de WM_CLASS.

## Pendências conhecidas

- Auto-update oficial não existe no Linux: atualização = novo Release / `install.sh`.
- `desktop login shell: /usr/bin/bash failed (timeout)` em alguns boots.
- Patch com 22 arquivos; o upgrade do kit Office para 0.2.4 vive no `build.sh`, não no patch.
