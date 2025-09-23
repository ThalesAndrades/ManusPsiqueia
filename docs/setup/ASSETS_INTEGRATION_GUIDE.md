# 🎨 ManusPsiqueia Assets Integration Guide

## Overview

This document outlines the integration of logos and brand assets for the ManusPsiqueia app. The assets have been structured to provide consistent branding across the application while maintaining the premium visual design.

## Assets Structure

### 📁 Assets.xcassets

```
Assets.xcassets/
├── AccentColor.colorset/           # App accent color (brand primary)
├── AppIcon.appiconset/             # App icon in all required sizes
├── BrandPrimary.colorset/          # Primary brand color (#6633CC)
├── BrandSecondary.colorset/        # Secondary brand color (#3399E6)
├── ManusIcon.imageset/             # Manus icon (template)
└── ManusLogo.imageset/             # Main ManusPsiqueia logo
```

## Brand Colors

### Primary Colors
- **Brand Primary**: `#6633CC` (Purple - RGB: 0.4, 0.2, 0.8)
- **Brand Secondary**: `#3399E6` (Blue - RGB: 0.2, 0.6, 0.9)

### Usage
The brand colors are defined in `Extensions/BrandColors.swift` with convenient extensions:

```swift
// Usage examples
.foregroundStyle(Color.brandGradient)
.foregroundStyle(Color.brandTextGradient)
.fill(Color.brandPrimary)
```

## Logo Implementation

### Current Implementation
The SplashScreenView now includes:

1. **Custom Logo Support**: Checks for custom `ManusLogo` asset
2. **Fallback Design**: Enhanced system icon with "M" overlay for Manus branding
3. **Brand Colors**: Consistent use of defined brand colors
4. **Gradient Effects**: Professional gradient styling

### Fallback Logo
When custom logo is not available, the app displays:
- System brain.head.profile icon
- Overlaid "M" for Manus branding
- Brand gradient coloring

## App Icon Structure

### Required Sizes
The AppIcon.appiconset includes all required iOS sizes:

- **iPhone**: 20x20, 29x29, 40x40, 60x60 (2x and 3x)
- **iPad**: 20x20, 29x29, 40x40, 76x76, 83.5x83.5 (1x and 2x)
- **Marketing**: 1024x1024 (1x)

### File Naming Convention
- `appicon-[size]@[scale]x.png`
- Example: `appicon-60@3x.png` for 180x180 pixel icon

## Next Steps

### To Add Custom Logo:
1. Create logo image files in PNG format
2. Add to `ManusLogo.imageset/` with names:
   - `manuslogo@1x.png` (base size)
   - `manuslogo@2x.png` (2x scale)
   - `manuslogo@3x.png` (3x scale)

### To Add App Icons:
1. Create app icon PNG files in required sizes
2. Add to `AppIcon.appiconset/` following naming convention
3. Ensure icons follow Apple Design Guidelines

### To Create Custom Icons:
1. Add new `.imageset` folders in Assets.xcassets
2. Include proper `Contents.json` files
3. Reference in code using `Image("AssetName")`

## Brand Guidelines

### Logo Usage
- Primary logo should be used on dark backgrounds
- Maintain minimum clear space around logo
- Use brand gradient for visual impact
- Fallback to system icon with "M" overlay

### Color Usage
- Use brand primary for primary UI elements
- Use brand secondary for accents and highlights
- Apply gradients for premium visual effects
- Maintain accessibility contrast ratios

### Design Principles
- Consistent spacing and alignment
- Premium visual hierarchy
- Smooth animations and transitions
- Professional medical app aesthetic

## Implementation Notes

### Modified Files
- `ManusPsiqueia/Views/SplashScreenView.swift`
- `Modules/ManusPsiqueiaUI/Sources/ManusPsiqueiaUI/Views/SplashScreenView.swift`
- `ManusPsiqueia/Extensions/BrandColors.swift` (new)
- `ManusPsiqueia/Assets.xcassets/` (enhanced)

### Benefits
- Consistent brand identity
- Easy color maintenance
- Scalable asset structure
- Professional presentation
- Future-ready for custom assets

---

**Note**: This implementation provides a foundation for brand assets while maintaining compatibility with the existing premium design system. Custom logo and icon files can be added without code changes.