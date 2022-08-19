extends Node
#SignalBus

#Repository of all signals that travels externally from a scene instance
#Scenes that can handle the signal themselves does not need to use this
#Useful for level wide communication

#-------------------------
#Player specific signals
#-------------------------

#player to level manager connection
signal projectile_spawned

signal movement_changed
signal action_changed

#player to camera connection
signal player_updated
