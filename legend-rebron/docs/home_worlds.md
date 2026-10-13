# Home screen cinematic worlds

The main menu uses the real Grassland, Desert and Practice arenas as private 3D backdrops. The initial map is random. Every 11-15 seconds a different map is selected randomly, with a 0.65 second crossfade; there are no manual map-selection buttons on Home. A small lower-right caption identifies the current backdrop.

Each shot picks one of three camera compositions and makes a slow dolly of less than one metre. Mouse position produces smoothed parallax (up to 0.20 m horizontal, 0.12 m vertical and a small look-target adjustment). FOV stays at 65 degrees; camera roll stays zero.

On activation a backdrop randomizes 5-7 ambient monsters: zombie, skeleton archer and flying eye are represented, with a 40% chance to include a golem and weighted extra monsters. Routes, starting points and speeds vary. Further random arrivals occur every 5-8 seconds, keeping at most eight active actors in the selected crowd; older actors shrink away. Ground actors walk with terrain collision, and eyes hover with their original wing animation.

Actors have no combat, health bars, drops or gameplay groups. Camera/crowd randomness uses a private RNG and never writes run/progress data or changes the stage selected by Play/Continue.

Each backdrop has a private SubViewport/World3D. Only the selected world processes/renders during steady display; both worlds run during transitions. Inactive actors/rendering are suspended. A gradient shade keeps the left-aligned menu readable.

Validation: backups/verify_home_cinematic.gd checks mixed monster visuals/movement, random non-repeating scenes, mouse parallax without roll, live arrivals/cap, inactive worlds and save isolation. The earlier backups/verify_home_continue.gd checks actual Continue and Play navigation; verify_home_worlds.gd describes the older four-zombie version.
