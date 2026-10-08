extends CharacterBody3D
## Pemain first-person sederhana khusus ruang ending (WASD / panah, mouse, Shift lari, Esc lepas mouse).

@export var speed: float = 3.6
@export var sprint_mult: float = 1.7
@export var mouse_sens: float = 0.0025
@export var eye_height: float = 1.6

var frozen := false
var _cam: Camera3D
var _pitch := 0.0


func _ready() -> void:
	add_to_group("player")
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.8
	cs.shape = cap
	cs.position.y = 0.9
	add_child(cs)
	_cam = Camera3D.new()
	_cam.position.y = eye_height
	_cam.fov = 75.0
	add_child(_cam)
	_cam.current = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if frozen:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sens)
		_pitch = clampf(_pitch - event.relative.y * mouse_sens, -1.45, 1.45)
		_cam.rotation.x = _pitch
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0.0
	var dir := Vector3.ZERO
	if not frozen:
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			dir.z -= 1.0
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			dir.z += 1.0
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			dir.x -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			dir.x += 1.0
	dir = (global_transform.basis * dir).normalized()
	var spd := speed * (sprint_mult if Input.is_key_pressed(KEY_SHIFT) else 1.0)
	velocity.x = dir.x * spd
	velocity.z = dir.z * spd
	move_and_slide()
