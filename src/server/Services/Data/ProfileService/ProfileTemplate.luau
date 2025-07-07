local template = {
	CurrencyData = {
		Tix = 0,
	},
	ItemData = {
		Inventory = {
			Hammer_B = 1, -- Represents the player having 1x of the first Item
		},
	}
}


export type ProfileTemplate = typeof(template)
return template