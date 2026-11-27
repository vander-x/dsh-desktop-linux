# STATUS

## Onde parei

Fluxo do objetivo validado de ponta a ponta:

- `scripts/build.sh dsh-v0.2.2-rc.5` → `exit=0`, AppImage 358 MB em `dist/`
- `scripts/verify-appimage.sh dist/*.AppImage` → `cli: dump-config ok (1287 lines)` / `boot: window opened without fatal error`
- CI `45923215870` → success em 6m39s; release `v0.2.2-rc.5` publicado por `github-actions[bot]`
- Artefato baixado do Release → `verify_exit=0`
- `install.sh` a partir do Release → sha256 `1e060f928f1a6afb`, idêntico ao artefato do CI
- Runtime sem chave: `dsh --profile headless "diga ok"` → `MISSING_CREDENTIAL` (esperado)

## Próximo passo

- Provar tarefa real de modelo: exige `DEEPSEEK_API_KEY` ou sign-in na janela.
- Opcional: `desktopName`/`syncDesktopName` para casar WM_CLASS (aviso do electron-builder).
- Opcional: investigar `desktop login shell: /usr/bin/bash failed (timeout)`.

## Pendências conhecidas

- Sem auto-update oficial no Linux: atualização = novo Release / `install.sh`.
- Patch com 22 arquivos e 607 linhas; aplicar sobre a tag da vez.
- AppImage não preserva SUID do chrome-sandbox: launcher usa `--no-sandbox`.
