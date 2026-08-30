# Toss Invest design-token observations

Source: `https://www.tossinvest.com/?focusedProductCode=A000660`

Observed: 2026-08-30, Chrome 151, dark and light modes, 1440 x 900 and 390 x 844 viewports.

## Dark semantic values

| Observed role | Value |
| --- | --- |
| Screen background | `#101013` |
| Main background | `#17171C` |
| Layer 1 | `#202025` |
| Layer 2 / floating surface | `#2C2C35` |
| Grey 50 overlay | `rgba(218,223,233,0.04)` |
| Grey 100 overlay | `rgba(214,224,239,0.09)` |
| Grey 200 overlay | `rgba(213,223,244,0.13)` |
| Primary text | `rgba(242,246,255,0.90)` |
| Secondary text | `rgba(217,223,235,0.80)` |
| Tertiary text/icon | `rgba(211,224,243,0.42)` |
| Brand icon | `#3182F6` |
| Brand text | `#4391FF` |
| Danger / finance-positive | `#F5445A` |
| Supporting green | `#57C28D` |
| Panel boundary | `rgba(214,224,239,0.09)` |
| Standard hover | `rgba(214,224,239,0.09)` |
| Weak hover | `rgba(218,223,233,0.04)` |
| Standard pressed | `rgba(213,223,244,0.13)` |

## Light semantic values

| Observed role | Value |
| --- | --- |
| Screen background | `#F6F7F9` |
| Main background / surface | `#FFFFFF` |
| Grey 50 | `#F9FAFB` |
| Grey 100 | `#F2F4F6` |
| Grey 200 | `#E5E8EB` |
| Grey 500 | `#8B95A1` |
| Grey 700 | `#4E5968` |
| Grey 900 | `#191F28` |
| Primary text | `rgba(26,31,41,0.89)` |
| Secondary text | `rgba(24,31,43,0.77)` |
| Brand icon | `#3182F6` |
| Brand text | `#2272EB` |
| Danger / finance-positive | `#DE2B39` |
| Standard hover | `rgba(7,25,76,0.04)` |
| Weak hover | `rgba(13,25,74,0.02)` |
| Standard pressed | `rgba(3,31,63,0.09)` |

## Geometry and type

- Dominant spacing and padding increments: 4 and 8 pixels.
- Common gaps: 2, 4, 8, 16, and 24 pixels.
- Common control radii: 4, 7, 8, and 10 pixels; 999 pixels for pills.
- Top navigation height: 52 pixels.
- Dense row height: 44 pixels.
- Common font sizes: 12, 13, 14, and 16 pixels.
- Common font weights: 400, 500, 600, and 700.
- Common line heights: 16, 20, and 23.2 pixels.
- Font stack begins with proprietary `Toss Product Sans`; it is reference-only and will not be
  copied or redistributed.

## Motion and surface treatment

- Most interactive transitions use 200 milliseconds with `ease`.
- A smaller set uses 100, 150, or 300 milliseconds.
- Panels rely on subtle inset boundaries more than elevation.
- Floating surfaces use small, low-opacity shadows rather than broad card shadows.

## Implementation translation

The values guide Clock Rhythm's semantic roles, density, geometry, and state treatment. Financial
color meaning, page content, branding, assets, proprietary fonts, and the source layout's 1024-pixel
minimum width are explicitly excluded.

