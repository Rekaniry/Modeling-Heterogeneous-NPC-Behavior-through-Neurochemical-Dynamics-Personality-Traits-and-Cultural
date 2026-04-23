extends CharacterBody2D

@onready var barra_id = $UI_Bars/ID_Plutchik
@onready var barra_vitality = $UI_Bars/Bar_Vitality
@onready var barra_NA = $UI_Bars/Bar_NA
@onready var barra_DA = $UI_Bars/Bar_DA
@onready var barra_5HT = $UI_Bars/Bar_5HT
@onready var barra_hunger = $UI_Bars/Bar_Hunger
@onready var barra_energy = $UI_Bars/Bar_Energy
@onready var barra_social = $UI_Bars/Bar_Social
@onready var barra_safety = $UI_Bars/Bar_Safety
@onready var barra_vitality_label = $UI_Bars/Bar_Vitality/Label
@onready var barra_NA_label = $UI_Bars/Bar_NA/Label
@onready var barra_DA_label = $UI_Bars/Bar_DA/Label
@onready var barra_5HT_label = $UI_Bars/Bar_5HT/Label
@onready var barra_hunger_label = $UI_Bars/Bar_Hunger/Label
@onready var barra_energy_label = $UI_Bars/Bar_Energy/Label
@onready var barra_social_label = $UI_Bars/Bar_Social/Label
@onready var barra_safety_label = $UI_Bars/Bar_Safety/Label

# --- Dados do DNA injetados pelo spawner no simulation_world.tscn ---
var dna: Dictionary

# --- Homeostase inicial ---
@onready var current_DA: float = GlobalSettings.Beta_DA
@onready var current_5HT: float = GlobalSettings.Beta_5HT
@onready var current_NA: float = GlobalSettings.Beta_NA

# --- Sistema de drives ---
var needs: Dictionary = {
	"hunger": 0.56, # Necessário para atingir 0.7 às 7:00
	"energy": 1.0,
	"social": 0.0,
	"safety": 1.0
}

var hunger_stimulus: bool = false
var energy_stimulus: bool = false
var social_stimulus: bool = false
var safety_stimulus: bool = false
var hunger_fixo_reducao: float = 0.0
var social_fixo_reducao: float = 0.0
var safety_fixo_reducao: float = 0.0

var starvation_timer: float = 0.0
var exhaustion_timer: float = 0.0
const CRITICAL_THRESHOLD = 720.0 # 12 minutos reais | ~15h de simulação

# Vitalidade e morte
var vitality: float = 1.0
var is_dead: bool = false
const VITALITY_DECAY_BASE: float = 0.0001
const VITALITY_RECOVERY_RATE: float = 0.00005

# Ciclo de sono
var sleep_target_duration: float = 0.0 # Segundos reais que o NPC planeja dormir

# Pesos Biológicos Fixos (Ki)
var k_i: Dictionary = {
	"hunger": 0.1,
	"energy": 0.15,
	"social": 0.05,
	"safety": 0.2
}

var health_euphoria: float = 0.0

# Penalidade de frustração
var fail_count: int = 0
var last_frustration_time: float = 0.0
var frustration_cooldown: float = 30.0
var last_achievement_time: float = 0.0
var achievement_cooldown: float = 20.0

# --- Impacto no drive ---
# Inicializado com 0.5 (idle)
var drive_weight_DA: float = 0.0
var drive_weight_NA: float = 0.0
var drive_weight_5HT: float = 0.0

var current_dominant_drive: String = ""
var nearby_npcs_count: int = 0

# --- Interruptores das zonas ativas ---
var active_zones: Array = []

# --- Movimentação ---
var target_zone: Area2D = null
var speed: float = 75.0
var wander_direction: Vector2 = Vector2.ZERO
@onready var _animated_sprite = $AnimatedSprite2D

# --- Memória espacial ---
var visited_sectors: Dictionary = {} # Guarda IDs dos setores conhecidos
var current_exploration_zone_id: int = -1
const GRID_COLS: int = 5
const GRID_ROWS: int = 4

# --- Fatores Moduladores ---
# Tabela 5
var m_l1_a_NA: float = 0.0; var m_l1_b_DA: float = 0.0; var m_l1_a_5HT: float = 0.0
var m_l2_b_NA: float = 0.0; var m_l2_a_DA: float = 0.0; var m_l2_a_5HT: float = 0.0
var m_l3_g_NA: float = 0.0; var m_l3_b_DA: float = 0.0; var m_l3_b_5HT: float = 0.0
var m_l4_b_NA: float = 0.0; var m_l4_g_DA: float = 0.0; var m_l4_a_5HT: float = 0.0
var m_l5_b_NA: float = 0.0; var m_l5_a_DA: float = 0.0; var m_l5_a_5HT: float = 0.0
var m_l6_b_NA: float = 0.0; var m_l6_a_DA: float = 0.0; var m_l6_g_5HT: float = 0.0
var m_l7_g_NA: float = 0.0; var m_l7_a_NA: float = 0.0; var m_l7_g_5HT: float = 0.0; var m_l7_a_5HT: float = 0.0
var m_l8_a_NA: float = 0.0; var m_l8_a_DA: float = 0.0; var m_l8_a_5HT: float = 0.0
var m_l9_g_NA: float = 0.0; var m_l9_b_DA: float = 0.0; var m_l9_a_5HT: float = 0.0
var m_l10_a_NA: float = 0.0; var m_l10_a_DA: float = 0.0; var m_l10_a_5HT: float = 0.0; var m_l10_g_5HT: float = 0.0
var m_l11_g_NA: float = 0.0; var m_l11_b_DA: float = 0.0; var m_l11_a_5HT: float = 0.0
var m_l12_b_NA: float = 0.0; var m_l12_g_DA: float = 0.0; var m_l12_a_5HT: float = 0.0
var m_l13_g_NA: float = 0.0; var m_l13_b_DA: float = 0.0; var m_l13_g_5HT: float = 0.0
var m_l14_a_NA: float = 0.0; var m_l14_g_DA: float = 0.0; var m_l14_a_5HT: float = 0.0
var m_l15_a_NA: float = 0.0; var m_l15_g_DA: float = 0.0; var m_l15_b_5HT: float = 0.0
# Tabela 6
var m_c1_b_NA: float = 0.0; var m_c1_a_5HT: float = 0.0
var m_c2_a_NA: float = 0.0; var m_c2_a_DA: float = 0.0; var m_c2_g_5HT: float = 0.0
var m_c3_a_NA: float = 0.0; var m_c3_g_NA: float = 0.0; var m_c3_a_DA: float = 0.0; var m_c3_a_5HT: float = 0.0; var m_c3_g_5HT: float = 0.0
var m_c4_a_NA: float = 0.0; var m_c4_b_NA: float = 0.0; var m_c4_g_NA: float = 0.0; var m_c4_a_DA: float = 0.0; var m_c4_b_DA: float = 0.0; var m_c4_a_5HT: float = 0.0; var m_c4_g_5HT: float = 0.0
var m_c5_a_NA: float = 0.0; var m_c5_b_NA: float = 0.0; var m_c5_g_NA: float = 0.0; var m_c5_a_DA: float = 0.0; var m_c5_b_DA: float = 0.0; var m_c5_a_5HT: float = 0.0; var m_c5_g_5HT: float = 0.0
# Needs
var m_safe_b_NA: float = 0.0; var m_safe_g_NA: float = 0.0; var m_safe_a_5HT: float = 0.0; var m_safe_g_5HT: float = 0.0

# --- Efeito de stimulus zone no NT ---
var current_effect_duration: float = 10.0
var is_recovering: bool = false

# --- Emoção Plutchik ---
var emotion_plutchik: String = ""

func _ready():
	add_to_group("npcs")
	
	_reset_wander_direction()
	
	$DetectionAreaStimulus.area_entered.connect(_on_area_2d_area_entered)
	$DetectionAreaStimulus.area_exited.connect(_on_area_2d_area_exited)
	$DetectionAreaNPCs.body_entered.connect(_on_detection_area_body_entered)
	$DetectionAreaNPCs.body_exited.connect(_on_detection_area_body_exited)
	
	if dna.is_empty():
		_generate_fallback_dna()

func _physics_process(delta: float):
	if Engine.time_scale == 0.0 or is_dead: return
	
	if is_nan(global_position.x) or is_inf(global_position.x) or \
	abs(global_position.x) > 3000 or abs(global_position.y) > 3000:
		_rescue_npc()
		return
	
	# Setup da movimentação e do drive
	_update_behavior_and_drive()
	
	# Movimentação
	_move_towards_target(delta)
	
	# Atualização de Sprite e posição de UI
	_update_sprite_animation()
	_adjust_ui_position()
	
	# Setup dos 24 (15 + 5 + 4) fatores moduladores
	_update_areas_modulators()
	
	# Aplicar os 4 fatores moduladores em Drive
	_update_needs(delta)
	
	# Aplicar os 20 (15 + 5) fatores moduladores em NTs
	_update_neurotransmitters(delta)
	
	# Aplica estresse biológico em caso de colapso de needs
	_check_biological_collapse(delta)
	
	# Gerenciamento de vida e morte
	_update_vitality(delta)
	
	# Atualização de valores de UI
	_update_ui()
	
	# Roda de emoções de Plutchik
	_update_plutchik_emotion()

# _ready: Inicializar direção aleatoriamente
func _reset_wander_direction():
	wander_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()

# _ready: Caso NPC seja criado sem DNA cria-se um padrão neutro
func _generate_fallback_dna():
	dna = { "Mod_Openness": 0.5, 
			"Mod_Conscientiousness": 0.5, 
			"Mod_Extraversion": 0.5, 
			"Mod_Agreeableness": 0.5, 
			"Mod_Neuroticism": 0.5, 
			"Mod_UAI": 0.5, 
			"Mod_COL": 0.5 
	}

# _physics_process: # NPC lançado para o infinito por conta de bug de colisão em time scale muito alto
func _rescue_npc():
	# Reposiciona na mesma área do spawn inicial
	global_position = Vector2(randf_range(100, 1800), randf_range(100, 900))
	
	# Precisa zerar a velocidade para o motor de física não tentar corrigir a posição nova com a força acumulada
	if self is CharacterBody2D: velocity = Vector2.ZERO
	
	print("Correção Física: NPC ", name, " resgatado do vazio e reposicionado.")

# _physics_process: Controlar movimentação do NPC de acordo com o drive crítico
# e aplicar os pesos de drive de acordo com esse drive crítico
func _update_behavior_and_drive():
	if is_dead: return
	
	# Sempre primeiro qual é o drive mais urgente no momento
	var prioritized_drives = _get_prioritized_critical_drives()
	var top_drive = "idle"
	if not prioritized_drives.is_empty(): top_drive = prioritized_drives[0].type
	
	# Atualiza o drive dominante para fins químicos e de Log, resolvendo o 
	# problema do Excel registrar Hunger quando não é mais crítico
	current_dominant_drive = top_drive
	_apply_drive_weights(current_dominant_drive)
	
	# Se já está em uma zona ou indo para uma, não muda o alvo
	# mesmo que a química tenha mudado
	if target_zone != null or _is_any_drive_active(): return
	
	# Se está idle no comportamento, mas tem prioridades, busca nova zona
	if top_drive != "idle":
		var zones = get_tree().get_nodes_in_group("stimulus_zones")
		for drive in prioritized_drives:
			var best_zone = _find_best_zone_for_drive(zones, drive.type)
			if best_zone:
				target_zone = best_zone
				return

# _update_behavior_and_drive: Pesos diferentes para um mesmo drive
func _apply_drive_weights(dominant_type: String):
	if dominant_type == "idle": # Em homeostase: alpha * (1.0 + 0.0) -> alpha não se altera
		drive_weight_DA = 0.0;
		drive_weight_NA = 0.0;
		drive_weight_5HT = 0.0
		return
	
	var val = needs[dominant_type]
	var intensity: float = 0.0
	
	# intensity mapeia o quanto o NPC ultrapassou o threshold crítico.
	# Se ele acabou de entrar na zona crítica, intensity = 0 (usa pesos base).
	# Se ele atingiu o limite extremo da necessidade, intensity = 1 (pesos máximos).
	match dominant_type:
		"hunger": intensity = remap(val, 0.7, 1.0, 0.0, 1.0)
		"social": intensity = remap(val, 0.6, 1.0, 0.0, 1.0)
		"energy": intensity = remap(val, dna.sleep_threshold, 0.0, 0.0, 1.0)
		"safety": intensity = remap(val, 0.4, 0.0, 0.0, 1.0)
	
	intensity = clamp(intensity, 0.0, 1.0)
	
	# Tabela 4 do artigo Drive Base:
	# Dominant neurotransmitters associated with each NPC state.
	# 1.0 ou -1.0 representam influência total do drive no canal químico.
	# Valores intermediários (0.1 a 0.5) representam efeitos colaterais biológicos.
	match dominant_type:
		"hunger": # SeekFood -> Foco em Dopamina
			# DA: Sobe de 0.5 até 1.0 (Busca desesperada)
			drive_weight_DA = lerp(0.5, 1.0, intensity) # Era 1.0 | Prioridade máxima: incentivar o comportamento de busca.
			drive_weight_NA = lerp(0.1, 0.4, intensity) # Era 0.15 | Noradrenalina baixa: apenas um estado de alerta para encontrar comida.
			drive_weight_5HT = lerp(-0.2, -0.6, intensity) # Serotonina negativa: a fome gera um leve déficit de bem-estar/irritação.
		"safety": # TakeCover -> Foco em Noradrenalina
			# NA: Sobe de 0.5 até 1.0 (Terror/Pânico)
			drive_weight_DA = lerp(-0.3, -0.8, intensity) # Dopamina cai: em perigo, o cérebro inibe o sistema de busca por prazer/recompensa.
			drive_weight_NA = lerp(0.5, 1.0, intensity) # Era 1.0 | Prioridade máxima: alerta total e resposta ao medo/ameaça.
			drive_weight_5HT = lerp(-0.45, -0.85, intensity) # Era -0.4 -> -0.35 -> -0.45 Serotonina cai: a insegurança é o oposto do bem-estar e da calma.
		"energy": # Sleep -> Foco em Serotonina (Restaurativa)
			# 5HT: Sobe de 0.55 até 0.9 (Necessidade restaurativa máxima)
			drive_weight_DA = lerp(-0.35, -0.8, intensity) # Era -0.4 -> -0.15 -> -0.35 | Dopamina negativa: simula a letargia e a falta de motivação típica da exaustão.
			drive_weight_NA = lerp(0.1, 0.5, intensity) # Era 0.2 | Noradrenalina leve: representa a irritabilidade ou "stress" físico causado pelo sono privado.
			drive_weight_5HT = lerp(0.55, 0.9, intensity) # Era 0.9 -> 0.45 -> 0.55 | Valor alto: o sono é o principal restaurador do equilíbrio químico (5-HT).
		"social": # Socialize -> Mix de DA e 5-HT
			# DA e 5HT escalam juntos (Solidão profunda)
			drive_weight_DA = lerp(0.35, 0.8, intensity) # Era 0.7 | Valor alto: a interação social é uma recompensa primária para o cérebro.
			drive_weight_NA = lerp(-0.25, 0.4, intensity) # Noradrenalina negativa: o suporte social atua como um buffer que reduz o estresse.
			drive_weight_5HT = lerp(0.35, 0.7, intensity) # Era 0.5 -> 0.25 -> 0.35 | Valor moderado: o vínculo social promove estabilidade emocional e bem-estar.
			# Se a solidão for extrema, o 5HT não apenas para de subir, ele é sugado para o fundo.
			if intensity > 0.9: drive_weight_5HT = -0.8 # Inversão dramática: a solidão do isolamento vira depressão reativa

# _update_behavior_and_drive: Verifica se o NPC está atualmente saciando algo
func _is_any_drive_active() -> bool:
	return hunger_stimulus or energy_stimulus or social_stimulus or safety_stimulus

# _update_behavior_and_drive: Retorna lista de drives críticos ordenados
func _get_prioritized_critical_drives() -> Array:
	var criticals = []
	for need in needs.keys():
		var val = needs[need]
		var is_critical = false
		
		# Inversão para drives que crescem para baixo (Segurança e Energia)
		var hull_need_val = val
		if (need == "safety") or (need == "energy"):
			hull_need_val = 1.0 - val
		
		# Thresholds da Tabela 3
		match need:
			"hunger": is_critical = (val > 0.7)
			"social": is_critical = (val > 0.6)
			"energy": is_critical = (val < dna.sleep_threshold)
			"safety": is_critical = (val < 0.4)
			
		if is_critical:
			# Cálculo de Hull: Drive = Ki + Necessidade
			var drive_val = k_i[need] + hull_need_val
			criticals.append({"type": need, "value": drive_val})
	
	criticals.sort_custom(func(a, b): return a.value > b.value)
	return criticals

# _update_behavior_and_drive: Busca a zona mais próxima que tenha vaga
func _find_best_zone_for_drive(zones_list: Array, drive_type: String) -> Area2D:
	var min_dist = INF
	var selected_zone = null
	
	for zone in zones_list:
		if _zone_matches_specific_drive(zone, drive_type):
			if zone.current_occupants.size() < zone.max_occupants:
				var dist = global_position.distance_to(zone.global_position)
				if dist < min_dist:
					min_dist = dist
					selected_zone = zone
	return selected_zone

# _find_best_zone_for_drive: Se zona chamada corresponde ao que o NPC precisa
func _zone_matches_specific_drive(zone: Area2D, drive_type: String) -> bool:
	if not is_instance_valid(zone): return false
	match drive_type:
		"hunger": return zone.is_food_source
		"energy": return zone.is_rest_zone
		"social": return zone.is_social_hub
		"safety": return zone.is_safe_haven
	return false

# _physics_process: Mover NPC até o target de need mais próximo encontrado
func _move_towards_target(_delta):
	var sensor_pos = $DetectionAreaStimulus/CollisionShape2D.global_position
	
	var combined_direction = Vector2.ZERO
	var is_physically_occupied = false
	
	# Se tem alguma área de zona detectada vai tentar se aproximar do centro e
	# se não conseguir estressa o NPC e esquece a área
	for zone in active_zones:
		if not is_instance_valid(zone): continue
		
		if zone.current_occupants.has(self):
			is_physically_occupied = true
			var dist_to_center = sensor_pos.distance_to(zone.global_position)
			
			# Se ainda não está no centro exato, contribui para o vetor de atração
			if dist_to_center > 5: # Margem pequena para evitar trepidação
				combined_direction += sensor_pos.direction_to(zone.global_position)
		else:
			active_zones.erase(zone)
			_apply_frustration_penalty()
	
	# Se não esqueceu a área então vai se aproximar do centro de forma mais lenta e
	# se encostar em outro NPC para de andar
	if is_physically_occupied:
		if combined_direction.length() > 0.1:
			velocity = combined_direction.normalized() * (speed * 0.5) # Velocidade reduzida ao entrar na zona
			
			# Se colidir com outro NPC no caminho do centro, ele para.
			var collided_1 = move_and_slide()
			if collided_1:
				var collision = get_last_slide_collision()
				if collision.get_collider().is_in_group("npcs"):
					velocity = Vector2.ZERO
		else:
			velocity = Vector2.ZERO
			move_and_slide()
		
		return
	
	if target_zone: # Se não estiver em zonas segue o drive
		if not is_instance_valid(target_zone):
			target_zone = null
			return
		
		var dist = sensor_pos.distance_to(target_zone.global_position)
		
		if dist < 10: velocity = Vector2.ZERO
		else: velocity = sensor_pos.direction_to(target_zone.global_position) * speed
	else: # Wander
		_check_world_boundaries()
		velocity = wander_direction * speed
		
		if randf() < 0.004: # Chance de mudar de direção aleatoriamente
			_reset_wander_direction()
	
	# Executa o movimento e trata colisões com outros NPCs
	var collided_2 = move_and_slide()
	if collided_2:
		_handle_collision_avoidance()

# _move_towards_target: NPC não conseguiu acessar a zone
func _apply_frustration_penalty():
	# Limiar de paciência
	# Conscientiousness: Aumenta a persistência (quer cumprir o plano).
	# Agreeableness: Aumenta a paciência social/espera.
	# Neuroticism: Diminui a tolerância (desiste rápido por estresse).
	# UAI: Diminui a persistência (a incerteza do sucesso gera fuga).
	var patience_mod = (dna.Mod_Conscientiousness + dna.Mod_Agreeableness) - (dna.Mod_Neuroticism + dna.Mod_UAI)
	# Mapear o limiar entre 1 (muito impaciente) e 6 (muito persistente)
	# Valor base central flutua em torno de 3.5
	var patience_threshold = clamp(3.5 + (patience_mod * 2.5), 1.0, 6.0)
	
	fail_count += 1
	
	# Não atingiu o limite de paciência do seu DNA, ele tenta outro alvo sem se frustrar quimicamente
	if fail_count < patience_threshold:
		cancel_target()
		return
	
	# Verifica o Cooldown (em segundos)
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_frustration_time < frustration_cooldown:
		cancel_target()
		return
	
	# Se passou pelos filtros, aplica a penalidade
	last_frustration_time = current_time
	fail_count = 0
	
	# Neuroticism: Amplifica a reatividade emocional negativa.
	# Agreeableness (Inverso): NPCs menos amáveis são mais propensos a irritação externa.
	# Conscientiousness (Inverso): NPCs focados em metas sentem mais o impacto do "erro" no plano.
	# UAI: A incerteza de não conseguir o que precisa gera um alerta basal maior.
	var personality_impact = (1.0 + dna.Mod_Neuroticism + dna.Mod_UAI) - (dna.Mod_Agreeableness + dna.Mod_Conscientiousness)
	
	# Resilience (Inverso de N): Define quão rápido o bem-estar (5HT) é drenado pelo desânimo.
	var resilience_impact = (1.0 - dna.Mod_Neuroticism)
	
	# Aumento de NA (Ansiedade) | diminuição de DA (Desmotivação) diminuição de 5HT por (Desânimo)
	var na_fixo_pen = 0.015 * personality_impact
	var da_fixo_pen = 0.01 * personality_impact
	var h5_fixo_pen = 0.008 * (1.0 / max(resilience_impact, 0.1))
	
	current_NA = clamp(current_NA + na_fixo_pen, 0.0, 1.0)
	current_DA = clamp(current_DA - da_fixo_pen, 0.0, 1.0)
	current_5HT = clamp(current_5HT - h5_fixo_pen, 0.0, 1.0)
	
	cancel_target()

# Chamada fora de ordem, mas botei em cima por semelhança da função acima
# _on_area_2d_area_entered: NPC conseguiu acessar a zone
func _apply_achievement_bonus():
	fail_count = 0
	
	# Também usa o cooldown para evitar que o bônus seja ativado tantas vezes
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_achievement_time < achievement_cooldown:
		return
	
	# Atualizamos o tempo para o próximo bônus
	last_achievement_time = current_time
	
	# Agreeableness: NPCs amáveis sentem maior gratificação em atingir harmonia.
	# Extraversion: A conquista do objetivo gera uma euforia de busca satisfeita maior.
	# Neuroticism (Inverso): NPCs estáveis conseguem relaxar (baixar NA) mais profundamente após o sucesso.
	# Conscientiousness: O prazer de concluir uma tarefa/alvo é maior para perfis disciplinados.
	var achievement_impact = (1.0 + dna.Mod_Agreeableness + dna.Mod_Extraversion + dna.Mod_Conscientiousness) - dna.Mod_Neuroticism
	
	# Como é chamado com frequência, usamos valores fixos baixos na casa de 0.01 a 0.02
	var na_fixo_ach = 0.01 * achievement_impact
	var da_fixo_ach = 0.005 * achievement_impact
	var h5_fixo_ach = 0.01 * achievement_impact
	
	current_NA = clamp(current_NA - na_fixo_ach, 0.0, 1.0)
	current_DA = clamp(current_DA + da_fixo_ach, 0.0, 1.0)
	current_5HT = clamp(current_5HT + h5_fixo_ach, 0.0, 1.0)

# _apply_frustration_penalty: NPC desiste da zone
# stimulus_zone.gd -> _eject_disappointed_npcs: NPC desiste da zone sem frustração
func cancel_target():
	target_zone = null
	_reset_wander_direction()

# _move_towards_target: Verificar até onde pode andar
func _check_world_boundaries():
	var bounds = GlobalSettings.world_boundary
	
	# Se ultrapassar a direita ou esquerda
	if global_position.x < bounds.position.x + 25 or global_position.x > bounds.size.x - 35:
		wander_direction.x *= -1
		_force_inside_bounds()
		
	# Se ultrapassar em cima ou embaixo
	if global_position.y < bounds.position.y + 35 or global_position.y > bounds.size.y - 110:
		wander_direction.y *= -1
		_force_inside_bounds()

# _check_world_boundaries: Garante que não fique preso na borda
func _force_inside_bounds():
	var bounds = GlobalSettings.world_boundary
	global_position.x = clamp(global_position.x, 10, bounds.size.x - 10)
	global_position.y = clamp(global_position.y, 10, bounds.size.y - 10)

# _move_towards_target: Quando 2 NPCs colidem ocorre desvio
func _handle_collision_avoidance():
	var collision = get_last_slide_collision()
	if collision:
		var collider = collision.get_collider()
		
		if collider.is_in_group("npcs"):
			if target_zone: # Indo para uma zona, tenta desviar para o lado
				var avoidance_force = collision.get_normal().rotated(PI/2) * 0.3
				velocity += avoidance_force * speed
			else: # Em wander
				_reset_wander_direction()

# _physics_process: Animação do sprite enquanto anda
func _update_sprite_animation():
	if velocity.length() < 0.1:
		_animated_sprite.stop()
		return

	# Calcula o ângulo em radianos e converte para graus
	var angle = rad_to_deg(velocity.angle()) 
	
	# Mapeamento de 360 graus para as 4 animações (fatias de 90°)
	# Direita: -45 a 45 | Baixo: 45 a 135 | Esquerda: 135 a -135 | Cima: -135 a -45
	if angle >= -45 and angle <= 45:
		_animated_sprite.play("walk_right")
	elif angle > 45 and angle <= 135:
		_animated_sprite.play("walk_down")
	elif angle < -45 and angle >= -135:
		_animated_sprite.play("walk_up")
	else:
		_animated_sprite.play("walk_left")

# _physics_process: Ajustar UI_Bars se o NPC estiver muito no topo da tela
func _adjust_ui_position():
	if global_position.y < 300.0: $UI_Bars.position.y = 50.0
	else: $UI_Bars.position.y = -300.0

# _physics_process: Atualizar fatores moduladores que serão usados em _update_neurotransmitters
func _update_areas_modulators():
	_reset_modulators()
	
	var max_duration = 0.0 # Tempo de maior progress de zonas
	
	for zone in active_zones:
		if not is_instance_valid(zone): continue
		
		if zone.is_unexpected:
			m_l1_a_NA = 1.8 # Era -1.5 | Aumento de Alerta/Taquicardia
			m_l1_b_DA = 0.8 # Curiosidade/Recompensa pela surpresa
			m_l1_a_5HT = -0.6 # Era -0.5 de m_l1_g_5HT | Queda leve no bem-estar pela incerteza
		if zone.is_analytical_mode:
			m_l2_b_NA = 0.65 # Era -1.2 | Foco e Atenção: Aumenta levemente o alerta mental sem causar pânico
			m_l2_a_DA = 0.5 # Era -0.6 | Motivação Cognitiva: Dopamina alta para sustentar o aprendizado e o foco
			m_l2_a_5HT = -0.4 # Era 0.5 | Fadiga Mental: O esforço intelectual reduz levemente o bem-estar (estresse de carga cognitiva)
		if zone.is_new_reward:
			m_l3_g_NA = 1.8 # Era 1.5 | Relaxamento: Aumenta a limpeza do estresse durante a conquista
			m_l3_b_DA = 1.4 # Era 6.0 -> 3.5 -> 2.0 -> 1.2 -> 1.4 de m_l3_a_DA | Pico de Prazer: Dopamina alta gera a euforia da descoberta
			m_l3_b_5HT = 1.1 # Era 1.5 -> 0.8 -> 1.1 | Satisfação: Eleva o bem-estar basal, consolidando a alegria
		if zone.is_fleeting_motivation:
			m_l4_b_NA = -0.8 # Era -1.0 | Desânimo Físico: O fim da motivação gera fadiga e baixo alerta basal (nevoeiro)
			m_l4_g_DA = 1.8 # Era 3.5 -> 2.5 | Natureza Fugaz: Aumenta a recaptação da dopamina, impedindo que o interesse se sustente
			m_l4_a_5HT = -0.5 # Era -0.6 | Queda de Resiliência: O "baque" da desmotivação reduz levemente o bem-estar basal
		if zone.is_explorable:
			var sector_id = _get_current_sector_id()
			var zone_id = zone.get_instance_id()
			
			if not visited_sectors.has(sector_id) or current_exploration_zone_id == zone_id: # Área nova: Estímulo de descoberta total
				m_l5_b_NA = 0.6 # Era -0.8 de m_l5_a_NA | Vigilância Sustentada: Eleva o alerta basal para manter o foco na busca
				m_l5_a_DA = 4.0 # Era 1.5 -> 3.0 -> 4.0 de m_l5_b_DA | Motivação de Busca: Dopamina alta impulsiona a investigação do novo
				m_l5_a_5HT = 0.6 # Estabilidade Emocional: Mantém o bem-estar para que a curiosidade vença o medo
				
				# Primeira vez que entra marca o setor e a zona
				if not visited_sectors.has(sector_id):
					visited_sectors[sector_id] = true
					current_exploration_zone_id = zone_id
			else: # Área conhecida: Estímulo de habituação (bem mais baixo)
				m_l5_b_NA = 0.1 # Era -0.1 de m_l5_a_NA | Interesse Residual: Mantém um alerta mínimo em áreas já conhecidas
				m_l5_a_DA = 0.5 # Era 0.3 de m_l5_b_DA | Habituação: Reduz a empolgação, mas mantém o engajamento básico
				m_l5_a_5HT = 0.1 # Conforto Familiar: Estabilidade leve ao transitar por áreas seguras
		if zone.is_persistence_focus:
			m_l6_b_NA = 0.6 # Era 0.5 | Atenção Sustentada: Eleva o alerta basal para manter a vigilância na tarefa longa
			m_l6_a_DA = 0.8 # Era -2.0 -> -0.7 de m_l6_g_DA | Reforço Interno: Alpha positivo sustenta a motivação para não desistir
			m_l6_g_5HT = -0.4 # Era -1.0 -> -0.5 | Resiliência: Reduz a taxa de decaimento do bem-estar, amortecendo a fadiga pelo esforço
		if zone.is_wellbeing_buffer:
			# Ignora Dopamina: O buffer é estabilidade, não prazer.
			
			# NA > 0.5 usa Gamma positivo para limpar o estresse.
			# NA < 0.5 usa Alpha positivo para tirar do nevoeiro mental.
			if current_NA > 0.5: m_l7_g_NA = 2.0 # Limpa o excesso (Alívio)
			else: m_l7_a_NA = 1.0 # Recupera a atenção (Foco)
			
			# 5HT < 0.5 usa Alpha positivo para subir o bem-estar.
			# 5HT > 0.5 usa Gamma positivo para evitar euforia instável.
			if current_5HT < 0.5: m_l7_a_5HT = 2.0 # Recupera do desânimo (Resiliência)
			else: m_l7_g_5HT = 2.0 # Estabiliza (Paz)
		if zone.is_social_interaction and zone.current_occupants.size() >= zone.min_occupants:
			social_stimulus = true
			# Polaridade Social: Transforma (0.0 a -1.0) em (-1.0 a 1.0 com 0.5 o ponto neutro)
			var social_polarity = (dna.Mod_Extraversion - 0.5) * 2.0
			
			# Bônus de multidão.
			var crowd_factor = float(zone.current_occupants.size()) / float(zone.max_occupants)
			
			# O impacto social escala com a quantidade de pessoas:
			# Extrovertidos: Ganham mais DA e 5HT em zonas cheias.
			# Introvertidos: Sofrem mais dreno de NA em zonas cheias.
			m_l8_a_NA = (-1.2 * social_polarity) * (1.0 + crowd_factor) # Era 0.8 em m_l8_g_NA | Alerta vs. Ansiedade: Extrovertido relaxa (NA cai), Introvertido estressa (NA sobe)
			m_l8_a_DA = (1.2 * social_polarity) * (1.0 + crowd_factor) # Era 1.0 | Recompensa vs. Dreno: Extrovertido ganha dopamina, Introvertido sente fadiga social
			m_l8_a_5HT = (1.5 * social_polarity) * (1.0 + crowd_factor) # Era 0.6 | # Bem-estar vs. Exposição: Extrovertido sente pertencimento, Introvertido sente desconforto
		if zone.is_high_stimulus:
			m_l9_g_NA = -1.5 # Era -1.2 em m_l9_a_NA | Imposição Externa: Força a agitação ignorando a exaustão interna
			m_l9_b_DA = 1.4 # Era 2.0 | Euforia Basal: Eleva o patamar de excitação da zona
			m_l9_a_5HT = -1.0 # Era -1.5 em m_l9_g_5HT | Desgaste Sensorial: Alpha negativo bloqueia o bem-estar, gerando irritabilidade
		if zone.is_conflict_mitigation and zone.current_occupants.size() >= zone.min_occupants:
			# Alívio de Tensão (NA alto): Reduz a irritabilidade e o alerta de luta, permitindo o diálogo
			# Desgaste ainda maior (NA baixo): Reduz a irritabilidade e o alerta de luta, permitindo o diálogo
			m_l10_a_NA = -1.5 # Era -4.0
			m_l10_a_DA = 0.3 # Era 0.8 | Motivação Cooperativa: Leve ganho motivacional para sustentar a resolução social
			
			# Lógica de eficácia baseada no alerta (Lei de Yerkes-Dodson)
			if current_NA > 0.45: # Caso Ideal: NPC focado e capaz de processar a paz
				if current_5HT < 0.5: m_l10_a_5HT = 1.0 # Recuperação total de bem-estar
				else: m_l10_g_5HT = 1.2 # Estabilização eficiente
			elif current_NA < 0.35: # Caso Nevoeiro: NPC apático/desatento, mediação pouco eficaz
				if current_5HT < 0.5: m_l10_a_5HT = 0.2 # Ganho quase irrelevante de bem-estar
				else: m_l10_g_5HT = 0.24 # Estabilização pouco eficiente
			else: # Caso Transição (0.35 - 0.45): Eficácia moderada
				if current_5HT < 0.5: m_l10_a_5HT = 0.6 # Ganho em meio termo de bem-estar
				else: m_l10_g_5HT = 0.72 # Estabilização em meio termo de eficiência
		if zone.is_quick_recovery:
			m_l11_g_NA = 3.5 # Era 2.0 | Reset de Estresse: Gamma agressivo drena o NA (alerta/ansiedade), mas se o NPC já estiver calmo, este valor pode induzir letargia ou hipotensão.
			m_l11_b_DA = 0.6 # Manter o NPC funcional após o alívio, evitando uma apatia imediata.
			m_l11_a_5HT = 1.6 # Era 1.0 -> 1.2 -> 1.6 | Pico de Alívio: Restaura a confiança e estabilidade, mas pode causar confusão mental/ruminagem se o 5HT já estiver alto.
		if zone.is_vulnerable:
			m_l12_b_NA = 1.0 # Era 3.5 -> 2.5 em m_l12_a_NA | Hipervigilância: Eleva apenas o piso de estresse/ansiedade, mantendo o alerta basal alto.
			m_l12_g_DA = 1.5 # Era -1.0 em m_l12_b_DA | Evasão de Recompensa: O medo "desliga" o sistema de busca e motivação
			m_l12_a_5HT = -1.5 # Inibição de Estabilidade: Impede que o NPC se acalme enquanto houver risco
		if zone.is_post_traumatic:
			# Inércia quase total: O NPC fica preso no estado químico em que entrou devido aos valores mínimos (0.05).
			# Gamma baixíssimo impede que o estresse limpe. 
			if current_NA > 0.5: m_l13_g_NA = 0.05
			else: m_l13_g_NA = -0.05
			
			# Gamma baixíssimo impede que o bem-estar se recupere.
			if current_5HT > 0.5: m_l13_g_5HT = 0.05
			else: m_l13_g_5HT = -0.05
			
			m_l13_b_DA = -1.2 # Apatia: Esmaga a linha de base da motivação.
		if zone.is_reactive_stress:
			m_l14_a_NA = 2.0 # Reatividade: Gera picos súbitos de estresse.
			m_l14_g_DA = 1.5 # Dreno de Esperança: Gamma alto acelera a limpeza da dopamina, impedindo motivação sustentada.
			m_l14_a_5HT = -1.0 # Sabotagem de Humor: Alpha negativo bloqueia o ganho de bem-estar, mantendo a instabilidade emocional.
		if zone.is_low_base_wellbeing:
			m_l15_a_NA = 1.2 # Irritabilidade: Facilita picos de estresse e raiva por baixa resiliência.
			m_l15_g_DA = 1.0 # Era -0.8 em m_l15_a_DA | Prazer Oco: Limpa a dopamina rapidamente, impedindo a satisfação duradoura.
			m_l15_b_5HT = -1.4 # Era -1.8 | Piso de Desânimo: Esmaga o bem-estar basal, dificultando a sensação de felicidade.
		
		if zone.is_uncertain:
			m_c1_b_NA = 1.4 # Ansiedade de Fundo: Beta robusto eleva o piso de estresse, saturando o alvo em NPCs sensíveis.
			m_c1_a_5HT = -1.2 # Insegurança Cultural: Alpha negativo bloqueia a estabilidade, impedindo a sensação de controle.
		if zone.is_high_risk_zone:
			m_c2_a_NA = 2.5 # Era 1.8 -> 1.2 em m_c2_b_NA Resposta de Choque: Reatividade a estímulo de alto risco.
			m_c2_a_DA = -1.0 # Inibição de Prazer: Impede a busca por recompensas, focando tudo na sobrevivência.
			m_c2_g_5HT = 1.2 # Desgaste de Resiliência: Acelera a perda de bem-estar devido à pressão do perigo.
		if zone.is_group_achievement and zone.current_occupants.size() >= zone.min_occupants:
			var crowd_factor = float(zone.current_occupants.size()) / float(zone.max_occupants)
			
			if dna.Mod_COL > 0.5: # Perfil Coletivista: Sucesso do grupo traz equilíbrio e recompensa.
				# Tende à homeostase de NA: O sucesso limpa o estresse ou recupera do choque/apatia.
				if current_NA > 0.5: m_c3_g_NA = 1.5 * (1.0 + crowd_factor) # Limpa o excesso de estresse competitivo.
				else: m_c3_a_NA = 1.0 * (1.0 + crowd_factor) # Recupera o alerta/engajamento se estiver apático.
				
				m_c3_a_DA = 1.5 * (1.0 + crowd_factor) # Era 4.0 -> 2.5 -> 1.5 | Sucesso Coletivo: Recompensa direta via Alpha pelo atingimento da meta.
				
				# Tende à homeostase de 5HT: Busca a plenitude estável no sentimento de pertencimento.
				if current_5HT < 0.45: m_c3_a_5HT = 1.5 * (1.0 + crowd_factor) # Recuperação firme
				elif current_5HT > 0.55: m_c3_g_5HT = 1.5 * (1.0 + crowd_factor) # Estabilização firme
				elif current_5HT >= 0.45 and current_5HT < 0.5: m_c3_a_5HT = 0.05 * (1.0 + crowd_factor) # Zona de Estabilidade: Força mínima para manter no centro sem oscilar
				else: m_c3_g_5HT = 0.05 * (1.0 + crowd_factor) # Zona de Estabilidade: Força mínima para manter no centro sem oscilar
			else: # Perfil Individualista: Sucesso do grupo gera dissonância e ressentimento.
				m_c3_a_NA = 1.5 * (1.0 + crowd_factor) # Tensão Competitiva: Gera picos de irritabilidade.
				m_c3_a_DA = -1.0 * (1.0 + crowd_factor) # Frustração: Inibe o prazer de uma conquista não-egoica.
				
				# Corrosão de 5-HT
				if current_5HT > 0.55: m_c3_g_5HT = 2.0 * (1.0 + crowd_factor) # Dreno Agressivo: A "felicidade coletiva" consome a paz do individualista.
				elif current_5HT < 0.45: m_c3_a_5HT = -1.0 * (1.0 + crowd_factor) # Barreira de Recuperação: O grupo impede que ele saia da melancolia.
				else: m_c3_g_5HT = 0.5 * (1.0 + crowd_factor) # Desgaste Lento: Mesmo estável, estar ali custa energia emocional.
		if zone.is_collective_belonging and zone.current_occupants.size() >= zone.min_occupants:
			var crowd_factor = float(zone.current_occupants.size()) / float(zone.max_occupants)
			
			if dna.Mod_COL > 0.5: # Perfil Coletivista
				m_c4_b_NA = -0.3 * (1.0 + crowd_factor) # Reduz o piso de estresse basal enquanto estiver no grupo
				# Relaxamento de NA (quanto mais estressado, mais o grupo acalma)
				if current_NA > 0.6: m_c4_g_NA = 2.0 * (1.0 + crowd_factor) # Queda acentuada para sair do estado de alerta
				elif current_NA > 0.4: m_c4_g_NA = 1.2 * (1.0 + crowd_factor) # Queda moderada para estabilização
				else: m_c4_g_NA = 0.5 * (1.0 + crowd_factor) # Quase não cai (já está relaxado)
				
				m_c4_a_DA = 0.5 * (1.0 + crowd_factor) # Motivação Social: Ganho leve/médio para sustentar a interação sem euforia.
				
				# Tendência à homeostase de 5HT (Pertencimento como âncora emocional)
				if current_5HT < 0.45: m_c4_a_5HT = 1.2 * (1.0 + crowd_factor) # Recuperação moderada
				elif current_5HT > 0.55: m_c4_g_5HT = 1.2 * (1.0 + crowd_factor) # Estabilização moderada
				elif current_5HT >= 0.45 and current_5HT < 0.5: m_c4_a_5HT = 0.05 * (1.0 + crowd_factor) # Zona de Estabilidade: Força mínima para manter no centro sem oscilar
				else: m_c4_g_5HT = 0.05 * (1.0 + crowd_factor) # Zona de Estabilidade: Força mínima para manter no centro sem oscilar
			else: # Perfil Individualista (Sensação de Invasão de Espaço)
				m_c4_a_NA = 1.2 * (1.0 + crowd_factor) # Estresse de Proximidade: Gera picos de irritabilidade por invasão.
				m_c4_b_DA = -1.0 * (1.0 + crowd_factor) # Perda de Autonomia: Reduz a linha de base motivacional (Anedonia Social).
				
				# Corrosão de 5-HT
				if current_5HT > 0.55: m_c4_g_5HT = 2.0 * (1.0 + crowd_factor) # Dreno Agressivo: A "felicidade coletiva" consome a paz do individualista.
				elif current_5HT < 0.45: m_c4_a_5HT = -1.0 * (1.0 + crowd_factor) # Barreira de Recuperação: O grupo impede que ele saia da melancolia.
				else: m_c4_g_5HT = 0.5 * (1.0 + crowd_factor) # Desgaste Lento: Mesmo estável, estar ali custa energia emocional.
		if zone.is_collective_wellbeing and zone.current_occupants.size() >= zone.min_occupants:
			var crowd_factor = float(zone.current_occupants.size()) / float(zone.max_occupants)
			
			if dna.Mod_COL > 0.5: # Perfil Coletivista
				m_c5_b_NA = -0.5 * (1.0 + crowd_factor) # Reduz o piso de estresse basal enquanto estiver no grupo
				# Relaxamento de NA (quanto mais estressado, mais o grupo acalma)
				if current_NA > 0.6: m_c5_g_NA = 2.0 * (1.0 + crowd_factor) # Queda acentuada para sair do estado de alerta
				elif current_NA > 0.4: m_c5_g_NA = 1.2 * (1.0 + crowd_factor) # Queda moderada para estabilização
				else: m_c5_g_NA = 0.5 * (1.0 + crowd_factor) # Quase não cai (já está relaxado)
				
				m_c5_a_DA = 0.2 * (1.0 + crowd_factor) # Recompensa Sutil: Apenas o prazer da presença, sem excitação.
				
				var plenitude_bonus = 1.0
				if needs.social > 0.8 and needs.energy > 0.8: plenitude_bonus = 2.0 # NPC está "aberto" para sentir o ápice do bem-estar
				
				# Tendência à homeostase de 5HT (O ápice do equilíbrio no grupo)
				if current_5HT < 0.45: m_c5_a_5HT = 2.5 * (1.0 + crowd_factor) * plenitude_bonus # Recuperação ultra-rápida de estados depressivos/irritáveis
				elif current_5HT > 0.55: m_c5_g_5HT = 2.5 * (1.0 + crowd_factor) # Estabilização agressiva de estados eufóricos/instáveis
				elif current_5HT >= 0.45 and current_5HT < 0.5: m_c5_a_5HT = 0.05 * (1.0 + crowd_factor) * plenitude_bonus # Zona de Estabilidade: Força mínima para manter no centro sem oscilar
				else: m_c5_g_5HT = 0.05 * (1.0 + crowd_factor) # Zona de Estabilidade: Força mínima para manter no centro sem oscilar
			else: # Perfil Individualista
				m_c5_a_NA = 1.0 * (1.0 + crowd_factor) # Tensão de Máscara Social: Gera alerta por cansaço de interação.
				m_c5_b_DA = -0.8 * (1.0 + crowd_factor) # Inibição Basal: Reduz a satisfação por falta de identificação.
				
				# Corrosão de 5-HT
				if current_5HT > 0.55: m_c5_g_5HT = 2.0 * (1.0 + crowd_factor) # Dreno Agressivo: A "felicidade coletiva" consome a paz do individualista.
				elif current_5HT < 0.45: m_c5_a_5HT = -1.0 * (1.0 + crowd_factor) # Barreira de Recuperação: O grupo impede que ele saia da melancolia.
				else: m_c5_g_5HT = 0.5 * (1.0 + crowd_factor) # Desgaste Lento: Mesmo estável, estar ali custa energia emocional.
		
		if zone.is_food_source: hunger_stimulus = true
		if zone.is_rest_zone: energy_stimulus = true
		if zone.is_social_hub and \
			zone.current_occupants.size() >= zone.min_occupants: social_stimulus = true
		if zone.is_safe_haven: safety_stimulus = true
		
		if zone.duration_seconds > max_duration:
			max_duration = zone.duration_seconds
	
	if active_zones.is_empty():
		is_recovering = true
	else:
		current_effect_duration = max_duration
		is_recovering = false

# _update_areas_modulators: Resetar 24 fatores moduladores
func _reset_modulators() -> void:
	m_l1_a_NA = 0.0; m_l1_b_DA = 0.0; m_l1_a_5HT = 0.0
	m_l2_b_NA = 0.0; m_l2_a_DA = 0.0; m_l2_a_5HT = 0.0
	m_l3_g_NA = 0.0; m_l3_b_DA = 0.0; m_l3_b_5HT = 0.0
	m_l4_b_NA = 0.0; m_l4_g_DA = 0.0; m_l4_a_5HT = 0.0
	m_l5_b_NA = 0.0; m_l5_a_DA = 0.0; m_l5_a_5HT = 0.0
	m_l6_b_NA = 0.0; m_l6_a_DA = 0.0; m_l6_g_5HT = 0.0
	m_l7_g_NA = 0.0; m_l7_a_NA = 0.0; m_l7_g_5HT = 0.0; m_l7_a_5HT = 0.0
	m_l8_a_NA = 0.0; m_l8_a_DA = 0.0; m_l8_a_5HT = 0.0
	m_l9_g_NA = 0.0; m_l9_b_DA = 0.0; m_l9_a_5HT = 0.0
	m_l10_a_NA = 0.0; m_l10_a_DA = 0.0; m_l10_a_5HT = 0.0; m_l10_g_5HT = 0.0
	m_l11_g_NA = 0.0; m_l11_b_DA = 0.0; m_l11_a_5HT = 0.0
	m_l12_b_NA = 0.0; m_l12_g_DA = 0.0; m_l12_a_5HT = 0.0
	m_l13_g_NA = 0.0; m_l13_b_DA = 0.0; m_l13_g_5HT = 0.0
	m_l14_a_NA = 0.0; m_l14_g_DA = 0.0; m_l14_a_5HT = 0.0
	m_l15_a_NA = 0.0; m_l15_g_DA = 0.0; m_l15_b_5HT = 0.0
	
	m_c1_b_NA = 0.0; m_c1_a_5HT = 0.0
	m_c2_a_NA = 0.0; m_c2_a_DA = 0.0; m_c2_g_5HT = 0.0
	m_c3_a_NA = 0.0; m_c3_g_NA = 0.0; m_c3_a_DA = 0.0; m_c3_a_5HT = 0.0; m_c3_g_5HT = 0.0
	m_c4_a_NA = 0.0; m_c4_b_NA = 0.0; m_c4_g_NA = 0.0; m_c4_a_DA = 0.0; m_c4_b_DA = 0.0; m_c4_a_5HT = 0.0; m_c4_g_5HT = 0.0
	m_c5_a_NA = 0.0; m_c5_b_NA = 0.0; m_c5_g_NA = 0.0; m_c5_a_DA = 0.0; m_c5_b_DA = 0.0; m_c5_a_5HT = 0.0; m_c5_g_5HT = 0.0
	
	m_safe_b_NA = 0.0; m_safe_g_NA = 0.0; m_safe_a_5HT = 0.0; m_safe_g_5HT = 0.0
	
	hunger_stimulus = false
	energy_stimulus = false
	social_stimulus = false
	safety_stimulus = false

# _physics_process: Calcular os needs
func _update_needs(delta: float):
	if is_dead: return
	
	# Ciclo de 20 min (1200s). 
	
	# FOME:
	# Chegar ao nível crítico (0.7) 3 vezes em 10 minutos (600s).
	# Sentir fome a cada 200 segundos (~3.3 min) | Taxa: 0.7 / 200s = 0.0035
	if !hunger_stimulus:
		if hunger_fixo_reducao != 0.0: hunger_fixo_reducao = 0.0
		var decay_rate = 0.0028 * dna.hunger_rate_multiplier
		if energy_stimulus: decay_rate *= 0.5 # Dormindo gasta menos fome
		needs.hunger = clamp(needs.hunger + (delta * decay_rate), 0.0, 1.0)
	elif hunger_stimulus:
		if hunger_fixo_reducao == 0.0: hunger_fixo_reducao = needs.hunger
		needs.hunger = clamp(needs.hunger - (delta * (hunger_fixo_reducao / 25)), 0.0, 1.0)
	
	# ENERGIA:
	# O NPC deve aguentar bem o dia, mas chegar à exaustão se não dormir na noite.
	if !energy_stimulus:
		if sleep_target_duration != 0.0: sleep_target_duration = 0.0
		var night_mult = 2.5 if GlobalSettings.is_night else 1.0
		needs.energy = clamp(needs.energy - (delta * 0.0008 * night_mult), 0.0, 1.0)
	elif energy_stimulus:
		# Se acabamos de entrar na zona e ainda não definimos a meta
		if sleep_target_duration == 0.0:
			var h = GlobalSettings.current_hour
			var hours_sim = 0.0
			
			if h >= 6 and h < 12: hours_sim = randf_range(2.0, 3.0) # Soneca matinal
			elif h >= 12 and h < 20: hours_sim = randf_range(1.0, 2.0) # Soneca tarde/pré-noite
			else: hours_sim = randf_range(6.0, 10.0) # Entre 20h e 6h: Sono principal
			
			sleep_target_duration = hours_sim * 50.0 # 1h simulação = 50 seg reais
			
			# Sincroniza a zona com o sono planejado do NPC
			if is_instance_valid(target_zone) and target_zone.is_rest_zone:
				target_zone.set_custom_duration(sleep_target_duration)
		
		# Recuperação constante enquanto a zona existir
		needs.energy = clamp(needs.energy + (delta * 0.0025), 0.0, 1.0)
	
	# SOCIAL:
	if !social_stimulus:
		if social_fixo_reducao != 0.0: social_fixo_reducao = 0.0
		if energy_stimulus: return
		
		var social_decay = 0.0
		var social_recovery = 0.0
		
		# O "Custo da Solidão" (Privação)
		# Quando o NPC está sozinho, a Extroversão atua como o motor de carência.
		# Quanto mais Extrovertido, mais rápido o drive de necessidade sobe.
		# NPCs Introvertidos são mais resilientes ao isolamento.
		if nearby_npcs_count == 0: social_decay = 0.008 * dna.Mod_Extraversion
		
		# O "Ganho da Interação" (Saciedade)
		# Quando em grupo, ambos os traços trabalham juntos para reduzir a carência:
		# Coletivismo sacia o drive pelo prazer do pertencimento/harmonia.
		# Extroversão sacia o drive pelo prazer do estímulo/interação ativa.
		if nearby_npcs_count > 0:
			# 4 combinações: 
			# (Ext+ COL+ = Saciedade plena)
			# (Ext+ COL- = Busca estímulo mas sem apego)
			# (Ext- COL+ = Conforto no grupo mas em silêncio)
			# (Ext- COL- = Indiferença social)
			var group_bonus = min(nearby_npcs_count * 0.2, 1.5) # Limita o bônus de multidão
			social_recovery = (0.002 * dna.Mod_COL + 0.001 * dna.Mod_Extraversion) * group_bonus
		
		# Sobe pela carência (decay) e desce pela interação (recovery)
		needs.social = clamp(needs.social + (delta * (social_decay - social_recovery)), 0.0, 1.0)
	elif social_stimulus:
		if social_fixo_reducao == 0.0: social_fixo_reducao = needs.social
		needs.social = clamp(needs.social - (delta * (social_fixo_reducao / 50)), 0.0, 1.0)
	
	# SEGURANÇA:
	# Insegurança cresce lentamente se estiver sozinho.
	if !safety_stimulus:
		if safety_fixo_reducao != 0.0: safety_fixo_reducao = 0.0
		if energy_stimulus: return
		
		if nearby_npcs_count == 0:
			# Neuroticismo e UAI como aceleradores do medo
			var insecurity_rate = 0.005 * dna.Mod_Neuroticism * (1.0 + dna.Mod_UAI)
			if GlobalSettings.is_night: insecurity_rate *= 2.0 # Acelera a queda de noite
			needs.safety = clamp(needs.safety - (delta * insecurity_rate), 0.0, 1.0)
		else:
			needs.safety = clamp(needs.safety + (delta * 0.0015), 0.0, 1.0)
	elif safety_stimulus:
		if safety_fixo_reducao == 0.0: safety_fixo_reducao = 1.0 - needs.safety
		needs.safety = clamp(needs.safety + (delta * (safety_fixo_reducao / 30)), 0.0, 1.0)
		
		# Se a segurança já está alta, o alerta (NA) pode ser desligado.
		var deep_peace_mult = 1.0
		if needs.safety > 0.9: deep_peace_mult = 3.0 # Triplica o alívio basal
		
		# Estabilização de NA e 5HT
		m_safe_b_NA = -0.3 * deep_peace_mult # Puxa o piso para baixo agressivamente
		m_safe_g_NA = 2.0 * deep_peace_mult # Limpa qualquer estresse residual rápido
		
		if current_5HT < 0.45: m_safe_a_5HT = 1.5 # Recupera da tristeza
		elif current_5HT > 0.55: m_safe_g_5HT = 1.5 # Acalma a euforia
		elif current_5HT >= 0.45 and current_5HT < 0.5: m_safe_a_5HT = 0.05 # Trava no centro (Paz)
		else: m_safe_g_5HT = 0.05 # Trava no centro (Paz)

# _update_areas_modulators: Identificar o setor quando NPC entra em zona de exploração
func _get_current_sector_id() -> int:
	# Largura e altura de cada quadrante
	var sector_w = GlobalSettings.screen_width / GRID_COLS
	var sector_h = GlobalSettings.screen_height / GRID_ROWS
	
	# Transforma a posição global em índice de coluna e linha
	var col = int(clamp(global_position.x / sector_w, 0, GRID_COLS - 1))
	var row = int(clamp(global_position.y / sector_h, 0, GRID_ROWS - 1))
	
	# Retorna um ID único para esse setor (ex: de 0 a 19)
	return row * GRID_COLS + col

# _physics_process: Calcular os NTs
func _update_neurotransmitters(delta: float):
	# L8 já foi processado com polaridade
	# C3, C4 e C5 já foram processados com dna.Mod_COL
	# Obs: Isso vale para todos os FMs
	
	# Obs: Na NA e DA Conscientiousness e Agreeableness são amortecedores, diferente de
	# Openness, Extraversion e Neuroticism que são amplificadores, por isso precisa da inversão de (1.0 - Mod)
	# Enquanto na 5HT ele sente mais bem-estar com esses valores, então o inverso se aplica para um NPC com alto
	# Neuroticism ao se tratar do 5HT dele.
	# Isso é uma ideia GERAL sobre a forma como os amortecimentos e amplificações funcionam,
	# mas existem casos específicos, nem todos abaixo isso se aplica.
	
	# NA
	var temp_alpha_NA = (m_l1_a_NA * (1.0 - dna.Mod_Openness)) + \
					(m_l7_a_NA * dna.Mod_Conscientiousness) + \
					(m_l8_a_NA) + \
					(m_l10_a_NA * dna.Mod_Agreeableness) + \
					(m_l14_a_NA * dna.Mod_Neuroticism) + \
					(m_l15_a_NA * dna.Mod_Neuroticism) + \
					(m_c2_a_NA * dna.Mod_UAI) + \
					(m_c3_a_NA) + \
					(m_c4_a_NA) + \
					(m_c5_a_NA)
	var temp_beta_NA = (m_l2_b_NA * dna.Mod_Openness) + \
					(m_l4_b_NA * (1.0 - dna.Mod_Openness)) + \
					(m_l5_b_NA * dna.Mod_Openness) + \
					(m_l6_b_NA * dna.Mod_Conscientiousness) + \
					(m_l12_b_NA * dna.Mod_Neuroticism) + \
					(m_c1_b_NA * dna.Mod_UAI) + \
					(m_safe_b_NA) + \
					(m_c4_b_NA) + \
					(m_c5_b_NA)
	var temp_gamma_NA = (m_l3_g_NA * dna.Mod_Openness) + \
					(m_l7_g_NA * dna.Mod_Conscientiousness) + \
					(m_l9_g_NA * dna.Mod_Extraversion) + \
					(m_l11_g_NA * dna.Mod_Agreeableness) + \
					(m_l13_g_NA * (1.0 - dna.Mod_Neuroticism)) + \
					(m_c3_g_NA) + \
					(m_c4_g_NA) + \
					(m_c5_g_NA) + \
					(m_safe_g_NA)
	
	# DA
	var temp_alpha_DA = (m_l2_a_DA * dna.Mod_Openness) + \
					(m_l5_a_DA * dna.Mod_Openness) + \
					(m_l6_a_DA * (1.0 - dna.Mod_Conscientiousness)) + \
					(m_l8_a_DA) + \
					(m_l10_a_DA * dna.Mod_Agreeableness) + \
					(m_c2_a_DA * dna.Mod_UAI) + \
					(m_c3_a_DA) + \
					(m_c4_a_DA) + \
					(m_c5_a_DA)
	var temp_beta_DA = (m_l1_b_DA * dna.Mod_Openness) + \
					(m_l3_b_DA * dna.Mod_Openness) + \
					(m_l9_b_DA * dna.Mod_Extraversion) + \
					(m_l11_b_DA * (1.0 - dna.Mod_Agreeableness)) + \
					(m_l13_b_DA * dna.Mod_Neuroticism) + \
					(m_c4_b_DA) + \
					(m_c5_b_DA)
	var temp_gamma_DA = (m_l4_g_DA * (1.0 - dna.Mod_Openness)) + \
					(m_l12_g_DA * dna.Mod_Neuroticism) + \
					(m_l14_g_DA * dna.Mod_Neuroticism) + \
					(m_l15_g_DA * dna.Mod_Neuroticism)
	
	# 5HT
	var temp_alpha_5HT = (m_l1_a_5HT * (1.0 - dna.Mod_Openness)) + \
					(m_l2_a_5HT * (1.0 - dna.Mod_Openness)) + \
					(m_l4_a_5HT * (1.0 - dna.Mod_Openness)) + \
					(m_l5_a_5HT * dna.Mod_Openness) + \
					(m_l7_a_5HT * dna.Mod_Conscientiousness) + \
					(m_l8_a_5HT) + \
					(m_l9_a_5HT * (1.0 - dna.Mod_Extraversion)) + \
					(m_l10_a_5HT * dna.Mod_Agreeableness) + \
					(m_l11_a_5HT * dna.Mod_Agreeableness) + \
					(m_l12_a_5HT * dna.Mod_Neuroticism) + \
					(m_l14_a_5HT * dna.Mod_Neuroticism) + \
					(m_c1_a_5HT * dna.Mod_UAI) + \
					(m_c3_a_5HT) + \
					(m_c4_a_5HT) + \
					(m_c5_a_5HT) + \
					(m_safe_a_5HT)
	var temp_beta_5HT = (m_l3_b_5HT * dna.Mod_Openness) + \
					(m_l15_b_5HT * dna.Mod_Neuroticism)
	var temp_gamma_5HT = (m_l6_g_5HT * dna.Mod_Conscientiousness) + \
					(m_l7_g_5HT * dna.Mod_Conscientiousness) + \
					(m_l10_g_5HT * dna.Mod_Agreeableness) + \
					(m_l13_g_5HT * (1.0 - dna.Mod_Neuroticism)) + \
					(m_c2_g_5HT * dna.Mod_UAI) + \
					(m_c3_g_5HT) + \
					(m_c4_g_5HT) + \
					(m_c5_g_5HT) + \
					(m_safe_g_5HT)
	
	# Alvos dos NTs por vetor de deslocamento
	# Fórmula: Beta + (Alpha * (temp_alpha + Drive)) + (Beta * temp_beta) - (Gamma * temp_gamma * Proximidade)
	var target_NA = GlobalSettings.Beta_NA + (GlobalSettings.Alpha_NA * (temp_alpha_NA + drive_weight_NA)) + (GlobalSettings.Beta_NA * temp_beta_NA) - (GlobalSettings.Gamma_NA * temp_gamma_NA * (current_NA / 0.5))
	var target_DA = GlobalSettings.Beta_DA + (GlobalSettings.Alpha_DA * (temp_alpha_DA + drive_weight_DA)) + (GlobalSettings.Beta_DA * temp_beta_DA) - (GlobalSettings.Gamma_DA * temp_gamma_DA * (current_DA / 0.5))
	var target_5HT = GlobalSettings.Beta_5HT + (GlobalSettings.Alpha_5HT * (temp_alpha_5HT + drive_weight_5HT)) + (GlobalSettings.Beta_5HT * temp_beta_5HT) - (GlobalSettings.Gamma_5HT * temp_gamma_5HT * (current_5HT / 0.5))
	
	var dist_NA = max(abs(target_NA - current_NA), 0.01)
	var dist_DA = max(abs(target_DA - current_DA), 0.01)
	var dist_5HT = max(abs(target_5HT - current_5HT), 0.01)
	
	var speed_NA = dist_NA / current_effect_duration
	var speed_DA = dist_DA / current_effect_duration
	var speed_5HT = dist_5HT / current_effect_duration
	
	# Em recuperação (sem zonas) ou dormindo (rest_zone)
	var recovery_active = is_recovering or energy_stimulus
	
	if recovery_active:
		var base_penalty = 0.25
		if energy_stimulus: base_penalty = 0.6
		var proximity_NA = clamp(abs(current_NA - 0.5) * 5.0, 0.1, 1.0)
		var proximity_DA = clamp(abs(current_DA - 0.5) * 5.0, 0.1, 1.0)
		var proximity_5HT = clamp(abs(current_5HT - 0.5) * 5.0, 0.1, 1.0)
		
		speed_NA *= base_penalty * proximity_NA
		speed_DA *= base_penalty * proximity_DA
		speed_5HT *= base_penalty * proximity_5HT
	
	current_NA = move_toward(current_NA, clamp(target_NA, 0.0, 1.0), delta * speed_NA)
	current_DA = move_toward(current_DA, clamp(target_DA, 0.0, 1.0), delta * speed_DA)
	current_5HT = move_toward(current_5HT, clamp(target_5HT, 0.0, 1.0), delta * speed_5HT)
	
	if recovery_active:
		var total_error = abs(current_NA - 0.5) + abs(current_DA - 0.5) + abs(current_5HT - 0.5)
		# Em recuperação volta pro tempo padrão; dormindo, mantém o estado
		if total_error < 0.01 and is_recovering:
			current_effect_duration = 10.0
			is_recovering = false
	
	# Injeção direta de euforia se todas as necessidades estão plenas, subida linear que ignora a homeostase.
	var all_needs_met = (needs.hunger < 0.15 and needs.energy > 0.85 and needs.safety > 0.85)
	if all_needs_met: current_5HT = clamp(current_5HT + (0.01 * delta), 0.0, 1.0)

# _physics_process: # Fome está no máximo ou energia no mínimo por muito tempo entra em colapso
func _check_biological_collapse(delta: float):
	if needs.hunger >= 1.0: starvation_timer += delta
	else: starvation_timer = move_toward(starvation_timer, 0.0, delta * 2)
	
	if needs.energy <= 0.0: exhaustion_timer += delta
	else: exhaustion_timer = move_toward(exhaustion_timer, 0.0, delta * 2)
	
	# Impacto no NT
	if starvation_timer > CRITICAL_THRESHOLD or exhaustion_timer > CRITICAL_THRESHOLD: _apply_biological_stress()

# _check_biological_collapse: O NPC fica preso em estados de raiva ou pânico (Plutchik) mesmo que ele ache uma zona legal pois o biológico impede que ele seja feliz
func _apply_biological_stress():
	# Fome/Sono extremos esmagam a serotonina e explodem a noradrenalina simulando a irritabilidade e o pânico biológico
	current_NA = move_toward(current_NA, 1.0, 0.01) # Sobe o estresse
	current_5HT = move_toward(current_5HT, 0.0, 0.01) # Zera o bem-estar

# _physics_process: Gerencia a saúde biológica do NPC
func _update_vitality(delta: float):
	if is_dead: return
	
	var total_decay_mult = 0.0
	var is_in_critical_state = false
	
	# Obs: Fazendo 4 ifs ao invés de if else garante que se tiver mais do que um estado crítico cairá ainda mais rápido
	if needs.hunger >= 0.975:
		total_decay_mult += 0.0005 # Impacto alto
		is_in_critical_state = true
	if needs.social >= 0.975:
		total_decay_mult += 0.0001 # Impacto leve
		is_in_critical_state = true
	if needs.energy <= 0.025:
		total_decay_mult += 0.0003 # Exaustão severa
		is_in_critical_state = true
	if needs.safety <= 0.025:
		total_decay_mult += 0.0002 # Insegurança/Estresse
		is_in_critical_state = true
	
	if is_in_critical_state:
		var damage = (VITALITY_DECAY_BASE + total_decay_mult) * delta
		vitality = clamp(vitality - damage, 0.0, 1.0)
		
		# Agonia física proporcional, quanto mais perto de 0 a vitalidade, mais rápido o NA sobe
		if vitality < 0.5:
			# Calcula a intensidade (0.0 em 0.5 de vida, 1.0 em 0.0 de vida)
			var agony_intensity = (0.5 - vitality) / 0.5
			
			# Multiplicador de velocidade (0.01 é um valor mais seguro e gradual)
			# No limite da morte (vida 0), ele tentará subir 0.01 * delta por frame.
			var agony_speed = delta * 0.01 * agony_intensity
			
			current_NA = move_toward(current_NA, 1.0, agony_speed)
	else: # Recuperação: Totalmente fora de perigo
		vitality = clamp(vitality + (VITALITY_RECOVERY_RATE * delta), 0.0, 1.0)
	
	if vitality <= 0.0: _die()

# _update_vitality: NPC morre
func _die():
	is_dead = true
	velocity = Vector2.ZERO
	target_zone = null
	_animated_sprite.stop()
	modulate = Color(0.2, 0.2, 0.2, 0.8)
	
	# Zera os neurotransmissores e necessidades para o log final ficar limpo
	current_DA = 0.0
	current_5HT = 0.0
	current_NA = 0.0
	for need in needs.keys(): needs[need] = 0.0
	
	current_dominant_drive = "idle"
	_apply_drive_weights(current_dominant_drive)
	
	print("NPC ", dna.id, " morreu. Registrando falência no log.")

# _physics_process: Atualizar barras de NTs
func _update_ui():
	barra_id.text = "ID:%d %s\nPlutchik: %s" % [dna.id, current_dominant_drive, emotion_plutchik]
	
	barra_vitality.value = vitality
	barra_vitality_label.text = "VIT: %.3f" % vitality
	
	barra_NA.value = current_NA
	barra_DA.value = current_DA
	barra_5HT.value = current_5HT
	
	barra_NA_label.text = "NA: %.3f" % current_NA
	barra_DA_label.text = "DA: %.3f" % current_DA
	barra_5HT_label.text = "5HT: %.3f" % current_5HT
	
	barra_hunger.value = needs.hunger
	barra_energy.value = needs.energy
	barra_social.value = needs.social
	barra_safety.value = needs.safety
	
	barra_hunger_label.text = "Hunger: %.3f" % needs.hunger
	barra_energy_label.text = "Energy: %.3f" % needs.energy
	barra_social_label.text = "Social: %.3f" % needs.social
	barra_safety_label.text = "Safety: %.3f" % needs.safety

# _physics_process: Tradução para Plutchik’s Wheel of Emotions
func _update_plutchik_emotion() -> void:
	if is_dead:
		emotion_plutchik = "Dead"
		return
	
	var d = current_DA
	var s = current_5HT
	var n = current_NA
	
	var current_state = Vector3(d, s, n)
	var homeostasis_center = Vector3(0.5, 0.5, 0.5)
	
	if current_state.distance_to(homeostasis_center) < 0.05:
		emotion_plutchik = "Homeostasis"
		return
	
	# Vértices do Cubo de Lovheim adaptados para a Roda de Emoções de Plutchik
	var extreme_centers = {
		"Ecstasy": Vector3(1, 1, 0),      # Família Alegria (Amarelo)
		"Admiration": Vector3(0, 1, 0),   # Família Confiança (Verde-Claro)
		"Loathing": Vector3(0, 1, 1),     # Família Nojo (Verde-Escuro)
		"Amazement": Vector3(1, 1, 1),    # Família Surpresa (Azul-Claro)
		"Grief": Vector3(0, 0, 0),        # Família Tristeza (Azul-Escuro)
		"Terror": Vector3(0, 0, 1),       # Família Medo (Roxo)
		"Rage": Vector3(1, 0, 1),         # Família Raiva (Vermelho)
		"Vigilance": Vector3(1, 0, 0)     # Família Antecipação (Laranja)
	}
	
	# Cálculo da menor distância para descobrir a pétala
	var closest_family = ""
	var min_dist = 999.0
	for family in extreme_centers.keys():
		var dist = current_state.distance_to(extreme_centers[family])
		if dist < min_dist:
			min_dist = dist
			closest_family = family
	
	# Cálculo da intensidade para saber a distância da homeostase
	# O raio máximo possível é sqrt(0.5^2 * 3) ≈ 0.866
	# Baixa (0.05 a 0.25): Ocupa cerca de 23% do caminho até o extremo.
	# Média (0.25 a 0.5): Ocupa o "meio de campo" (até 57% do caminho).
	# Alta (> 0.5): Representa o terço final do cubo (os estados realmente intensos).
	var intensity_radius = current_state.distance_to(homeostasis_center)
	
	if intensity_radius > 0.5:
		match closest_family:
			"Ecstasy": emotion_plutchik = "Ecstasy" # Êxtase
			"Admiration": emotion_plutchik = "Admiration" # Admiração
			"Loathing": emotion_plutchik = "Loathing" # Repulsa
			"Amazement": emotion_plutchik = "Amazement" # Espanto
			"Grief": emotion_plutchik = "Grief" # Sofrimento
			"Terror": emotion_plutchik = "Terror" # Pavor
			"Rage": emotion_plutchik = "Rage" # Fúria
			"Vigilance": emotion_plutchik = "Vigilance" # Vigilância
	elif intensity_radius > 0.25:
		match closest_family:
			"Ecstasy": emotion_plutchik = "Joy" # Alegria
			"Admiration": emotion_plutchik = "Trust" # Confiança
			"Loathing": emotion_plutchik = "Disgust" # Nojo
			"Amazement": emotion_plutchik = "Surprise" # Surpresa
			"Grief": emotion_plutchik = "Sadness" # Tristeza
			"Terror": emotion_plutchik = "Fear" # Medo
			"Rage": emotion_plutchik = "Anger" # Raiva
			"Vigilance": emotion_plutchik = "Anticipation" # Antecipação
	else:
		match closest_family:
			"Ecstasy": emotion_plutchik = "Serenity" # Serenidade
			"Admiration": emotion_plutchik = "Acceptance" # Aceitação
			"Loathing": emotion_plutchik = "Boredom" # Tédio
			"Amazement": emotion_plutchik = "Distraction" # Distração
			"Grief": emotion_plutchik = "Pensiveness" # Melancolia
			"Terror": emotion_plutchik = "Apprehension" # Apreensão
			"Rage": emotion_plutchik = "Annoyance" # Chateação
			"Vigilance": emotion_plutchik = "Interest" # Interesse

# Signal: Stimulus Zone
func _on_area_2d_area_entered(area: Area2D):
	if energy_stimulus: return
	
	if area.is_in_group("stimulus_zones"):
		var can_perceive: bool = true
		var zona_need: bool = false
		
		if area.is_drive_zone():
			can_perceive = false
			
			if area.is_food_source and current_dominant_drive == "hunger": can_perceive = true; zona_need = true
			if area.is_rest_zone and current_dominant_drive == "energy": can_perceive = true; zona_need = true
			if area.is_social_hub and current_dominant_drive == "social": can_perceive = true; zona_need = true
			if area.is_safe_haven and current_dominant_drive == "safety": can_perceive = true; zona_need = true
		
		if can_perceive and not active_zones.has(area):
			active_zones.append(area)
			# A atração só acontece se ele estiver em Idle ou se o alvo for confirmado.
			if target_zone == null or zona_need:
				if area.try_occupy(self): _apply_achievement_bonus()

# Signal: Stimulus Zone
func _on_area_2d_area_exited(area: Area2D):
	if active_zones.has(area): active_zones.erase(area)
	if area.get_instance_id() == current_exploration_zone_id: current_exploration_zone_id = -1

# Signal: NPC	
func _on_detection_area_body_entered(body):
	if body != self and body.is_in_group("npcs"):
		nearby_npcs_count += 1

# Signal: NPC
func _on_detection_area_body_exited(body):
	if body != self and body.is_in_group("npcs"):
		nearby_npcs_count = max(0, nearby_npcs_count - 1)
