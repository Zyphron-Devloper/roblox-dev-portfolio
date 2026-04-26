--[[
	CurrencyConfig (ModuleScript)
	Location: ReplicatedStorage > Modules > CurrencyConfig

	Central configuration for the entire currency system.
	Adjust these values to tune your game's economy.
	Used by both server and client modules.
]]

local CurrencyConfig = {}

-- ═══════════════════════════════════════════════════════
-- CURRENCY DEFAULTS
-- ═══════════════════════════════════════════════════════

--- Starting coins for new players (no saved data).
CurrencyConfig.DEFAULT_COINS = 0

--- Absolute maximum coins a player can hold.
CurrencyConfig.MAX_COINS = 999999999

--- Absolute minimum coins a player can hold.
CurrencyConfig.MIN_COINS = 0

-- ═══════════════════════════════════════════════════════
-- DATA STORE
-- ═══════════════════════════════════════════════════════

--- Name of the DataStore used to persist coin data.
--- Bump the version suffix (_V1, _V2, …) when you change
--- the data schema to avoid corrupting old saves.
CurrencyConfig.DATASTORE_NAME = "PlayerCurrency_V1"

-- ═══════════════════════════════════════════════════════
-- AUTOSAVE
-- ═══════════════════════════════════════════════════════

--- How often (in seconds) the server auto-saves every
--- online player's data.
CurrencyConfig.AUTOSAVE_INTERVAL = 60

-- ═══════════════════════════════════════════════════════
-- RETRY / RESILIENCE
-- ═══════════════════════════════════════════════════════

--- Number of retry attempts for DataStore save operations.
CurrencyConfig.SAVE_RETRIES = 3

--- Delay (seconds) between each retry attempt.
CurrencyConfig.RETRY_DELAY = 2

-- ═══════════════════════════════════════════════════════
-- TESTING LIMITS (for client-side test buttons)
-- ═══════════════════════════════════════════════════════

--- Maximum amount a single test-add request can grant.
CurrencyConfig.MAX_TEST_ADD = 1000

--- Maximum amount a single test-remove request can take.
CurrencyConfig.MAX_TEST_REMOVE = 1000

-- ═══════════════════════════════════════════════════════
-- COIN PACKS (in-app purchases)
-- ═══════════════════════════════════════════════════════

--- Each pack defines:
---   coins     = number of coins the player receives
---   productId = Roblox Developer Product ID (number or nil)
---
--- HOW TO ENABLE PURCHASING:
---   Set productId to your real Developer Product ID number.
---   Example:  { coins = 10, productId = 123456789 }
---
--- WHEN productId IS nil:
---   The buy button for that pack will display "Coming Soon"
---   and will be greyed out / disabled. No purchase prompt
---   will appear.
---
--- IMPORTANT: Coins are NOT granted from the client.
--- The server's ProcessReceipt callback awards coins
--- after Roblox confirms payment.
CurrencyConfig.COIN_PACKS = {
	{ coins = 10,  productId = nil }, -- Set productId to enable
	{ coins = 30,  productId = nil }, -- Set productId to enable
	{ coins = 50,  productId = nil }, -- Set productId to enable
	{ coins = 100, productId = nil }, -- Set productId to enable
	{ coins = 300, productId = nil }, -- Set productId to enable
	{ coins = 500, productId = nil }, -- Set productId to enable
}

return CurrencyConfig
