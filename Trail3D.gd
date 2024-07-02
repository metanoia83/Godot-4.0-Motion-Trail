@tool
class_name Trail3D extends MeshInstance3D

enum InterpolationMode {
	LINEAR,
	SQUARE,
	CUBE,
	QUAD
}
enum InterpolationDirection {
	FORWARD,
	BACKWARD
}

var points: Array[Vector3]  = []
var widths: Array  = []
var lifePoints: Array[float] = []

@export var trailEnabled: bool = true

@export var fromWidth: float = 0.5
@export var toWidth: float = 0.0
@export_range(0.5, 1.5) var scaleAcceleration: float  = 1.0

@export var motionDelta: float = 0.1
@export var lifespan: float = 1.0

@export var scaleTexture: bool = true
@export var startColor: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var endColor: Color = Color(1.0, 1.0, 1.0, 0.0)


@export var colorInterpolationMode: InterpolationMode = InterpolationMode.LINEAR
@export var interpolationDirection: InterpolationDirection = InterpolationDirection.FORWARD

var oldPos: Vector3

func _ready() -> void:
	oldPos = get_global_transform().origin
	mesh = ImmediateMesh.new()

func _process(delta: float) -> void:
	if (oldPos - get_global_transform().origin).length() > motionDelta and trailEnabled:
		appendPoint()
		oldPos = get_global_transform().origin

	var p: int = 0
	var max_points: int = points.size()
	while p < max_points:
		lifePoints[p] += delta
		if lifePoints[p] > lifespan:
			removePoint(p)
			p -= 1
			if (p < 0): p = 0

		max_points = points.size()
		p += 1

	mesh.clear_surfaces()

	if points.size() < 2:
		return

	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)

	for i in range(points.size()):
		var t: float = float(i) / (points.size() - 1.0)

		var currColor: Color = endColor

		var progress: float = t

		if interpolationDirection == InterpolationDirection.BACKWARD:
			progress = 1 - t

		if colorInterpolationMode == InterpolationMode.LINEAR:
			currColor = startColor.lerp(endColor, 1 - progress)
		elif colorInterpolationMode == InterpolationMode.SQUARE:
			currColor = startColor.lerp(endColor, 1- (progress ** 2))
		elif colorInterpolationMode == InterpolationMode.CUBE:
			currColor = startColor.lerp(endColor, 1 - pow(progress, 3))
		elif colorInterpolationMode == InterpolationMode.QUAD:
			currColor = startColor.lerp(endColor,1- pow(progress, 4))

		mesh.surface_set_color(currColor)

		var currWidth: Vector3 = widths[i][0] - pow(1-t, scaleAcceleration) * widths[i][1]

		if scaleTexture:
			var t0: float = motionDelta * i
			var t1: float = motionDelta * (i + 1)
			mesh.surface_set_uv(Vector2(t0, 0))
			mesh.surface_add_vertex(to_local(points[i] + currWidth))
			mesh.surface_set_uv(Vector2(t1, 1))
			mesh.surface_add_vertex(to_local(points[i] - currWidth))
		else:
			var t0: float = i / points.size()
			var t1: float = t

			mesh.surface_set_uv(Vector2(t0, 0))
			mesh.surface_add_vertex(to_local(points[i] + currWidth))
			mesh.surface_set_uv(Vector2(t1, 1))
			mesh.surface_add_vertex(to_local(points[i] - currWidth))
	mesh.surface_end()

func appendPoint() -> void:
	var direction: Vector3 = get_global_transform().origin - oldPos
	direction = direction.normalized()
	rotation.y = atan2(direction.x, direction.z)

	points.append(get_global_transform().origin)
	widths.append([
		get_global_transform().basis.x * fromWidth,
		get_global_transform().basis.x * fromWidth - get_global_transform().basis.x * toWidth
	])
	lifePoints.append(0.0)

func removePoint(i: int) -> void:
	points.remove_at(i)
	widths.remove_at(i)
	lifePoints.remove_at(i)
