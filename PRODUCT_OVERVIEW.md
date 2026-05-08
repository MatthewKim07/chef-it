# Chefit — Product Overview

Chefit is an iOS/macOS app that turns your pantry into a meal plan. Snap or type what you have, get ranked recipe matches, share your cooking, and shop for what you're missing — all in one place.

---

## The User Journey

### 1. Sign Up & Log In

First-time users create an account with an email, password, and display name. Returning users log in with email/password. A JWT token is stored securely in the Keychain so the session persists across app launches. Logout is available from the profile tab.

---

### 2. Building Your Pantry

The **Home** tab is where users manage their ingredient board.

**Manual entry** — type ingredients as a free-form list (comma, semicolon, newline, and other delimiters all work). Autocomplete suggestions appear as you type.

**Photo scan** — tap the **Scan** tab to use the camera or photo library. AI detects ingredients from the image, assigns a confidence score to each, and lets the user review and confirm before adding them to the pantry.

Once added, each ingredient is:
- Categorized automatically (produce, protein, dairy, pantry, spice, grain, condiment, other)
- Optionally given an expiry date for freshness tracking
- Editable or removable individually
- Clearable in bulk (with undo)

The pantry persists locally via UserDefaults.

---

### 3. Recipe Discovery

As soon as ingredients are in the pantry, Chefit starts finding recipes.

**How matching works:**
- Recipes are fetched live from the Edamam API, with seed recipes as a fallback.
- A protein-led algorithm builds the query plan — recipes are grouped around the proteins the user has.
- Each recipe gets a score based on ingredient coverage (50% weight), protein hits (bonus), missing ingredient count (penalty), and cooking time (tiebreaker).

**Three tiers of results:**
| Tier | Meaning |
|---|---|
| Ready to cook | All ingredients on hand |
| Almost there | 1–2 ingredients missing |
| Excluded | Too many gaps |

**Context-aware recommendations:**
- The "For You" feed adapts to time of day — breakfast, lunch, dinner, late-night — with appropriate cooking time filters.
- Ingredients nearing expiry are surfaced first so nothing goes to waste.

**Recipe metadata shown:**
- Match percentage and pantry coverage breakdown
- Cooking time and difficulty (easy / medium / hard)
- Badges: Quick, Easy, 1-Pan, Healthy, High-Protein

---

### 4. Recipe Details

Tapping a recipe opens the full detail view:
- Hero image with match badge
- Full ingredient list with status indicators (have it / missing)
- Step-by-step cooking instructions
- Servings and dietary info
- "Start cooking" action

Users can **favorite** a recipe (heart icon) — favorites persist locally.

---

### 5. Shopping List

Any missing ingredient can be added to the **Shopping List** directly from a recipe card.

Features:
- Items grouped by category (produce, protein, dairy, etc.)
- Quantity management with +/- controls
- Check-off items as you shop
- Smart deduplication when adding from multiple recipes

**One-tap shopping** — Chefit connects to grocery providers:
- **Instacart** (primary)
- Kroger, Walmart, Target, Amazon Fresh (fallback)

Each provider card shows a price estimate, delivery time, and item availability (full vs. partial coverage). Tap to open the provider app with your list.

The cart persists locally via UserDefaults.

---

### 6. Reviews

On any recipe detail page, users can leave a **star rating (1–5)** with optional written feedback. Submitting again updates the existing review (upsert). All reviews for a recipe are visible to any user.

---

### 7. Community Feed

The **Community** tab shows a paginated feed of posts from all users — 20 per page with infinite scroll and pull-to-refresh.

Each post card shows:
- Author avatar and display name
- Recipe photo
- Caption
- Comment count and relative timestamp

Tapping a post opens the **detail view** with the full image, caption, a linked recipe callout (if present), and the full comments thread. Users can add a comment inline — the count updates in real time.

Post authors can delete their own posts (with confirmation).

---

### 8. Creating a Post

From the Community tab, tap the compose button to create a post:
1. Pick a photo from the library (normalized to max 1600px before upload)
2. Write a caption
3. Optionally link a recipe
4. Post — image uploads to Cloudinary, metadata saves to the backend

---

### 9. User Profiles

Tapping any author opens their **public profile**:
- Display name, bio, avatar
- 3-column grid of their posts

**Your own profile** (Profile tab) adds:
- Edit profile sheet (display name, bio)
- Avatar upload via photo picker
- Logout

The profile menu also provides quick links to the Shopping List, Pantry/Scan, and placeholder links for Settings and Help & Support.

---

### 10. Search & Browse

The **Search** tab lets users find recipes by keyword. It also surfaces:
- Recent searches
- Browse categories: Quick & Easy, Vegetarian, Dinner, Breakfast
- Trending ingredients as scrollable pills

---

## Navigation

Four bottom tabs:

| Tab | Purpose |
|---|---|
| Home | Pantry board + For You recipe feed |
| Scan | Camera/photo scan for ingredients |
| Community | Social feed, post creation |
| Profile | Your profile, posts, account settings |

---

## Backend & Data

| Layer | Technology |
|---|---|
| App | SwiftUI (iOS 17+, macOS 14+) |
| Backend | Node.js + Express |
| Database | PostgreSQL (Neon) |
| Images | Cloudinary CDN |
| Auth | JWT (Keychain-stored) |
| Recipes | Edamam API + local seed fallback |

Local persistence (UserDefaults): pantry ingredients, shopping cart, favorite recipe IDs.

---

## What's Coming

- Follow / unfollow users
- Like posts
- Notifications
- Full cooking mode with step timer
- Search filters
- Settings and Help screens
