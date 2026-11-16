extends Node

## Служебная сцена: делает набор скриншотов всех макетов приложений.
## Запуск:
##   godot --path . --scene res://tools/capture_apps.tscn

const APPS := ["computer", "terminal", "maps", "gallery", "notes", "recycle"]

func _ready() -> void:
	await get_tree().process_frame
	var desktop: Desktop = load("res://scenes/desktop/Desktop.tscn").instantiate()
	get_tree().root.add_child(desktop)
	await get_tree().process_frame
	await get_tree().process_frame

	for app_id in APPS:
		desktop.open_app(app_id)
		await get_tree().process_frame
		var window := desktop._find_window(app_id)
		if window:
			window.size = Vector2(minf(window.size.x, 1180.0), minf(window.size.y, 620.0))
			window.position = Vector2(
				(desktop.window_layer.size.x - window.size.x) * 0.5,
				(desktop.window_layer.size.y - window.size.y) * 0.5
			)
			desktop._bring_to_front(window)
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		_save("app_%s.png" % app_id)
		if window:
			window.close()
		await get_tree().process_frame

	var start_button: Button = desktop.get_node("Taskbar/MainMargin/MainRow/StartButton")
	start_button.emit_signal("pressed")
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	_save("start_menu.png")

	print("SCREENSHOTS: done")
	get_tree().quit()

func _save(file_name: String) -> void:
	var image := get_viewport().get_texture().get_image()
	var path := "res://docs/screenshots/%s" % file_name
	image.save_png(path)
	print("SCREENSHOT: ", path)
