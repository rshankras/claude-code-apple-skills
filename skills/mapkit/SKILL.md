---
name: mapkit
description: MapKit and GeoToolbox skills — PlaceDescriptor patterns, geocoding, and cross-service place identifiers with MapKit integration. Use when working with maps, place data, or geocoding.
allowed-tools: [Read, Glob, Grep]
last_verified: 2026-07-16
review_by: 2027-06-22
---

# MapKit Skills

Location and place-data patterns built on MapKit and GeoToolbox.

## When This Skill Activates

Use this skill when the user:
- Works with **PlaceDescriptor** or GeoToolbox
- Needs **geocoding** or reverse geocoding
- Handles **place identifiers across services** (Apple Maps + third-party)

## Available Skills

Paths are relative to THIS file's directory — skills run with cwd set to the
user's project, so resolve each path from this SKILL.md's own location.

| Skill | Read | Covers |
|-------|------|--------|
| geotoolbox | `geotoolbox/SKILL.md` | GeoToolbox PlaceDescriptor, geocoding, multi-service place identifiers |

## How to Route

1. Read `geotoolbox/SKILL.md` (relative to this file) plus any reference files it lists.
2. Apply the guidance to the user's code.
