# Chefit Brand Guidelines
> **scan. cook. enjoy. 🍴**  
> *Smart recipes from what you have.*

This document is the single source of truth for Chefit's visual identity, tone, and design system. All contributors should follow these guidelines to ensure consistency across every screen, component, and asset.

---

## Table of Contents
1. [Brand Identity](#1-brand-identity)
2. [Colour Palette](#2-colour-palette)
3. [Typography](#3-typography)
4. [Logo & Mascot](#4-logo--mascot)
5. [Iconography](#5-iconography)
6. [Spacing & Layout](#6-spacing--layout)
7. [Component Patterns](#7-component-patterns)
8. [App Flow Overview](#8-app-flow-overview)
9. [Tone of Voice](#9-tone-of-voice)
10. [Do's and Don'ts](#10-dos-and-donts)

---

## 1. Brand Identity

### Mission
Chefit is more than recipes — it's a community of home cooks making the most of what they have.

### Core Values
- **Approachable** — Cooking should feel fun and achievable, not intimidating.
- **Smart** — AI-powered recommendations that feel magical but simple.
- **Community-first** — Real people, real results, real inspiration.
- **Sustainable** — Use what's in your pantry; reduce food waste.

### Tagline
> `scan. cook. enjoy.` — always lowercase, always followed by the peach heart emoji ❤️ in branded contexts.

---

## 2. Colour Palette

All colours are specified in HEX. Use the CSS variable names in code.

### Primary Palette

| Name       | HEX       | CSS Variable            | Usage                              |
|------------|-----------|-------------------------|------------------------------------|
| Sage Green | `#4C5A3E` | `--color-sage-green`    | Primary brand colour, headings, active nav |
| Matcha     | `#A8C5A1` | `--color-matcha`        | Secondary accents, icons, tags     |
| Pistachio  | `#E8F0E3` | `--color-pistachio`     | Backgrounds, card surfaces, icon bubbles |
| Cream      | `#FFF7E8` | `--color-cream`         | App background, light surfaces     |
| Peach      | `#FFB79D` | `--color-peach`         | CTA buttons, highlights, hearts    |
| Honey      | `#FFD26F` | `--color-honey`         | Accent, badges, star ratings       |

### Text Colour

| Name | HEX       | CSS Variable      | Usage              |
|------|-----------|-------------------|--------------------|
| Text | `#2F3A2E` | `--color-text`    | All body copy      |

### Colour Roles

```
Page background    → Cream (#FFF7E8)
Card background    → Pistachio (#E8F0E3) or White
Primary button     → Peach (#FFB79D)  |  Text: White
Secondary button   → Outlined, Sage Green border
Active nav icon    → Sage Green (#4C5A3E)
Inactive nav icon  → Matcha (#A8C5A1)
Icon bubble bg     → Pistachio (#E8F0E3)
Tags / chips       → Matcha (#A8C5A1), text White or Sage
Accent / badge     → Honey (#FFD26F)
Danger / error     → Use a muted red, never pure #FF0000
```

### Accessibility
- Sage Green on Cream passes **WCAG AA** for normal text. Always verify contrast when pairing colours.
- Never place Honey text on Cream — insufficient contrast.
- Peach buttons must use **white** text, not dark green.

---

## 3. Typography

### Typefaces

| Role      | Font               | Weights Used       |
|-----------|--------------------|--------------------|
| Headings  | **Playfair Display** | Regular (400), Bold (700) |
| Body      | **Nunito**         | Regular (400), SemiBold (600), Bold (700) |

Both fonts are available via Google Fonts:
```html
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@400;700&family=Nunito:wght@400;600;700&display=swap" rel="stylesheet">
```

### Type Scale

| Token           | Font               | Size  | Weight | Line Height | Usage                        |
|-----------------|--------------------|-------|--------|-------------|------------------------------|
| `--text-h1`     | Playfair Display   | 28px  | 700    | 1.2         | Screen titles                |
| `--text-h2`     | Playfair Display   | 22px  | 700    | 1.3         | Section headings             |
| `--text-h3`     | Playfair Display   | 18px  | 400    | 1.4         | Recipe names, card titles    |
| `--text-body`   | Nunito             | 15px  | 400    | 1.6         | General body copy            |
| `--text-label`  | Nunito             | 13px  | 600    | 1.4         | Tags, meta info, captions    |
| `--text-micro`  | Nunito             | 11px  | 400    | 1.4         | Timestamps, icon labels      |
| `--text-button` | Nunito             | 15px  | 700    | 1           | All button text              |

---

## 4. Logo & Mascot

### Logo
- **Wordmark:** `chefit` — always lowercase, set in a rounded bold sans-serif, Sage Green (`#4C5A3E`).
- The leaf on the `i` is a core part of the wordmark — never remove it.
- Minimum size: **80px wide** in digital contexts.
- Clear space: maintain padding equal to the height of the `c` on all four sides.

### Logo Variations
| Variant          | When to use                               |
|------------------|-------------------------------------------|
| Full (icon + wordmark) | Splash screen, onboarding, marketing |
| Wordmark only    | In-app header, tight spaces               |
| Icon only        | App icon, favicon, avatars                |

### Mascot — "Chef Bit"
The Chefit mascot is a friendly, round bread-loaf chef with rosy cheeks, small leaf sprouts, and a warm expression.

**Rules:**
- Chef Bit should always look **happy, welcoming, or playful** — never serious or sad.
- Use Chef Bit on: splash screens, empty states, onboarding, success moments, and community CTAs.
- Do not distort, recolour, or add accessories not in the original design.
- Speech bubbles use **Pistachio** background, **Sage Green** text, Nunito font.
- Example copy: *"Let's cook something amazing!"* — keep it warm and encouraging.

---

## 5. Iconography

### Navigation Icons
Used in the bottom tab bar. Always 5 icons.

| Tab        | Icon Style         | Active State          |
|------------|--------------------|-----------------------|
| Home       | House outline      | Sage Green fill + dot |
| Search     | Magnifying glass   | Sage Green            |
| Add / Scan | `+` in circle      | Peach fill (always prominent) |
| Saved      | Heart outline      | Sage Green fill       |
| Profile    | Person outline     | Sage Green            |

The **Add/Scan** button is always the visual centrepiece of the nav bar — larger, Peach-filled, centred.

### Feature Icons
Displayed in rounded Pistachio bubbles (circle or squircle background).

| Feature        | Icon           |
|----------------|----------------|
| Scan Pantry    | Fridge         |
| AI Recipes     | Sparkle bowl   |
| My Recipes     | Recipe book    |
| Shopping List  | Basket         |
| Favourites     | Heart          |
| Profile        | Person         |

Icon style: **outline with soft rounded strokes**, 2px stroke weight, Sage Green lines on Pistachio background. Never use filled solid icons for feature icons.

### Ingredient Icons
Chefit has a full library of ingredient icons (see `chefit_ingredient_icons.png`). These are used in:
- Scanned pantry displays
- Recipe ingredient lists
- Search results

**Style rules:**
- Illustrated/cartoon style — colourful, friendly, not photographic.
- Consistent scale — each icon should read clearly at **40×40px**.
- Never mix this style with flat geometric icons.

Categories available: Fruits, Vegetables, Herbs, Dairy, Meat & Fish, Grains, Nuts & Seeds, Oils & Condiments, Spices, Pantry staples.

---

## 6. Spacing & Layout

### Base Unit
All spacing uses an **8px base grid**. Use multiples: `4, 8, 12, 16, 24, 32, 48px`.

```
--space-xs:   4px
--space-sm:   8px
--space-md:  16px
--space-lg:  24px
--space-xl:  32px
--space-2xl: 48px
```

### Border Radius
Chefit uses **very rounded** corners throughout to match its friendly aesthetic.

```
--radius-sm:  8px    (tags, chips, input fields)
--radius-md: 16px    (cards, list items)
--radius-lg: 24px    (bottom sheets, modals)
--radius-xl: 32px    (buttons)
--radius-full: 9999px (pills, avatars, nav add button)
```

### Cards
- Background: White or Pistachio (`#E8F0E3`)
- Border radius: `--radius-md` (16px)
- Shadow: `0 2px 8px rgba(0,0,0,0.06)` — subtle, never dramatic
- Padding: `--space-md` (16px) internally

### Buttons

| Type      | Background | Text    | Border Radius | Min Height |
|-----------|------------|---------|---------------|------------|
| Primary   | Peach      | White   | `--radius-xl` | 48px       |
| Secondary | Transparent| Sage    | `--radius-xl` | 48px       |
| Ghost     | Transparent| Sage    | `--radius-xl` | 40px       |

Buttons are always **full-width** within their container on mobile screens.

---

## 7. Component Patterns

### Bottom Navigation Bar
- 5 tabs, always visible (except during active cooking mode).
- Scan/Add button: Peach circle, `+` icon, slightly elevated (shadow or size).
- Active tab: Sage Green icon + label. Inactive: Matcha/grey icon, no label highlight.

### Recipe Cards
- Thumbnail image (rounded corners, 16px radius).
- Recipe name: `--text-h3` Playfair Display.
- Meta row: time icon + duration, difficulty badge — all in `--text-micro` Nunito.
- Heart icon (favourite toggle) top-right of image.

### Search
- Search bar: Cream/White fill, rounded pill shape, magnifying glass icon left, filter icon right.
- Recent searches shown as Matcha pill tags.
- Category grid: icon + label in Pistachio bubbles.

### Ingredient Chips (Detected / Selected)
- Pistachio background, Sage Green text, ingredient icon left.
- Removable state: show `×` on right.
- Border: 1px Matcha.

### Step Cards (Cooking Mode)
- Numbered circle: Peach fill, white number.
- Step description: `--text-body` Nunito.
- Ingredient callout inline (e.g. tomato icon + amount).

### Community / Social Posts
- Avatar (circular), username, timestamp.
- Photo card with rounded corners.
- Interaction row: ❤️ like count, 💬 comment count, 🔖 save.
- Hashtags in Matcha colour.

---

## 8. App Flow Overview

The app has **13 core screens**. Contributors should understand the overall flow before building any screen.

```
Splash → Sign Up/Log In → Home
                            ├── Search → Recipe Discovery → Recipe Details → Cooking Mode
                            ├── Scan Pantry → Ingredients Detected → Recipe Recommendations
                            │                                              └── Shopping List
                            ├── Saved / Favourites
                            ├── Profile
                            └── Community (Social)
```

### Screen Summary

| # | Screen                   | Purpose                                              |
|---|--------------------------|------------------------------------------------------|
| 1 | Splash / Onboarding      | Warm welcome, introduce brand and mascot             |
| 2 | Sign Up / Log In         | Email, Google, Apple auth                            |
| 3 | Home                     | Daily inspiration, popular recipes, search entry     |
| 4 | Search                   | Full search, categories, trending ingredients        |
| 5 | Recipe Discovery         | Recipe card with key info before committing          |
| 6 | Recipe Details           | Ingredients, Steps, Notes tabs + Start Cooking CTA   |
| 7 | Scan Pantry              | Camera scan to detect pantry ingredients             |
| 8 | Ingredients Detected     | Review/edit detected items                           |
| 9 | Recipe Recommendations   | AI-matched recipes from scanned ingredients          |
| 10| Shopping List            | To-buy + pantry items, "Add All to Cart" action      |
| 11| Favourites / Saved       | User's saved recipes                                 |
| 12| Profile                  | Account, cooking stats, settings                     |
| 13| Community (Social)       | Feed of what others cooked, upvote/comment/save      |

---

## 9. Tone of Voice

Chefit speaks like a **friendly, encouraging kitchen companion** — not a corporate app, not a stern chef.

### Principles

| Trait         | Do                                      | Don't                              |
|---------------|-----------------------------------------|------------------------------------|
| Warm          | "Hello Chef! 👋"                        | "Welcome, User."                   |
| Encouraging   | "You've got this!"                      | "No valid recipes found."          |
| Casual        | "What's for dinner?"                    | "Please select a meal category."   |
| Helpful       | "We found 3 recipes you can make!"      | "Matching results: 3"              |
| Playful       | "Let's cook something amazing! 🍳"      | "Begin cooking session."           |

### Microcopy Guidelines
- **Empty states:** Always include Chef Bit + a warm message + an action. Never just show "No results."
- **Errors:** Apologetic and helpful. *"Hmm, we couldn't find that. Try a different ingredient?"*
- **Success moments:** Celebrate! *"Boom — added to your list! 🎉"*
- **Loading states:** Keep them friendly. *"Finding recipes... 🌿"*
- **Buttons:** Action verbs. `Start Cooking`, `Find Recipes`, `Scan Now`, `View Recipe`, `Add to Cart`.

---

## 10. Do's and Don'ts

### ✅ Do
- Use the exact HEX values from the colour palette — no approximations.
- Keep corners round. Chefit has zero sharp corners in its UI.
- Use Playfair Display for all headings and Nunito for all body text.
- Include Chef Bit on empty states and onboarding moments.
- Keep the tone warm and first-person friendly ("we", "your", "you").
- Follow the 8px spacing grid.
- Use the full ingredient icon library for consistency.
- Always show the `+` scan button as the visual centrepiece of the nav bar.

### ❌ Don't
- Don't use Honey text on Cream backgrounds (fails contrast).
- Don't use solid/filled feature icons — always outline style.
- Don't write "user" in microcopy — say "Chef", "you", or "your".
- Don't use hard drop shadows — keep shadows at 6% opacity max.
- Don't stretch or skew the logo or mascot.
- Don't introduce new typefaces — stick to Playfair Display and Nunito only.
- Don't use photography-style food images in the icon library — illustrations only.
- Don't remove the leaf from the `i` in the wordmark.
- Don't use bright pure red/green/blue — always use the palette.

---

## Appendix: Quick Reference Tokens

```css
/* Colours */
--color-sage-green:  #4C5A3E;
--color-matcha:      #A8C5A1;
--color-pistachio:   #E8F0E3;
--color-cream:       #FFF7E8;
--color-peach:       #FFB79D;
--color-honey:       #FFD26F;
--color-text:        #2F3A2E;

/* Spacing */
--space-xs:   4px;
--space-sm:   8px;
--space-md:  16px;
--space-lg:  24px;
--space-xl:  32px;
--space-2xl: 48px;

/* Border Radius */
--radius-sm:   8px;
--radius-md:  16px;
--radius-lg:  24px;
--radius-xl:  32px;
--radius-full: 9999px;

/* Typography */
--font-heading: 'Playfair Display', serif;
--font-body:    'Nunito', sans-serif;

--text-h1:     28px / 700;
--text-h2:     22px / 700;
--text-h3:     18px / 400;
--text-body:   15px / 400;
--text-label:  13px / 600;
--text-micro:  11px / 400;
--text-button: 15px / 700;

/* Shadows */
--shadow-card: 0 2px 8px rgba(0, 0, 0, 0.06);
--shadow-nav:  0 -1px 12px rgba(0, 0, 0, 0.06);
```

---

*Last updated: April 2026 · Maintained by the Chefit design team.*  
*Questions? Open an issue or ping the #design channel.*
