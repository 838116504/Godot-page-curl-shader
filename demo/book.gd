extends Control

const LEFT_TOP = Vector2(-1.0, -1.0)

enum EDGE_DIR { RIGHT = 0, LEFT, TOP, BOTTOM }

export var frontPage = preload("res://f.png")
export var backPage = preload("res://h.png")
export var curlRadius = 20.0
export(EDGE_DIR) var edgeDirection = EDGE_DIR.RIGHT
export var clickEdgeWidth = 10.0

var dragStart = null
var dragEnd:Vector2
var dragLimitSegment:PoolVector2Array
var dragLimitDir = null
var curlAngle:float

func get_line():
	return $line

func _get_minimum_size():
	if frontPage:
		return frontPage.get_size()
	
	return Vector2.ZERO

func _draw():
	draw_texture(frontPage, Vector2.ZERO)
	if dragStart:
		get_line().points = [dragStart, dragEnd]
	else:
		get_line().points = []

func _ready():
	if frontPage:
		material = ShaderMaterial.new()
		material.shader = preload("res://curlPage.shader")
		material.set_shader_param("back", backPage)
		material.set_shader_param("pageSize", frontPage.get_size())

func _gui_input(p_event):
	if p_event is InputEventMouseButton:
		if p_event.button_index == BUTTON_LEFT:
			if p_event.pressed:
				if !frontPage:
					return
				var clickRect:Rect2
				match edgeDirection:
					EDGE_DIR.RIGHT:
						clickRect = Rect2(Vector2(frontPage.get_size().x - clickEdgeWidth, 0.0), Vector2(clickEdgeWidth, frontPage.get_size().y))
						dragLimitSegment = PoolVector2Array([Vector2.ZERO, Vector2(0, frontPage.get_size().y)])
						dragLimitDir = Vector2.RIGHT
						curlAngle = 180
					EDGE_DIR.LEFT:
						clickRect = Rect2(Vector2.ZERO, Vector2(clickEdgeWidth, frontPage.get_size().y))
						dragLimitSegment = PoolVector2Array([Vector2(frontPage.get_size().x, 0), frontPage.get_size()])
						dragLimitDir = Vector2.LEFT
						curlAngle = -180
					EDGE_DIR.TOP:
						clickRect = Rect2(Vector2.ZERO, Vector2(frontPage.get_size().x, clickEdgeWidth))
						dragLimitSegment = PoolVector2Array([Vector2.ZERO, Vector2(frontPage.get_size().x, 0)])
						dragLimitDir = Vector2.UP
						curlAngle = -180
					EDGE_DIR.BOTTOM:
						clickRect = Rect2(Vector2(0.0, frontPage.get_size().y - clickEdgeWidth), Vector2(frontPage.get_size().x, clickEdgeWidth))
						dragLimitSegment = PoolVector2Array([Vector2(0, frontPage.get_size().y), frontPage.get_size()])
						dragLimitDir = Vector2.DOWN
						curlAngle = 180
					_:
						return
				if !clickRect.has_point(p_event.position):
					return

				dragStart = p_event.position
				dragEnd = dragStart
			elif dragStart:
				dragStart = null
				update()

	elif p_event is InputEventMouseMotion:
		if !frontPage:
			return
		if dragStart:
			var dragVec:Vector2 = (p_event.position - dragStart).normalized()
			if dragVec.dot(dragLimitDir) > 0:
				material.set_shader_param("curlAngle", 0.0)
				return

			var maxCurl
			dragEnd = p_event.position
			var curCurl = (dragEnd - dragStart).dot(dragVec)
			maxCurl = min((dragLimitSegment[0] - dragStart).dot(dragVec), (dragLimitSegment[1] - dragStart).dot(dragVec))
			curCurl = min(curCurl, maxCurl + curlRadius)
			dragEnd = dragVec * curCurl + dragStart
			var curlPosA = dragEnd
			var curlPosB = dragEnd + dragVec.rotated(PI/2.0)
			material.set_shader_param("curlPosA", curlPosA)
			material.set_shader_param("curlPosB", curlPosB)
			material.set_shader_param("curlRadius", curlRadius)
			material.set_shader_param("curlAngle", curlAngle)
			update()






