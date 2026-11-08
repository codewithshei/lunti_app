# LUNTI Flutter Project Instructions

## Project Context
LUNTI is a sustainable bamboo-products shopping app built with Flutter. The project already contains existing code, screens, reusable widgets, sample product data, and Figma-based designs.

**Important:** Work on the existing project. Do not recreate it from scratch.

## First Priority: Inspect Before Editing
Before making changes:
1. Read this file and any relevant project documentation, including `LUNTI_ARCHITECTURE.md` if it exists.
2. Inspect the actual Flutter source code and compare it with the architecture documentation.
3. Identify which features are complete, partially implemented, or missing.
4. Check the current navigation, state management, product repository, data models, and reusable widgets.
5. Run `flutter analyze` and `flutter test` when appropriate, and report the actual results.
6. Provide a prioritized checklist before major changes.

Do not assume that a feature works just because a screen exists. Inspect the implementation and relevant code.

## Preserve Existing Work
- Do not delete or overwrite working features unnecessarily.
- Do not rebuild the app from scratch.
- Preserve the existing Figma layouts and visual direction unless explicitly asked to redesign them.
- Reuse existing widgets, colors, typography, data models, and navigation patterns where practical.
- Make focused, incremental changes.
- Before a large refactor, explain why it is needed and ask for approval.
- Do not discard or replace existing files just to make the implementation easier.

## LUNTI Visual Style
Keep the existing LUNTI visual identity:
- Forest green: `#344E41`
- Sage: `#E8ECDF`
- Cream: `#FAF8F2`
- Beige: `#DAD7CD`
- Ink: `#27372D`
- Secondary text: `#687267`
- Typography: Playfair Display and Poppins
- Design reference width: approximately 390 px
- Typical horizontal gutter: 20 px
- Corner radius: 12, 16, or 20 px
- Buttons and controls: approximately 44–52 px high

Use the project's existing theme and design tokens if available instead of duplicating hardcoded styles.

## Feature and Data Rules
- Keep sample/mock data until the project owner explicitly approves backend integration.
- Do not connect Firebase or another backend yet unless explicitly requested.
- Do not implement real payment processing.
- Use clearly labeled prototype behavior for payment and checkout flows.
- Never collect or store real credit-card details in this prototype.
- Do not invent product facts, product customisation options, prices, stock counts, or policies. Flag missing information and use clearly marked sample data where necessary.
- Keep UI state consistent across screens.

## Product Customisation / Engraving
Some products may support engraving, but customisation must be product-specific.
- Do not assume every product can be engraved.
- Only show Natural/Engraved options for products confirmed to support those options.
- If Engraved is selected, require the customer to enter the name or text to engrave.
- Validate that the engraving text is not empty or only whitespace.
- Apply a reasonable character limit and show a helpful character counter or validation message.
- If the product supports additional engraving instructions, keep them optional.
- If Natural is selected, do not require engraving text.
- Pass the selected variation, engraving text, quantity, unit price, and line total into the cart item.
- Treat cart items with different engraving text or variations as distinct configurations.
- Display the selected engraving text in the cart and order summary so customers can verify it before checkout.
- Do not invent which products support engraving or the engraving price. If the existing data is uncertain, report it and ask for confirmation or mark it as sample data.

## Shared State and Shopping Flow
When implementing or auditing features, check that related screens share the appropriate state and data. Avoid separate, disconnected hardcoded lists for the same information.

Expected shopping flow, as applicable to the existing design:
1. Browse or search products.
2. Open Product Details.
3. Choose an available product variation and optional customisation.
4. Add the configured product to the shared cart.
5. Review and edit the cart.
6. Enter or select a delivery address in Checkout.
7. Choose a prototype payment method without collecting real card details.
8. Show Order Confirmation after a successful prototype checkout.
9. Make the order visible in Order History and Order Details.
10. Show a prototype Order Tracking status.
11. Keep wishlist, profile, saved addresses, and order history consistent with shared local state.

Wishlist expectations:
- Product-card hearts and the wishlist screen should use the same shared wishlist state.
- Tapping a heart should save or remove a product.
- Saved products should appear in Wishlist and be removable there.
- Tapping a saved product should open its details page.
- Empty states should be provided where appropriate.

Cart and order expectations:
- Cart items should preserve product ID, quantity, selected variation, engraving text if applicable, unit price, and line total.
- Support changing quantities and removing items.
- Calculate subtotals and totals from actual cart data rather than hardcoded labels.
- Checkout should validate required fields and show a clear summary.
- Use mock order/payment behavior only until real backend integration is explicitly approved.
- Do not claim that a real payment was processed or an order was sent to a real store.

## Navigation and Error Handling
- Reuse the existing routing and navigation architecture.
- Ensure navigation works from cards, buttons, tabs, and empty states.
- Handle loading, missing-product, and error states gracefully.
- Avoid buttons that appear functional but only show unrelated placeholder messages.
- Keep accessibility in mind: readable text, clear button labels, and adequate touch targets.

## Animations and UI Polish
Prioritize correct functionality and shared state before major visual redesign.
After core flows work:
- Add subtle, purposeful animations only where they improve usability.
- Keep scrolling smooth and layouts responsive.
- Avoid large redesigns without approval.
- Compare completed screens against the provided Figma references when available.

## Development and Verification
After each meaningful implementation task:
1. Run `flutter analyze`.
2. Run relevant tests and `flutter test` when appropriate.
3. Fix regressions introduced by the changes.
4. Do not report a command as successful unless you actually ran it.
5. Summarize changed files, implemented behavior, tests run, results, and known limitations.
6. List any assumptions or sample data that still require confirmation.

## Working Agreement
- Make one focused, reviewable set of changes at a time.
- If the next step is unclear, audit the actual project and recommend the highest-priority task.
- Ask before large architecture changes, destructive edits, backend integration, or replacing working code.
- Keep explanations concise and beginner-friendly.
- Preserve the LUNTI project and its existing progress.
