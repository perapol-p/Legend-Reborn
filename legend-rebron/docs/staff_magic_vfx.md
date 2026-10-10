# Staff magic VFX

Texture assets: Kenney Particle Pack 1.0, CC0, downloaded from https://kenney.nl/assets/particle-pack. The archive is backed up at backups/kenney_particle-pack.zip. Selected textures and original License.txt are in assets/vfx/kenney_particles. Credits in that license identify Kenney, D4r and Tim2501.

- Animated staff gem: purple emission, a soft halo, blue magic seal and a short spark burst attached to the original animated Bone. Original arm animations remain in use.
- Magic projectile: procedural energy shell, bright core, three orbiting rings and a world-space star trail. Spells launch from the animated gem towards the crosshair target; close walls between the camera and gem block the shot.
- Impact: short sparks, fading flare and two expanding shock rings. High level nuke explosions use purple arcane visuals at the existing splash radius.
- Vortex: three flowing translucent spiral ribbons, rising sparks and a ground-aligned seal. Original pull and damage logic are unchanged.
- Warp: matching purple departure/arrival bursts.
- Shader phase advances with active process time, preserving pause behavior. Materials use additive blending and ordinary depth testing, with no camera shake or global bloom required by the compatibility renderer.
- Impact bursts are limited to 18 active instances and expire after 0.65 seconds; detached trails expire after 0.42 seconds. These transient visuals are not saved. Saved projectiles/vortices rebuild their visuals when restored.
- Damage multipliers, hit radii, cooldowns and skill upgrade behavior are unchanged. The procedural shaders in shaders/magic_energy.gdshader and magic_ribbon.gdshader are custom project code.

Checks: backups/verify_staff.gd (original model/animations and skill/save compatibility), backups/verify_magic_vfx.gd (actual aimed hit/damage, trails, vortex, save restoration, pause and cleanup), backups/verify_magic_final.gd (LV5 attack contents, nuke splash and close-wall blocking).
