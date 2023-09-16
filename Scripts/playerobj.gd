extends CharacterBody3D

# Player Stuff IDK

@onready var head = $head
@onready var standingShape = $standingShape
@onready var crouchingShape = $crouchingShape
@onready var upCast = $RayCast3D

# Speed Vars

var currentSpeed = 5.0
@export var jumpVelocity = 4.5
@export var walkingSpeed = 5.0
@export var sprintingSpeed = 8.0
@export var crouchingSpeed = 3.0

@export var lerpSpeed = 10.0

# States

var walking = false
var sprinting = false
var crouching = false
var freeLooking = false
var sliding = false

# Lone Crouching Var

var crouchingDepth = 0.5

# Camera

@export var mouseSens = 0.25

var direction = Vector3.ZERO

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _input(event):
	# Mouse Movement Logic
	if event is InputEventMouseMotion:
		rotate_y(-deg_to_rad(event.relative.x * mouseSens))
		head.rotate_x(-deg_to_rad(event.relative.y * mouseSens))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	
func _physics_process(delta):
	
	# Handle Movement States (pls maintainers switch to state machine)
	if Input.is_action_pressed("crouch"):
		# Crouching
		currentSpeed = crouchingSpeed
		
		head.position.y = lerp(head.position.y, 1.6 - crouchingDepth, delta*lerpSpeed)
		
		crouchingShape.disabled = false
		standingShape.disabled = true
		
		walking = false
		sprinting = false
		crouching = true
	elif !upCast.is_colliding():
		walking = false
		sprinting = false
		crouching = false
		crouchingShape.disabled = true
		standingShape.disabled = false
		
		head.position.y = lerp(head.position.y, 1.6, delta*lerpSpeed)
		
		if Input.is_action_pressed("sprint"):
			# Sprinting
			currentSpeed = sprintingSpeed
		else:
			# Walking
			currentSpeed = walkingSpeed
	else:
		head.position.y = lerp(head.position.y, 1.6 - crouchingDepth, delta*lerpSpeed)
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jumpVelocity

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta*lerpSpeed)
	if direction:
		velocity.x = direction.x * currentSpeed
		velocity.z = direction.z * currentSpeed
	else:
		velocity.x = move_toward(velocity.x, 0, currentSpeed)
		velocity.z = move_toward(velocity.z, 0, currentSpeed)

	move_and_slide()
