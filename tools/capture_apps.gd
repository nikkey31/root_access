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
		if app_id == "gallery" and window:
			var preview := window.content_container.get_child(0) as AppPreview
			var toolbar: Dictionary = preview.get("_toolbar_buttons")
			var properties: Button = toolbar.get("Свойства / Подробнее")
			if properties:
				properties.emit_signal("pressed")
				await get_tree().process_frame
				await RenderingServer.frame_post_draw
				_save("gallery_properties.png")
				var card := preview.get("_photo_info_card") as InfoCard
				card.close()
		if app_id == "maps" and window:
			var preview := window.content_container.get_child(0) as AppPreview
			var maps := preview.find_children("*", "MapPreview", true, false)
			if not maps.is_empty():
				var map := maps[0] as MapPreview
				map.marker_clicked.emit(MapPreview.MARKERS[3])
				await get_tree().process_frame
				await RenderingServer.frame_post_draw
				_save("map_card_michelle.png")
				var card := preview.get("_map_info_card") as InfoCard
				card.close()
				map.marker_clicked.emit(MapPreview.MARKERS[5])
				await get_tree().process_frame
				await RenderingServer.frame_post_draw
				_save("map_card_warehouse.png")
				card.action_button.emit_signal("pressed")
				await get_tree().process_frame
				await RenderingServer.frame_post_draw
				_save("map_card_capture.png")
				card.close()
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
