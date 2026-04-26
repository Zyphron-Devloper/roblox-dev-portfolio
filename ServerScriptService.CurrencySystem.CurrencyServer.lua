--[[
	CurrencyServer (Script)
	Location: ServerScriptService > CurrencySystem > CurrencyServer
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CurrencyConfig = require(ReplicatedStorage.Modules.CurrencyConfig)
local CurrencyService = require(script.Parent.CurrencyService)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RequestAddCoins = Remotes:WaitForChild("RequestAddCoins")
local RequestRemoveCoins = Remotes:WaitForChild("RequestRemoveCoins")
local RequestGetCoins = Remotes:WaitForChild("RequestGetCoins")

-- Player lifecycle
Players.PlayerAdded:Connect(function(player: Player)
	CurrencyService.InitPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player: Player)
	CurrencyService.SavePlayer(player)
	CurrencyService.CleanupPlayer(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		CurrencyService.InitPlayer(player)
	end)
end

-- BindToClose: emergency save
game:BindToClose(function()
	CurrencyService.SaveAllPlayers()
	if not game:GetService("RunService"):IsStudio() then
		task.wait(2)
	end
end)

-- Autosave loop
task.spawn(function()
	while true do
		task.wait(CurrencyConfig.AUTOSAVE_INTERVAL)
		for _, player in ipairs(Players:GetPlayers()) do
			task.spawn(function()
				CurrencyService.SavePlayer(player)
			end)
		end
	end
end)

-- RequestAddCoins (TESTING ONLY - real rewards from server logic)
RequestAddCoins.OnServerEvent:Connect(function(player: Player, amount: unknown)
	if typeof(amount) ~= "number" then return end
	amount = math.clamp(math.floor(amount :: number), 1, CurrencyConfig.MAX_TEST_ADD)
	CurrencyService.AddCoins(player, amount)
end)

-- RequestRemoveCoins (TESTING ONLY)
RequestRemoveCoins.OnServerEvent:Connect(function(player: Player, amount: unknown)
	if typeof(amount) ~= "number" then return end
	amount = math.clamp(math.floor(amount :: number), 1, CurrencyConfig.MAX_TEST_REMOVE)
	CurrencyService.RemoveCoins(player, amount)
end)

-- RequestGetCoins (RemoteFunction)
RequestGetCoins.OnServerInvoke = function(player: Player): number
	return CurrencyService.GetCoins(player) or CurrencyConfig.DEFAULT_COINS
end

-- ═══════════════════════════════════════════════════════
-- PROCESS RECEIPTS (Developer Product purchases)
-- ═══════════════════════════════════════════════════════

local MarketplaceService = game:GetService("MarketplaceService")

-- Build reverse lookup: productId → coins
local productToCoins = {}
for _, pack in ipairs(CurrencyConfig.COIN_PACKS) do
	productToCoins[pack.productId] = pack.coins
end

MarketplaceService.ProcessReceipt = function(receiptInfo)
	local plr = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not plr then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local coins = productToCoins[receiptInfo.ProductId]
	if coins then
		local success = CurrencyService.AddCoins(plr, coins)
		if success then
			print("[CurrencyServer] Granted", coins, "coins to", plr.Name)
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end

print("[CurrencyServer] Currency system initialised")
