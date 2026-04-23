extends Area2D

# --- Mapeamento das justificativas das tabelas V e VI ---

@export_group("Contextos de Abertura (Openness)")
@export var is_unexpected: bool = false            # L1
@export var is_analytical_mode: bool = false       # L2
@export var is_new_reward: bool = false            # L3
@export var is_fleeting_motivation: bool = false   # L4
@export var is_explorable: bool = false            # L5

@export_group("Contextos de Conscienciosidade (Conscientiousness)")
@export var is_persistence_focus: bool = false     # L6
@export var is_wellbeing_buffer: bool = false      # L7

@export_group("Contextos de Extroversão (Extraversion)")
@export var is_social_interaction: bool = false    # L8
@export var is_high_stimulus: bool = false         # L9

@export_group("Contextos de Amabilidade (Agreeableness)")
@export var is_conflict_mitigation: bool = false   # L10
@export var is_quick_recovery: bool = false        # L11

@export_group("Contextos de Neuroticismo (Neuroticism)")
@export var is_vulnerable: bool = false           # L12
@export var is_post_traumatic: bool = false        # L13
@export var is_reactive_stress: bool = false            # L14
@export var is_low_base_wellbeing: bool = false    # L15

@export_group("Evitação de Incerteza (UAI)")
@export var is_uncertain: bool = false             # L1
@export var is_high_risk_zone: bool = false        # L2

@export_group("Coletivismo (COL)")
@export var is_group_achievement: bool = false     # L3
@export var is_collective_belonging: bool = false  # L4
@export var is_collective_wellbeing: bool = false  # L5

@export_group("Recursos Biológicos")
@export var is_food_source: bool = false # Para saciar Hunger
@export var is_rest_zone: bool = false # Para saciar Energy
@export var is_social_hub: bool = false # Para saciar Social
@export var is_safe_haven: bool = false # Para saciar Safety

const ALL_FLAGS = [
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

@export_group("Configurações de Consumo")
@export var max_occupants: int = 0
@export var min_occupants: int = 0
@export var current_occupants: Array = [] # Quantos NPCs tem

@export var duration_seconds: float = 10.0 # Tempo padrão para consumir a zone
@export var is_being_consumed: bool = false

@export var lifetime_seconds: float = 50.0 # 1h no jogo = 50seg reais
@export var time_active: float = 0.0 # Contador do lifetime

@export var max_wait_time: float = 15.0 # Tempo de espera até alcançar o min_occupants
@export var wait_timer: float = 0.0 # Contador do tempo de espera

@onready var label = $UI_Container/Label
@onready var progress_bar = $UI_Container/ProgressBar
@onready var info_panel = $UI_Container/InfoPanel
@onready var info_button = $UI_Container/InfoButton
@onready var text_stimulus = $UI_Container/InfoPanel/RichTextLabel

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D

func _ready():
	add_to_group("stimulus_zones")
	_apply_visual_modulation()
	_auto_configure_by_type()
	
	if is_social_interaction or is_social_hub or is_conflict_mitigation:
		collision.shape.radius = 82.5
		sprite.scale = Vector2(0.033, 0.033)
	elif is_group_achievement or is_collective_belonging or is_collective_wellbeing:
		collision.shape.radius = 110.0
		sprite.scale = Vector2(0.044, 0.044)
	
	if global_position.y < 150.0:
		label.position.y = 55.0
		progress_bar.position.y = 79.0
		info_button.position.y = 109.0
		info_panel.position.y = -116.0
	
	progress_bar.max_value = duration_seconds
	progress_bar.value = 0
	progress_bar.visible = false
	
	info_button.pressed.connect(_on_info_button_pressed)
	info_panel.visible = false

func _process(delta):
	if Engine.time_scale == 0.0: return
	
	# Autodestruição se ninguém entrar em 1h = 50s
	if current_occupants.is_empty():
		time_active += delta
		if info_panel.visible: _update_info_text()
		if time_active >= lifetime_seconds: queue_free()
		return
	
	if current_occupants.size() < min_occupants: _handle_waiting_logic(delta)
	else: _handle_consumption_logic(delta)
	
	_update_transparency(delta)

# _ready: Cor de cada zone
func _apply_visual_modulation():
	# --- Sobrevivência e Fisiologia ---
	if is_food_source: modulate = Color.ORANGE
	elif is_rest_zone: modulate = Color.REBECCA_PURPLE
	elif is_safe_haven: modulate = Color.DARK_GREEN
	
	# --- Ameaça e Risco (NA+) ---
	elif is_vulnerable or is_high_risk_zone: modulate = Color.CRIMSON
	elif is_uncertain: modulate = Color.GOLD
	
	# --- Social e Coletivo (C3, C4, C5, L8) ---
	elif is_social_hub or is_social_interaction: modulate = Color.DEEP_SKY_BLUE
	elif is_collective_wellbeing or is_collective_belonging: modulate = Color.CYAN
	
	# --- Recompensa e Conquista (DA+) ---
	elif is_new_reward or is_group_achievement: modulate = Color.SPRING_GREEN
	elif is_fleeting_motivation: modulate = Color.LAWN_GREEN
	
	# --- Cognição e Curiosidade (L1, L2, L5) ---
	elif is_unexpected or is_analytical_mode or is_explorable: modulate = Color.KHAKI
	
	# --- Resiliência e Foco (L6, L7, L10, L11) ---
	elif is_persistence_focus or is_wellbeing_buffer: modulate = Color.STEEL_BLUE
	elif is_conflict_mitigation or is_quick_recovery: modulate = Color.PALE_GREEN
	
	# --- Vulnerabilidade e Baixo Bem-estar (L13, L14, L15) ---
	elif is_post_traumatic or is_reactive_stress or is_low_base_wellbeing: modulate = Color.SLATE_GRAY
	
	else: modulate = Color.WHITE
	
	label.text = _get_active_flag_name()

# _update_visual e _update_info_text: Nome do estímulo
func _get_active_flag_name() -> String:
	for flag in ALL_FLAGS:
		if get(flag):
			return flag.replace("is_", "").replace("_", " ").capitalize()
	return "Neutral"

# _ready: Configurar todas as zones
func _auto_configure_by_type():
	# 1s real ≈ 1.2min simulado
	# O duration_seconds reflete a persistência necessária para que 
	# o estímulo altere os NTs de forma significativa.
	
	# --- Tabela V ---
	if is_unexpected or is_new_reward or is_fleeting_motivation:
		# Estímulos de recompensa imediata ou susto. O impacto é rápido.
		duration_seconds = 5.0; min_occupants = 1; max_occupants = 1
	elif is_analytical_mode or is_persistence_focus:
		# Simula ~45 min de concentração profunda.
		duration_seconds = 40.0; min_occupants = 1; max_occupants = 1
	elif is_explorable:
		# Curiosidade. Tempo para o NPC "investigar" o local (~25 min).
		duration_seconds = 20.0; min_occupants = 1; max_occupants = 2
	elif is_wellbeing_buffer or is_quick_recovery:
		# Alívio rápido ou pausa para descanso mental (~20 min).
		duration_seconds = 15.0; min_occupants = 1; max_occupants = 4
	elif is_high_stimulus:
		# Sobrecarga sensorial. O NPC processa o caos rapidamente (~12 min).
		duration_seconds = 10.0; min_occupants = 1; max_occupants = 10
	elif is_vulnerable or is_reactive_stress:
		# Eventos de medo agudo. Tempo de exposição ao perigo (~18 min).
		duration_seconds = 15.0; min_occupants = 1; max_occupants = 1
	elif is_post_traumatic or is_low_base_wellbeing:
		# Processamento de estados depressivos ou trauma requer longa exposição (~70 min).
		duration_seconds = 60.0; min_occupants = 1; max_occupants = 1
	elif is_conflict_mitigation:
		# Resolução de problemas sociais. Simula uma conversa séria (~30 min).
		duration_seconds = 25.0; min_occupants = 2; max_occupants = 2;
	
	# --- Tabela VI ---
	elif is_uncertain or is_high_risk_zone:
		# Ansiedade antecipatória. O NPC gasta tempo avaliando o risco (~25 min).
		duration_seconds = 20.0; min_occupants = 1; max_occupants = 1
	elif is_group_achievement or is_collective_belonging or is_collective_wellbeing:
		# Rituais sociais coletivos. Atividades de grupo são mais longas (~55 min).
		duration_seconds = 45.0; min_occupants = 3; max_occupants = 8;
	
	# --- Necessidades Fisiológicas ---
	elif is_food_source:
		# Tempo médio de uma refeição (~30 min).
		duration_seconds = 25.0; min_occupants = 1; max_occupants = 1
	elif is_rest_zone:
		# Simula um ciclo de sono (~8 horas simulação).
		duration_seconds = 400.0; min_occupants = 1; max_occupants = 1
	elif is_social_hub or is_social_interaction:
		# Tempo médio de uma interação social (~1 hora).
		duration_seconds = 50.0; min_occupants = 2; max_occupants = 6;
	elif is_safe_haven:
		# Tempo para o NPC recuperar o fôlego e sentir-se seguro novamente (~35 min).
		duration_seconds = 30.0; min_occupants = 1; max_occupants = 3
	
	# Sincroniza o feedback visual da barra com os tempos definidos acima
	progress_bar.max_value = duration_seconds

# Chamado pelo NPC para ajustar o tempo de sono individualizado na zona
func set_custom_duration(new_duration: float):
	if is_rest_zone:
		duration_seconds = new_duration
		progress_bar.max_value = duration_seconds
		# print("Zona de Descanso ajustada para: ", duration_seconds, "s")

# _process: NPC esperando min_occupants para trigger de modulação
func _handle_waiting_logic(delta):
	wait_timer += delta
	progress_bar.visible = false
	
	if wait_timer >= max_wait_time:
		_eject_disappointed_npcs()

# _handle_waiting_logic: Tempo de espera por outro NPC alcançado
func _eject_disappointed_npcs():
	# NPCs saem sem frustração
	for npc in current_occupants:
		npc.cancel_target()
	
	current_occupants.clear()
	queue_free() # Deletar a zona

# _process: Tem min_occupants
func _handle_consumption_logic(delta):
	wait_timer = 0.0 # Reseta o timer de espera se alguém chegar
	progress_bar.visible = true
	progress_bar.value += delta
	
	if progress_bar.value >= duration_seconds: queue_free()

# _process: Transparência dos nodes stimulus_zone quando tiver NPC na área
func _update_transparency(_delta):
	# NPC adiciona a zona à lista dele, vamos checar se a área tem sobreposições
	var overlapping_bodies = get_overlapping_bodies()
	var has_npc = false
	
	for body in overlapping_bodies:
		if body.is_in_group("npcs"):
			has_npc = true
			break
	
	var target_alpha = 0.3 if has_npc else 1.0
	
	# Suaviza a transição
	label.modulate.a = lerp(modulate.a, target_alpha, 0.5)
	progress_bar.modulate.a = lerp(modulate.a, target_alpha, 0.5)
	info_button.modulate.a = lerp(modulate.a, target_alpha, 0.5)
	info_panel.modulate.a = lerp(modulate.a, target_alpha, 0.5)

# npc.gd -> _move_towards_target: Verifica se há vaga
func try_occupy(npc: CharacterBody2D) -> bool:
	if current_occupants.size() < max_occupants:
		if not current_occupants.has(npc):
			current_occupants.append(npc)
			return true
	return false

# $UI_Container/InfoPanel: Abrir painel
func _on_info_button_pressed():
	info_panel.visible = !info_panel.visible
	if info_panel.visible: _update_info_text()

# _on_info_button_pressed: Stimulus text
func _update_info_text():
	var active_flag = _get_active_flag_name()
	
	# Construção do relatório técnico para o TCC
	var report = "[b][center]STIMULUS REPORT[/center][/b]\n"
	report += "Type: [color=yellow]" + active_flag + "[/color]\n"
	report += "---------------------------------\n"
	report += "Duration: " + str(duration_seconds) + "s\n"
	report += "Occupancy: " + str(current_occupants.size()) + "/" + str(max_occupants) + "\n"
	report += "Mín. Required: " + str(min_occupants) + " NPC(s)\n"
	report += "Lifetime Rem.: " + str(int(lifetime_seconds - time_active)) + "s\n"
	
	# Impacto Neuromodulatório
	report += "\n[b]Theoretical Effects (Neuromodulation):[/b]\n"
	report += _get_theoretical_impact()
	
	text_stimulus.bbcode_enabled = true
	text_stimulus.text = report

# _update_info_text: Tradução dos efeitos dos 20 Fatores Moduladores
func _get_theoretical_impact() -> String:
	# --- Contextos de Abertura (L1-L5) ---
	if is_unexpected: return "[color=red]L1 (NA):[/color] Alpha -1.5 (Susto)\n[color=green]L1 (DA):[/color] Beta +0.8 (Curiosidade)\n[color=blue]L1 (5HT):[/color] Gamma -0.5 (Resiliência)"
	if is_analytical_mode: return "[color=red]L2 (NA):[/color] Beta -1.2 (Foco)\n[color=green]L2 (DA):[/color] Alpha -0.6 (Filtro)\n[color=blue]L2 (5HT):[/color] Alpha +0.5 (Estabilidade)"
	if is_new_reward: return "[color=red]L3 (NA):[/color] Gamma +1.5 (Alívio)\n[color=green]L3 (DA):[/color] Alpha +6.0 (Êxtase)\n[color=blue]L3 (5HT):[/color] Beta +1.2 (Satisfação)"
	if is_fleeting_motivation: return "[color=red]L4 (NA):[/color] Beta -1.0 (Letargia)\n[color=green]L4 (DA):[/color] Gamma +3.5 (Evasão)\n[color=blue]L4 (5HT):[/color] Alpha -0.6 (Vulnerabilidade)"
	if is_explorable: return "[color=red]L5 (NA):[/color] Alpha -0.8 (Exploração s/ estresse)\n[color=green]L5 (DA):[/color] Beta +1.5 (Busca)\n[color=blue]L5 (5HT):[/color] Alpha +0.6 (Segurança)"
	
	# --- Conscienciosidade (L6-L7) ---
	if is_persistence_focus: return "[color=red]L6 (NA):[/color] Beta +0.5 (Atenção)\n[color=green]L6 (DA):[/color] Gamma -2.0 (Persistência)\n[color=blue]L6 (5HT):[/color] Gamma -1.0 (Paciência)"
	if is_wellbeing_buffer: return "[color=red]L7 (NA):[/color] Alpha -1.0 (Estoicismo)\n[color=green]L7 (DA):[/color] Beta +0.5 (Motivação base)\n[color=blue]L7 (5HT):[/color] Gamma -3.0 (Escudo)"
	
	# --- Extroversão (L8-L9) ---
	if is_social_interaction: return "[color=red]L8 (NA):[/color] Gamma +2.0 (Desabafo)\n[color=green]L8 (DA):[/color] Alpha +4.5 (Recompensa)\n[color=blue]L8 (5HT):[/color] Alpha +1.5 (Vínculo)"
	if is_high_stimulus: return "[color=red]L9 (NA):[/color] Alpha -1.2 (Resiliência ao caos)\n[color=green]L9 (DA):[/color] Beta +2.0 (Entusiasmo)\n[color=blue]L9 (5HT):[/color] Gamma -1.5 (Estabilidade)"
	
	# --- Amabilidade (L10-L11) ---
	if is_conflict_mitigation: return "[color=red]L10 (NA):[/color] Alpha -2.5 (Paz)\n[color=green]L10 (DA):[/color] Alpha +0.8 (Cooperação)\n[color=blue]L10 (5HT):[/color] Beta +1.2 (Harmonia)"
	if is_quick_recovery: return "[color=red]L11 (NA):[/color] Gamma +2.0 (Limpeza)\n[color=green]L11 (DA):[/color] Beta +0.6 (Prontidão)\n[color=blue]L11 (5HT):[/color] Alpha +1.0 (Restauração)"
	
	# --- Neuroticismo (L12-L15) ---
	if is_vulnerable: return "[color=red]L12 (NA):[/color] Alpha +3.5 (Pânico)\n[color=green]L12 (DA):[/color] Beta -1.0 (Inibição)\n[color=blue]L12 (5HT):[/color] Alpha -1.5 (Instabilidade)"
	if is_post_traumatic: return "[color=red]L13 (NA):[/color] Gamma -2.5 (Vigilância)\n[color=green]L13 (DA):[/color] Beta -1.2 (Anedonia)\n[color=blue]L13 (5HT):[/color] Gamma +1.5 (Esgotamento)"
	if is_reactive_stress: return "[color=red]L14 (NA):[/color] Beta +2.0 (Ansiedade)\n[color=green]L14 (DA):[/color] Gamma +1.5 (Desânimo)\n[color=blue]L14 (5HT):[/color] Alpha -1.0 (Insegurança)"
	if is_low_base_wellbeing: return "[color=red]L15 (NA):[/color] Alpha +1.2 (Irritabilidade)\n[color=green]L15 (DA):[/color] Alpha -0.8 (Desprazer)\n[color=blue]L15 (5HT):[/color] Beta -1.8 (Depressão)"
	
	# --- Tabela VI (C1-C5) ---
	if is_uncertain: return "[color=red]C1 (NA):[/color] Alpha +3.0 / Beta +1.2\n[color=green]C1 (DA):[/color] (Sem impacto direto)\n[color=blue]C1 (5HT):[/color] Alpha -1.0"
	if is_high_risk_zone: return "[color=red]C2 (NA):[/color] Beta +1.8\n[color=green]C2 (DA):[/color] Alpha -1.0\n[color=blue]C2 (5HT):[/color] Gamma +1.2"
	if is_group_achievement: return "[color=red]C3 (NA):[/color] Gamma +1.5\n[color=green]C3 (DA):[/color] Alpha +4.0\n[color=blue]C3 (5HT):[/color] Alpha +1.5"
	if is_collective_belonging: return "[color=red]C4 (NA):[/color] Beta -1.0\n[color=green]C4 (DA):[/color] Beta +1.5\n[color=blue]C4 (5HT):[/color] Alpha +1.2"
	if is_collective_wellbeing: return "[color=red]C5 (NA):[/color] Gamma +1.2\n[color=green]C5 (DA):[/color] Beta +0.8\n[color=blue]C5 (5HT):[/color] Alpha +3.0"
	
	# --- Biológicos ---
	if is_food_source: return "Impacto: Drive de Fome (Dopamina de busca)"
	if is_rest_zone: return "Impacto: Drive de Energia (Serotonina restaurativa)"
	if is_social_hub: return "Impacto: Drive Social (Dopamina social)"
	if is_safe_haven: return "Impacto: Drive de Segurança (Redução de Noradrenalina)"
	
	return "Impacto neuromodulatório misto."

# npc.gd -> _on_area_2d_area_entered: Se é uma zona de need
func is_drive_zone() -> bool:
	return is_food_source or is_rest_zone or is_social_hub or is_safe_haven
