# Endgame Design: The Homecoming

## Overview

The endgame for Into the Wild is a **homecoming**. The player follows a trail blazed by explorer E.W. Carlston, walks out of the wilderness, and arrives back at their cozy house in the Oakland Hills. The house is a fully explorable interior scene where the player can relax, view their wilderness inventory as a memento, and optionally return to a fresh wilderness with 5 chosen items (New Game+).

**Emotional tone:** Warm, personal, satisfying. The wilderness was the journey — home is the destination.

---

## Part 1: Carlston's Trail (4 Landmarks)

The player follows a sequence of landmarks, each containing a clue pointing to the next. The trail spans the far reaches of the map, requiring late-game tools and thorough exploration.

### Landmark 1: The Sinkhole / Explorer's Journal (Existing)

- **Location:** Pocket desert at (-350, 0) — already exists
- **What's here:** The Explorer's Journal, already containing diary entries about Carlston's exploration
- **New content:** A final diary entry is added (or the existing final entry is extended) with a hint: something like *"I marked the old ranger trail. Start at the carved tree on the north ridge."*
- **Requirement to reach:** Navigate to the hidden pocket desert (rock spire as landmark)

### Landmark 2: The Carved Tree

- **Location:** ~300 units north of spawn, deep in the HILLS biome on a ridge
- **What's here:** A distinctive tree with Carlston's initials and an arrow carved into it. Interacting reveals a note/carving: *"Follow the ridge east to the stone cairn."*
- **Requirement to reach:** Grappling hook or significant climbing to reach the ridge

### Landmark 3: The Stone Cairn

- **Location:** ~400 units NE of spawn, in the ROCKY/MOUNTAIN region at high elevation
- **What's here:** A stacked-rock marker on a high point. Interacting reveals: *"The trail drops into the valley beyond the mountains. Look for the old signpost."*
- **Requirement to reach:** Hang glider or grappling hook recommended for efficient access

### Landmark 4: The Signpost / Trailhead

- **Location:** ~500+ units from spawn, at the very edge of the generated world
- **What's here:** A weathered wooden signpost pointing two directions — back toward the wilderness, and forward: **"Longridge Road, Oakland, California — 225 miles"**
- **Interaction:** Player can choose **"Leave the wilderness?"** — confirming triggers the transition sequence
- **Requirement to reach:** The furthest point the player will ever travel

### Trail Design Principles

- Each landmark is a simple interactable object (similar to the existing wilderness sign)
- No complex puzzles — the challenge is exploration and reaching remote locations
- Clues are embedded in the journal entry and at each landmark
- The trail spans a wide arc across the map: west (sinkhole) → north (hills) → northeast (mountains) → far edge (signpost)

---

## Part 2: The Transition

When the player confirms "Leave the wilderness?" at the signpost:

1. **Auto-walk:** Player automatically walks forward along a narrow dirt trail beyond the signpost (no player control — cinematic moment)
2. **Sound fadeout:** Wilderness sounds (birds, wind, ambient music) slowly drop out over ~3 seconds
3. **Screen fade to black:** Over ~5 seconds
4. **Beat of silence:** 2-3 seconds of black screen. Optionally brief text: *"225 miles later..."*
5. **Fade in:** The house interior loads and fades in

The player's full inventory at the moment of departure is saved — this becomes the contents of the house storage box.

---

## Part 3: The Oakland Hills House

### Architecture: Separate Scene

The house is a completely separate Godot scene (`house.tscn`), loaded independently from the wilderness. This provides:

- Clean separation from wilderness terrain/chunk systems
- Full control over indoor atmosphere (warm lighting, no weather)
- A natural "chapter break" feeling from the scene transition
- Easy to iterate on independently

### Interior Style

**Classic colonial:**
- Dark hardwood floors (deep brown BoxMesh)
- White walls
- Crown molding (thin accent strips along ceiling edges)
- Six-pane windows (grid of BoxMesh mullions over a painted backdrop)
- Warm indoor lighting (OmniLights simulating lamps)

### Rooms & Contents

**Living Room:**
- Couch, coffee table, rug on hardwood
- Bookshelves along one wall
- Two framed pictures on the wall:
  - An all-black cat with yellow eyes
  - A black-and-white tuxedo cat with yellow eyes
  - (Both rendered as BoxMesh pixel-art style in frames)
- **Wilderness Storage Box** — a familiar-looking storage container (same visual style as the campsite storage box). Contains the player's complete inventory from when they left the wilderness. Opens the standard storage UI but in **view-only mode** — items cannot be taken out or equipped. A memento of the journey.

**Kitchen:**
- White cabinets, counter, stovetop
- **Kettle** (interactable): "Make tea" — plays a sound, brief text: *"Warm. Familiar."*
- Fridge

**Dining Room:**
- Table with chairs
- **Chandelier** overhead (hanging cluster of small BoxMesh shapes with warm OmniLight)
- **Sandwich on a plate** (interactable): "Eat sandwich" — same gentle moment

**Windows:**
- Six-pane colonial style throughout
- View: Oakland Hills backdrop — green hillside, scattered houses, hints of fog or bay in the distance

**Front Door:**
- The key interaction point for returning to the wilderness (see Part 4)

### Atmosphere

- **No HUD** — no health bar, no hunger meter, no equipped item display. All survival UI is stripped away.
- **No survival mechanics** — no hunger depletion, no health concerns. Just peace.
- **Ambient audio** — quiet indoor sounds, maybe a clock ticking, distant neighborhood sounds
- **Warm lighting** — soft lamp glow throughout, no harsh sunlight

---

## Part 4: Returning to the Wilderness (New Game+)

### Front Door Interaction

The front door offers two options:

1. **"Return to the wilderness"** — starts the New Game+ flow
2. **"Stay home"** — closes the interaction (player can keep exploring the house or quit from pause menu)

### Item Selection (5 Items)

When the player chooses to return:

1. **Item selection screen** appears showing the full inventory from the wilderness storage box (everything they had when they completed the journey)
2. Player **selects exactly 5 items** to carry back as starting equipment
3. Confirming the selection triggers a fade to black
4. **New wilderness generates** with a fresh world seed:
   - Camp level reset to 1
   - No structures, no landmarks discovered
   - Trail landmarks generate in new positions
   - Player starts with their 5 chosen items
5. The full journey can be completed again

### Design Notes

- The 5-item limit forces meaningful choices — do you bring a diamond axe for efficiency, or rare resources for a head start on crafting?
- Each New Game+ run feels different based on item selection and new world generation
- The house storage box updates each time the player completes a journey, showing only the most recent run's inventory

---

## Summary

| Phase | What Happens | Player Action |
|-------|-------------|---------------|
| Carlston's Trail | Follow 4 landmarks across the far wilderness | Explore, use late-game tools |
| Transition | Cinematic walk-out, fade to black | Watch |
| The House | Explore cozy Oakland Hills home | Walk around, interact with objects |
| New Game+ | Choose 5 items, return to fresh wilderness | Select items, start new journey |
