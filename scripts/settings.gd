

extends Node

enum size {DEBUG, SMALL, NORMAL, EXTENDED}
var world_size: size = size.NORMAL

enum retile_mode {DISABLED, RUNTIME, GENERATION}
var retile: retile_mode = retile_mode.RUNTIME
