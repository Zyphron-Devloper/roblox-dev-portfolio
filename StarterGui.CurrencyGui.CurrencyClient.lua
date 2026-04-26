--[[
	CurrencyClient (LocalScript)
	Location: StarterGui > CurrencyGui > CurrencyClient

	Client-side controller for the currency UI.

	Responsibilities:
	  - Update CoinsLabel when CoinsUpdated fires.
	  - Fetch initial coin count on load.
	  - Handle Buy button: opens a beautiful shop UI with
	    all coin packs from CurrencyConfig.COIN_PACKS.

	IMPORTANT:
	  Coins are NEVER granted from the client. The Buy button
	  only calls MarketplaceService:PromptProductPurchase().
	  Actual coin rewards must happen in a server-side
	  ProcessReceipt callback.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local CurrencyConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("CurrencyConfig"))

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CoinsUpdated = Remotes:WaitForChild("CoinsUpdated")
local RequestGetCoins = Remotes:WaitForChild("RequestGetCoins")

-- UI references
local gui = script.Parent
local mainFrame = gui:WaitForChild("MainFrame")
local coinsLabel = mainFrame:WaitForChild("CoinsLabel")
local buyButton = mainFrame:WaitForChild("BuyButton")

-- ═══════════════════════════════════════════════════════
-- BUY BUTTON SETUP
-- ═══════════════════════════════════════════════════════

buyButton.Text = "Shop"
buyButton.BackgroundColor3 = Color3.fromRGB(60, 90, 220)

-- ═══════════════════════════════════════════════════════
-- COIN DISPLAY
-- ═══════════════════════════════════════════════════════

local function flashLabel()
	local tween = TweenService:Create(coinsLabel, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		TextSize = 26
	})
	tween:Play()
	tween.Completed:Wait()
	TweenService:Create(coinsLabel, TweenInfo.new(0.15), {
		TextSize = 22
	}):Play()
end

local function updateDisplay(coins)
	coinsLabel.Text = "Coins: " .. tostring(coins)
	task.spawn(flashLabel)
end

CoinsUpdated.OnClientEvent:Connect(function(coins)
	updateDisplay(coins)
end)

task.spawn(function()
	local coins = RequestGetCoins:InvokeServer()
	if typeof(coins) == "number" then
		updateDisplay(coins)
	end
end)

-- ═══════════════════════════════════════════════════════
-- SHOP UI
-- ═══════════════════════════════════════════════════════

local PACK_THEMES = {
	{ top = Color3.fromRGB(70, 75, 95),   stroke = Color3.fromRGB(130, 135, 155), tag = "STARTER" },
	{ top = Color3.fromRGB(35, 115, 65),  stroke = Color3.fromRGB(70, 200, 110),  tag = "BASIC" },
	{ top = Color3.fromRGB(35, 75, 175),  stroke = Color3.fromRGB(75, 130, 230),  tag = "POPULAR" },
	{ top = Color3.fromRGB(115, 45, 175), stroke = Color3.fromRGB(175, 95, 245),  tag = "GREAT VALUE" },
	{ top = Color3.fromRGB(195, 145, 25), stroke = Color3.fromRGB(255, 210, 55),  tag = "BEST DEAL" },
	{ top = Color3.fromRGB(195, 35, 35),  stroke = Color3.fromRGB(255, 75, 75),   tag = "MEGA PACK" },
}

local shopOverlay = nil

local function closeShop()
	if not shopOverlay then return end
	local sf = shopOverlay:FindFirstChild("ShopFrame")
	if sf then
		local t = TweenService:Create(sf, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, 0),
			Position = UDim2.new(0.5, 0, 0.5, 0),
		})
		t:Play()
		t.Completed:Wait()
	end
	shopOverlay:Destroy()
	shopOverlay = nil
end

local function openShop()
	if shopOverlay then return end

	-- Overlay
	local overlay = Instance.new("Frame")
	overlay.Name = "ShopOverlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.35
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 50
	overlay.Parent = gui
	shopOverlay = overlay

	-- Clickable overlay background to close
	local bgBtn = Instance.new("TextButton")
	bgBtn.Size = UDim2.new(1, 0, 1, 0)
	bgBtn.BackgroundTransparency = 1
	bgBtn.Text = ""
	bgBtn.ZIndex = 50
	bgBtn.Parent = overlay
	bgBtn.MouseButton1Click:Connect(closeShop)

	-- Shop panel
	local shopFrame = Instance.new("Frame")
	shopFrame.Name = "ShopFrame"
	shopFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	shopFrame.Size = UDim2.new(0, 520, 0, 430)
	shopFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	shopFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 32)
	shopFrame.BorderSizePixel = 0
	shopFrame.ZIndex = 51
	shopFrame.Parent = overlay

	local corner = Instance.new("UICorner", shopFrame)
	corner.CornerRadius = UDim.new(0, 14)

	local stroke = Instance.new("UIStroke", shopFrame)
	stroke.Thickness = 2
	local grad = Instance.new("UIGradient", stroke)
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 215, 0)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 160, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 215, 0)),
	})

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -60, 0, 50)
	title.Position = UDim2.new(0, 20, 0, 5)
	title.BackgroundTransparency = 1
	title.Text = "Coin Shop"
	title.TextColor3 = Color3.fromRGB(255, 215, 0)
	title.TextSize = 26
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = 52
	title.Parent = shopFrame

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 34, 0, 34)
	closeBtn.Position = UDim2.new(1, -44, 0, 8)
	closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.TextSize = 16
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.ZIndex = 53
	closeBtn.BorderSizePixel = 0
	closeBtn.Parent = shopFrame
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
	closeBtn.MouseButton1Click:Connect(closeShop)

	-- Hover on close button
	closeBtn.MouseEnter:Connect(function()
		TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(220, 60, 60)}):Play()
	end)
	closeBtn.MouseLeave:Connect(function()
		TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(180, 40, 40)}):Play()
	end)

	-- Grid container
	local grid = Instance.new("Frame")
	grid.Size = UDim2.new(1, -40, 1, -70)
	grid.Position = UDim2.new(0, 20, 0, 60)
	grid.BackgroundTransparency = 1
	grid.ZIndex = 51
	grid.Parent = shopFrame

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0, 148, 0, 165)
	gridLayout.CellPadding = UDim2.new(0, 12, 0, 12)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	gridLayout.Parent = grid

	-- Create pack cards
	local packs = CurrencyConfig.COIN_PACKS
	for i, pack in ipairs(packs) do
		local theme = PACK_THEMES[i] or PACK_THEMES[1]

		local card = Instance.new("Frame")
		card.Name = "Pack_" .. pack.coins
		card.BackgroundColor3 = theme.top
		card.BorderSizePixel = 0
		card.ZIndex = 52
		card.LayoutOrder = i
		card.Parent = grid
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

		local cs = Instance.new("UIStroke", card)
		cs.Thickness = 1.5
		cs.Color = theme.stroke

		-- Tag label (e.g. "BEST DEAL")
		local tagLbl = Instance.new("TextLabel")
		tagLbl.Size = UDim2.new(1, 0, 0, 18)
		tagLbl.Position = UDim2.new(0, 0, 0, 6)
		tagLbl.BackgroundTransparency = 1
		tagLbl.Text = theme.tag
		tagLbl.TextColor3 = theme.stroke
		tagLbl.TextSize = 10
		tagLbl.Font = Enum.Font.GothamBold
		tagLbl.ZIndex = 53
		tagLbl.Parent = card

		-- Coin amount
		local amtLbl = Instance.new("TextLabel")
		amtLbl.Size = UDim2.new(1, 0, 0, 40)
		amtLbl.Position = UDim2.new(0, 0, 0, 30)
		amtLbl.BackgroundTransparency = 1
		amtLbl.Text = tostring(pack.coins)
		amtLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		amtLbl.TextSize = 34
		amtLbl.Font = Enum.Font.GothamBold
		amtLbl.ZIndex = 53
		amtLbl.Parent = card

		-- "Coins" sub-label
		local subLbl = Instance.new("TextLabel")
		subLbl.Size = UDim2.new(1, 0, 0, 20)
		subLbl.Position = UDim2.new(0, 0, 0, 68)
		subLbl.BackgroundTransparency = 1
		subLbl.Text = "Coins"
		subLbl.TextColor3 = Color3.fromRGB(200, 200, 210)
		subLbl.TextSize = 14
		subLbl.Font = Enum.Font.Gotham
		subLbl.ZIndex = 53
		subLbl.Parent = card

		-- Buy button inside card
		-- If productId is nil, show "Coming Soon" (greyed out, disabled).
		-- If productId is set, show "BUY" (gold, clickable).
		local hasProduct = (pack.productId ~= nil and typeof(pack.productId) == "number")

		local packBtn = Instance.new("TextButton")
		packBtn.Size = UDim2.new(0.8, 0, 0, 32)
		packBtn.Position = UDim2.new(0.1, 0, 1, -42)
		packBtn.AnchorPoint = Vector2.new(0, 0)
		packBtn.TextSize = 14
		packBtn.Font = Enum.Font.GothamBold
		packBtn.ZIndex = 53
		packBtn.BorderSizePixel = 0
		packBtn.Parent = card
		Instance.new("UICorner", packBtn).CornerRadius = UDim.new(0, 6)

		if hasProduct then
			-- Active buy button (gold)
			packBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
			packBtn.Text = "BUY"
			packBtn.TextColor3 = Color3.fromRGB(25, 25, 25)

			local baseBtnColor = Color3.fromRGB(255, 215, 0)
			local hoverBtnColor = Color3.fromRGB(255, 235, 80)
			packBtn.MouseEnter:Connect(function()
				TweenService:Create(packBtn, TweenInfo.new(0.15), {BackgroundColor3 = hoverBtnColor}):Play()
			end)
			packBtn.MouseLeave:Connect(function()
				TweenService:Create(packBtn, TweenInfo.new(0.15), {BackgroundColor3 = baseBtnColor}):Play()
			end)

			packBtn.MouseButton1Click:Connect(function()
				MarketplaceService:PromptProductPurchase(player, pack.productId)
			end)
		else
			-- Disabled "Coming Soon" button (greyed out)
			packBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
			packBtn.Text = "Coming Soon"
			packBtn.TextColor3 = Color3.fromRGB(140, 140, 150)
			packBtn.AutoButtonColor = false
		end
	end

	-- Open animation
	shopFrame.Size = UDim2.new(0, 0, 0, 0)
	TweenService:Create(shopFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 520, 0, 430),
	}):Play()
end

-- ═══════════════════════════════════════════════════════
-- BUY BUTTON CLICK → OPEN SHOP
-- ═══════════════════════════════════════════════════════

-- Hover effects on main Buy/Shop button
local baseColor = Color3.fromRGB(60, 90, 220)
local hoverColor = Color3.fromRGB(80, 110, 255)

buyButton.MouseEnter:Connect(function()
	TweenService:Create(buyButton, TweenInfo.new(0.15), {BackgroundColor3 = hoverColor}):Play()
end)
buyButton.MouseLeave:Connect(function()
	TweenService:Create(buyButton, TweenInfo.new(0.15), {BackgroundColor3 = baseColor}):Play()
end)

buyButton.MouseButton1Click:Connect(openShop)

print("[CurrencyClient] UI controller ready")
