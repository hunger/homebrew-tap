# homebrew-tap

Homebrew formulae that install prebuilt GitHub release binaries on macOS and Linux.

| Formula       | Version               | Last Updated          | Notes                                              |
|---------------|-----------------------|-----------------------|----------------------------------------------------|
| [`maki`](https://github.com/tontinton/maki) | 0.5.5 | 2026-09-16T18:14:15Z | musl on Linux; use `brew upgrade`, not `maki update` |
| [`nvim-nightly`](https://github.com/neovim/neovim) | 0.13.0-dev-1651 | 2026-09-16T07:45:13Z | prebuilt `nightly` release, installed as `nvim-nightly`; coexists with `neovim` |
| [`kache`](https://github.com/kunobi-ninja/kache) | 0.22.0 | 2026-09-14T19:27:04Z | musl static binaries on Linux; shell completions |
| [`release-plz`](https://github.com/release-plz/release-plz) | 0.3.167 | 2026-09-14T08:00:13Z | musl on Linux; no Intel macOS asset, builds from source there |
| [`helix-nightly`](https://github.com/helix-editor/helix) | 2026.07.23.1603 | 2026-09-11T15:03:51Z  | built from a pinned `master` commit, installed as `hx-nightly`; Linux x86_64 bottle hosted on this repo's Releases, other platforms build from source (~2 min) |
| [`jj-starship`](https://github.com/dmmulroy/jj-starship) | 0.7.4 | 2026-09-11T14:51:57Z  | musl static binaries on Linux                      |
| [`crates-lsp`](https://github.com/MathiasPius/crates-lsp) | 0.4.3 | 2026-09-11T14:51:57Z  | glibc-linked binaries on Linux (no musl upstream)  |
| [`devbox`](https://codeberg.org/devbox-rs/devbox) | 1.0.1 | 2026-09-11T14:51:57Z  | Linux x86_64 only (sole upstream asset); Codeberg, livecheck via Forgejo API |

## Use

Push this directory to `github.com/hunger/homebrew-tap`, then:

```sh
brew install hunger/tap/jj-starship
```

Homebrew 6 treats third-party taps as untrusted by default. The tap-qualified
install form above trusts only that formula; `brew trust hunger/tap` trusts the whole tap.

Homebrew 6 no longer installs formula files from arbitrary paths. To use this
checkout locally without a remote, link it into the Taps directory once:

```sh
ln -s "$PWD" "$(brew --repository)/Library/Taps/hunger/homebrew-tap"
brew trust hunger/tap
brew install hunger/tap/jj-starship
brew test hunger/tap/jj-starship
```

## Updating a formula

1. Bump `version`.
2. Download each release asset and update its `sha256`
   (`curl -sSL <url> | sha256sum`).
3. `brew style Formula/`, `brew audit --tap hunger/tap`, then `brew reinstall hunger/tap/<name>` and `brew test hunger/tap/<name>`.

`brew livecheck hunger/tap/<name>` reports the newest upstream tag.

## Automatic updates

`.github/workflows/update.yml` runs every two hours (and on manual dispatch).
It calls `scripts/bump-formulae.py`, which for every formula that
`brew livecheck` reports as outdated:

1. rewrites the version in every `url` line and in the `version` line,
2. downloads each asset and refreshes its `sha256`,
3. runs `brew style`, `brew audit --strict`, `brew reinstall` and `brew test`
   on the runner (Linux x86_64),
4. reverts the file if anything fails.

Most formulae have the version in their URLs and are bumped by plain
substitution. Two other modes are selected with a `# bump:` comment in the
formula:

- `# bump: fixed-url` (nvim-nightly): the URLs point at the moving `nightly`
  tag and never change; the version comes from the formula's livecheck block
  (the release notes) and only `version` and the checksums are refreshed.
- `# bump: git-commit <commits API URL>` (helix-nightly): the URL pins a
  commit tarball. The branch head is fetched from the GitHub API, the commit
  in the URL is replaced, and `version` becomes the commit's UTC time as
  `YYYY.MM.DD.HHMM`.

### Bottles

Formulae marked `# bottle: x86_64_linux` (helix-nightly) are compiled on the
runner with `--build-bottle`, bottled, and the tarball is uploaded to a GitHub
Release on this repository tagged `<formula>-<version>`. The bottle block is
merged into the formula before the commit, so a pushed formula always has its
bottle available. Bottles are for Linux x86_64 with the default
`/home/linuxbrew/.linuxbrew` prefix only; everything else builds from source.
The newest five releases per formula are kept.

A bumped formula loses its old bottle block until the new bottle is built in
the same run. To re-bottle a formula without an upstream change, run the
workflow manually with its name in the "force" input.

Successful bumps are committed straight to the default branch, authored as
Tobias Hunger <tobias.hunger@gmail.com>; there are no pull requests. If any formula fails the
job is marked failed after committing the others, and the job summary lists
what went wrong.

The workflow uses the default `GITHUB_TOKEN` with `contents: write`, so no
extra secrets are needed. Branch protection on `main` must allow that token to
push (or be off). Note that commits made with `GITHUB_TOKEN` do not trigger
other workflows.

Run the script locally the same way: `python3 scripts/bump-formulae.py [FORMULA...]`
(`--no-verify` skips the install and test steps; `--bottle --bottle-root-url URL`
also builds bottles into `bottles/`; `--force NAME` processes a current formula).
