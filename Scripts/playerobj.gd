extends CharacterBody3D

# Player Stuff IDK

@onready var head = $nek/head
@onready var standingShape = $standingShape
@onready var crouchingShape = $crouchingShape
@onready var upCast = $RayCast3D
@onready var nek = $nek
@onready var eyes = $nek/head/eyes
@onready var mainCamera = $nek/head/eyes/MainCamera

# Speed Vars

var currentSpeed = 5.0
@export var jumpVelocity = 4.5
@export var walkingSpeed = 5.0
@export var sprintingSpeed = 8.0
@export var crouchingSpeed = 3.0

@export var lerpSpeed = 10.0

@export var freeLookTiltAmount = 8

@export var inSpeedDivide = 8

# States

var walking = false
var sprinting = false
var crouching = false
var freeLooking = false
var sliding = false

# Slide Vars

var slideTimer = 0.0
@export var slideTimerMax = 1.0
@export var slideSpeed = 10.0
var slideVector = Vector2.ZERO

# Head Bobing Vars

@export var headBobingSprint = 22.0
@export var headBobingWalk = 14.0
@export var headBobingCrouch = 10.0

@export var headBobIntensityCrouching = 0.05
@export var headBobIntensityWalking = 0.1
@export var headBobIntensitySprint = 0.2

var headBobbingVector = Vector2.ZERO
var headBobbingIntensity
var headBobbingIndex = 0.0

# Lone Crouching Var

var crouchingDepth = 0.5

# Camera

@export var mouseSens = 0.25

var direction = Vector3.ZERO

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var tiltFlSl = 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _input(event):
	# Mouse Movement Logic
	if event is InputEventMouseMotion:
		if freeLooking:
			nek.rotate_y(-deg_to_rad(event.relative.x * mouseSens))
			nek.rotation.y = clamp(nek.rotation.y, deg_to_rad(-120), deg_to_rad(120))
		else: 
			rotate_y(-deg_to_rad(event.relative.x * mouseSens))
		head.rotate_x(-deg_to_rad(event.relative.y * mouseSens))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	
func _physics_process(delta):
	# Getting Movement Vector
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	
	# Handle Movement States (pls maintainers switch to state machine)
	
	if Input.is_action_just_pressed("crouch") && sliding:
		sliding = false
	
	if Input.is_action_pressed("crouch") || sliding:
		# Crouching
		currentSpeed = crouchingSpeed
		
		head.position.y = lerp(head.position.y, 0.0 - crouchingDepth, delta*lerpSpeed)
		
		crouchingShape.disabled = false
		standingShape.disabled = true
		
		# Slide Begin Logic
		
		if sprinting && input_dir != Vector2.ZERO && is_on_floor():
			sliding = true
			slideTimer = slideTimerMax
			slideVector = input_dir
		
		walking = false
		sprinting = false
		crouching = true
	elif !upCast.is_colliding():
		walking = false
		sprinting = false
		crouching = false
		crouchingShape.disabled = true
		standingShape.disabled = false
		
		head.position.y = lerp(head.position.y, 0.0, delta*lerpSpeed)
		
		if Input.is_action_pressed("sprint"):
			# Sprinting
			currentSpeed = sprintingSpeed
			walking = false
			sprinting = true
		else:
			# Walking
			walking = true
			sprinting = false
			currentSpeed = walkingSpeed
	else:
		head.position.y = lerp(head.position.y, 0.0 - crouchingDepth, delta*lerpSpeed)
		
	# Handle Free Looking
	
	if Input.is_action_pressed("freeLook") && !sliding:
		freeLooking = true
		mainCamera.rotation.z = deg_to_rad(nek.rotation.y*freeLookTiltAmount)
	else:
		if !sliding:
			freeLooking = false
			nek.rotation.y = lerp(nek.rotation.y, 0.0, lerpSpeed*delta)
			tiltFlSl = 0.0
			mainCamera.rotation.z = lerp(mainCamera.rotation.z, 0.0, lerpSpeed*delta)
		else:
			freeLooking = true
			tiltFlSl = lerp(tiltFlSl, -10.0, lerpSpeed*delta)
			mainCamera.rotation.z = deg_to_rad(nek.rotation.y*freeLookTiltAmount + tiltFlSl)
	# Handle sliding
	
	if sliding:
		slideTimer -= delta
		if slideTimer <= 0:
			sliding = false
			
	# Handle HeadBob
	if sprinting:
		headBobbingIntensity = headBobIntensitySprint
		headBobbingIndex += headBobingSprint*delta
	elif walking:
		headBobbingIntensity = headBobIntensityWalking
		headBobbingIndex += headBobingWalk*delta
	elif crouching: 
		headBobbingIntensity = headBobIntensityCrouching 
		headBobbingIndex += headBobingCrouch*delta
	
	if is_on_floor() && !sliding && input_dir != Vector2.ZERO:
		headBobbingVector.y = sin(headBobbingIndex)
		headBobbingVector.x = sin(headBobbingIndex/2)+0.5
		
		eyes.position.y = lerp(eyes.position.y, headBobbingVector.y * (headBobbingIntensity/2), lerpSpeed*delta)
		eyes.position.x = lerp(eyes.position.x, headBobbingVector.x * headBobbingIntensity, lerpSpeed*delta)
	else:
		eyes.position.y = lerp(eyes.position.y, 0.0, lerpSpeed*delta)
		eyes.position.x = lerp(eyes.position.x, 0.0, lerpSpeed*delta)
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump"):
		if !sliding and is_on_floor():
			velocity.y = jumpVelocity
		sliding = false


	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	
	direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta*lerpSpeed/inSpeedDivide)
	
	if is_on_floor():
		direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta*lerpSpeed)
	
	if sliding:
		direction = (transform.basis * Vector3(slideVector.x, 0, slideVector.y)).normalized()
	
	if direction:
		velocity.x = direction.x * currentSpeed
		velocity.z = direction.z * currentSpeed
		
		if sliding:
			velocity.x = direction.x * (slideTimer + 0.1) * slideSpeed
			velocity.z = direction.z * (slideTimer + 0.1) * slideSpeed
	else:
		velocity.x = move_toward(velocity.x, 0, currentSpeed)
		velocity.z = move_toward(velocity.z, 0, currentSpeed)

	move_and_slide()
