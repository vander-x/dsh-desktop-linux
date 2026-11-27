# DeepSeek Harness desktop para Linux (não oficial)

AppImage do **DeepSeek Harness Desktop** para Linux x64, recompilado do código-fonte oficial
([deepseek-ai/deepseek-harness](https://github.com/deepseek-ai/deepseek-harness), MIT), porque a
DeepSeek publica instaladores apenas para macOS e Windows.

O upstream já prevê Linux (`electron-builder` com alvo `AppImage`, Landlock, fallback WebAssembly do
LibreOfficeKit, engines `libreoffice-kit-linux-*-glibc`). O que falta é o gate de pacote e duas
particularidades de execução no Linux, todas em `patches/linux-x64.patch`:

| Patch | Por quê |
|---|---|
| alvo `linux-x64` em `package-target.ts` e `desktop-build-paths.mjs` | sem isso o pipeline recusa empacotar |
| `executableName` no bloco `linux` | electron-builder derivava `@deepseek-aidsh-desktop`, nome inválido |
| sem política de update no manifesto Linux | o app só implementa política para macOS/Windows e abortava no boot |
| Host roda em Node standalone | sharp/libvips segfaulta dentro do Electron no Linux ([electron#46323](https://github.com/electron/electron/issues/46323)) |
| `runtime/dsh` desempacotado do asar | Node real não lê caminhos dentro de `.asar` |

## Instalar

```sh
DSH_DESKTOP_REPO=seu-usuario/dsh-desktop-linux ./install.sh
```

Instala em `~/.local/opt/dsh-desktop/`, link em `~/.local/bin/dsh-desktop` e entrada no launcher.

## Atualizar

O workflow roda todo dia: se `@deepseek-ai/dsh@latest` mudou, rebuilda e publica um release novo.
Localmente, rode `install.sh` de novo.

## Build local

```sh
scripts/build.sh                # versão do npm latest
scripts/build.sh dsh-v0.2.2-rc.5
```

Requer Node ≥ 24.22.3, pnpm 11.28.5, `tar` com xz e ~10 GB livres. Saída em `dist/`.

Se o build estourar memória em máquina de 8 GB, use `DSH_GATE_CONCURRENCY=1`.

## Requisitos (medidos no binário)

| Dependência | Versão mínima | Como foi medido |
|---|---|---|
| glibc | 2.28 | maior símbolo em `runtime/bin/node` (`objdump -T`) |
| libstdc++ | `GLIBCXX_3.4.21` (GCC 5+) | `objdump -T` em `node` e `sharp` |
| Electron | glibc 2.25 | `objdump -T` em `deepseek-harness` |
| Libs de desktop | GTK3, NSS, ALSA, X11/Wayland | `ldd` do binário Electron |

Na prática: Ubuntu 20.04+, Debian 10+, Fedora 30+, Arch, qualquer desktop moderno. Não roda em
distros com glibc < 2.28 (RHEL 7, Ubuntu 16.04) nem em ambiente sem servidor gráfico.

## Limitações

- Build não oficial e sem assinatura. Para executar direto precisa de `libfuse2`; sem ele use
  `--appimage-extract-and-run`. O launcher usa `--no-sandbox` porque o AppImage não preserva o
  `chrome-sandbox` SUID.
- Office usa o engine WebAssembly, não o LibreOfficeKit nativo (o nativo Linux existe no npm como
  `libreoffice-kit-linux-x64-glibc`, mas o seletor do upstream pede `linux-x64` e cai no wasm).
- Sem auto-update pelo servidor da DeepSeek (não há feed Linux): atualize pelo release deste repo.
- O Host roda em Node bundle próprio; extensões que esperam APIs exclusivas do Electron podem não
  funcionar.

## Créditos

Todo o código é da DeepSeek (MIT). Este repositório carrega o patch de plataforma e o empacotamento.
