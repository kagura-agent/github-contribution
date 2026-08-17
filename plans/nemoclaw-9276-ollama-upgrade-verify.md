# Plan: NemoClaw #9276 — Ollama upgrade path claims success while daemon stays stale

## Context

- **Issue**: [Ubuntu 22.04][Onboard] local Ollama onboarding aborts after upgrade leaves daemon below required version
- **Regression**: worked v0.0.107 → broken v0.0.109 (commit 90f821e80 / PR #9157 raised `MIN_OLLAMA_VERSION` 0.7.0 → 0.32.9)
- **QA evidence**: official install.sh prints "Install complete" (its `trap install_success EXIT` fires on any exit) and exits 0, but binary AND daemon stay 0.23.4. NemoClaw then discovers staleness only in `assertOllamaUpgradeApplied` (called AFTER `installOllamaOnLinux` returns ok), and hard-aborts with "Restart the system daemon and rerun" — no recovery attempt.

## Root cause (NemoClaw-side)

`installOllamaSystem` (src/lib/onboard/install-ollama-linux.ts):
1. Runs official install.sh via `runOfficialInstallScript` — install.sh exit code is effectively trusted as "success" (runShell process.exit on non-zero, but install.sh can exit 0 without replacing the binary, e.g. PATH-resolution mismatch or silent download failure; its EXIT trap prints success regardless)
2. Applies loopback systemd override (may or may not restart daemon depending on sudo/unit detection)
3. **Returns `{ok: true}` without verifying the daemon actually advanced past `MIN_OLLAMA_VERSION`**

Verification only happens later in `setup-nim-ollama.ts` → `assertOllamaUpgradeApplied`, which hard-fails with a manual-restart message instead of recovering.

## Change list

1. **src/lib/onboard/install-ollama-linux.ts** — `installOllamaSystem`:
   - After the install + override sequence, verify the **running daemon** version via `getRunningOllamaDaemonVersion` (reuse from `../inference/ollama-version`).
   - If daemon is below `MIN_OLLAMA_VERSION`:
     - Attempt recovery: explicit daemon restart (systemd: `sudo systemctl restart ollama`; non-systemd/not-applicable: reuse existing `pkill -x ollama` + relaunch pattern already in the not-applicable branch), then re-probe once.
     - If still below minimum → return `{ok: false, mode: "system", binPath}` with a clear actionable message (installer did not take effect; binary/daemon still at X).
   - If daemon meets minimum → return ok:true (existing behavior for happy path).
   - Fresh installs (non-upgrade) skip the version gate (matches current docs: "Fresh installs skip this second probe").

2. **src/lib/onboard/install-ollama-linux-upgrade.test.ts** — new tests (upgrade path):
   - stale daemon + restart succeeds + re-probe new → ok:true, restart command invoked
   - stale daemon + restart attempted + still stale → ok:false with message
   - daemon already ≥ MIN after install → ok:true, no extra restart
   - non-upgrade (fresh) install → no version gate (ok:true)
   - verify recovery uses the right mechanism per systemd availability

3. **docs/inference/set-up-ollama.mdx** — fix stale doc: "currently `0.7.0`" → `0.32.9`; update post-upgrade paragraph to describe auto-restart + truthful failure instead of "stops if version remains below minimum".

## Implementation approach / patterns to reuse

- `getRunningOllamaDaemonVersion`, `getInstalledOllamaVersion`, `isOllamaVersionAtLeast`, `MIN_OLLAMA_VERSION` from `src/lib/inference/ollama-version.ts`
- Existing recovery patterns already in `installOllamaSystem`: `pkill -x ollama` + `ollama serve` relaunch (not-applicable branch); `ensureManagedOllamaLoopbackSystemdOverride` for systemd restart
- `runShellImpl` test seam already exists in `InstallOllamaLinuxOptions` — tests inject fake runners (existing test style in install-ollama-linux-upgrade.test.ts)
- Message wording follows `assertOllamaUpgradeApplied` style (ollama-install-menu.ts:221)

## Edge cases / ripple

- **systemd present + passwordless sudo**: override restart already runs; recovery = explicit `systemctl restart ollama` + re-probe
- **no systemd / override not-applicable**: existing pkill+relaunch branch; recovery reuses it then re-probes
- **install.sh legitimately fails (non-zero exit)**: runShell already process.exit → unchanged behavior
- **user-local mode**: never an upgrade (decideInstallOllamaLinuxMode rejects user-local upgrade) → untouched
- **Windows-host Ollama (host.docker.internal)**: not routed through this entry (menu gate) → untouched
- **macOS**: separate `install-ollama-macos.ts` path → untouched
- Keep `assertOllamaUpgradeApplied` as caller-side safety net (now redundant-but-harmless; passing it means verified)

## Test strategy

- Extend `install-ollama-linux-upgrade.test.ts` with the 4 cases above, using existing test seams (runShellImpl, waitForHttpImpl, sleepSecondsImpl, ensureManagedOllamaLoopbackSystemdOverrideImpl)
- Run: `npx vitest run --project cli src/lib/onboard/install-ollama-linux.test.ts src/lib/onboard/install-ollama-linux-upgrade.test.ts` (+ dependent onboard-selection tests if touched)
- Typecheck: `npx tsc -p tsconfig.src.json --noEmit`

## Risks

- Maintainer may prefer fixing install.sh invocation (e.g., unset OLLAMA_VERSION / verify binary path) over post-install verification — but verification is the root-cause fix on our side and matches issue's expected result ("confirms that the binary and serving daemon meet the minimum")
- Scope must stay minimal: don't refactor assertOllamaUpgradeApplied, don't touch user-local/macOS
- DCO: all commits `--signoff`, PR body must include Signed-off-by trailer (3 past failures — do not repeat)
