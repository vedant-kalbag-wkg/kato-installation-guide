# Kato Kiosk Installation Guide

Internal step-by-step guide for creating, configuring and installing a Kato
kiosk — from the Command Centre record through FreedomPay FCC, the Kato app,
kiosk lockdown and the installation record.

Written for field installers and operations. Six stages, each with a
*Done when* gate, plus a final checklist and a troubleshooting table.

## Build

Authored for **Overleaf** (or any full TeX Live install).

- **Main document:** `Kato_Kiosk_Installation_Guide.tex`
- **Compiler:** pdfLaTeX
- **Format:** A4

On Overleaf, set the main document above and the compiler to *pdfLaTeX* in
*Menu → Settings*. All packages used (`inter`, `tcolorbox`, `tikz`, `listings`,
`tabularx`, `lastpage`, …) ship with the standard Overleaf TeX Live
distribution — no manual installation required.

## Sources

Content is drawn from the internal Obsidian notes *Installation Guide* and
*Configuration Guide*, with FreedomPay detail cross-checked against the
certified **FreedomPay Windows FCC — Auth & Capture Integration Guide**
(CER-3425).

## Assets

- `images/wkg-logo-horizontal.png`, `images/wkg-logo-stacked.png` — official
  We Know Group logo assets (cover, page headers). Never redraw or regenerate
  these.
- `images/cc-*.png` — Command Centre screenshots (locations, kiosks, prep
  checks, API keys, installations).
- `images/fcc-*.png` — FreedomPay FCC installer and log screenshots.

## Branding

Follows the *We Know Group Brand Guidelines V2 2023* and mirrors the FCC
certification guide so the two documents read as a set: Azure `#00A6D3` hero
colour, Graphite `#121212`, Night Blue `#0C2752`, and the Inter typeface as the
licensed stand-in for Circular Pro.
