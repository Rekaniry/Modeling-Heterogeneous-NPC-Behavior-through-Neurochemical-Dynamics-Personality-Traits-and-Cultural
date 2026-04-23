extends Node

var Beta_NA: float = 0.5
var Beta_DA: float = 0.5
var Beta_5HT: float = 0.5

var Alpha_NA: float = 0.35
var Alpha_DA: float = 0.25
var Alpha_5HT: float = 0.15

var Gamma_NA: float = 0.35
var Gamma_DA: float = 0.25
var Gamma_5HT: float = 0.15

# --- Tempo Global ---
var is_night: bool = false
var current_day: int = 1
var current_hour: int = 6
var current_minute: int = 0
var total_cycle_time: float = 1200.0

# Configurações de população
var npc_count: int = 12
var npc_data_list: Array = []

# Tamanho da janela
var screen_width: float = 1920.0
var screen_height: float = 1080.0
var world_boundary: Rect2 = Rect2(0, 0, screen_width, screen_height)

func generate_population():
	npc_data_list.clear()
	
	for i in range(npc_count):
		var npc_dna = {
			"id": i,
			# Usar range de 0.01 a 1.0 garante que o DNA nunca seja nulo
			"Mod_Openness": randf_range(0.01, 1.0),
			"Mod_Conscientiousness": randf_range(0.01, 1.0),
			"Mod_Extraversion": randf_range(0.01, 1.0),
			"Mod_Agreeableness": randf_range(0.01, 1.0),
			"Mod_Neuroticism": randf_range(0.01, 1.0),
			"Mod_UAI": randf_range(0.01, 1.0),
			"Mod_COL": randf_range(0.01, 1.0),
			"hunger_rate_multiplier": randf_range(0.8, 1.2), # Metabolismo +/- 20%
			"sleep_threshold": randf_range(0.15, 0.50) # Ativo vs Preguiçoso
		}
		
		npc_data_list.append(npc_dna)
