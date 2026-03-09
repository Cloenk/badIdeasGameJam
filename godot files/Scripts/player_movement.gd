extends CharacterBody2D

#Variables for player horizontal movement
@export var speed = 0;
@export var max_speed = 400
@export var acceleration = 0.6;
@export var break_speed = 0.8;
@export var turn_speed = 1.6;

#Variables for player vertical movement
@export var in_climbable_area = false;
@export var is_climbing = false;
@export var climbing_speed = 100;
@export var max_climbing_speed = 100;

func set_horizontal_speed(delta,input) -> void:
	#get player input direction
	var input_direction = input
	var speed_dir = 0
	#Player is pressing a key
	if(input_direction[0]!=0):
		#Player is moving and accelerating
		if input_direction[0]*speed > 0:
			if input_direction[0]*speed < max_speed:
				speed += delta*acceleration*(max_speed-(max_speed/(speed*speed+1)))*input_direction[0]
		#Player is moving and turning around
		elif input_direction[0]*speed < 0:
			if(input_direction[0]*speed < -1):
				speed -= delta*(turn_speed)*((max_speed/(speed*speed+1))-max_speed)*input_direction[0]
			else:
				speed = 0
		else:
			#Player begins movement from no speed
			speed = input_direction[0]*10
	#No player input
	else:
		#Get movement player direction
		if speed < 0:
			speed_dir = -1
		elif speed > 0:
			speed_dir = 1
		else:
			speed_dir = 0
		#Slow player speed based on current movement direction
		speed += delta*break_speed*((max_speed/(speed*speed+1))-max_speed) * speed_dir
		#Player is stopped
		if speed*speed_dir < 10:
			speed = 0
	#Set player velocity for move_and_slide()
	velocity = Vector2(1,0) * speed

func set_climbing_speed(input) -> void:
	speed = max_climbing_speed * input[0]
	climbing_speed = max_climbing_speed * input[1]
	velocity =  Vector2(speed,climbing_speed)
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	is_climbing = false
	in_climbable_area = false
	pass # Replace with function body.
	
func _physics_process(delta: float) -> void:
	var input = Input.get_vector(&"player_left", &"player_right", &"player_up", &"player_down")
	if in_climbable_area:
		print(input[1])
		if Input.is_action_pressed(&"player_up") or Input.is_action_pressed(&"player_down") : 
			is_climbing = true
			print('climbing')
	if is_climbing:
		set_climbing_speed(input)
	else:
		set_horizontal_speed(delta,input)
	move_and_slide();
 
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_climbable_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	if body == self:
		in_climbable_area = true
		print('climbable')
	pass # Replace with function body.


func _on_climbable_body_shape_exited(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	if body == self:
		is_climbing = false
		in_climbable_area = false
		print('not climbing')
	pass # Replace with function body.
