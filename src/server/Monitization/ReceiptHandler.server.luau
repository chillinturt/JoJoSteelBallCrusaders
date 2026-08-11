-- ReceiptHandler.server.luau
-- Handles MarketplaceService.ProcessReceipt for developer products.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerData = require(ServerScriptService.DataSaving.PlayerData)
local XPSystem = require(ServerScriptService.DataSaving.XPSystem)
local InventoryManager = require(ServerScriptService.DataSaving.InventoryManager)

local XP_MULT_PRODUCT = 3610724195
local STAND_ARROW_PRODUCT = 3610724240
local ROKAKAKA_PRODUCT = 3610724270

-- ProductId -> function(player) run once per successful purchase.
local PRODUCT_HANDLERS = {
	[XP_MULT_PRODUCT] = function(player)
		XPSystem.GrantXPBoost(player)
	end,

	[STAND_ARROW_PRODUCT] = function(player)
		-- Purchases must never be lost/denied due to a full inventory.
		InventoryManager.AddItem(player, "StandArrow", 5, true)
	end,

	[ROKAKAKA_PRODUCT] = function(player)
		InventoryManager.AddItem(player, "Rokakaka", 5, true)
	end,
}

local function processReceipt(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		-- Player left before purchase completed; retry later.
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local data = PlayerData.GetData(player)
	if not data then
		-- Profile hasn't finished loading yet; retry later.
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	data.PurchaseHistory = data.PurchaseHistory or {}

	-- Already granted (e.g. Roblox retried after we returned Granted
	-- but before it recorded that) - just confirm again.
	if data.PurchaseHistory[receiptInfo.PurchaseId] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local handler = PRODUCT_HANDLERS[receiptInfo.ProductId]
	if not handler then
		warn("[ReceiptHandler] No handler for ProductId", receiptInfo.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local ok, err = pcall(handler, player)
	if not ok then
		warn("[ReceiptHandler] Failed to grant product", receiptInfo.ProductId, err)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	data.PurchaseHistory[receiptInfo.PurchaseId] = true

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

MarketplaceService.ProcessReceipt = processReceipt
