--!strict

--[[
	BuyPrompt (design: the `buyOpen` dialog in frames 5b / 5d / 5f)

	Our confirmation step before Roblox's own purchase flow: item tint, title
	("Buy item" / "Buy N items"), what's being bought, the price (or Free),
	Cancel / Buy. It never imitates Roblox's purchase UI — the line under the
	price says Roblox confirms next, and `onConfirm` hands off to Roblox's
	real prompt (PurchaseController).

	While Roblox's prompt is up the Buy button waits. If the purchase is
	cancelled or fails (or only part of it went through), the dialog stays
	with the reason in place of the note, Buy becomes Try again and Cancel
	becomes Close. A full success closes it (Hud).

	Dims the screen behind it and swallows input; tapping the dimmed area
	cancels. Rises in / drops out with a fade.

	Props:
		itemIds: { number }?   unowned items to buy; nil = closed
		status: Status?        nil = not sent yet; else waiting or the outcome
		onCancel: () -> ()
		onConfirm: (itemIds: { number }) -> ()
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local views = script.Parent
local components = views:WaitForChild("components")
local hooks = views:WaitForChild("hooks")
local Tokens = require(views:WaitForChild("Tokens"))
local Press = require(views:WaitForChild("Press"))
local useSkin = require(hooks:WaitForChild("useSkin"))
local useTransition = require(hooks:WaitForChild("useTransition"))
local PillButton = require(components:WaitForChild("PillButton"))
local GlassPanel = require(components:WaitForChild("GlassPanel"))
local Icon = require(components:WaitForChild("Icon"))
local ShadowText = require(components:WaitForChild("ShadowText"))
local Parts = require(views:WaitForChild("screens"):WaitForChild("Parts"))
local PlaceholderData = require(views:WaitForChild("screens"):WaitForChild("PlaceholderData"))

local e = React.createElement

export type Status = {
	state: "waiting" | "done" | "cancelled" | "failed",
	reason: string,
}

local NOTE = "You'll confirm the purchase with Roblox next."
local WAITING_NOTE = "Confirm the purchase in Roblox's window."
local PROBLEM = Color3.fromHex("#ff9a8a") -- the reason line when it didn't all go through

local WIDTH = 440
local HEIGHT = 222
local MARGIN = 12

local function Dialog(props: {
	itemIds: { number },
	status: Status?,
	t: any,
	onCancel: () -> (),
	onConfirm: (ids: { number }) -> (),
})
	local skin = useSkin()
	local items = {}
	local total = 0
	for _, id in props.itemIds do
		local item = PlaceholderData.item(id)
		table.insert(items, item)
		total += item.price
	end
	local single = #items == 1
	local names = {}
	for _, item in items do
		table.insert(names, item.name)
	end
	local title = if single then "Buy item" else "Buy " .. #items .. " items"
	local text = if single then "Would you like to buy " .. items[1].name .. "?" else table.concat(names, ", ")
	local margin = skin.px(MARGIN)
	local thumb = skin.px(84)
	local status = props.status
	local waiting = status ~= nil and status.state == "waiting"
	local outcome = status ~= nil and not waiting -- an answer came back with a reason
	local note = if waiting then WAITING_NOTE elseif outcome and status.reason ~= "" then status.reason else NOTE
	local buyLabel = if waiting
		then "Waiting for Roblox…"
		elseif outcome then "Try again"
		elseif total > 0 then "Buy · " .. total
		else "Get free"

	return e("TextButton", {
		Name = "BuyPrompt",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Tokens.color.black,
		BackgroundTransparency = props.t:map(function(t: number)
			return 1 - 0.5 * math.clamp(t, 0, 1)
		end),
		AutoButtonColor = false,
		Text = "",
		ZIndex = 40,
		[React.Event.InputBegan] = Press.began(props.onCancel), -- tap outside to cancel
		[React.Event.Activated] = Press.activated(props.onCancel),
	}, {
		Dialog = e("CanvasGroup", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = props.t:map(function(t: number)
				return UDim2.new(0.5, 0, 0.5, (1 - t) * skin.px(Tokens.motion.promptRise))
			end),
			Size = UDim2.fromOffset(skin.px(WIDTH) + margin * 2, skin.px(HEIGHT) + margin * 2),
			GroupTransparency = props.t:map(function(t: number)
				return 1 - math.clamp(t, 0, 1)
			end),
			BackgroundTransparency = 1,
			ZIndex = 41,
		}, {
			Margin = e("UIPadding", {
				PaddingTop = UDim.new(0, margin),
				PaddingBottom = UDim.new(0, margin),
				PaddingLeft = UDim.new(0, margin),
				PaddingRight = UDim.new(0, margin),
			}),
			-- Swallow taps on the dialog itself so they don't cancel.
			Block = e("TextButton", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = "",
				AutoButtonColor = false,
				ZIndex = 0, -- beneath the panel, or it eats the buttons' taps
			}),
			-- Dense glass: a modal must not show the controls behind it through itself.
			Panel = e(GlassPanel, {
				variant = "bar",
				cornerRadius = Tokens.radius.sidePanel,
				shadow = true,
			}, {
				Padding = e("UIPadding", {
					PaddingTop = UDim.new(0, skin.px(18)),
					PaddingBottom = UDim.new(0, skin.px(18)),
					PaddingLeft = UDim.new(0, skin.px(18)),
					PaddingRight = UDim.new(0, skin.px(18)),
				}),
				Thumb = e(Parts.Thumb, {
					colour = Parts.swatch(items[1].colour),
					image = Parts.image(items[1]),
					radius = 16,
					size = UDim2.fromOffset(thumb, thumb),
				}),
				Info = e("Frame", {
					Position = UDim2.fromOffset(thumb + skin.px(16), 0),
					Size = UDim2.new(1, -(thumb + skin.px(16)), 0, thumb + skin.px(30)),
					BackgroundTransparency = 1,
				}, {
					Layout = e("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, skin.px(6)) }),
					Title = e(ShadowText, { text = title, style = { size = 20, weight = 900 }, layoutOrder = 1 }),
					Text = e("TextLabel", {
						Size = UDim2.new(1, 0, 0, skin.textPx(14) * 2 + skin.px(4)),
						BackgroundTransparency = 1,
						Text = text,
						TextColor3 = Tokens.color.white,
						TextTransparency = Tokens.alpha.textSoft,
						TextSize = skin.textPx(14),
						FontFace = Tokens.font(700),
						TextWrapped = true,
						TextTruncate = Enum.TextTruncate.AtEnd,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextYAlignment = Enum.TextYAlignment.Top,
						LayoutOrder = 2,
					}),
					Price = e("Frame", {
						Size = UDim2.new(1, 0, 0, skin.px(26)),
						BackgroundTransparency = 1,
						LayoutOrder = 3,
					}, {
						Layout = e("UIListLayout", {
							FillDirection = Enum.FillDirection.Horizontal,
							VerticalAlignment = Enum.VerticalAlignment.Center,
							SortOrder = Enum.SortOrder.LayoutOrder,
							Padding = UDim.new(0, skin.px(4)),
						}),
						Amount = e(ShadowText, {
							text = if total > 0 then Tokens.robux(total) else "Free",
							style = { size = 22, weight = 900 },
							color = if total > 0 then Tokens.color.accentText else Color3.fromHex("#9be37a"),
							shadow = false,
							layoutOrder = 2,
						}),
					}),
				}),
				Note = e("TextLabel", {
					AnchorPoint = Vector2.new(0, 1),
					Position = UDim2.new(0, 0, 1, -skin.px(Tokens.size.ctaHeight + 12)),
					Size = UDim2.new(1, 0, 0, skin.px(18)),
					BackgroundTransparency = 1,
					Text = note,
					TextColor3 = if outcome then PROBLEM else Tokens.color.white,
					TextTransparency = if outcome then 0 else Tokens.alpha.textDim,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextSize = skin.textPx(12.5),
					FontFace = Tokens.font(700),
					TextXAlignment = Enum.TextXAlignment.Left,
				}),
				Buttons = e("Frame", {
					AnchorPoint = Vector2.new(0, 1),
					Position = UDim2.fromScale(0, 1),
					Size = UDim2.new(1, 0, 0, skin.px(Tokens.size.ctaHeight)),
					BackgroundTransparency = 1,
				}, {
					Cancel = e(PillButton, {
						variant = "pill",
						size = Tokens.size.ctaHeight,
						width = 150,
						label = if outcome then "Close" else "Cancel",
						sound = "back",
						onActivated = props.onCancel,
					}),
					Buy = e(PillButton, {
						variant = "pill",
						size = Tokens.size.ctaHeight,
						width = 220,
						icon = "shopping_basket",
						iconSize = 18,
						label = buyLabel,
						active = true,
						disabled = waiting,
						sound = false, -- the purchase result plays its own sound
						anchorPoint = Vector2.new(1, 0),
						position = UDim2.fromScale(1, 0),
						onActivated = function()
							props.onConfirm(props.itemIds)
						end,
					}),
				}),
			}),
		}),
	})
end

local function BuyPrompt(props: {
	itemIds: { number }?,
	status: Status?,
	onCancel: () -> (),
	onConfirm: (ids: { number }) -> (),
})
	-- Keep the last item list so the dialog still has content while it leaves.
	local lastIds = React.useRef(nil :: { number }?)
	if props.itemIds then
		lastIds.current = props.itemIds
	end

	local transitions = useTransition(props.itemIds ~= nil, {
		from = { t = 0 },
		enter = { t = 1 },
		leave = { t = 0 },
		config = Tokens.spring.promptIn,
		leaveConfig = Tokens.spring.promptOut,
	})

	local children: { [string]: any } = {}
	for _, transition in transitions do
		local ids = props.itemIds or lastIds.current
		if ids then
			children["Prompt" .. transition.key] = e(Dialog, {
				itemIds = ids,
				status = props.status,
				t = transition.springProps.t,
				onCancel = props.onCancel,
				onConfirm = props.onConfirm,
			})
		end
	end
	return e(React.Fragment, nil, children)
end

return BuyPrompt
