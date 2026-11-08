# LUNTI — Capstone Diagram Set (HOA01)

Visual diagrams for the HOA01 *M-Commerce System and Architecture Setup* documentation.
All four share the LUNTI pastel cream / sage theme and are rendered at 2× for print.

| Figure | File | Contents |
|---|---|---|
| **01-A** | `01-system-architecture` | Client layer → integration & data flow → Firebase backend services |
| **01-B** | `02-order-flowchart` | Order lifecycle: placement → fulfilment → completion → payment settlement |
| **02-A** | `02a-customer-app-flow` | Customer mobile app: session, auth, browsing, checkout, order tracking |
| **02-B** | `02b-admin-dashboard-flow` | Admin Studio: auth, live analytics, catalog, orders, reviews, support |

## Files per figure

- **`.png`** — the deliverable. 3200 px wide, 2× device scale, transparent-free cream background.
  Sizes: 01-A 3200×1980 · 01-B 3200×2612 · 02-A 3200×1980 · 02-B 3200×2120.
- **`.html`** — the editable source. Open in any browser; the diagram is a fixed 1600 px stage.
  Fonts are bundled in `fonts/` (Poppins + Playfair Display), so it renders offline.
- **`.mmd`** — Mermaid source. Paste into <https://mermaid.live> or render with
  `mmdc -i <file>.mmd -o <file>.svg` for an editable vector version.

## Re-rendering the PNGs

The PNGs were produced with headless Chrome at a 1600 px viewport and `deviceScaleFactor: 2`.
To reproduce:

```bash
# any static server works; the pages use relative font paths
python -m http.server 8080 --directory docs/diagrams
# then screenshot each page at 1600 x <stage height> with 2x device scale
```

Stage heights: 01-A 990 · 01-B 1306 · 02-A 990 · 02-B 1060.

## Design notes

- Connectors are drawn in an SVG layer above the node layer, so arrowheads and the
  decision diamonds are never hidden behind the swimlane panels.
- Swimlane panels (02-A, 02-B) group related steps; arrows cross panels where the
  journey moves from one feature area to the next.
- Content is sourced from the running system: the order state machine
  (pending → approved → packed → shipped → completed), the COD settlement rule,
  base64 media storage on the Spark plan, and the `support_chats` message threads.
