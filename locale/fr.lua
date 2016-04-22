return {
	locale = "fr",
	base   = "assets/sfx/en",
	quotes = { "\"", "\"" },
	strings = {
		-- Main Menu
		["main/play"]    = { text = "Jouer" },
		["main/play+"]   = { text = "Jouer+" },
		["main/options"] = { text = "Options" },
		["main/credits"] = { text = "Crédits" },
		["main/debug"]   = { text = "Débug" },
		["main/crash"]   = { text = "Crash" },
		["main/exit"]    = { text = "Quitter" },

		-- Credits
		["credits/thanks"] = {
			text  = "Merci d'avoir joué!",
			audio = "thanks.ogg"
		},

		-- Pause Menu
		["pause/continue"] = { text = "Continuer" },
		["pause/reset"]    = { text = "Recommencer le Niveau" },
		["pause/exit"]     = { text = "Retourner au Menu Principal" },

		-- Options Menu
		["options/language"]    = { text = "Langage" },
		["options/volume_up"]   = { text = "Volume +" },
		["options/volume_down"] = { text = "Volume -" },

		-- Grandpa
		["play/grandpa_letter"] = {
			audio = "grandpa_letter.wav",
			text  = [[
À mon petit-fils préféré,

J'espère que cette lettre te trouvera en bonne santé. Je ne t'ai pas vu depuis la saison passée. Je suis pris dans ma maison depuis que des monstres ont commencés à apparaître dans la forêt. Si jamais tu veux me visiter, j'aurai un cadeau pour toi. Prend soin de venir armé!

Plein de tendresse,

Grand-papa
			]]
		},
		["play/grandpa_came"] = {
			audio = "grandpa_came.wav",
			text  = "Ah! Tu est venu! T'as beaucoup changé. Bon c'est pas grave, ça va juste rendre les choses moins mélèze! Hehehe~"
		},
		["play/grandpa_gift"] = {
			audio = "grandpa_gift.wav",
			text  = "Voilà ton cadeau, n'est-il pas joli? Si tu le porte, ça devrait renforcer ta détermination!"
		},

		-- Player
		["play/player_pine"] = {
			audio = "player_pine.wav",
			text  = "J'espère que grand-papa va bien."
		},
		["play/player_monster"] = {
			audio = "player_monster.wav",
			text  = "Ah! Un monstre!"
		},
		["play/player_taiga"] = {
			audio = "player_taiga.wav",
			text  = "Ah! Une Taiga!"
		},
		["play/player_dead_end"] = {
			audio = "player_dead_end.wav",
			text  = "Un fond de sac?! Fertilisant!"
		},
		["play/player_leaf"] = {
			audio = "player_leaf.wav",
			text  = "Vas-t'en!"
		},
		["play/player_hickory"] = {
			audio = "player_hickory.wav",
			text  = "C'est le temps de sortir mon veil Hickory!"
		},
		["play/player_shrublord"] = {
			audio = "player_shrublord.wav",
			text  = "Viens-t'en saule-chat!"
		},
		["play/player_bow"] = {
			audio = "player_bow.wav",
			text  = "Ça ce dit arc ou arche?"
		},
	}
}
