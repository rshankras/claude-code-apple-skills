# In-App Events Templates

Ready-to-use event metadata templates by category and purpose.

## Template 1: Fitness Challenge Event

```
Reference Name: january-fitness-challenge-2025
Badge: Challenge
Event Name: 30-Day Fitness Challenge
Short Description: Complete daily workouts to earn badges
Long Description: Start the new year strong! Complete one workout each day for 30 days. Track your streak, earn exclusive badges, and see how you compare.
Start Date: 2025-01-01 00:00 PST
End Date: 2025-01-31 23:59 PST
Deep Link: yourapp://challenge/january-2025
```

**Image Concept**: Energetic gradient (blue → purple), centered "30" with burst effect, workout silhouette at bottom.

---

## Template 2: App Major Update

```
Reference Name: v3-redesign-launch
Badge: Major Update
Event Name: All-New Design & Features
Short Description: Completely redesigned from the ground up
Long Description: Version 3.0 brings a stunning new interface, faster performance, and features you've been asking for. Update now to experience the difference.
Start Date: [release date]
End Date: [release date + 14 days]
Deep Link: yourapp://whats-new
```

**Image Concept**: Before/after split screen showing old vs. new UI, clean and modern aesthetic.

---

## Template 3: Seasonal Content

```
Reference Name: holiday-collection-2025
Badge: Special Event
Event Name: Holiday Collection
Short Description: Limited-time festive themes and content
Long Description: Celebrate the holidays with exclusive seasonal themes, festive stickers, and special rewards. Available for a limited time — don't miss out!
Start Date: 2025-12-15 00:00 PST
End Date: 2026-01-05 23:59 PST
Deep Link: yourapp://seasonal/holiday-2025
```

**Image Concept**: Holiday-themed with snowflakes, warm colors, gift imagery, app content preview.

---

## Template 4: Learning Milestone

```
Reference Name: vocabulary-sprint-march
Badge: Challenge
Event Name: Vocabulary Sprint
Short Description: Learn 100 new words this month
Long Description: Challenge yourself to learn 100 new vocabulary words in March. Daily goals, progress tracking, and a certificate of completion await. Ready?
Start Date: 2025-03-01 00:00 PST
End Date: 2025-03-31 23:59 PST
Deep Link: yourapp://challenge/vocab-sprint
```

---

## Template 5: Community Event

```
Reference Name: community-creation-week
Badge: Live Event
Event Name: Community Creation Week
Short Description: Create, share, and vote on community content
Long Description: Join thousands of creators in our biggest community event. Submit your creations, vote on favorites, and win featured placement in the app.
Start Date: 2025-06-15 00:00 PST
End Date: 2025-06-22 23:59 PST
Deep Link: yourapp://community/creation-week
```

---

## Template 6: New Feature Premiere

```
Reference Name: ai-assistant-premiere
Badge: Premiere
Event Name: Introducing AI Assistant
Short Description: Your new intelligent helper is here
Long Description: Meet your personal AI assistant — powered by on-device intelligence. Ask questions, get suggestions, and work smarter. Available now for all Pro users.
Start Date: [feature release date]
End Date: [release date + 14 days]
Deep Link: yourapp://features/ai-assistant
```

---

## Template 7: Back-to-School

```
Reference Name: back-to-school-2025
Badge: Special Event
Event Name: Back to School Ready
Short Description: Get organized for the new school year
Long Description: Start the school year prepared with new templates, study tools, and organizational features. Special student pricing available for a limited time.
Start Date: 2025-08-15 00:00 PST
End Date: 2025-09-15 23:59 PST
Deep Link: yourapp://promo/back-to-school
```

---

## Event Card Image Specifications

### Required Sizes

| Placement | Size | Aspect Ratio |
|-----------|------|-------------|
| Event Card | 1080 x 1920 px | 9:16 (portrait) |
| Event Card (landscape) | 1920 x 1080 px | 16:9 |

### Design Guidelines

**Layout Structure:**
```
┌─────────────────────────┐
│                         │
│    [Safe Zone - 80%]    │
│                         │
│    ┌─────────────────┐  │
│    │   Key Visual    │  │
│    │   or Feature    │  │
│    │   Screenshot    │  │
│    └─────────────────┘  │
│                         │
│    Event Title Text     │
│    (if text overlay)    │
│                         │
└─────────────────────────┘
```

**Color Palette by Event Type:**
- Challenge: Energetic (orange, red, electric blue)
- Competition: Bold (gold, silver, dark backgrounds)
- Live Event: Urgent (red, white, high contrast)
- Special Event: Festive (matches seasonal theme)
- Major Update: Clean (your brand colors, modern)
- New Season: Fresh (greens, blues, seasonal tones)
- Premiere: Premium (dark backgrounds, spotlight effect)

**Text on Images:**
- Maximum 3-5 words on the image itself
- Use your app's brand font
- Ensure readability at small sizes (event cards are small in browse)
- Don't duplicate the event name (it appears separately)

---

## Deep Link Configuration

### URL Scheme Setup

```swift
// In your App's URL handling
enum DeepLink {
    case event(String)
    case challenge(String)
    case feature(String)
    case promo(String)

    init?(url: URL) {
        guard let host = url.host() else { return nil }
        let path = url.pathComponents.dropFirst().joined(separator: "/")

        switch host {
        case "event": self = .event(path)
        case "challenge": self = .challenge(path)
        case "features": self = .feature(path)
        case "promo": self = .promo(path)
        default: return nil
        }
    }
}
```

### Universal Links (Recommended)
```json
{
    "applinks": {
        "apps": [],
        "details": [{
            "appID": "TEAMID.com.yourapp",
            "paths": ["/event/*", "/challenge/*", "/features/*", "/promo/*"]
        }]
    }
}
```

---

## Event Scheduling Best Practices

### Event Duration by Type
| Type | Recommended Duration | Reason |
|------|---------------------|--------|
| Challenge | 7-30 days | Time to participate and complete |
| Competition | 3-7 days | Creates urgency |
| Live Event | 1-4 hours | Real-time participation |
| Special Event | 7-14 days | Limited-time feel |
| Major Update | 7-14 days | Discovery window |
| New Season | 7 days | Season launch hype |
| Premiere | 7-14 days | Feature awareness |

### Overlap Strategy
- Maximum 5 events visible at once
- Don't overlap events with the same badge type
- Stagger events so one ends as another begins
- Keep at least 1 event active at all times for product page engagement
