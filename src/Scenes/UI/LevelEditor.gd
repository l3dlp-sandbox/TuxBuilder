extends Node2D

const CAMERA_MOVE_SPEED = 32
var category_selected = "Tiles"
var tilemap_selected = "TileMap"
var tile_type = 0
var tile_selected = Vector2(0,0)
var old_tile_selected = Vector2(0,0)
var object_category = "BadGuys"
var object_type = "Snowball"
var mouse_down = false
var anim_in = false

var layer_types = [] # All layer types (Gets from layer folder)

func _ready():
	anim_in = get_tree().current_scene.editmode
	visible = false
	$UI.offset = Vector2(get_viewport().size.x * 9999,get_viewport().size.y * 9999)
	$UI/SideBar/VBoxContainer/TilesButton.grab_focus()
	update_tiles()
	update_layers()

func _process(_delta):
	$UI/SideBar/VBoxContainer/TilesButton.text = ""
	$UI/SideBar/VBoxContainer/ObjectsButton.text = ""
	$Grid.rect_size = Vector2(get_viewport().size.x + 32, get_viewport().size.y + 32)
	$Grid.rect_position = Vector2(get_tree().current_scene.get_node("Camera2D").position.x - (get_viewport().size.x / 2), get_tree().current_scene.get_node("Camera2D").position.y - (get_viewport().size.y / 2))
	$Grid.rect_position = Vector2(floor($Grid.rect_position.x / 32) * 32, floor($Grid.rect_position.y / 32) * 32)
	
	if get_tree().current_scene.editmode == false:
		# Move out animation
		if anim_in == true:
			anim_in = false
			$UI/AnimationPlayer.play("MoveOut")
		if $UI/AnimationPlayer.current_animation != "MoveOut":
			visible = false
			$UI.offset = Vector2 (get_viewport().size.x * 9999,get_viewport().size.y * 9999)
			return
	else:
		# Move in animation
		if anim_in == false:
			anim_in = true
			$UI/AnimationPlayer.play("MoveIn")
		visible = true
		$UI.offset = Vector2(0,0)
		
	# Navigation
	if Input.is_action_pressed("ui_up"):
		get_tree().current_scene.get_node("Camera2D").position.y -= CAMERA_MOVE_SPEED
		
	if Input.is_action_pressed("ui_down"):
		get_tree().current_scene.get_node("Camera2D").position.y += CAMERA_MOVE_SPEED
		
	if Input.is_action_pressed("ui_left"):
		get_tree().current_scene.get_node("Camera2D").position.x -= CAMERA_MOVE_SPEED
		
	if Input.is_action_pressed("ui_right"):
		get_tree().current_scene.get_node("Camera2D").position.x += CAMERA_MOVE_SPEED
	
	# Scaling Bottom Bar
	$UI/BottomBar/ScrollContainer/HBoxContainer.rect_min_size.y = 64
	$UI/BottomBar/ScrollContainer.rect_size.y = 64
	if $UI/BottomBar/ScrollContainer.rect_size.y != 64:
		$UI/BottomBar/ScrollContainer/HBoxContainer.rect_min_size.y = 52
		$UI/BottomBar/ScrollContainer.rect_size.y = 64
	
	# Placing tiles / objects
	tile_selected = get_tree().current_scene.get_node(str("Level/", tilemap_selected)).world_to_map(get_global_mouse_position())
	update_selected_tile()
	if Input.is_action_pressed("click_left"):
		if get_viewport().get_mouse_position().x < get_viewport().size.x - 128 and get_viewport().get_mouse_position().y < get_viewport().size.y - 64 and (tile_selected != old_tile_selected or mouse_down == false) and $UI/AddLayer.visible == false:
			
			if category_selected == "Tiles":
				
				# Tile erasing
				if $UI/SideBar/VBoxContainer/HBoxContainer/EraserButton.pressed == true:
					get_tree().current_scene.get_node(str("Level/", tilemap_selected)).set_cellv(tile_selected, -1)
				
				# Tile placing
				else: get_tree().current_scene.get_node(str("Level/", tilemap_selected)).set_cellv(tile_selected, tile_type)
				get_tree().current_scene.get_node(str("Level/", tilemap_selected)).update_bitmask_area(tile_selected)
			
			else:
				# Object erasing
				if $UI/SideBar/VBoxContainer/HBoxContainer/EraserButton.pressed == true:
					for child in get_tree().current_scene.get_node("Level").get_children():
						if child.position == $SelectedTile.position:
							child.queue_free()
				else:
				
				# Object placing
					if $UI/SideBar/VBoxContainer/HBoxContainer/EraserButton.pressed == false:
						var object = load(str("res://Scenes/Objects/", object_category, "/", object_type, ".tscn")).instance()
						object.position = $SelectedTile.position
						get_tree().current_scene.get_node("Level").add_child(object)
						object.set_owner(get_tree().current_scene.get_node("Level"))
						object.set_name(object_type)
		
		mouse_down = true
	else: mouse_down = false
	old_tile_selected = tile_selected

func update_selected_tile():
	if not (get_viewport().get_mouse_position().x < get_viewport().size.x - 128 and get_viewport().get_mouse_position().y < get_viewport().size.y - 64) or $UI/AddLayer.visible == true:
		$EraserSprite.visible = false
		$SelectedTile.visible = false
		return
	
	$SelectedTile.position.x = (tile_selected.x + 0.5) * get_tree().current_scene.get_node(str("Level/", tilemap_selected)).cell_size.x
	$SelectedTile.position.y = (tile_selected.y + 0.5) * get_tree().current_scene.get_node(str("Level/", tilemap_selected)).cell_size.y
	$SelectedTile.offset = Vector2(0,0)
	
	if $UI/SideBar/VBoxContainer/HBoxContainer/EraserButton.pressed == true:
		$EraserSprite.visible = true
		$SelectedTile.visible = true
		$SelectedTile.texture = load("res://Sprites/Editor/EraseSelect.png")
		$SelectedTile.region_rect = Rect2(0,0,32,32)
		$SelectedTile.modulate = Color(1,1,1,1)
		$EraserSprite.position = $SelectedTile.position
	
	else:
		$EraserSprite.visible = false
		$SelectedTile.visible = true
		$SelectedTile.modulate = Color(1,1,1,0.25)
		
		if category_selected == "Tiles":
			var selected_texture = get_tree().current_scene.get_node(str("Level/", tilemap_selected)).get_tileset().tile_get_texture(tile_type)
			$SelectedTile.texture = (selected_texture)
			$SelectedTile.region_rect.position = get_tree().current_scene.get_node(str("Level/", tilemap_selected)).get_tileset().autotile_get_icon_coordinate(tile_type) * get_tree().current_scene.get_node(str("Level/", tilemap_selected)).cell_size
			$SelectedTile.region_enabled = true

		else:
			var selected_texture = load(str("res://Scenes/Objects/", object_category, "/", object_type, ".tscn")).instance().get_node("AnimatedSprite").get_sprite_frames().get_frame("default",0)
			$SelectedTile.texture = (selected_texture)
			$SelectedTile.region_enabled = false
			$SelectedTile.offset = load(str("res://Scenes/Objects/", object_category, "/", object_type, ".tscn")).instance().get_node("AnimatedSprite").offset

# Buttons
func _on_TilesButton_pressed():
	if category_selected != "Tiles":
		category_selected = "Tiles"
		for child in $UI/SideBar/Panel/ScrollContainer/SidebarList.get_children():
			child.queue_free()
		update_tiles()

func _on_ObjectsButton_pressed():
	if category_selected != "Objects":
		category_selected = "Objects"
		for child in $UI/SideBar/Panel/ScrollContainer/SidebarList.get_children():
			child.queue_free()
		update_objects()

func update_tiles():
	for child in $UI/SideBar/Panel/ScrollContainer/SidebarList.get_children():
		child.queue_free()
	# List all the tile categories and tiles inside them
	# E.g. ("Ground - Snow, Cave, Grass || Blocks - Bonus Block, Brick")
	
	# TEMPORARY TILES LIST CODE BELOW
	var child = load("res://Scenes/Editor/Category.tscn").instance()
	child.item = "Ground"
	$UI/SideBar/Panel/ScrollContainer/SidebarList.add_child(child)
	
	var child2 = load("res://Scenes/Editor/Tile.tscn").instance()
	child2.tile_type = "Snow"
	child.get_node("VBoxContainer/Content").add_child(child2)

func update_objects():
	for child in $UI/SideBar/Panel/ScrollContainer/SidebarList.get_children():
		child.queue_free()

	# List all of the folders inside the objects folder as
	# object categories and list all of the scenes
	# inside each folder as objects for that category
	
	# TEMPORARY OBJECTS LIST CODE BELOW
	var child = load("res://Scenes/Editor/Category.tscn").instance()
	child.item = "BadGuys"
	$UI/SideBar/Panel/ScrollContainer/SidebarList.add_child(child)
	
	var child2 = load("res://Scenes/Editor/Object.tscn").instance()
	child2.object_category = "BadGuys"
	child2.object_type = "Snowball"
	child.get_node("VBoxContainer/Content").add_child(child2)

func _on_LayerAdd_button_down():
	$UI/AddLayer/VBoxContainer/OptionButton.clear()
	# Add all filenames from the layers folder into an
	# array, then add all the array items into the
	# OptionsButton.
	
	# TEMPORARY LAYERS LIST CODE BELOW
	var layers = ["TileMap", "Background"]
	for i in layers.size():
		$UI/AddLayer/VBoxContainer/OptionButton.add_item(layers[i])
	
	$UI/AddLayer.popup()

func _on_AddLayer_popup_hide():
	$UI/BottomBar/LayerAdd.pressed = false

func _on_LayerConfirmation_pressed():
	$UI/AddLayer.hide()
	var selected = $UI/AddLayer/VBoxContainer/OptionButton.get_item_text($UI/AddLayer/VBoxContainer/OptionButton.selected)
	var layer = load(str("res://Scenes/Editor/Layers/", selected, ".tscn")).instance()
	layer.z_index = $UI/AddLayer/VBoxContainer/SpinBox.value
	get_tree().current_scene.get_node("Level").add_child(layer)
	layer.set_owner(get_tree().current_scene.get_node("Level"))
	layer.set_name(selected)
	
	update_layers()

func update_layers(): # Updates the list of layers at the bottom
	for child in $UI/BottomBar/ScrollContainer/HBoxContainer.get_children():
		child.queue_free()
	for child in get_tree().current_scene.get_node("Level").get_children():
		if child.is_in_group("layer"):
			var layer = load("res://Scenes/Editor/Layer.tscn").instance()
			layer.type = child.get_class()
			layer.layername = child.get_name()
			layer.z_axis = child.z_index
			$UI/BottomBar/ScrollContainer/HBoxContainer.add_child(layer)