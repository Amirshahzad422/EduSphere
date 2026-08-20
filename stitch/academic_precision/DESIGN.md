---
name: Academic Precision
colors:
  surface: '#f9f9fb'
  surface-dim: '#d9dadc'
  surface-bright: '#f9f9fb'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f3f6'
  surface-container: '#edeef0'
  surface-container-high: '#e8e8ea'
  surface-container-highest: '#e2e2e5'
  on-surface: '#1a1c1e'
  on-surface-variant: '#44474a'
  inverse-surface: '#2f3133'
  inverse-on-surface: '#f0f0f3'
  outline: '#75777a'
  outline-variant: '#c5c6ca'
  surface-tint: '#5d5e61'
  primary: '#000101'
  on-primary: '#ffffff'
  primary-container: '#1a1c1e'
  on-primary-container: '#838486'
  inverse-primary: '#c6c6c9'
  secondary: '#00696e'
  on-secondary: '#ffffff'
  secondary-container: '#61f4fd'
  on-secondary-container: '#006e73'
  tertiary: '#010000'
  on-tertiary: '#ffffff'
  tertiary-container: '#410006'
  on-tertiary-container: '#e05456'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e2e2e5'
  primary-fixed-dim: '#c6c6c9'
  on-primary-fixed: '#1a1c1e'
  on-primary-fixed-variant: '#454749'
  secondary-fixed: '#6bf6ff'
  secondary-fixed-dim: '#3edae3'
  on-secondary-fixed: '#002022'
  on-secondary-fixed-variant: '#004f53'
  tertiary-fixed: '#ffdad8'
  tertiary-fixed-dim: '#ffb3b0'
  on-tertiary-fixed: '#410006'
  on-tertiary-fixed-variant: '#8c1520'
  background: '#f9f9fb'
  on-background: '#1a1c1e'
  surface-variant: '#e2e2e5'
typography:
  display-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  display-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
  headline-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  xs: 4px
  sm: 12px
  md: 16px
  lg: 24px
  xl: 32px
  gutter-mobile: 16px
  gutter-desktop: 24px
  margin-mobile: 20px
  margin-desktop: 64px
---

## Brand & Style
The design system is rooted in the concepts of knowledge and career progression. It adopts a **Corporate Modern** style with an **Editorial** influence, prioritizing content clarity over decorative flair. The aesthetic is "New Professional"—reliable like a traditional institution but agile like a modern tech platform.

The UI evokes an emotional response of focus and intentionality. It avoids "AI dashboard" clutter by utilizing generous whitespace and a strict information hierarchy. The interface feels structured, architectural, and premium, favoring sharp execution and sophisticated accents over trendy visual effects.

## Colors
The palette is built on a foundation of "Deep Navy" and "Charcoal" to establish authority and structure. 

- **Primary (Deep Navy):** Used for core navigation, headings, and high-emphasis containers.
- **Secondary (Electric Teal):** The primary action color, used for progress indicators, success states, and primary CTAs.
- **Tertiary (Coral):** Reserved for secondary highlights, notifications, or specific course categories to provide a warm, human contrast.
- **Background (Warm Off-White):** Provides a soft, paper-like canvas that reduces eye strain during long study sessions.
- **Neutral (Charcoal):** Used for body text and secondary UI elements to maintain high legibility without the harshness of pure black.

## Typography
This design system employs a dual-font strategy to balance character with utility. 

**Plus Jakarta Sans** is used for headings to provide a modern, approachable, and slightly premium feel. Its geometric nature supports the brand's "progress" narrative. **Inter** is used for all body copy, inputs, and labels to ensure maximum readability across all device sizes, particularly on mobile screens where pixel density and legibility are paramount.

For mobile devices, display and large headline sizes scale down to prevent awkward text wrapping, while body sizes remain constant to preserve accessibility.

## Layout & Spacing
The system utilizes a **Fluid Grid** model based on an 8px square rhythm. 

- **Mobile:** 4-column layout with 16px gutters and 20px side margins.
- **Tablet:** 8-column layout with 24px gutters.
- **Desktop:** 12-column layout with a max-width of 1280px, centered on the screen.

Spacing is used generously to separate course modules and learning materials. Elements should "breathe"—vertical rhythm is maintained by using `lg` (24px) or `xl` (32px) spacing between distinct content sections.

## Elevation & Depth
Elevation is expressed through **Tonal Layers** and **Ambient Shadows**. Instead of heavy shadows, the system uses subtle, diffused elevation to separate the background from the foreground.

- **Level 0 (Background):** #FAFAFA.
- **Level 1 (Cards/Containers):** Pure white (#FFFFFF) with a soft 10% opacity charcoal shadow (0px 4px 12px).
- **Level 2 (Modals/Popovers):** Pure white (#FFFFFF) with a more defined 15% opacity shadow (0px 8px 24px).

In dark mode or high-contrast scenarios, elevation is communicated via subtle 1px inner borders (#E0E0E0) rather than increased shadow intensity.

## Shapes
The shape language is consistently "Rounded." A corner radius of 8px to 12px is used to strike a balance between professional structure and approachable learning.

- **Standard Buttons & Inputs:** 8px (rounded).
- **Course Cards & Containers:** 12px (rounded-lg).
- **Avatars & Tags:** Circular or Pill-shaped (rounded-xl) to contrast against the more structured grid elements.

## Components

### Buttons
- **Primary:** Solid Deep Navy or Electric Teal. High-contrast white text. No gradients.
- **Secondary:** Outlined 1px (Charcoal) with transparent background.
- **Tertiary:** Text-only with Electric Teal coloring for "View All" or "Read More" links.

### Input Fields
Inputs use a white background with a 1px Charcoal border. On focus, the border shifts to Electric Teal with a 2px stroke. Labels are consistently placed above the field in `label-md`.

### Course Cards
Cards are the primary container for the platform. They feature a 12px radius, a 4px top-accent bar in Electric Teal (for active courses) or Coral (for new courses), and utilize `headline-md` for titles.

### Progress Indicators
Linear bars use a 4px height with rounded ends. The track is a light gray (#EEEEEE) and the fill is Electric Teal (#00C2CB).

### Chips/Tags
Used for course categories or difficulty levels (e.g., "Beginner"). These use `label-sm` text, a light background tint of the accent colors, and a pill-shaped radius.