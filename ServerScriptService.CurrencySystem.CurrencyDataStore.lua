--[[
	CurrencyDataStore (ModuleScript)
	Location: ServerScriptService > CurrencySystem > CurrencyDataStore

	Handles all DataStoreService interactions for the currency
	system. Provides safe load/save with pcall wrapping and
	automatic retry logic so the main thread is never blocked
	unnecessarily.

	NOTE: This module should ONLY be required by server scripts.
]]

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CurrencyConfig = require(ReplicatedStorage.Modules.CurrencyConfig)

local CurrencyDataStore = {}

-- ═══════════════════════════════════════════════════════
-- PRIVATE: Get or create the DataStore handle
-- ═══════════════════════════════════════════════════════

local dataStore: DataStore? = nil

local function getStore(): DataStore
	if not dataStore then
		dataStore = DataStoreService:GetDataStore(CurrencyConfig.DATASTORE_NAME)
	end
	return dataStore :: DataStore
end

-- ═══════════════════════════════════════════════════════
-- PUBLIC API
-- ═══════════════════════════════════════════════════════

--[[
	LoadCoins(player: Player) -> number

	Attempts to read the player's saved coin count from the
	DataStore. If the read fails for any reason the function
	returns DEFAULT_COINS so the player can still play.
]]
function CurrencyDataStore.LoadCoins(player: Player): number
	local key = tostring(player.UserId)
	local success, result = pcall(function()
		return getStore():GetAsync(key)
	end)

	if success and type(result) == "number" then
		return result
	else
		if not success then
			warn("[CurrencyDataStore] Failed to load coins for", player.Name, ":", result)
		end
		return CurrencyConfig.DEFAULT_COINS
	end
end

--[[
	SaveCoins(player: Player, coins: number) -> boolean

	Persists the given coin count to the DataStore for the
	specified player. Uses retry logic (configurable via
	CurrencyConfig.SAVE_RETRIES / RETRY_DELAY) to handle
	transient failures.

	Returns true if the save eventually succeeded, false
	otherwise.
]]
function CurrencyDataStore.SaveCoins(player: Player, coins: number): boolean
	local key = tostring(player.UserId)

	for attempt = 1, CurrencyConfig.SAVE_RETRIES do
		local success, err = pcall(function()
			getStore():SetAsync(key, coins)
		end)

		if success then
			return true
		end

		warn(
			"[CurrencyDataStore] Save attempt",
			attempt,
			"failed for",
			player.Name,
			":",
			err
		)

		-- Don't wait after the last attempt
		if attempt < CurrencyConfig.SAVE_RETRIES then
			task.wait(CurrencyConfig.RETRY_DELAY)
		end
	end

	warn("[CurrencyDataStore] All save attempts exhausted for", player.Name)
	return false
end

--[[
	SaveCoinsById(userId: number, coins: number) -> boolean

	Same as SaveCoins but accepts a raw UserId instead of a
	Player reference.  Useful during BindToClose when the
	Player object may already be partially cleaned up.
]]
function CurrencyDataStore.SaveCoinsById(userId: number, coins: number): boolean
	local key = tostring(userId)

	for attempt = 1, CurrencyConfig.SAVE_RETRIES do
		local success, err = pcall(function()
			getStore():SetAsync(key, coins)
		end)

		if success then
			return true
		end

		warn("[CurrencyDataStore] SaveById attempt", attempt, "failed for UserId", userId, ":", err)

		if attempt < CurrencyConfig.SAVE_RETRIES then
			task.wait(CurrencyConfig.RETRY_DELAY)
		end
	end

	warn("[CurrencyDataStore] All SaveById attempts exhausted for UserId", userId)
	return false
end

return CurrencyDataStore
