extends Node

## Служебная сцена для скриншота макета рабочего стола.
## Запуск (из корня проекта, с реальным окном):
##   godot --path . --scene res://tools/capture_desktop.tscn

func _ready() -> void:
	await get_tree().process_frame
	var desktop: Desktop = load("res://scenes/desktop/Desktop.tscn").instantiate()
	get_tree().root.add_child(desktop)
	await get_tree().process_frame
	await get_tree().process_frame
	if desktop.thought_box:
		desktop.thought_box.clear_thoughts()
		desktop.thought_box.visible = false

	desktop.open_app("computer")
	await get_tree().process_frame
	desktop.open_app("terminal")
	await get_tree().process_frame

	var layer := desktop.get_node("DesktopSurface/WindowLayer")
	var computer := layer.get_child(0) as WindowFrame
	computer.position = Vector2(126, 38)
	computer.size = Vector2(792, 526)

	var terminal := layer.get_child(1) as WindowFrame
	terminal.position = Vector2(500, 166)
	terminal.size = Vector2(704, 446)
	desktop._bring_to_front(computer)
	desktop._bring_to_front(terminal)

	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw

	var image := get_viewport().get_texture().get_image()
	image.save_png("res://docs/screenshots/desktop_mockup.png")
	print("SCREENSHOT: ", image.get_size(), " -> docs/screenshots/desktop_mockup.png")
	get_tree().quit()
