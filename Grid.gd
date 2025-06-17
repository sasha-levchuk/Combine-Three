#class_name Map 
extends TileMapLayer
var START: Vector2i = Vector2i(0,0)
@export var SIZE: Vector2i = Vector2i(5,2)
var tiles: Dictionary[Vector2i, Tile]
var dragged_tile: Tile
var where_from: Vector2i
var matches: Array[Vector2i]
var tiles_left_to_respawn: int
var deferred_queue: Array[Callable]
@onready var tilesize := tile_set.tile_size
signal tiles_respawned


func _ready():
	populate_grid()


func reset_grid():
	for coord in tiles:
		set_cell(coord, -1)
	tiles.clear()
	populate_grid()


func populate_grid():
	for x in SIZE.x:
		for y in SIZE.y:
			spawn_tile( Vector2i(x,y) )
	update_internals()


func spawn_tile( coord: Vector2i, type := randi()%Tile.TYPES.keys().size() ):
	set_cell( coord, 0, Vector2i.ZERO, type )


func _on_tile_spawned(tile: Tile):
	var coord = local_to_map( tile.position )
	tiles[coord] = tile
	tile.drag_started.connect( _on_tile_drag_started )
	tile.drag_ended.connect( _on_tile_drag_ended )
	tile.name = str(coord)
	tile.set_label(str(coord))
	prints('tile', tile.name, 'has been spawned at', coord)
	if not tiles_left_to_respawn:
		tiles_left_to_respawn -= 1
		tiles_respawned.emit()


func _on_tile_drag_started( tile: Tile ):
	dragged_tile = tile
	where_from = local_to_map( tile.position )
	prints('started dragging', tile)


func _on_tile_drag_ended(direction: Vector2i):
	var where_to := where_from + direction
	if not is_valid( where_to ):
		return dragged_tile.move(where_from)
	swap(where_from, where_to)
	#await get_tree().create_timer(.1).timeout
	#collect_matches()
	#if not matches:
		#return swap( where_to, where_from )


func is_valid(v: Vector2i) -> bool:
	return START.x<=v.x and v.x<SIZE.x and START.y<=v.y and v.y<SIZE.y


func clear_matches():
	matches.clear()
	for row in SIZE.y:
		check_matches_in_row(row)
	for coord in matches:
		#set_cell(coord)
		tiles[coord].queue_free()
		tiles[coord]=null


func check_matches_in_row(row: int):
	var prev_type := -1
	var streak := 1
	for x in SIZE.x:
		var coord := Vector2i(x,row)
		var type := tiles[coord].type
		if type==prev_type:
			streak += 1
			if streak > 2:
				if streak == 3:
					matches.append(coord+Vector2i.LEFT*2)
					matches.append(coord+Vector2i.LEFT)
				matches.append(coord)
		else:
			streak = 1
			prev_type = type


func swipe_down():
	var rebuilt_tiles: Dictionary[Vector2i,Tile]
	for coord in tiles:
		var offset := Vector2i.ZERO
		for hole in matches:
			if hole.x == coord.x and hole.y > coord.y:
				offset += Vector2i.DOWN
		if offset:
			rebuilt_tiles[coord+offset] = tiles[coord].move(coord+offset)
	tiles = rebuilt_tiles


func respawn():
	for coord in matches:
		spawn_tile(Vector2i(coord.x, -1-coord.y))
	tiles_left_to_respawn = matches.size()
	await tiles_respawned
	swipe_down()


func swap( origin: Vector2i, destination: Vector2i ) -> Signal:
	move(destination, origin)
	tiles[destination] = dragged_tile.move(destination)
	return dragged_tile.animation_ended


func fall_down(v: Vector2i):
	prints('tile', v, 'was moved down')
	move(v, v + Vector2i.DOWN)


func move(origin: Vector2i, destination: Vector2i):
	tiles[destination] = tiles[origin].move(destination)


func update_labels():
	for v in tiles:
		tiles[v].set_label(str(v))


func print_state():
	print(' ')
	print('grid state:')
	for y in SIZE.y:
		var s := ''
		for x in SIZE.x:
			var v := Vector2i(x,y)
			if tiles.has(v):
				s += 'G' if tiles[v].type else 'R'
			else:
				s += '-'
		print(s)
