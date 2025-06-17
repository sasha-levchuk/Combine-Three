class_name Tile extends Button

enum TYPES{RED, GREEN, BLUE, YELLOW}
@export var type: TYPES
var drag_offset: Vector2
var center: Vector2
var on_button_up: Callable
@onready var grid_trans: Transform2D = get_parent().transform

signal drag_started
signal drag_ended
signal animation_ended


func _ready():
	set_process(false)


func _on_button_down():
	center = position + size/2
	drag_offset = get_global_mouse_position() * grid_trans - position
	z_index = 1
	set_process( true )
	button_up.connect( _on_button_up.bind( position ) )
	drag_started.emit( self )


func _process( _delta ):
	#print(get_local_mouse_position())
	var mouse := get_global_mouse_position() * grid_trans
	position = mouse - drag_offset
	var direction:Vector2i=((mouse-center)*2/size).limit_length(1.4142135865763)
	if direction:
		button_up.disconnect(_on_button_up)
		set_process(false)
		drag_ended.emit(direction)


func _on_button_up( prev_pos ):
	set_process( false )
	top_level = false
	move_precise( prev_pos )
	prints('returned', self.name, 'to', prev_pos)
	button_up.disconnect(_on_button_up)


func move(coord: Vector2i) -> Tile:
	move_precise( Vector2(coord) * size )
	return self


func move_precise(new_pos: Vector2):
	var tween = get_tree().create_tween()
	tween.tween_property(self, "position", new_pos, .2).set_trans(Tween.TRANS_QUINT)
	tween.tween_callback(func():
		z_index = 0
		animation_ended.emit()
	)

func set_label(s: String):
	%Label.text = s
