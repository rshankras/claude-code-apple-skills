# App Store Asset Specifications Reference

Complete specifications for all App Store Connect assets, updated for 2025.

## App Icon

| Attribute | Requirement |
|-----------|-------------|
| Size | 1024 x 1024 px |
| Format | PNG |
| Color Space | sRGB or Display P3 |
| Transparency | Not allowed |
| Rounded Corners | Do not round — system applies mask |
| Interlaced | Not allowed |
| Layers | Single layer, flat |

### Icon Design Guidelines
- Simple, recognizable at small sizes (29x29 px on Watch)
- Single focal point — avoid clutter
- Use brand colors consistently
- No photos — use graphic design or illustration
- No text (except single letters/numbers for brand identity)
- Test at all sizes: 1024, 180, 120, 87, 80, 60, 58, 40, 29, 20

---

## Screenshots

### iPhone Screenshots

| Device | Display Size | Screenshot Size (Portrait) | Screenshot Size (Landscape) |
|--------|-------------|---------------------------|----------------------------|
| iPhone 16 Pro Max | 6.9" | 1320 x 2868 px | 2868 x 1320 px |
| iPhone 16 Pro | 6.3" | 1206 x 2622 px | 2622 x 1206 px |
| iPhone 16 Plus | 6.7" | 1290 x 2796 px | 2796 x 1290 px |
| iPhone 16 | 6.1" | 1179 x 2556 px | 2556 x 1179 px |
| iPhone SE | 4.7" | 750 x 1334 px | 1334 x 750 px |
| iPhone 8 Plus | 5.5" | 1242 x 2208 px | 2208 x 1242 px |

**Required**: 6.9" and 6.7" sizes at minimum. Others are optional but recommended.
**Count**: Minimum 1, maximum 10 per localization.

### iPad Screenshots

| Device | Display Size | Screenshot Size (Portrait) | Screenshot Size (Landscape) |
|--------|-------------|---------------------------|----------------------------|
| iPad Pro 13" (M4) | 13" | 2064 x 2752 px | 2752 x 2064 px |
| iPad Pro 11" (M4) | 11" | 1668 x 2388 px | 2388 x 1668 px |
| iPad 10th gen | 10.9" | 1640 x 2360 px | 2360 x 1640 px |
| iPad mini | 8.3" | 1488 x 2266 px | 2266 x 1488 px |

**Required**: 13" size at minimum for iPad apps.

### Mac Screenshots

| Display | Screenshot Size |
|---------|----------------|
| Mac (Retina) | 2880 x 1800 px (or 1440 x 900 minimum) |
| Mac (standard) | 1280 x 800 px minimum |

**Maximum**: 2560 x 1600 px or 1600 x 2560 px.

### Apple Watch Screenshots

| Device | Screenshot Size |
|--------|----------------|
| Apple Watch Ultra 2 | 502 x 610 px |
| Apple Watch Series 10 (46mm) | 416 x 496 px |
| Apple Watch SE (44mm) | 368 x 448 px |

### Apple TV Screenshots

| Size |
|------|
| 3840 x 2160 px or 1920 x 1080 px |

### Apple Vision Pro Screenshots

| Size |
|------|
| 3840 x 2160 px |

---

## Screenshot Content Guidelines

### DO:
- Show actual app UI (can be enhanced/annotated)
- Include captions that explain benefits
- Start with the most compelling screen
- Use device frames for context (optional)
- Show real content (not placeholder Lorem Ipsum)

### DON'T:
- Include status bar time/battery unless necessary
- Show competitor apps or references
- Include pricing in screenshots (changes by region)
- Use "iPhone" or "iPad" device images (trademark)
- Include misleading content not in the actual app

### Caption Best Practices
- 3-7 words per caption
- Benefit-focused, not feature-focused
- ✅ "Track your progress effortlessly"
- ❌ "Dashboard with charts and statistics"

---

## App Preview Video

| Attribute | Requirement |
|-----------|-------------|
| Duration | 15-30 seconds |
| Format | H.264, M4V, MP4, or MOV |
| Frame Rate | 30 fps |
| Audio | Optional (256 kbps AAC) |
| Maximum File Size | 500 MB |

### Resolution by Device
| Device | Resolution |
|--------|-----------|
| iPhone 16 Pro Max | 1320 x 2868 (portrait) or 2868 x 1320 (landscape) |
| iPhone 16 Plus | 1290 x 2796 or 2796 x 1290 |
| iPad Pro 13" | 2064 x 2752 or 2752 x 2064 |
| Mac | Up to 1920 x 1080 |

### Preview Best Practices
- **First 3 seconds**: Show the core value (most users don't watch all 30s)
- **No live-action footage**: Must be app screen recording (can overlay text/graphics)
- **Poster frame**: Choose the most compelling frame as the preview thumbnail
- **Audio**: If included, use music or narration that adds value
- **CTA**: End with a clear call to action or key benefit

---

## In-App Event Card Images

| Attribute | Requirement |
|-----------|-------------|
| Size | 1080 x 1920 px (portrait) |
| Alternate | 1920 x 1080 px (landscape) |
| Format | PNG or JPEG |
| Transparency | Not allowed |
| Safe Zone | Keep critical content in center 80% |

### Event Card Video (Optional)
| Attribute | Requirement |
|-----------|-------------|
| Duration | Up to 30 seconds |
| Format | H.264, M4V, MP4, or MOV |
| Frame Rate | 30 fps |
| Audio | Optional |

---

## Subscription Promotional Image

| Attribute | Requirement |
|-----------|-------------|
| Size | 1024 x 1024 px |
| Format | PNG or JPEG |
| Transparency | Not allowed |
| Purpose | Shown on product page for promoted IAPs |

### Design Tips
- Feature the value of the subscription visually
- Don't just repeat the app icon
- Show premium features or content
- Keep text minimal — product name is shown separately
- Test at thumbnail size (appears small in search results)

---

## Featuring Artwork (If Featured by Apple)

Apple may request additional artwork if your app is selected for featuring.

| Placement | Size | Notes |
|-----------|------|-------|
| Today tab background | 2560 x 1440 px | Full-bleed, atmospheric |
| App of the Day card | 2400 x 1200 px | Feature hero image |
| Collection banner | 2560 x 686 px | Horizontal banner |

These are requested only after Apple confirms featuring — don't pre-create.

---

## Asset Production Checklist

### Minimum Viable Assets
- [ ] App icon (1024 x 1024)
- [ ] iPhone screenshots (6.9" size) — minimum 3, recommended 5-10
- [ ] iPad screenshots (13" size) — if iPad app
- [ ] App Store description and promotional text

### Recommended Additional Assets
- [ ] iPhone screenshots (6.7" size)
- [ ] App preview video (15-30 seconds)
- [ ] Mac screenshots — if Mac app
- [ ] Watch screenshots — if Watch app
- [ ] Localized screenshots for top markets

### Promotional Assets (When Needed)
- [ ] In-App Event card image (1080 x 1920)
- [ ] Subscription promotional image (1024 x 1024)
- [ ] Custom Product Page screenshots (per page)

### Quality Checks
- [ ] All text is readable at actual display size
- [ ] Screenshots accurately represent current app version
- [ ] App preview shows actual app footage (not mockups)
- [ ] Colors are consistent with brand identity
- [ ] No competitor references or trademark violations
- [ ] Tested in both light and dark mode product page display
