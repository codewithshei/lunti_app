# LUNTI Flutter UI/UX Development Prompt

## Project
Build and improve **LUNTI**, a Flutter mobile shopping app for a sustainable bamboo-products brand.

## Before Coding
1. Inspect the existing project and explain its current structure briefly.
2. Preserve existing work and follow the current Figma designs as the primary reference.
3. If screenshots or exported Figma frames are available, review them before implementing screens.
4. Do not delete, overwrite, or restructure important files without explaining why first.

## Design Direction
- Style: clean, modern, natural, calm, and easy to use.
- Brand colors: forest green, sage green, cream, beige, and bamboo-inspired neutrals.
- Use consistent typography, spacing, border radius, icons, and reusable widgets.
- Prioritize readable text, accessible color contrast, clear feedback, and intuitive navigation.
- Keep all screens visually consistent with the LUNTI brand and existing Figma designs.

## Use of UI Repositories
- Use free/open-source Flutter repositories and component libraries as inspiration where helpful.
- Suggested references:
  - Best Flutter UI Templates: https://github.com/mitesh77/Best-Flutter-UI-Templates
  - Flutter E-Commerce UI Kit: https://github.com/Furqankhanzada/flutter_eCommerce_ui_kit
  - FlockUI components: https://www.flockui.com/
  - Official Flutter samples: https://github.com/flutter/samples
- Do not blindly copy a whole template or mix unrelated design styles.
- Check each project's license before reusing code.
- Avoid unnecessary dependencies.

## Database and Backend
- The app will use **Firebase** as its backend/database.
- Before integrating Firebase, inspect the existing project and explain the setup steps and required configuration.
- Use **Cloud Firestore** for structured app data unless there is a clear reason to recommend another Firebase product.
- Firebase Authentication may be used for sign-up/sign-in if authentication is part of the requested scope.
- Use Firebase Storage only if the app needs to store product images or user-uploaded files.
- Do not hardcode Firebase credentials or secrets into source code.
- Do not pretend Firebase is connected if project configuration and Firebase setup have not been completed.
- Do not create, modify, or delete cloud data without explicit authorization and clear explanation.
- Keep the UI prototype usable with clearly labeled sample data while Firebase is not configured.
- Separate data access from UI code using reusable services/repositories so Firebase can be connected cleanly.
- Do not add Firebase dependencies or change app configuration until the existing project has been inspected and the integration plan explained.

## Implementation Plan
1. Start by improving/implementing the **Home Page only**.
2. Make reusable widgets for repeated elements, such as product cards, buttons, and section headers.
3. After the Home Page is reviewed, continue screen by screen: product catalog/search, product details, wishlist, cart, checkout, order confirmation, profile, and order history—only where these screens exist in the project or Figma.
4. Keep navigation understandable and consistent.
5. Use sample product data only if the backend is not connected yet. Clearly mark mock data and do not pretend real orders or payments work.
6. Do not add payment integration unless specifically requested.

## Quality Checks
- Run `flutter pub get` if dependencies need to be resolved.
- Run `flutter analyze` after changes and fix issues introduced by your changes.
- Explain which files were changed and how to run/test the app.
- If a requirement is unclear, ask before making a large or destructive change.

## First Task
Inspect the project and available Figma screenshots. Then:
1. Briefly explain the current project structure and your plan.
2. Implement **only the Home Page**, keeping the existing LUNTI branding and layout direction.
3. Identify any Firebase setup requirements, but do not connect or change Firebase configuration yet unless I explicitly ask.
4. After coding, summarize the changes and any remaining limitations.
