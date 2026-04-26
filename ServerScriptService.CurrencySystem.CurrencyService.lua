--[[
	CurrencyService (ModuleScript)
	Location: ServerScriptService > CurrencySystem > CurrencyService

	The authoritative server-side currency manager.
	All coin mutations flow through this module.

	Features:
	  • Server-authoritative – never trusts the client.
	  • Validates every input (player, amount, type).
	  • Clamps coins to [MIN_COINS, MAX_COINS].
	  • Automatically updates leaderstats.
	  • Fires CoinsUpdated RemoteEvent on every change.

	Designed to be imported by CurrencyServer and any future
	server-side systems (shops, rewards, daily bonuses, etc.).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CurrencyConfig = require(ReplicatedStorage.Modules.CurrencyConfig)
local CurrencyDataStore = require(script.Parent.CurrencyDataStore)

-- Remote references
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CoinsUpdated = Remotes:WaitForChild("CoinsUpdated")

-- ═══════════════════════════════════════════════════════
-- INTERNAL STATE
-- ═══════════════════════════════════════════════════════

-- In-memory coin cache. Keyed by Player (not UserId) so
-- entries are automatically eligible for GC after cleanup.
local playerCoins: { [Player]: number } = {}

local CurrencyService = {}

-- ═══════════════════════════════════════════════════════
-- PRIVATE HELPERS
-- ═══════════════════════════════════════════════════════

--- Clamp a value between MIN and MAX coins.
local function clampCoins(value: number): number
	return math.clamp(value, CurrencyConfig.MIN_COINS, CurrencyConfig.MAX_COINS)
end

--- Push the current coin count into the player's leaderstats
--- IntValue AND fire the client-facing remote.
local function broadcastUpdate(player: Player, coins: number)
	-- Update leaderstats
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coinValue = leaderstats:FindFirstChild("Coins")
		if coinValue then
			coinValue.Value = coins
		end
	end

	-- Notify the owning client
	CoinsUpdated:FireClient(player, coins)
end

-- ═══════════════════════════════════════════════════════
-- PUBLIC API
-- ═══════════════════════════════════════════════════════

--[[
	InitPlayer(player: Player)

	Called once when the player joins.
	  1. Creates leaderstats + Coins IntValue.
	  2. Loads saved coins from the DataStore.
	  3. Caches the value in memory.
	  4. Broadcasts the initial value.
]]
function CurrencyService.InitPlayer(player: Player)
	-- Create leaderstats folder
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local coinsValue = Instance.new("IntValue")
	coinsValue.Name = "Coins"
	coinsValue.Value = CurrencyConfig.DEFAULT_COINS
	coinsValue.Parent = leaderstats

	-- Load persisted coins (non-blocking via task.spawn is
	-- NOT needed here because we want the value ready before
	-- the client GUI requests it).
	local savedCoins = CurrencyDataStore.LoadCoins(player)
	local coins = clampCoins(savedCoins)

	playerCoins[player] = coins
	broadcastUpdate(player, coins)
end

--[[
	GetCoins(player: Player) -> number?

	Returns the cached coin count, or nil if the player
	hasn't been initialised yet.
]]
function CurrencyService.GetCoins(player: Player): number?
	return playerCoins[player]
end

--[[
	AddCoins(player: Player, amount: number) -> boolean

	Adds `amount` coins (must be > 0). Returns false if the
	inputs are invalid.
]]
function CurrencyService.AddCoins(player: Player, amount: number): boolean
	if typeof(amount) ~= "number" or amount ~= amount then return false end -- NaN guard
	amount = math.floor(amount)
	if amount <= 0 then return false end

	local current = playerCoins[player]
	if current == nil then return false end

	local newCoins = clampCoins(current + amount)
	playerCoins[player] = newCoins
	broadcastUpdate(player, newCoins)
	return true
end

--[[
	RemoveCoins(player: Player, amount: number) -> boolean

	Removes `amount` coins (must be > 0). Returns false if
	the player doesn't have enough coins or inputs are bad.
]]
function CurrencyService.RemoveCoins(player: Player, amount: number): boolean
	if typeof(amount) ~= "number" or amount ~= amount then return false end
	amount = math.floor(amount)
	if amount <= 0 then return false end

	local current = playerCoins[player]
	if current == nil then return false end

	if current < amount then
		return false -- Insufficient funds
	end

	local newCoins = clampCoins(current - amount)
	playerCoins[player] = newCoins
	broadcastUpdate(player, newCoins)
	return true
end

--[[
	SetCoins(player: Player, amount: number) -> boolean

	Directly sets the player's coins to `amount` (clamped).
	Useful for admin commands, rewards, or resets.
]]
function CurrencyService.SetCoins(player: Player, amount: number): boolean
	if typeof(amount) ~= "number" or amount ~= amount then return false end
	amount = math.floor(amount)

	local current = playerCoins[player]
	if current == nil then return false end

	local newCoins = clampCoins(amount)
	playerCoins[player] = newCoins
	broadcastUpdate(player, newCoins)
	return true
end

--[[
	SavePlayer(player: Player) -> boolean

	Persists the player's in-memory coins to the DataStore.
	Returns true on success.
]]
function CurrencyService.SavePlayer(player: Player): boolean
	local coins = playerCoins[player]
	if coins == nil then return false end

	return CurrencyDataStore.SaveCoins(player, coins)
end

--[[
	SavePlayerById(userId: number) -> boolean

	Used during BindToClose when the Player object might be
	gone. Looks up cached coins by scanning the table.
]]
function CurrencyService.SaveAllPlayers()
	for player, coins in pairs(playerCoins) do
		task.spawn(function()
			CurrencyDataStore.SaveCoinsById(player.UserId, coins)
		end)
	end
end

--[[
	CleanupPlayer(player: Player)

	Removes the player from the in-memory cache.
	Must be called AFTER SavePlayer in the PlayerRemoving
	handler.
]]
function CurrencyService.CleanupPlayer(player: Player)
	playerCoins[player] = nil
end

--[[
	GetAllPlayerCoins() -> { [Player]: number }

	Exposes the full cache. Used by the autosave loop.
]]
function CurrencyService.GetAllPlayerCoins(): { [Player]: number }
	return playerCoins
end

return CurrencyService
