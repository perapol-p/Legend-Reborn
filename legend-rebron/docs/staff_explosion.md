# Staff LV5 Explosion
- Requires equipped Staff (internal ID spellbook), weapon level 5.
- Press E (the rebindable Interact action). Targeted healing supplies take priority.
- Cooldown: 30 active seconds, independent of RMB Warp. Pause freezes it.
- Aims up to 30 metres and places the effect on the ground beneath the aimed point when available.
- Charges until 0.5 seconds after the final click in wizard_pre_explosion.wav (click at 3.43s, blast at 3.93s; full file duration 5.46s), then pulses 10 hits at 0.18-second intervals within 27 metres (1.62 seconds from first hit to last).
- Total damage across all 10 hits is 12 times the normal Staff damage roll; critical damage and hit/DPS/combo feedback use the existing combat system.
- Each pulse applies one tenth of total damage and checks current enemy position. Enemies entering or leaving the blast receive only the pulses they remain in range for.
- Terrain blocks blast damage. Other enemies do not shield each other; no victim-count cap.
- Uses the supplied 1.fbx Scene animation at 2.5x playback and original six JPEG textures with additive materials, scaled 6.6x (three times the initial effect size).
- Cooldown, pending animation age, damage, critical roll, blast radius completed-impact flag and pulse count persist through Continue.
- On each of the ten hits, the caster receives a brief 0.16-second screen shake that shifts the whole rendered scene and HUD by up to roughly 11 pixels, without changing aim rotation or camera roll. Pause, death and respawn clear the shake.
- The visual jumps straight into the blast frame 0.5 seconds after the final click; the original click tail remains audible. The pre-explosion chant plays on Effects and pauses with gameplay; Continue resumes its saved offset. Charge animation is slowed independently; the blast retains its original 2.5x playback.
- VFX disappears after its animation or when the run finishes.

Verification: backups/verify_staff_explosion.gd.
Preview: backups/staff_explosion_preview.png.

Multi-hit verification: backups/verify_explosion_ten_hits.gd.
