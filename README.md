# Kato Kiosk Guides

Two internal step-by-step guides, split by who does the work.

| Document | Audience | Covers |
|---|---|---|
| `Kato_Kiosk_Setup_Guide.tex` | IT | Building the machine: FreedomPay FCC install, PAL packages, verification. Done once per machine. |
| `Kato_Kiosk_Configuration_Guide.tex` | Account Managers & IT | Configuring a kiosk for an installation: Command Centre record and credentials (AM), then silent app install and kiosk lockdown (IT). |

The setup guide comes first — a machine must be built and verified before
its prep checks can be cleared in the configuration guide.

## Build

Authored for **Overleaf** (or any full TeX Live install).

- **Compiler:** pdfLaTeX
- **Format:** A4
- **Shared styling:** `wkg-preamble.tex` — both documents `\input` it, so
  branding changes are made in one place.

Each `.tex` produces its own PDF. On Overleaf, right-click a file and choose
**Set as main document** to compile that guide, then switch to build the other.
Set the compiler to *pdfLaTeX* in *Menu → Settings*.

All packages used (`inter`, `tcolorbox`, `tikz`, `listings`, `tabularx`,
`lastpage`, …) ship with the standard Overleaf TeX Live distribution — no
manual installation required.

## Sources

The internal Obsidian notes **Installation Guide** and **Configuration Guide**
are the sole sources of truth for these documents. Do not reintroduce content
from the FreedomPay certification guide — it is outdated.

## Assets

- `images/wkg-logo-horizontal.png`, `images/wkg-logo-stacked.png` — official
  We Know Group logo assets (cover, page headers). Never redraw or regenerate
  these.
- `images/cc-*.png` — Command Centre screenshots (locations, kiosks, prep
  checks, API keys, installations).
- `images/fcc-*.png` — FreedomPay FCC installer and log screenshots.
- `images/ncentral-powershell.png` — N-central System Shell, for the one-run
  install script.
- `scripts/Install-Kiosk.ps1` — the N-central install script. The guide prints
  it with `\lstinputlisting` and embeds it as a PDF attachment
  (`attachfile2`), so edit the script here, never in the `.tex`. Upload the
  `scripts/` folder to Overleaf alongside `images/`.

## Branding

Follows the *We Know Group Brand Guidelines V2 2023*: Azure `#00A6D3` hero
colour, Graphite `#121212`, Night Blue `#0C2752`, and the Inter typeface as the
licensed stand-in for Circular Pro.
