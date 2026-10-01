extends RefCounted
## Translate Android cutout/navigation insets to Godot's stretched logical canvas.
static func insets(screen: Vector2i, safe: Rect2i, logical: Vector2) -> Dictionary:
	var result := {"left":0,"top":0,"right":0,"bottom":0}
	if screen.x<=0 or screen.y<=0 or not safe.has_area(): return result
	var bounds := safe.intersection(Rect2i(Vector2i.ZERO,screen))
	if not bounds.has_area(): return result
	var scale := logical/Vector2(screen)
	result.left=ceili(maxi(0,bounds.position.x)*scale.x)
	result.top=ceili(maxi(0,bounds.position.y)*scale.y)
	result.right=ceili(maxi(0,screen.x-bounds.end.x)*scale.x)
	result.bottom=ceili(maxi(0,screen.y-bounds.end.y)*scale.y)
	return result
