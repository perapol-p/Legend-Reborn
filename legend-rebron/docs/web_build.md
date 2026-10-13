# Legend Reborn web build
Ready-to-upload archive: build/Legend-Reborn-Web.zip (18,952,535 bytes).
The archive has index.html at its root and only the browser runtime files.

itch.io:
1. Create/edit the game page and choose HTML as the project kind.
2. Upload Legend-Reborn-Web.zip and mark it "This file will be played in the browser".
3. Set the embed to 1280 x 720 and allow fullscreen.
4. Test on the actual itch.io page before publishing.
The build targets keyboard/mouse desktop browsers with WebGL 2.0.

Performance changes:
- Web defaults to Low; Settings offers Low / Medium / High.
- Low renders 3D at 75% resolution, disables sun shadows, reduces particle counts and effect geometry.
- Menu previews are 768 x 432 on Low and construct each arena only when first selected.
- Enemy steering is cached and staggered; animation updates are throttled by distance/visibility.
- Low omits ordinary enemy-to-enemy collision, restoring it when enemies pursue an elevated player or finish climbing. Enemy/player/world and projectile hits remain active.
- Scenery uses collision bits 1+2; enemies use bit 4; player and weapon queries include enemies.
- Tornado area queries are cached for up to 0.1 seconds and refresh for every damage tick.
- Area LOS uses the scenery-only collision layer so enemies do not require repeated skip-ray queries.
- Arrows sweep a whole frame segment, repeating only for pierced bodies; spell collision shapes are reused.
- Hit overlay materials are attached only during the actual flash.
- Zombie materials are shared; skeleton archers load only their four required animation clips.
- Texture import limits: item art 256, portraits/effect textures 512, monster and weapon textures 1024. Original files remain available.
- The release bundle excludes backups, test scenes, unused animations and inactive weapon assets.
- Web pointer lock uses a trusted click and resumes properly after scene transitions and pause.

Validation:
- Chromium: boot, map/class/loadout selection, movement, held attacks, pointer lock, pause and resume passed with no game script errors.
- Native regression checks: staff LV1/2 piercing and decreasing damage, accurate aim LV1-5, ten-hit Explosion and Continue mid-attack, climbing/stacking, boss/flyer combat and victory timing passed.
- The 160 mixed-enemy + 4 tornado + LV5 stress scene runs, but remains CPU/render intensive and measured roughly 7.5 FPS using Godot process delta in automated Chromium. This is a stress limit, not a guarantee of smooth play on all devices.
- Browser startup on localhost was about 3.3 seconds; this does not predict internet download time.
- Screenshot capture emits Chromium ReadPixels warnings. Short native test exits retain existing ObjectDB warnings.

Rebuild production:
Godot --headless --path <project> --export-release Web build/web/index.html
ZIP only the .html/.js/.wasm/.pck/.png runtime files, with index.html at root.
The Web Validation preset is for local stress testing and is excluded from the production ZIP.
