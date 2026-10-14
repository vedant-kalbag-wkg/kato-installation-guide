# Kato Kiosk Guide

One internal step-by-step guide, `Kato_Kiosk_Guide.tex`, split by who does
the work:

| Section | Audience | Covers |
|---|---|---|
| Part 1 | Account Managers | Command Centre: location, kiosk, configuration, prep checks, installation record; send IT the kiosk's link. |
| Part 2 | IT | Copy the Kiosk ID and generate the API key from that link (used at once, never saved), silent app install (N-central script or manual), kiosk lockdown. |
| Appendix A | IT | Building the machine: FreedomPay FCC install, PAL packages, verification. Once per machine, before Part 2. |
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
- `images/ncentral-powershell.png` — N-central System Shell, for the one-run
  install script.
- `scripts/Install-Kiosk.txt` — the N-central install script. The guide's
  *Open Install-Kiosk.txt* button links to it on GitHub (`main`), so edit the
  script here and push it; the link always serves the latest version. It is
  PowerShell, but stays `.txt` so it opens in Notepad. The PDF
  does not include it, so Overleaf does not need the `scripts/` folder.

## Branding

Follows the *We Know Group Brand Guidelines V2 2023*: Azure `#00A6D3` hero
colour, Graphite `#121212`, Night Blue `#0C2752`, and the Inter typeface as the
licensed stand-in for Circular Pro.
