return {
	locale = "phpceo",
	base   = "assets/sfx/phpceo",
	quotes = { "\"", "\"" },
	strings = {
		-- Main Menu
		["main/play"]    = { text = "ENGAGE CUSTOMERS" },
		["main/play+"]   = { text = "ENGAGE MORE CUSTOMERS" },
		["main/options"] = { text = "CONFIGURABLE GOALS" },
		["main/credits"] = { text = "OUTSOURCED TEAM" },
		["main/debug"]   = { text = "PRODUCTION ENVIRONMENT" },
		["main/crash"]   = { text = "DEPLOY" },
		["main/exit"]    = { text = "POSTPONE PROFITS" },

		-- Credits
		["credits/thanks"] = {
			text  = "ANOTHER FINE PRODUCT BY EJEW.IN, LLC",
			audio = "thanks.ogg"
		},

		-- Pause Menu
		["pause/continue"] = { text = "RESUME PRINTING MONEY" },
		["pause/reset"]    = { text = "PIVOT BUSINESS STRATEGY" },
		["pause/exit"]     = { text = "SPRINT OVERVIEW" },

		-- Options Menu
		["options/language"]    = { text = "JAVASCRIPT" },
		["options/volume_up"]   = { text = "ZOOM" },
		["options/volume_down"] = { text = "ENHANCE" },

		-- Grandpa
		["play/grandpa_letter"] = {
			audio = "grandpa_letter.wav",
			text  = [[
DEAR EMPLOYEE,

IF YOU ARE READING THIS, YOU ARE PROBABLY NOT MAKING ME MONEY. I REALIZE THAT I HAVEN'T DONE YOUR YEARLY PERFORMANCE REPORT. I HAVE BEEN LOCKED UP IN THE WAR ROOM EVER SINCE BUGS BEGAN APPEARING IN OUR APPLICATION. IF YOU WANT TO KEEP YOUR JOB, GET IN HERE. BE PREPARED TO EXPLAIN THIS TO THE SHAREHOLDERS!

HELP,

PHPCEO
			]]
		},
		["play/grandpa_came"] = {
			audio = "grandpa_came.wav",
			text  = "YOU'RE FINALLY HERE. DID YOU ALWAYS HAVE THAT ... FACE? NEVERMIND THAT, I CAN'T REALLY AFFORD TO HAVE TO TALK TO HR FOR THE THIRD TIME THIS WEEK."
		},
		["play/grandpa_gift"] = {
			audio = "grandpa_gift.wav",
			text  = "ANYWAYS, HERE'S THE PRODUCTION SERVER. FIX IT. I PROBABLY SHOULDN'T HAVE TAKEN IT, BUT YOU DIDN'T STOP ME!"
		},

		-- Player
		["play/player_pine"] = {
			audio = "player_pine.wav",
			text  = "I hope my boss didn't over-promise again."
		},
		["play/player_monster"] = {
			audio = "player_monster.wav",
			text  = "Oh no, a bug!"
		},
		["play/player_taiga"] = {
			audio = "player_taiga.wav",
			text  = "Sometimes you just have to see the application for the trees. I think."
		},
		["play/player_dead_end"] = {
			audio = "player_dead_end.wav",
			text  = "Weird, my debugger just immediately bails here."
		},
		["play/player_leaf"] = {
			audio = "player_leaf.wav",
			text  = "But I hate binary space partitions!"
		},
		["play/player_hickory"] = {
			audio = "player_hickory.wav",
			text  = "And WOODEN'T you know, I reached back like a lumberjack and chopped a foe!"
		},
		["play/player_shrublord"] = {
			audio = "player_shrublord.wav",
			text  = "More like lord of the DIES. A LOT."
		},
		["play/player_bow"] = {
			audio = "player_bow.wav",
			text  = "BOW WOW WOW WOW, WOW WOW, WOW. wOw."
		},
	}
}
