return {
	locale = "en",
	base   = "assets/sfx/en",
	quotes = { "\"", "\"" },
	strings = {
		-- Main Menu
		["main/play"]    = { text = "Play" },
		["main/play+"]   = { text = "Play+" },
		["main/options"] = { text = "Options" },
		["main/credits"] = { text = "Credits" },
		["main/debug"]   = { text = "Debug" },
		["main/crash"]   = { text = "Crash" },
		["main/exit"]    = { text = "Exit" },

		-- Credits
		["credits/thanks"] = {
			text  = "Thank you for playing",
			audio = "thanks.ogg"
		},

		-- Pause Menu
		["pause/continue"] = { text = "Continue" },
		["pause/reset"]    = { text = "Restart Level" },
		["pause/exit"]     = { text = "Exit to Menu" },

		-- Options Menu
		["options/language"]    = { text = "Language" },
		["options/volume_up"]   = { text = "Volume +" },
		["options/volume_down"] = { text = "Volume -" },

		-- Grandpa
		["play/grandpa_letter"] = {
			audio = "grandpa_letter.wav",
			text  = [[
To my favourite grandson,

I hope this letter finds you well. It's been a season since I last saw you. I've been cooped up in my house ever since monsters started appearing in the forest. If you want to visit me, I have a gift for you. Make sure to come armed!

Lots of love,

Grandpa
			]]
		},
		["play/grandpa_came"] = {
			audio = "grandpa_came.wav",
			text  = "Oh! You came! You look... different than I remember. But that's alright, it will make this gift less awkward! Dohohoho~"
		},
		["play/grandpa_gift"] = {
			audio = "grandpa_gift.wav",
			text  = "And here is your gift, isn't it lovely? If you wear this, it should strengthen your resolve!"
		},

		-- Player
		["play/player_pine"] = {
			audio = "player_pine.wav",
			text  = "I hope Grandpa is pine."
		},
		["play/player_monster"] = {
			audio = "player_monster.wav",
			text  = "Oh no! A monster!"
		},
		["play/player_taiga"] = {
			audio = "player_taiga.wav",
			text  = "Ah! A Taiga!"
		},
		["play/player_dead_end"] = {
			audio = "player_dead_end.wav",
			text  = "A dead end?! Yew've got to be kidding me!"
		},
		["play/player_leaf"] = {
			audio = "player_leaf.wav",
			text  = "Make like a tree and leaf!"
		},
		["play/player_hickory"] = {
			audio = "player_hickory.wav",
			text  = "It's time for ol' Hickory!"
		},
		["play/player_shrublord"] = {
			audio = "player_shrublord.wav",
			text  = "Come at me shrublord!"
		},
		["play/player_bow"] = {
			audio = "player_bow.wav",
			text  = "Is it pronounced bow or bow?"
		},
	}
}
