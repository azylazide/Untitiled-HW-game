extends ActorResource
class_name PlayerResource

#enum MOVE_ABILITIES {DASH,DJUMP,WALLCLIMB}
#enum ATTACK_ABILITIES {DASH,DJUMP,WALLCLIMB}
var attack_ability_list = []

export(int, FLAGS, "DASH", "DJUMP", "WALLCLIMB") var move_ability_flags:= 7
