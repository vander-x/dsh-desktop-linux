# STATUS

## Onde parei

Build completo verde (`exit=0`) com `patch` aplicado sobre `dsh-v0.2.2-rc.5`:

- smoke empacotado: `{"node":"24.21.0","platform":"linux","arch":"x64","koffi":true,"sharp":true,"html":true,"pty":true,"pnpm":true,"grep":true,"glob":true}`
- CLI offline plugin install/remove: passou
- Host subiu e serviu web (`dsh web: http://127.0.0.1:...`)
- Office: DOCX, XLSX, PPTX → PDF, image rendering, conversion, recalculation
- `scripts/verify-appimage.sh dist/*.AppImage` → `cli: dump-config ok (1287 linhas)` / `boot: janela abriu sem erro fatal`
- `dsh --profile headless "diga ok"` → só `MISSING_CREDENTIAL: llm-deepseek` (esperado sem chave)

## Próximo passo

- Rodar `scripts/build.sh` (validação do fluxo completo: clone → patch → install → AppImage).
- Com `DEEPSEEK_API_KEY` exportada, provar uma tarefa real: `dsh --profile headless "liste os arquivos"`.
- Publicar no GitHub e disparar o workflow `build-appimage`.

## Pendências conhecidas

- `desktop login shell: /usr/bin/bash failed (timeout)` no boot; sem impacto observado.
- `desktopName` não definido: o WM_CLASS da janela não casa com o `.desktop` (aviso do electron-builder).
- Patch com 21 arquivos; reaplicar sempre sobre a tag da vez.
