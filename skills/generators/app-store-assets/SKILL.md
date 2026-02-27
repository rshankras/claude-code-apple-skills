---
name: app-store-assets
description: Comprehensive App Store asset specifications and guidelines for all promotional artwork — app icons, screenshots, app previews, event cards, subscription images, and featuring artwork. Use when preparing assets for App Store Connect upload.
allowed-tools: [Read, Write, Edit, Glob, Grep, AskUserQuestion]
---

# App Store Assets Generator

Generate complete asset specifications, design guidelines, and checklists for all App Store Connect promotional artwork and media.

## When This Skill Activates

Use this skill when the user:
- Asks about "App Store asset specs" or "screenshot sizes"
- Mentions "app preview" video requirements
- Wants to know "what images do I need" for App Store
- Preparing assets for submission or update
- Asks about "featuring artwork" or "subscription images"
- Needs a comprehensive asset checklist

## Configuration Questions

Ask user via AskUserQuestion:

1. **Which platforms?** (multi-select)
   - iPhone
   - iPad
   - Mac
   - Apple Watch
   - Apple TV
   - Apple Vision Pro

2. **What assets do you need?**
   - App icon
   - Screenshots
   - App preview video
   - In-App Event card images
   - Subscription promotional images
   - Custom Product Page assets
   - All of the above

## Output Format

Read `specs-reference.md` and generate a customized asset checklist for the user's platforms.

```markdown
# App Store Asset Checklist: [App Name]

## Required Assets

### App Icon
| Spec | Value |
|------|-------|
| Size | 1024 x 1024 px |
| Format | PNG |
| Color space | sRGB or Display P3 |
| Layers | Flat (no transparency, no rounded corners) |
| Shape | Square (system applies mask) |

### Screenshots: [Platform]
[Platform-specific requirements]

### App Preview (Optional but Recommended)
[Video specifications]

## Promotional Assets

### In-App Event Card
[Specs if applicable]

### Subscription Image
[Specs if applicable]

## Production Checklist
- [ ] All sizes prepared
- [ ] Localizations ready
- [ ] Tested on actual devices for readability
- [ ] Compliant with Apple content guidelines
```

## References

- **specs-reference.md** — Complete specifications for all asset types
- Related: `app-store/screenshot-planner` — Screenshot strategy and captioning
- Related: `generators/in-app-events` — Event card design guidance
- Related: `generators/custom-product-pages` — CPP-specific asset planning
