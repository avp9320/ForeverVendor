# Forever Vendor

A tiny vendor-quality-of-life addon for **World of Warcraft: Forever**.

Forever Vendor has one job: get gray junk out of your bags without putting another permanent window on your screen.

## Features

- Automatically sells poor-quality (gray) items when you open a merchant.
- Re-checks every item immediately before selling it.
- Never intentionally sells white, green, blue, purple, or higher-quality items.
- Ignores gray items with no vendor value.
- Prints one compact summary after a sale, for example:
  - `Forever Vendor: Sold 8 junk items for 1g 42s 5c.`
- Says nothing when there is no junk to sell.
- No minimap button.
- No permanent UI.
- No external database or dependency.

## Commands

- `/fv status` — show current settings.
- `/fv on` — enable automatic junk selling.
- `/fv off` — disable automatic junk selling.
- `/fv summary on` — show the compact sale summary.
- `/fv summary off` — sell silently.
- `/fv sell` — manually trigger a junk sale while a merchant is open.

## Install

Place the `ForeverVendor` folder inside your WoW `Interface/AddOns` folder, then enable **Forever Vendor** on the AddOns screen.

GitHub releases are packaged automatically as installable `ForeverVendor` ZIP files for addon-manager use.

## Compatibility

Built for the same World of Warcraft: Forever addon baseline as the rest of the Forever addon suite (`Interface: 16001`). The code supports both legacy container functions and their `C_Container` equivalents where available.

## Version

0.1.2
