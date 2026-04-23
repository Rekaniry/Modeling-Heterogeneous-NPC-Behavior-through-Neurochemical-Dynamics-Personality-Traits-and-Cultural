extends Node2D

# --- Ciclo de dia e noite ---
#@onready var light_env = $CanvasLayer/ColorRect
var total_cycle_time: float = 1200.0 # 20 minutos
var half_cycle: float = 600.0 # 10 minutos
var current_timer: float = 0.0

# --- Velocidade do tempo ---
@onready var clock_label = $CanvasLayer/ClockLabel
@onready var speed_button_left = $CanvasLayer/SpeedButton_Left
@onready var speed_button_right = $CanvasLayer/SpeedButton_Right
@onready var speed_label = $CanvasLayer/SpeedLabel
var speed_steps: Array = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
var current_speed_index: int = 0
@onready var pause_button = $CanvasLayer/PauseButton
var is_paused: bool = false
var saved_time_scale: float = 1.0

# --- Instâncias ---
@export var npc_scene: PackedScene
@export var zone_scene: PackedScene

# --- Spawn zones ---
var spawn_timer: float = 0.0
var spawn_interval: float = 2.0

var inverter: bool = true

func _ready():
	#light_env.color = Color(1.0, 1.0, 0.75, 0.1)
	
	GlobalSettings.generate_population()
	_spawn_initial_npcs()
	
	speed_button_left.pressed.connect(_on_speed_button_pressed.bind(-1))
	pause_button.pressed.connect(_on_pause_button_pressed)
	speed_button_right.pressed.connect(_on_speed_button_pressed.bind(1))
	_update_speed_ui()

func _process(delta: float):
	if Engine.time_scale == 0.0: return
	
	current_timer += delta
	spawn_timer += delta
	
	if current_timer >= total_cycle_time: # Reinicia em 20 min
		current_timer = 0.0
	
	_update_clock_ui()
	
	@warning_ignore("unused_variable")
	var was_night = GlobalSettings.is_night
	GlobalSettings.is_night = current_timer > half_cycle
	
	#if Input.is_action_pressed("Debug"):
	#	_transition_light(inverter)
	#	inverter = !inverter
	
	# Se estado mudou
	#if was_night != GlobalSettings.is_night:
	#	_transition_light(GlobalSettings.is_night)
	
	# Spawner zones
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		_spawn_random_zone()

# _ready: Spawn NPCs
func _spawn_initial_npcs():
	for dna in GlobalSettings.npc_data_list:
		var npc = npc_scene.instantiate()
		npc.dna = dna # Passa o dicionário antes do NPC entrar na árvore
		npc.position = Vector2(randf_range(100, 1800), randf_range(100, 900)) # Posição aleatória no mapa
		$NPCs.add_child(npc)

# _ready: Atualiza velocidade
func _on_speed_button_pressed(direction: int):
	if is_paused: return
	
	# Índices de speed_steps
	current_speed_index += direction
	
	# Não sai do limite da array
	current_speed_index = clamp(current_speed_index, 0, speed_steps.size() - 1)
	
	# Velocidade na Engine
	var new_speed = speed_steps[current_speed_index]
	Engine.time_scale = new_speed
	
	_update_speed_ui()

# _ready: Pausa a simulação
func _on_pause_button_pressed():
	is_paused = !is_paused
	
	if is_paused:
		saved_time_scale = Engine.time_scale
		Engine.time_scale = 0.0
		pause_button.modulate = Color.ORANGE
	else:
		Engine.time_scale = saved_time_scale
		pause_button.modulate = Color.WHITE
	
	_update_speed_ui()

# _on_speed_button_pressed: Atualiza na UI
func _update_speed_ui():
	speed_label.text = " Velocity: " + str(Engine.time_scale) + "x"

# _process: Atualiza relógio e transforma 0-1200 seg para 24h
func _update_clock_ui():
	# 24h = 1440min | 1seg = 1.2min de simulação (1440 / 1200)
	var total_sim_minutes = current_timer * 1.2
	
	# Dia começa às 06:00 360min
	var current_sim_minutes = int(total_sim_minutes + 360) % 1440
	
	@warning_ignore("integer_division")
	var hours = int(current_sim_minutes / 60)
	var minutes = int(current_sim_minutes % 60)
	
	if hours == 0 and GlobalSettings.current_hour == 23:
		GlobalSettings.current_day += 1
		print("--- INÍCIO DO DIA ", GlobalSettings.current_day, " ---")
	
	GlobalSettings.current_hour = hours
	GlobalSettings.current_minute = minutes
	
	# Formata com zeros à esquerda
	clock_label.text = "Dia %d - %02d:%02d" % [GlobalSettings.current_day, hours, minutes]
	
	if GlobalSettings.is_night: clock_label.modulate = Color.CORNFLOWER_BLUE
	else: clock_label.modulate = Color.YELLOW

# _process: Animação de mudança de coloração da tela
#func _transition_light(to_night: bool):
#	var tween = create_tween()
#	
#	if to_night:
#		tween.tween_property(light_env, "color", Color(0.15, 0.15, 0.35, 0.1), 25.0)
#	else:
#		tween.tween_property(light_env, "color", Color(1.0, 1.0, 0.75, 0.1), 25.0)

# _process: Spawnar zone
func _spawn_random_zone():
	var zone = zone_scene.instantiate()
	#var current_hour = _get_current_sim_hour()
	
	# Sorteia qual das 24 flags será ativada
	var all_flags = [
		"is_unexpected",
		"is_analytical_mode",
		"is_new_reward",
		"is_fleeting_motivation",
		"is_explorable",
		"is_persistence_focus",
		"is_wellbeing_buffer",
		"is_social_interaction",
		"is_high_stimulus",
		"is_conflict_mitigation",
		"is_quick_recovery",
		"is_vulnerable",
		"is_post_traumatic",
		"is_reactive_stress",
		"is_low_base_wellbeing",
		
		"is_uncertain",
		"is_high_risk_zone",
		"is_group_achievement",
		"is_collective_belonging",
		"is_collective_wellbeing",
		
		"is_food_source",
		"is_rest_zone",
		"is_social_hub",
		"is_safe_haven",
	]
	
	# Urna de sorteio
	var raffle_pool = []
	
	for flag in all_flags:
		var weight = 1 # Peso base para todas as zonas
		
		if flag == "is_food_source" or flag == "is_rest_zone"\
		or flag == "is_social_hub" or flag == "is_safe_haven":
			weight = 4
		
		# Aumentar chance de COMIDA (7-8h, 12-13h, 17-18h)
		#if flag == "is_food_source":
		#	if (current_hour >= 7 and current_hour < 8) or \
		#	   (current_hour >= 12 and current_hour < 13) or \
		#	   (current_hour >= 17 and current_hour < 18):
		#		weight = 15
		
		# Aumentar chance de DESCANSO (22-24h)
		#if flag == "is_rest_zone" and (current_hour >= 22 and current_hour < 24): weight = 15
		
		# Adiciona flag na urna n vezes
		for i in range(weight): raffle_pool.append(flag)
	
	# Sorteia
	var random_flag = raffle_pool[randi() % raffle_pool.size()]
	zone.set(random_flag, true)
	
	# Spawn na tela 1920x1080
	zone.position = Vector2(randf_range(90, 1830), randf_range(116, 966))
	$Stimulus_Zones.add_child(zone)

# _spawn_random_zone: Auxiliar para pegar a hora decimal (ex: 7.5 = 07:30)
#func _get_current_sim_hour() -> float:
#	var total_sim_minutes = current_timer * 1.2
#	var current_sim_minutes = (total_sim_minutes + 360) # Inicia 06:00
#	return fmod(current_sim_minutes / 60.0, 24.0)
