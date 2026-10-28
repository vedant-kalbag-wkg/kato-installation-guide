# Kato Kiosk Guide

One internal step-by-step guide, `Kato_Kiosk_Guide.tex`, split by who does
the work:

| Section | Audience | Covers |
|---|---|---|
| Part 1 | Account Managers | Command Centre: location, kiosk, configuration, prep checks, installation record; send IT the kiosk's link. |
| Part 2 | IT | Copy the Kiosk ID and generate the API key from that link (used at once, never saved). Option A: one N-central setup script builds the machine, installs the app and locks it down. Option B: the same by hand. |
| Appendix A | IT | Building the machine by hand: FreedomPay FCC install, PAL packages, verification, troubleshooting. Once per machine; the setup script does it as its step 1. |
| Appendix B | Both | One-page quick reference. |

## Build

Authored for **Overleaf** (or any full TeX Live install).

- **Compiler:** pdfLaTeX
- **Format:** A4
- **Shared styling:** `wkg-preamble.tex` — kept separate so branding changes
  are made in one place.

`Kato_Kiosk_Guide.tex` is the main document. On Overleaf, set the compiler to
*pdfLaTeX* in *Menu → Settings*.

All packages used (`inter`, `tcolorbox`, `tikz`, `listings`, `tabularx`,
`lastpage`, `upquote`, …) ship with the standard Overleaf TeX Live distribution — no
manual installation required.

## Sources

The internal Obsidian notes **Installation Guide** and **Configuration Guide**
are the sole sources of truth for this guide. Do not reintroduce content
from the FreedomPay certification guide — it is outdated.

## Assets

- `images/wkg-logo-horizontal.png`, `images/wkg-logo-stacked.png` — official
  We Know Group logo assets (cover, page headers). Never redraw or regenerate
  these.
- `images/cc-*.png` — Command Centre screenshots (locations, kiosks, prep
  checks, API keys, installations).
- `images/fcc-*.png` — FreedomPay FCC installer and log screenshots.
- `images/ncentral-powershell.png` — N-central System Shell in PowerShell
  mode, where the setup scripts are pasted.
- `scripts/v2/` — the setup scripts the guide's Part 2 Option A uses. They are
  pasted into the N-central remote connection's PowerShell (running as
  SYSTEM), or run from the N-central repository with parameters. The guide
  links to them on `main` (raw.githubusercontent.com), so a push to `main`
  updates what IT get.
  - `1-FreedomPay.ps1` — Appendix A for one region (`UK`, `DE`, `ES`, `PT`).
  - `2-Kiosk-App.txt` — downloads, installs and checks the Kato app as
    SelfBooker.
  - `3-Shell-Lock.txt` — Shell Launcher lockdown, then a restart into Kato.
  - `setup_kiosk.ps1` — all three steps in one script, with every setting
    at the top. It holds the full code of each step, so rebuild it after
    editing a step. Its output is also saved to `C:\installation.log`.

  Every script must survive being pasted line by line into PowerShell 5.1:
  `} catch {` / `} else {` on the same line as the closing brace, and no bare
  `exit`. The guide's command boxes follow the same rule: every line is a
  complete command, short enough not to wrap in the PDF.
- `scripts/Install-Kiosk.txt` — the earlier N-central install script (app
  install only), superseded by `scripts/v2/` and no longer in the guide.
  `.github/workflows/publish-install-script.yml` still re-uploads it to the
  `install-script` GitHub release when it changes on `main`, so old links keep
  working. The PDF does not include any script, so Overleaf does not need the
  `scripts/` folder.
- `scripts/Get-KioskFile.ps1` — N-central repository script that downloads a
  file from an HTTPS link into a folder on one or many kiosks, replacing any
  older copy (`-Url … -Destination … [-FileName …]`). Guide: *Push a file to
  kiosks from N-central*, option 2.

## Branding

Follows the *We Know Group Brand Guidelines V2 2023*: Azure `#00A6D3` hero
colour, Graphite `#121212`, Night Blue `#0C2752`, and the Inter typeface as the
licensed stand-in for Circular Pro.
