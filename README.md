# Kato Kiosk Guide

One internal step-by-step guide, `Kato_Kiosk_Guide.tex`, split by who does
the work:

| Section | Audience | Covers |
|---|---|---|
| Part 1 | Account Managers | Command Centre: location, kiosk, prep checks, credentials, installation record. |
| Part 2 | IT | Silent app install (N-central script or manual) and kiosk lockdown. |
| Appendix A | IT | Building the machine: FreedomPay FCC install, PAL packages, verification. Once per machine, before Part 2. |
| Appendix B | Both | One-page quick reference. |
| Appendix C | IT | The N-central install script, printed on its own pages. |

## Build

Authored for **Overleaf** (or any full TeX Live install).

- **Compiler:** pdfLaTeX
- **Format:** A4
- **Shared styling:** `wkg-preamble.tex` — kept separate so branding changes
  are made in one place.

`Kato_Kiosk_Guide.tex` is the main document. On Overleaf, set the compiler to
*pdfLaTeX* in *Menu → Settings*.

All packages used (`inter`, `tcolorbox`, `tikz`, `listings`, `tabularx`,
`lastpage`, `upquote`, `attachfile2`, …) ship with the standard Overleaf TeX Live distribution — no
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
