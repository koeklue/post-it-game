class_name InputMode
extends RefCounted

## Shared definition of the two control schemes, used by the spawner and the UI.

enum Mode { MOUSE, TRACKPAD }

const TRACKPAD_RADIUS_FACTOR := 0.8 ## Trackpad targets are 20% smaller
const TRACKPAD_HOVER_TIME := 0.2 ## Seconds the cursor has to dwell to score a hit
const TRACKPAD_LIFETIME_FACTOR := 1.3 ## Dwelling costs time, so targets stay longer
