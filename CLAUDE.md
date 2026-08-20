# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

得正物料盤點 (Dezheng Material Inventory Count) — a single-file, client-only mobile web app for a tea shop's staff to count physical inventory and export the results as an Excel file to share via LINE. There is no backend, no build step, and no package manager: `index.html` is the entire application.

## Development

There is no build, lint, or test tooling in this repo. To work on the app:

- Run `./preview.sh` to start a local server (`python3 -m http.server 8000`) in the project root. It prints two URLs:
  - `http://localhost:8000` — preview on the Mac.
  - `http://<lan-ip>:8000` — preview on a phone connected to the **same Wi-Fi**, where `<lan-ip>` is auto-detected via `ipconfig getifaddr en0` (falls back to `en1`).
- A local server (rather than opening the file directly) is needed for `navigator.share` and other browser APIs to behave like production on mobile.
- Test on an actual mobile browser (iOS Safari / Android Chrome) when touching the share/export flow, since `navigator.share`/`canShare` with files only works on mobile and falls back to plain download on desktop.
- There is no automated test suite; verify changes manually by walking through the four screens (start → count → done → history).

## Architecture

Everything lives in `index.html`: inline `<style>`, inline `<body>` markup, inline `<script>`. Two external dependencies are loaded from CDNs: the SheetJS library (`xlsx.full.min.js`), used to generate `.xlsx` files client-side, and `@zip.js/zip.js`, used to wrap the generated `.xlsx` in a password-protected `.zip` before export.

**Screen flow** — four `.screen` divs toggled by adding/removing the `active` class via `showScreen(name)`, which maps to element IDs `screen-start`, `screen-count`, `screen-done`, `screen-history`:
1. `start` — staff enters their name, or views local history.
2. `count` — one row per SKU (grouped by category), each with a numeric input and +/− steppers; progress bar tracks how many SKUs have a value.
3. `done` — read-only summary table of the submitted count with total value, plus export/share actions.
4. `history` — list of past local records; tapping one reopens it on the `done` screen.

**Item master data**: the `ITEMS` array (top of the `<script>` block) is the full product catalog — sku, name, spec, unit, price, category — hardcoded inline as JSON. This was generated from a `得正_盤點品項主檔.xlsx` source file's `品項主檔` sheet. Unlike some sibling projects, none of these items carry the optional packaging fields (`unit_weight_g`, `pack_weight_g`, `packs_per_unit`, `sub_unit`, `piece_unit`, `pieces_per_sub`) — the source spec text isn't consistent enough to derive them reliably (e.g. unit mismatches between 規格 and 單位 columns), so every item renders as a single numeric quantity input. **To update the catalog (add/remove/reprice items), edit this array directly** — there is no separate data file or import pipeline. If a future source file has clean, consistent packaging data, those optional fields can be added per-item to enable the loose-pack/leftover-weight entry UI (see `renderItemList` for the branching logic).

**State & persistence**:
- `currentResults` (in-memory, `{ sku: {qty} }`) holds the in-progress count.
- Completed counts are saved as full records (`{ id, store, staff, datetime, items[] }`) into `localStorage` under `dezheng_inventory_history`, via `saveRecord()`/`getHistory()`. This is per-device storage only — the app intentionally does not sync across phones or to a server; the subtitle text on the start screen ("資料只存在這裝置上") reflects this design choice, so don't build in cross-device sync without confirming that's actually wanted.

**Excel export**: `buildWorkbook(record)` turns a record into a SheetJS worksheet (header rows + item rows + total row) and `getFileName()` derives `{store}_盤點_{yyyymmdd}_{staff}.xlsx`. `buildProtectedZip(record)` writes that workbook to an `.xlsx` blob and wraps it in a password-protected `.zip` (via zip.js, legacy ZipCrypto — chosen over AES for broad compatibility with default unzip tools on staff phones; password is hardcoded as `EXCEL_ZIP_PASSWORD`) so staff can't casually open the file and see prices. `shareExcel()` prefers the native Web Share API with the `.zip` file attachment (so users can share straight to LINE) and falls back to `downloadExcel()` (plain file download) when the browser doesn't support sharing files.

## Conventions

- UI copy, comments, and data are in Traditional Chinese (zh-Hant) — match this when adding features or comments.
- No frameworks/bundlers are used by design (single static file, easy to host anywhere / open directly). Keep new functionality inline in `index.html` unless the user asks to restructure the project.
- This is an independent sibling project of `~/Documents/InventoryApp/qingshan-inventory` — same architecture and conventions, separate GitHub repo (`kurowei/dezheng-inventory`) and separate GitHub Pages URL. Changes here never affect qingshan-inventory and vice versa.
