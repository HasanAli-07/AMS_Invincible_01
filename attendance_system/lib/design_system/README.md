# Design System

This folder contains the **token-based design system** for the app.

- `tokens/`: The single source of truth for design values (colors, spacing, radius, typography, elevation, opacity, gradients).  
  - Widgets must **not** use primitive tokens directly; they should use **semantic** tokens.
- `theme/`: Maps tokens into Flutter `ThemeData` for light and dark mode.  
  - Exposes `AppTheme.light()` and `AppTheme.dark()` used in `MaterialApp`.
- `components/`: Design System primitives (`DSButton`, `DSCard`, `DSScaffold`, `DSText`).  
  - Screens should use **only these DS components**, never raw `Scaffold`, `Text`, `ElevatedButton`, etc.

**Rule:** If a value is not represented as a token here, it is not allowed in UI code.  
This keeps the UI consistent, brand-safe, and easy to evolve over time.


