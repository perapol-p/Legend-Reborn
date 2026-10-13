# UI layout and assets
The shared UI uses all three user-supplied textures from Assets/UI:
- TextBox2.png: nine-slice buttons, cards, windows and dialogs.
- TextBox3.png: inset artwork and the lower-left HUD backdrop.
- TextBox-export.png: primary Play, Start Run and Resume buttons.

Dark panels, warm ivory text, gold highlights and muted secondary text form the shared palette. Artwork keeps its aspect ratio and uses linear filtering independently of pixel frames.

Home has a two-line title and a distinct primary action. Stage cards separate mode, name, description and encounter information. Character cards prioritize portraits and class roles. Loadout separates character, weapon and destination using rich text. Settings uses a centred frame and highlights its active tab. Item rarity colours and existing inventory/reward behaviour remain connected to the shared style.

Selected map backgrounds, mouse parallax and black inward transitions remain active. Practice hints hide while paused or choosing rewards.

Verification: backups/verify_ui_polish.gd; previews: backups/polished_*.png.
