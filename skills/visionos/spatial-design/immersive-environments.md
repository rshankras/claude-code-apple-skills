# Immersive Environments — Production & Budgets

Building custom environments that hold 90fps on device. Design rules live in `SKILL.md`; this
file is the production pipeline and the hard numbers (from Apple's WWDC24–26 environment
sessions and the Moon-environment optimization case study).

## The budgets (WWDC25 optimization session)

| Budget | Target |
|---|---|
| Total triangles | **< 200,000** (the Moon example came from 100M+ source polygons) |
| Visible per frame | **< 100,000** after frustum culling |
| Entities | **< 200 total assets** |
| Draw calls | **< 100 per frame** — merge and bake into consistent mesh partitions |
| Texture memory | **< 250 MB** (gigabytes of PBR maps re-baked onto optimized UV atlases) |
| Billboard threshold | beyond **~1 km** perceived distance — depth cues flatten from 1–3 km, so distant content becomes billboards (millions of polygons → thousands) |

## Design around the viewing area

- Environments are built at **real-world scale** — drop human-figure references in the scene
  and verify scale in-headset repeatedly (monitor perception lies about both scale and light).
- Define the **Immersive Boundary** (the few-meters traversable zone) and drive every
  optimization decision from it: don't model geometry invisible from it, decimate distant
  assets, preserve silhouettes only from positions people can actually occupy.
- Never place assets in front of an in-environment viewing screen (depth conflict with media).
- Support day/night lighting setups driven by HDRIs.

## The pipeline

1. **Reference like a photographer** (WWDC26): tripod at 1m (optionally a second at 2m for
   occluded areas), deep depth of field, bracketed exposures for the sun-to-shadow range,
   Macbeth charts + chrome/gray spheres for lighting integration. 360° panorama target:
   **14,400 × 7,200 px (~40 px/degree)**; viewers see ~**81°** of it when fully immersed —
   compose key content inside that.
2. **Model** in Maya/Houdini/Blender → export USDC → Reality Composer Pro. Clean naming
   (names drive per-piece material edits); disable post-process tone mapping so looks match.
3. **Bake** lighting + surface detail into textures, set materials **unlit**; repack UVs into
   few groups (the studio example: 6 UV maps / 6 textures). Dual-texture strategy: one atlas
   for the boundary zone (surface-area scaled), one for everything beyond (screen-space scaled).
4. **Cull**: backfaces via dot-product against the boundary, hidden geometry via raycast
   occlusion (~50% of remaining triangles in the case study). Apple's Immersive Optimization
   Toolkit for Houdini ships 14 HDAs (Adaptive Reduce, Vista Billboard, Mesh Partition,
   Boundary/Frustum Partition…).
5. **Fake the expensive parts**: UV flow maps and precomputed data textures for soft shadows
   and motion; hierarchical vertex animation + layered sine waves for natural movement —
   carry motion in textures, not geometry.
6. **Ground the scene**: virtual objects cast shadows; light-emitters spill color; soft edges
   where the environment blends into passthrough; spatial audio emitters at scene locations.

## ✅ / ❌

- ✅ A/B every optimized asset against the source panorama — fidelity is the point of baking.
- ✅ Justify everything added or removed; curate rather than replicate reality.
- ❌ Real-time lighting where baked would do; geometry for areas nobody can see; assets
  detailed uniformly regardless of viewing distance.
- ❌ Testing only on the monitor — scale, light, and comfort all read differently in-headset.

## References

- https://developer.apple.com/videos/play/wwdc2024/10087/ (Create custom environments)
- https://developer.apple.com/videos/play/wwdc2025/305/ (Optimize your custom environments)
- https://developer.apple.com/videos/play/wwdc2026/234/ (Design immersive environments)
