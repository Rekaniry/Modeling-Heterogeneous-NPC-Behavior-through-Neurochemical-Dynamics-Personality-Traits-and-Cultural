extends Node

var target_npcs: Array = []
var is_logging: bool = false
var file_path: String = ""
var log_interval: float = 5.0
var timer: float = 0.0

# Guardar as linhas de cada NPC separadamente para somente no final inserir no CSV de forma organizada por ID de NPC
var log_buffer: Dictionary = {}

func _ready():
	await get_tree().create_timer(2.0).timeout
	_setup_all_npcs()

# _ready: Pegamos sempre o primeiro NPC instanciado (NPC 0)
func _setup_all_npcs():
	target_npcs = get_tree().get_nodes_in_group("npcs")
	for npc in target_npcs: log_buffer[npc.dna.id] = [] # Inicializa o buffer
	print(">>>> [DATA COLLECTOR] Monitorando ", target_npcs.size(), " NPCs com Buffer de memória.")

func _physics_process(delta: float):
	var day = GlobalSettings.current_day
	var hour = GlobalSettings.current_hour
	
	if day == 5 and hour == 6 and not is_logging: # Iniciar log no Dia 5 às 06:00
		is_logging = true
		print(">>>> [DATA COLLECTOR]: Coleta iniciada (armazenando em memória...)")
	elif day == 10 and hour == 6 and is_logging: _save_buffer_to_csv() # Encerrar log no Dia 10 às 06:00
	
	if is_logging:
		timer += delta
		if timer >= log_interval:
			_capture_data_to_buffer()
			timer = 0.0

# _physics_process: Em vez de escrever no arquivo, guarda no dicionário
func _capture_data_to_buffer():
	for npc in target_npcs:
		if is_instance_valid(npc):
			var line = "%d,%d,%d,%d,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%s,%s,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f\n" % [
				npc.dna.id,
				GlobalSettings.current_day,
				GlobalSettings.current_hour,
				GlobalSettings.current_minute,
				npc.current_DA,
				npc.current_5HT,
				npc.current_NA,
				npc.vitality,
				npc.needs.hunger,
				npc.needs.energy,
				npc.needs.social,
				npc.needs.safety,
				npc.emotion_plutchik,
				npc.current_dominant_drive,
				npc.dna.Mod_Openness,
				npc.dna.Mod_Conscientiousness,
				npc.dna.Mod_Extraversion,
				npc.dna.Mod_Agreeableness,
				npc.dna.Mod_Neuroticism,
				npc.dna.Mod_UAI,
				npc.dna.Mod_COL
			]
			log_buffer[npc.dna.id].append(line)

# _capture_data_to_buffer: Passar o que está no dicionário para o CSV
func _save_buffer_to_csv():
	is_logging = false
	var mode_suffix = "HYBRID" # PERSONALITY, CULTURE, HYBRID
	file_path = "user://TOTAL_LOG_%s_v16.csv" % [mode_suffix]
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string("sep=,\n")
		file.store_string("NPC_ID,Day,Hour,Minute,DA,5HT,NA,VIT,Hunger,Energy,Social,Safety,Emotion,Drive,DNA_O,DNA_C,DNA_E,DNA_A,DNA_N,DNA_UAI,DNA_COL\n")
		
		# Itera NPC por NPC, garantindo a ordem das 1200 linhas
		var ids = log_buffer.keys()
		ids.sort()
		
		for id in ids:
			for line in log_buffer[id]:
				file.store_string(line)
		
		file.close()
		print(">>>> [DATA COLLECTOR]: Gravação finalizada e ORDENADA com sucesso.")
