extends Node

## Служебный скриншот: проверка того, что программный курсор попадает
## внутрь CRT-линзы и остаётся под реальной позицией мыши.

func _ready() -> void:
	await get_tree().process_frame
	var desktop: Desktop = load("res://scenes/desktop/Desktop.tscn").instantiate()
	get_tree().root.add_child(desktop)
	await get_tree().process_frame
	await get_tree().process_frame
	if desktop.thought_box:
		desktop.thought_box.clear_thoughts()
		desktop.thought_box.visible = false

	var ui_point := Vector2(980, 380)
	var screen_point := desktop.crt_ui_to_screen(ui_point)
	Input.warp_mouse(screen_point)
	var motion := InputEventMouseMotion.new()
	motion.position = screen_point
	motion.global_position = screen_point
	Input.parse_input_event(motion)

	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png("res://docs/screenshots/crt_cursor.png")
	print("SCREENSHOT: crt_cursor.png, cursor_ui=", desktop.crt_cursor.position, " mouse_screen=", screen_point)
	get_tree().quit()
