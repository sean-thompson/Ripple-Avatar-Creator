--!strict

--[[
	PurchaseView (client)

	Roblox tells only the client how a bulk purchase prompt ended
	(MarketplaceService.PromptBulkPurchaseFinished), but only the server can
	open one. This passes the outcome on to PurchaseController.Finished: the
	overall status ("Completed" / "Aborted" / "Error"), Robux spent and each
	item's status. The server checks ownership itself; the statuses only pick
	the wording of the result.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage:WaitForChild("Network"))

-- Enum items arrive as EnumItems (or, defensively, strings): just the name.
local function nameOf(value: any): string
	if typeof(value) == "EnumItem" then
		return value.Name
	end
	local text = tostring(value)
	return text:match("([^%.]+)$") or text
end

MarketplaceService.PromptBulkPurchaseFinished:Connect(function(...: any)
	-- (player, status, results); tolerate the player being left off.
	local status, results = ...
	if typeof(status) == "Instance" then
		status, results = select(2, ...)
	end
	local items = {}
	local robuxSpent = nil
	if type(results) == "table" then
		robuxSpent = if type(results.RobuxSpent) == "number" then results.RobuxSpent else nil
		for _, entry in results.Items or {} do
			if type(entry) == "table" then
				table.insert(items, {
					id = tostring(entry.id or entry.Id),
					type = nameOf(entry.type or entry.Type),
					status = nameOf(entry.status or entry.Status),
				})
			end
		end
	end
	Network.Intent.Purchase:FireServer(Network.Actions.Purchase.Finished, {
		status = nameOf(status),
		robuxSpent = robuxSpent,
		items = items,
	})
end)
