# Carlston Wilderness Information Sign

## Overview

A National Forest Service-style information kiosk near spawn that players can interact with to read wilderness regulations (disguised game instructions).

## 3D Sign — Covered Kiosk

Procedural BoxMesh construction:
- Two tall dark-brown wooden posts (~3.5 units tall)
- Angled roof with dark green/brown planks
- Large information board between posts (~2.5 wide x 1.5 tall) at eye-height
- Board face: olive/tan color
- "INFORMATION" header strip across top in darker color
- Position: approximately (6, 0, -4) from spawn, facing toward player's likely initial direction

Extends `StructureBase`, joins `"interactable"` group, returns `"Read Sign"` as interaction text.

## Information Overlay Screen

Full-screen overlay when player presses E:
- Dark semi-transparent background (ColorRect)
- Central panel styled like a park sign — forest-green border, tan/cream interior
- Uses `hud_font.tres` throughout

### Content

Title: "CARLSTON WILDERNESS" (gold, 56px)

Regulations (white, 32-36px):
- Hunting of birds and rabbits is permitted within wilderness boundaries
- Swimming areas are unmarked. Exercise caution near water — currents can be dangerous
- Deep pits and sinkholes are present in this area. Watch your step
- Collection of wood, stone, and natural resources is permitted
- Take care of the wilderness

Footer: "[E] Close" hint

### Behavior
- HUD hides while overlay is shown
- Player movement frozen
- Game does NOT pause (ambient sounds, day/night continue)
- Dismiss with E or Escape

## Files

1. `scripts/world/wilderness_sign.gd` — Sign mesh + interaction + overlay UI
2. `scripts/ui/hud.gd` — Add hide/show methods for overlay mode
3. World/scene placement — Add sign near spawn
