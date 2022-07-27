extends Node
class_name StateMachine
#Base state machine class
#Statemachine node must have state nodes as children and states added to a group

signal changing_state
signal current_state

#group of the state nodes 
export(String) var state_group = null
#current state
var current_state: State
#initial state
export(NodePath) var init_state
#list of states as nodes
var _state_list := []
#dict of states as name node pair
var state_dict :={}

#connection to other state machines for communication
export(NodePath) var observed_SM = null
var observed_SM_node #statemachine
var observed_state: String

func _ready():
	#disables state machine if unassigned state group
	enable_statemachine(false)
	
	#enable state machine
	if _get_states():
		_connect_states()
		_initial_state(init_state)
		enable_statemachine(true)
		
	pass

func enable_statemachine(enable:bool):
	if enable:
		set_physics_process(true)
		set_process_unhandled_input(true)
		set_process(true)
		
		if not observed_SM == null:
			observed_SM_node = get_node(observed_SM)
			if observed_SM_node.has_method("on_observed_SM_state_changed"):
				observed_SM_node.connect("changing_state",self,"on_observed_SM_state_changed")
		
	else:
		set_physics_process(false)
		set_process_unhandled_input(false)
		set_process(false)

#relegate inputs to state
func _unhandled_input(_event: InputEvent) -> void:
	current_state.state_input(_event)
	pass

func _process(_delta: float) -> void:
	current_state.state_process(_delta)
	pass

#relegate physics to state
func _physics_process(_delta: float) -> void:
	#broadcast SM and current state
	emit_signal("current_state", self.name, current_state.name)
	current_state.state_physics(_delta)
	pass

#handle switching of states
func switch_states(_new_state: String) -> void:
	_debug_print_state(current_state,_new_state)
	
	#double-check if it is in dict
	if not state_dict.has(_new_state):
		return
	
	#get info from old state, run its exit function
	var state_info = current_state.exit()
	var old_state = current_state
	#get reference to new state
	current_state = state_dict[_new_state]
	#enter new state passing old info
	current_state._prev_state = old_state
	emit_signal("changing_state", current_state.name, old_state.name)
	current_state.enter(state_info)
	pass

#get states from specified group and add to dict
func _get_states() -> bool:
	#catch if unassigned
	if state_group == null:
		return false
	
	_state_list = get_tree().get_nodes_in_group(state_group)
	for s in _state_list:
		state_dict[s.name] = s
	return true

#pass self reference to the state nodes
func _connect_states() -> void:
	for s in _state_list:
		s.state_machine = self
		connect("current_state", s, "initialize_inhibiting_connection")
		pass

#set initial state
func _initial_state(_s: NodePath) -> void:
	current_state = get_node(_s)
	current_state._prev_state = null
	current_state.enter()
	pass

func on_observed_SM_state_changed(current: String, old: String) -> void:
	observed_state = current

#var leaves = []
#find_leaves(state_machine_node, leaves)
#func find_leaves(parent:Node, results:Array):
#    if parent.get_child_count() == 0:
#        results.append(parent)
#    for child in parent.get_children():
#        find_leaves(child, results)

func _debug_print_state(initial: Node,final: String) -> void:
	print("Switching from ",initial.name," to ",final)
