return {
	locale = "de",
	base   = "assets/sfx/en",
	quotes = { "\"", "\"" },
	strings = {
		-- Main Menu
		["main/play"]    = { text = "Spielen" },
		["main/play+"]   = { text = "Spielen+" },
		["main/options"] = { text = "Optionen" },
		["main/credits"] = { text = "Credits" },
		["main/debug"]   = { text = "Debug" },
		["main/crash"]   = { text = "Crash" },
		["main/exit"]    = { text = "Ende" },

		-- Credits
		["credits/thanks"] = {
			text  = "Danke fürs Spielen",
			audio = "thanks.ogg"
		},

		-- Pause Menu
		["pause/continue"] = { text = "Weiter" },
		["pause/reset"]    = { text = "Level neu starten" },
		["pause/exit"]     = { text = "Menü" },

		-- Options Menu
		["options/language"]    = { text = "Sprache wählen" },
		["options/volume_up"]   = { text = "Lautstärke +" },
		["options/volume_down"] = { text = "Lautstärke -" },

		-- Grandpa
		["play/grandpa_letter"] = {
			audio = "grandpa_letter.wav",
			text  = [[
An meinen liebsten Enkel,

ich hoffe, dass Du wohlauf bist, wenn Du diesen Brief erhältst. Es ist schon eine Ewigkeit her, seit ich Dich das letzte Mal gesehen habe. Ich fange langsam an Wurzeln in meinem Haus zu schlagen, da vor einiger Zeit Monster im Wald aufgetaucht sind. Komm mich doch mal besuchen, ich habe ein Geschenk für Dich. Bring aber auf jeden Fall etwas mit um Dich gegen mögliche Angreifer verteidigen zu können.

Hab dich lieb,

Opa
			]]
		},
		["play/grandpa_came"] = {
			audio = "grandpa_came.wav",
			text  = "Oh! Du bist gekommen! Du siehst… anders aus als ich dich in Erinnerung habe. Aber das ist ok, das wird mein Geschenk weniger unpassend machen! Dohohoho~"
		},
		["play/grandpa_gift"] = {
			audio = "grandpa_gift.wav",
			text  = "Und hier ist dein Geschenkt, ist es nicht hübsch? Wenn du das hier trägst, sollte es deine Entschlossenheit erhöhen!"
		},

		-- Player
		["play/player_pine"] = {
			audio = "player_pine.wav",
			text  = "Ich hoffe bei Großvater ist alles im grünen Bereich."
		},
		["play/player_monster"] = {
			audio = "player_monster.wav",
			text  = "Oh nein! Ein Monster!"
		},
		["play/player_taiga"] = {
			audio = "player_taiga.wav",
			text  = "Ah! Ein Tiger!"
		},
		["play/player_dead_end"] = {
			audio = "player_dead_end.wav",
			text  = "Eine Sackgasse?! Ich könnte mich in Grund und Boden ärgern!"
		},
		["play/player_leaf"] = {
			audio = "player_leaf.wav",
			text  = "Mach‘s wie trockenes Laub und verkrümel dich!"
		},
		["play/player_hickory"] = {
			audio = "player_hickory.wav",
			text  = "Das wird jetzt mehr weh tun als von einem Baumstamm plattgemacht zu werden!"
		},
		["play/player_shrublord"] = {
			audio = "player_shrublord.wav",
			text  = "Komm her du überdimensionales Sonnenblümchen!"
		},
		["play/player_bow"] = {
			audio = "player_bow.wav",
			text  = "Versuch mal einen Bogen hier drum zu machen!"
		},
	}
}
