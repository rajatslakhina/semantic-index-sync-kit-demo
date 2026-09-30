# SemanticIndexSync — Demo App

**Watch an on-device semantic index go partially blind when the OS ships a new embedding model, keep answering on the keyword floor while it does, and climb back one budgeted background pass at a time.**

This is the runnable companion to [**semantic-index-sync-kit**](https://github.com/rajatslakhina/semantic-index-sync-kit) — a SwiftUI host for the library's workbench view. The app is deliberately thin: it owns the corpus and the budget (product decisions), and the library owns every rule about epochs, merging and admission control.

---

## Why this matters

A cosine similarity between a query vector from model revision 4 and a stored vector from revision 3 is a perfectly well-formed number. It is finite, it sorts, it renders in a list — and it is noise. Nothing throws, nothing logs, nothing crashes. The user simply finds that the search box which answered their question last week now returns the wrong three notes, and quietly concludes the feature is bad.

That failure is invisible in a code review and invisible in a crash dashboard. The only way to see it is to make the embedding space an explicit identity and then *watch what the system does* when that identity changes. That is what this app is for.

---

## What you can do in it

The app opens on a fully indexed corpus with a query already run, so there is something real on screen before you touch anything.

| Control | What it demonstrates |
|---|---|
| **Search** | Hybrid ranking. Each hit is tagged `MEANING`, `HYBRID` or `KEYWORD`, so you can see which scoring path actually produced it. |
| **Coverage bar** | `Completeness` — the fraction of the live corpus the query could search *by meaning*, and an honest one-line summary. It is a required field of every result, not an optional diagnostic. |
| **Ship an OS model revision** | Bumps the embedding epoch. Coverage drops to **0%**, the status pill flips to *Degraded*, and every hit re-tags as `KEYWORD` — the search box still works, on the lexical floor. |
| **Roll the model revision back** (same button, after a bump) | The payoff for keying vectors by chunk *and* epoch: the previous space is still on disk, so coverage returns to 100% with **zero** re-embedding. |
| **Thermal state / Low Power Mode** | Admission control — visible once there is queued work, i.e. after a model bump. Set thermal to *Serious* and the next pass returns a **typed refusal** (`thermal serious exceeds ceiling fair`) instead of silently doing nothing. (On a fully covered index there is nothing to defer, so a pass correctly reports "nothing queued" instead.) |
| **Run one background pass** | Re-embeds 8 passages under the budget. Coverage climbs, hits re-tag to `MEANING`/`HYBRID`, and the queue is resumable — a deferred pass loses no work. |
| **Reset** | Puts the corpus back. Each sync retires a document — the peer's delete wins its conflict — so without this the most interesting button eventually empties the app. |
| **Sync from peer device** | Both devices edit from the same shared history while offline: this one edits two documents, the peer deletes one and edits the other. Neither write saw the other, so the merge is **genuinely concurrent** — the one case last-writer-wins cannot represent. The log reports `concurrent merges resolved 2 · tombstones upheld 1`. (Building the peer's records from the *current* local version instead would make them strictly newer, LWW would handle them correctly too, and the demo would prove nothing — `OfflineEditScenarioTests` asserts this against the shipped builder, not a re-implementation of it.) |

The interesting sequence is: **ship a model revision → search → run passes one at a time.** That is the whole thesis in about four taps.

---

## Screenshots

**There are none, and this section exists to say so plainly rather than leave a gap.**

No screenshot of this app running exists, because the app was never run. See *Verification* below for exactly what did and did not happen — in particular, "builds for a Simulator" and "ran on a Simulator" are two different claims and only one of them is made here.

---

## How to run it

```bash
git clone https://github.com/rajatslakhina/semantic-index-sync-kit-demo.git
cd semantic-index-sync-kit-demo
open Demo.xcodeproj
```

Then in Xcode: select the **Demo** scheme, pick any iOS Simulator, and Build & Run (⌘R).

On first open Xcode resolves the library from GitHub — this project references it as a **remote** Swift Package at a released version, not a local path and not a branch:

```
repositoryURL = "https://github.com/rajatslakhina/semantic-index-sync-kit.git";
requirement = { kind = upToNextMajorVersion; minimumVersion = 2.0.0; };
```

Two deliberate choices there, and it is worth being exact about what each one does:

- **Not `branch = main`.** Branch-tracking means every clone and every CI run resolves whatever `main` happens to be that day — the wrong default for an artifact meant to still build a year from now.
- **`upToNextMajorVersion` is a *range*, not a pin.** On its own it would accept any 2.x, so a clone next year could resolve a newer library than this one was built against. What makes the resolution reproducible is that **`Package.resolved` is committed** — deliberately *not* gitignored, unlike the Xcode default — so the exact revision is recorded in the repository (`be41382`, tag `v2.0.0`). The range says which upgrades are acceptable; the lockfile says which revision you actually get.

Requires Xcode 16 or later and an iOS 17 deployment target.

---

## Verification — exactly what happened

Three separate claims, kept separate on purpose.

**1. The library was genuinely built and tested.** A clean zero-warning build (`rm -rf .build && swift build -Xswiftc -warnings-as-errors`) and **86 of 86 tests passing** on Swift 6.1.2, plus a mutation check. Documented in [its README](https://github.com/rajatslakhina/semantic-index-sync-kit#verification). This actually happened.

**2. This app compiles against the real remote library — verified by CI, and it caught a real break first.** The workflow runs `xcodebuild -resolvePackageDependencies` and then `xcodebuild build -scheme Demo -destination 'generic/platform=iOS Simulator'` on `macos-15`. It **passed**, which establishes two things: the library genuinely resolves from GitHub at the recorded revision, and this app — including the library's SwiftUI view — compiles against it.

It is worth saying how it got there, because the first run **failed**, and that failure is the argument for having the job at all. The library's `v2.0.0` removed a field from `SeedDocument`, and `DemoCorpus.swift` — which lives in *this* repository and so was never compiled while the library was being developed — still passed it. Nothing local caught it: the package's own CI was green, because the package was fine. Only the job that builds this app against the published library surfaced it, as `EmitSwiftModule normal x86_64 (in target 'Demo')`, exit code 65. That is precisely the seam two repositories create, and precisely why the demo has CI of its own rather than relying on the library's.

Read the [Actions tab](../../actions) for the live answer rather than trusting this paragraph; a README is not evidence.

**3. Run on a Simulator: NO. This did not happen.** The app was never launched, no UI was ever observed, and no screenshot was taken. The table above describes what the code does, traced by hand — not something anyone watched happen. **A passing build is not a launch, and nothing here should be read as one.**

What blocked it, specifically: this was an unattended scheduled run. Computer-use access to Xcode and Simulator *was* granted, but the project could not be opened — background app control could not type a path into Finder's "Go to Folder" sheet, refusing with:

> `This element (AXTextField at element_index 2 via AXWindow>AXSheet) cannot be typed into while Finder is in the background — this app does not expose its content as an accessible text field (its AXFocusedUIElement is not text-editable). Options: call app_release then use the display-scope tools (which take over the screen), or describe the goal and try a different path.`

The only remaining path was a full-screen takeover of a machine that had the user's own Finder windows open, with nobody present to supervise it. That was declined rather than risk disturbing unrelated work.

One further honesty note, since it is the kind of thing a reviewer should not have to discover: `IndexWorkbenchView.swift` has never been compiled on this machine — the package guards it behind `#if canImport(SwiftUI)`, so the Linux build skips it entirely. Its view model and configuration *were* separately type-checked under Swift 6 strict concurrency with that guard removed. The CI job above is the only thing that compiles the view itself.

## Why two repositories

The library ships as a clean SPM package with no app target of any kind, so anyone can depend on it without inheriting a demo. The demo is a separate Xcode project that consumes it exactly the way a real client would — over the network, at a pinned version. Splitting them is what makes the dependency claim checkable rather than asserted: if the remote reference were wrong, CI here would fail to resolve.

---

## License

MIT — see [LICENSE](LICENSE).
