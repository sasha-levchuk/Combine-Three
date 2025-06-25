class_name Tile extends Button

const SIZE := Vector2(64, 64)
enum TYPES{ RED, GREEN, BLUE, YELLOW }
@export var SCENES: Dictionary[TYPES, PackedScene]
@export var type: TYPES
var start: Vector2
var drag_offset: Vector2
var center: Vector2
var is_locked := false
@onready var grid_trans: Transform2D = get_parent().transform

signal dragged(coord, direction)


func _ready():
	size = SIZE
	set_process(false)


func _on_button_down():
	is_locked = true
	start = position
	center = position + size/2
	drag_offset = get_global_mouse_position() * grid_trans - position
	z_index = 10
	set_process( true )
	button_up.connect( _on_button_up, CONNECT_ONE_SHOT )


func _process( _delta ):
	var mouse := get_global_mouse_position() * grid_trans
	position = mouse - drag_offset
	var direction:Vector2i=((mouse-center)*2/size).limit_length(1.4142135865763)
	if direction:
		button_up.disconnect(_on_button_up)
		set_process(false)
		dragged.emit( Vector2i( start / size ), direction)


func _on_button_up( ):
	set_process( false )
	move_precise( start )


func move(coord: Vector2i) -> Signal:
	return move_precise( Vector2(coord) * size )


func flash_pink():
	var panel := %PinkPanel
	panel.show()
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): 
		panel.hide()
		panel.modulate.a = 1.0
	)


func collapse() -> Signal:
	%ColorDeletion.show()
	is_locked = true
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free).set_delay(0.1)
	return tween.finished


func move_precise(new_pos: Vector2) -> Signal:
	var time := 0.1 + new_pos.distance_to(position) / 800
	mouse_filter = MOUSE_FILTER_IGNORE
	is_locked = true
	var tween := create_tween()
	tween.tween_property(self, "position", new_pos, time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		mouse_filter = MOUSE_FILTER_STOP
		z_index = 0
		is_locked = false
	)
	return tween.finished


func set_label(s: String):
	%Label.text = s
