--[[
	Catálogo de emotes UGC
	LocalScript → StarterPlayer.StarterPlayerScripts

	Copia TODO este archivo a un LocalScript.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local AvatarEditorService = game:GetService("AvatarEditorService")
local RunService = game:GetService("RunService")

if RunService:IsServer() and not RunService:IsClient() then
	warn("[EmoteCatalog] Este archivo tiene que ser un LocalScript en StarterPlayerScripts.")
	return
end

local player = Players.LocalPlayer
if not player then
	warn("[EmoteCatalog] No hay LocalPlayer. Usa un LocalScript, no un Script de servidor.")
	return
end

local playerGui = player:WaitForChild("PlayerGui")

local COLORS = {
	Panel = Color3.fromRGB(10, 24, 18),
	Card = Color3.fromRGB(18, 42, 32),
	CardSelected = Color3.fromRGB(24, 58, 44),
	Inset = Color3.fromRGB(6, 14, 10),
	Text = Color3.fromRGB(245, 248, 246),
	Muted = Color3.fromRGB(168, 190, 178),
	Stroke = Color3.fromRGB(78, 148, 112),
	Selected = Color3.fromRGB(92, 210, 168),
	Cyan = Color3.fromRGB(42, 212, 224),
	CyanBtn = Color3.fromRGB(20, 138, 150),
	Red = Color3.fromRGB(192, 57, 57),
	White = Color3.fromRGB(255, 255, 255),
}

local FONT = Enum.Font.Gotham
local FONT_BOLD = Enum.Font.GothamBold
local FONT_MED = Enum.Font.GothamMedium
local COLUMNS = 3

-- IDs, nombres y precios reales del Marketplace (EmoteAnimation).
local FALLBACK_EMOTES = {
	{id=135669863262978, name="Ratatata [MOCAP]", price=55},
	{id=138274472194739, name="🔥 Tubo Dance", price=55},
	{id=99967539604568, name="Kasane Teto [R6]", price=55},
	{id=105983696629099, name="♡ Sitting Cute Pose", price=55},
	{id=128427568238614, name="scuba dance!! 🤿", price=55},
	{id=124630114425909, name="Chinese Cat Dance 🐈 ♡", price=55},
	{id=140419068803831, name="♡ cute bowing pose", price=55},
	{id=135733828012519, name="♡ cute little figurine stand pose", price=55},
	{id=80996014547344, name="🔥 I Got The Feeling [BEST] 🔥", price=55},
	{id=87682285023546, name="♡ cute kitty meow pose", price=55},
	{id=105919939077031, name="♡ cute shy hands pose", price=55},
	{id=81290863225182, name="Step Yokoyure", price=55},
	{id=79908632555947, name="[OG] Needy Plancheey Bounce", price=55},
	{id=112487392936070, name="FAKE MM2 Death", price=55},
	{id=85539118388694, name="Move Your Body", price=55},
	{id=128361681108488, name="MM2 Sit", price=55},
	{id=92376636301266, name="Getting Natty", price=55},
	{id=102156359502324, name="BLACKPINK - I Bring the Pain Like…", price=55},
	{id=129318794208523, name="Cali Pose 3.0", price=60},
	{id=89422843608956, name="BLACKPINK - Shut Down", price=55},
	{id=134186568925294, name="♡ Kawaii Heart Pose", price=55},
	{id=83486899998763, name="Neck Rolling", price=55},
	{id=90702753520455, name="Easy", price=55},
	{id=121156272689339, name="🙏 Muay Thai Wai Kru Ritual, Standing 🥊", price=55},
	{id=116014955957687, name="Shootin' Hoops", price=55},
	{id=124669321350123, name="🐾 cutiecat kawaii kitty bounce", price=55},
	{id=131547710296022, name="SaWaDiKa - LISA", price=55},
	{id=131605495388312, name="Worm Cosmic Spiral Endless", price=55},
	{id=124687896624185, name="Prayer - Muslim Sujud ☪️🕋🤲🕌", price=55},
	{id=115247082615045, name="Creepy Spider 🕷️", price=55},
	{id=96649442187973, name="The Bass Dance - Trend", price=55},
	{id=122389262342400, name="Confident Baddie Profile Pose", price=55},
	{id=79500766652981, name="Jeyke Funk Dance", price=55},
	{id=135575670072680, name="Twisting Body 🌪️", price=55},
	{id=114276171614039, name="Jack In The Box", price=55},
	{id=114466050070275, name="JENNIE's Cute Sitting Profile Pose", price=60},
	{id=79795305221612, name="Floating Aura", price=55},
	{id=110553756436163, name="Helicopter", price=55},
	{id=83606297144428, name="Rat Dance", price=55},
	{id=134913783169182, name="Plane", price=55},
	{id=14353423348, name="Baby Queen - Bouncy Twirl", price=55},
	{id=85076031433488, name="Tank", price=55},
	{id=115407270129592, name="Car", price=55},
	{id=129668542320076, name="/e sit", price=55},
	{id=107498554725527, name="Fake MM2 Death", price=55},
	{id=73500261613116, name="Box", price=55},
	{id=15610015346, name="Yungblud Happier Jump", price=55},
	{id=84868707350198, name="Hide", price=55},
	{id=14353421343, name="Baby Queen - Face Frame", price=55},
	{id=3576823880, name="Point2", price=0, priceStatus="Free"},
	{id=3576968026, name="Shrug", price=0, priceStatus="Free"},
	{id=3576686446, name="Hello", price=0, priceStatus="Free"},
	{id=3360686498, name="Stadium", price=0, priceStatus="Free"},
	{id=3360689775, name="Salute", price=0, priceStatus="Free"},
	{id=3716636630, name="Monkey", price=55},
	{id=4646306583, name="Curtsy", price=55},
	{id=3360692915, name="Tilt", price=0, priceStatus="Free"},
	{id=3823158750, name="Godlike", price=80},
	{id=4849499887, name="Happy", price=55},
	{id=5915779043, name="Applaud", price=0, priceStatus="Free"},
	{id=4689362868, name="Sleep", price=55},
	{id=5104377791, name="Hero Landing", price=80},
	{id=3576717965, name="Shy", price=55},
	{id=5917570207, name="Floss Dance", price=80},
	{id=7466046574, name="Quiet Waves", price=110},
	{id=4272484885, name="Baby Dance", price=100},
}

local favorites = {}
local selectedId = nil
local showFavorites = false
local showPopular = false
local searchQuery = ""
local catalogPages = nil
local loadingPage = false
local searchToken = 0
local isOpen = true
local cardRefs = {}
local usingFallback = false
local fallbackCursor = 0
local playingTrack = nil
local playingId = nil
local savedAnimate = nil

local function create(className, props)
	local inst = Instance.new(className)
	if props then
		for key, value in pairs(props) do
			if key ~= "Parent" then
				inst[key] = value
			end
		end
		if props.Parent then
			inst.Parent = props.Parent
		end
	end
	return inst
end

local function corner(parent, px)
	return create("UICorner", { CornerRadius = UDim.new(0, px), Parent = parent })
end

local function stroke(parent, color, thickness, transparency)
	return create("UIStroke", {
		Color = color,
		Thickness = thickness,
		Transparency = transparency,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

local function pad(parent, t, r, b, l)
	return create("UIPadding", {
		PaddingTop = UDim.new(0, t),
		PaddingRight = UDim.new(0, r),
		PaddingBottom = UDim.new(0, b),
		PaddingLeft = UDim.new(0, l),
		Parent = parent,
	})
end

local function thumbUri(id)
	return "rbxthumb://type=Asset&id=" .. tostring(id) .. "&w=150&h=150"
end

local function formatPrice(item)
	if item.priceStatus == "Free" or item.price == 0 then
		return "Gratis"
	end
	if item.price == nil then
		return "—"
	end
	return tostring(item.price)
end

local function normalize(raw)
	local id = raw.Id or raw.id
	local name = raw.Name or raw.name
	if typeof(id) ~= "number" or typeof(name) ~= "string" or name == "" then
		return nil
	end
	local price = raw.Price or raw.price or raw.LowestPrice or raw.lowestPrice
	local status = raw.PriceStatus or raw.priceStatus
	if typeof(price) ~= "number" then
		price = nil
	end
	return {
		id = id,
		name = name,
		price = price,
		priceStatus = status,
	}
end

local gui = playerGui:FindFirstChild("UGCEmoteCatalog")
if gui then
	gui:Destroy()
end

gui = create("ScreenGui", {
	Name = "UGCEmoteCatalog",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 1000,
	Parent = playerGui,
})

local panel = create("Frame", {
	Name = "Panel",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -12, 0, 12),
	Size = UDim2.new(0, 332, 1, -24),
	BackgroundColor3 = COLORS.Panel,
	BackgroundTransparency = 0.22,
	BorderSizePixel = 0,
	Parent = gui,
})
corner(panel, 12)
stroke(panel, COLORS.Stroke, 1, 0.55)

create("UISizeConstraint", {
	MinSize = Vector2.new(260, 280),
	MaxSize = Vector2.new(380, 10000),
	Parent = panel,
})

local toolbar = create("Frame", {
	Name = "Toolbar",
	Position = UDim2.new(0, 0, 0, 0),
	Size = UDim2.new(1, 0, 0, 42),
	BackgroundTransparency = 1,
	Parent = panel,
})
pad(toolbar, 8, 8, 6, 8)

create("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = toolbar,
})

local searchHolder = create("Frame", {
	Name = "Search",
	LayoutOrder = 1,
	Size = UDim2.new(0, 110, 1, 0),
	BackgroundColor3 = COLORS.Inset,
	BackgroundTransparency = 0.15,
	BorderSizePixel = 0,
	Parent = toolbar,
})
corner(searchHolder, 7)
stroke(searchHolder, COLORS.Stroke, 1, 0.7)

create("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(0, 22, 1, 0),
	Text = "⌕",
	TextColor3 = COLORS.Muted,
	TextSize = 16,
	Font = FONT_BOLD,
	Parent = searchHolder,
})

local searchBox = create("TextBox", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 22, 0, 0),
	Size = UDim2.new(1, -26, 1, 0),
	ClearTextOnFocus = false,
	PlaceholderText = "Buscar...",
	PlaceholderColor3 = Color3.fromRGB(138, 163, 148),
	Text = "",
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = COLORS.Text,
	TextSize = 12,
	Font = FONT_MED,
	Parent = searchHolder,
})

local function makeIconButton(name, order, text, bg, parent)
	local btn = create("TextButton", {
		Name = name,
		LayoutOrder = order,
		Size = UDim2.new(0, 28, 0, 28),
		BackgroundColor3 = bg,
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
		Text = text,
		TextColor3 = COLORS.White,
		TextSize = 14,
		Font = FONT_BOLD,
		AutoButtonColor = true,
		Parent = parent,
	})
	corner(btn, 7)
	stroke(btn, COLORS.Stroke, 1, 0.7)
	return btn
end

local refreshBtn = makeIconButton("Refresh", 2, "↻", COLORS.Card, toolbar)
local favBtn = makeIconButton("Favorites", 3, "★", COLORS.Card, toolbar)

local popularBtn = create("TextButton", {
	Name = "Popular",
	LayoutOrder = 4,
	Size = UDim2.new(0, 72, 0, 28),
	BackgroundColor3 = COLORS.CyanBtn,
	BorderSizePixel = 0,
	Text = "Populares",
	TextColor3 = COLORS.White,
	TextSize = 11,
	Font = FONT_BOLD,
	AutoButtonColor = true,
	Parent = toolbar,
})
corner(popularBtn, 7)

local closeBtn = makeIconButton("Close", 5, "×", COLORS.Red, toolbar)
closeBtn.TextSize = 18

local gridWrap = create("ScrollingFrame", {
	Name = "GridWrap",
	Position = UDim2.new(0, 0, 0, 42),
	Size = UDim2.new(1, 0, 1, -42),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 4,
	ScrollBarImageColor3 = Color3.fromRGB(120, 190, 150),
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	Parent = panel,
})
pad(gridWrap, 2, 8, 8, 8)

local grid = create("Frame", {
	Name = "Grid",
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	Parent = gridWrap,
})

local gridLayout = create("UIGridLayout", {
	CellPadding = UDim2.new(0, 8, 0, 8),
	CellSize = UDim2.new(0, 96, 0, 148),
	FillDirection = Enum.FillDirection.Horizontal,
	FillDirectionMaxCells = COLUMNS,
	SortOrder = Enum.SortOrder.LayoutOrder,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	Parent = grid,
})

local emptyLabel = create("TextLabel", {
	Name = "Empty",
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -16, 0, 60),
	Position = UDim2.new(0, 8, 0, 24),
	Text = "",
	TextColor3 = COLORS.Muted,
	TextSize = 12,
	Font = FONT_MED,
	TextWrapped = true,
	Visible = false,
	ZIndex = 2,
	Parent = gridWrap,
})

local details = create("Frame", {
	Name = "Details",
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 0, 1, 0),
	Size = UDim2.new(1, 0, 0, 54),
	BackgroundColor3 = COLORS.Inset,
	BackgroundTransparency = 0.35,
	BorderSizePixel = 0,
	Visible = false,
	Parent = panel,
})
pad(details, 8, 10, 8, 10)

local detailsName = create("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -86, 0, 16),
	Text = "",
	TextColor3 = COLORS.White,
	TextSize = 12,
	Font = FONT_BOLD,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextTruncate = Enum.TextTruncate.AtEnd,
	Parent = details,
})

local idRow = create("Frame", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 0, 0, 20),
	Size = UDim2.new(1, -86, 0, 18),
	Parent = details,
})

create("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(0, 18, 1, 0),
	Text = "ID",
	TextColor3 = COLORS.Muted,
	TextSize = 9,
	Font = FONT_BOLD,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = idRow,
})

local idBox = create("TextBox", {
	BackgroundColor3 = COLORS.Inset,
	BackgroundTransparency = 0.2,
	Position = UDim2.new(0, 20, 0, 0),
	Size = UDim2.new(1, -20, 1, 0),
	ClearTextOnFocus = false,
	TextEditable = false,
	Text = "",
	TextColor3 = Color3.fromRGB(215, 238, 227),
	TextSize = 11,
	Font = FONT,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = idRow,
})
corner(idBox, 5)
stroke(idBox, COLORS.Stroke, 1, 0.7)

local copyBtn = create("TextButton", {
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, 0, 1, 0),
	Size = UDim2.new(0, 78, 0, 22),
	BackgroundColor3 = COLORS.Cyan,
	BackgroundTransparency = 0.82,
	BorderSizePixel = 0,
	Text = "Copiar ID",
	TextColor3 = COLORS.Cyan,
	TextSize = 10,
	Font = FONT_BOLD,
	AutoButtonColor = true,
	Parent = details,
})
corner(copyBtn, 6)
stroke(copyBtn, COLORS.Cyan, 1, 0.45)

local detailsPrice = create("TextLabel", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, 0, 0, 0),
	Size = UDim2.new(0, 78, 0, 16),
	BackgroundTransparency = 1,
	Text = "",
	TextColor3 = COLORS.White,
	TextSize = 11,
	Font = FONT_BOLD,
	TextXAlignment = Enum.TextXAlignment.Right,
	Parent = details,
})

local reopenBtn = create("TextButton", {
	Name = "Reopen",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -12, 0, 12),
	Size = UDim2.new(0, 92, 0, 32),
	BackgroundColor3 = COLORS.Panel,
	BackgroundTransparency = 0.22,
	BorderSizePixel = 0,
	Text = "  Emotes",
	TextColor3 = COLORS.White,
	TextSize = 13,
	Font = FONT_BOLD,
	Visible = false,
	AutoButtonColor = true,
	Parent = gui,
})
corner(reopenBtn, 9)
stroke(reopenBtn, COLORS.Stroke, 1, 0.55)

local function setButtonActive(btn, active, activeColor, idleColor)
	btn.BackgroundColor3 = active and activeColor or idleColor
	if btn == popularBtn then
		btn.TextColor3 = active and Color3.fromRGB(6, 33, 38) or COLORS.White
	end
end

local function resizeGrid()
	local width = math.max(1, grid.AbsoluteSize.X)
	local gap = 8
	local cell = math.floor((width - gap * (COLUMNS - 1)) / COLUMNS)
	if cell < 72 then
		cell = math.max(64, math.floor((width - gap) / 2))
		gridLayout.FillDirectionMaxCells = 2
	else
		gridLayout.FillDirectionMaxCells = COLUMNS
	end
	gridLayout.CellSize = UDim2.new(0, cell, 0, cell + 52)
end

local function layoutBody()
	local bottom = details.Visible and 54 or 0
	gridWrap.Size = UDim2.new(1, 0, 1, -(42 + bottom))
end

local function setOpen(open)
	isOpen = open
	panel.Visible = open
	reopenBtn.Visible = not open
end

local function highlight(id)
	selectedId = id
	for cardId, card in pairs(cardRefs) do
		local selected = cardId == id
		card.BackgroundColor3 = selected and COLORS.CardSelected or COLORS.Card
		local s = card:FindFirstChildOfClass("UIStroke")
		if s then
			s.Color = selected and COLORS.Selected or COLORS.Stroke
			s.Transparency = selected and 0.15 or 0.7
		end
	end
end

local function restoreAnimate(character)
	if savedAnimate and savedAnimate.Parent then
		savedAnimate.Disabled = false
	end
	savedAnimate = nil
	local animate = character and character:FindFirstChild("Animate")
	if animate and animate:IsA("LocalScript") then
		animate.Disabled = false
	end
end

local function stopEmote()
	if playingTrack then
		pcall(function()
			playingTrack:Stop(0.1)
		end)
		playingTrack = nil
	end
	playingId = nil
	local character = player.Character
	if character then
		restoreAnimate(character)
	end
end

local function stopOtherTracks(animator, keep)
	if not animator then
		return
	end
	local ok, tracks = pcall(function()
		return animator:GetPlayingAnimationTracks()
	end)
	if not ok or type(tracks) ~= "table" then
		return
	end
	for _, track in ipairs(tracks) do
		if track ~= keep then
			pcall(function()
				track:Stop(0.05)
			end)
		end
	end
end

local function playEmoteOnAvatar(item)
	local character = player.Character
	if not character then
		return false, "No hay personaje"
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false, "Sin Humanoid"
	end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = humanoid:FindFirstChild("Animator")
	end

	if playingId == item.id and playingTrack and playingTrack.IsPlaying then
		stopEmote()
		return false, "detenido"
	end

	stopEmote()

	local animate = character:FindFirstChild("Animate")
	if animate and (animate:IsA("LocalScript") or animate:IsA("Script")) then
		savedAnimate = animate
		animate.Disabled = true
	end

	stopOtherTracks(animator, nil)

	local track = nil
	local okPlay = pcall(function()
		track = humanoid:PlayEmoteAndGetAnimTrackById(item.id)
	end)
	if okPlay and typeof(track) == "Instance" then
		pcall(function()
			track.Looped = true
			track.Priority = Enum.AnimationPriority.Action
			if not track.IsPlaying then
				track:Play(0.1)
			end
		end)
		playingTrack = track
		playingId = item.id
		return true, nil
	end

	local playedName = false
	pcall(function()
		playedName = humanoid:PlayEmote(item.name) == true
	end)
	if playedName then
		playingId = item.id
		return true, nil
	end

	if animator then
		local animation = Instance.new("Animation")
		animation.Name = "UGCEmotePreview"
		animation.AnimationId = "rbxassetid://" .. tostring(item.id)
		local okLoad, loaded = pcall(function()
			return animator:LoadAnimation(animation)
		end)
		if okLoad and typeof(loaded) == "Instance" then
			pcall(function()
				loaded.Looped = true
				loaded.Priority = Enum.AnimationPriority.Action
				loaded:Play(0.1)
			end)
			playingTrack = loaded
			playingId = item.id
			return true, nil
		end
	end

	restoreAnimate(character)
	return false, "No se pudo reproducir"
end

local function showDetails(item)
	details.Visible = true
	layoutBody()
	idBox.Text = tostring(item.id)
	detailsPrice.Text = "R$ " .. formatPrice(item)
	highlight(item.id)

	task.spawn(function()
		local playing, err = playEmoteOnAvatar(item)
		if playing then
			detailsName.Text = "▶  " .. item.name
		elseif err == "detenido" then
			detailsName.Text = item.name
		else
			detailsName.Text = item.name
			if err and err ~= "detenido" then
				detailsName.Text = item.name .. "  (" .. err .. ")"
			end
		end
	end)
end

local function clearGrid()
	for _, child in ipairs(grid:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	cardRefs = {}
end

local function addCard(item, order)
	if cardRefs[item.id] then
		return
	end

	local card = create("TextButton", {
		Name = "Emote_" .. tostring(item.id),
		LayoutOrder = order,
		BackgroundColor3 = COLORS.Card,
		BackgroundTransparency = 0.28,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Parent = grid,
	})
	corner(card, 9)
	stroke(card, COLORS.Stroke, 1, 0.7)
	cardRefs[item.id] = card

	local thumb = create("ImageLabel", {
		BackgroundColor3 = COLORS.Inset,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 6, 0, 6),
		Size = UDim2.new(1, -12, 1, -58),
		Image = thumbUri(item.id),
		ScaleType = Enum.ScaleType.Fit,
		Parent = card,
	})
	corner(thumb, 7)

	create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 6, 1, -50),
		Size = UDim2.new(1, -12, 0, 28),
		Text = item.name,
		TextColor3 = COLORS.White,
		TextSize = 11,
		Font = FONT_BOLD,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = card,
	})

	create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 6, 1, -20),
		Size = UDim2.new(1, -12, 0, 16),
		Text = "R$  " .. formatPrice(item),
		TextColor3 = COLORS.White,
		TextSize = 11,
		Font = FONT_MED,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})

	local star = create("TextButton", {
		Name = "Fav",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -6, 0, 6),
		Size = UDim2.new(0, 18, 0, 18),
		BackgroundColor3 = COLORS.Inset,
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		Text = favorites[item.id] and "★" or "☆",
		TextColor3 = favorites[item.id] and Color3.fromRGB(255, 213, 106) or COLORS.White,
		TextSize = 12,
		Font = FONT_BOLD,
		ZIndex = 3,
		Parent = card,
	})
	corner(star, 9)

	card.MouseButton1Click:Connect(function()
		showDetails(item)
	end)

	star.MouseButton1Click:Connect(function()
		if favorites[item.id] then
			favorites[item.id] = nil
			star.Text = "☆"
			star.TextColor3 = COLORS.White
		else
			favorites[item.id] = item
			star.Text = "★"
			star.TextColor3 = Color3.fromRGB(255, 213, 106)
		end
	end)

	if selectedId == item.id then
		highlight(item.id)
	end
end

local function filteredFallback()
	local query = string.lower(searchQuery)
	local list = {}
	for _, item in ipairs(FALLBACK_EMOTES) do
		local ok = true
		if showFavorites and not favorites[item.id] then
			ok = false
		end
		if ok and query ~= "" then
			if not string.find(string.lower(item.name), query, 1, true) then
				ok = false
			end
		end
		if ok then
			table.insert(list, item)
		end
	end
	if showPopular then
		-- Los últimos del fallback son los más populares / oficiales.
		table.sort(list, function(a, b)
			return a.id < b.id
		end)
	end
	return list
end

local function renderFallbackPage()
	local list = filteredFallback()
	local order = 0
	for _, child in ipairs(grid:GetChildren()) do
		if child:IsA("GuiObject") then
			order = order + 1
		end
	end
	local added = 0
	while fallbackCursor < #list and added < 18 do
		fallbackCursor = fallbackCursor + 1
		order = order + 1
		addCard(list[fallbackCursor], order)
		added = added + 1
	end
	emptyLabel.Visible = order == 0
	emptyLabel.Text = order == 0 and "No se encontraron emotes." or ""
end

local function rebuildFromFavorites()
	clearGrid()
	local order = 0
	local query = string.lower(searchQuery)
	for _, item in pairs(favorites) do
		if query == "" or string.find(string.lower(item.name), query, 1, true) then
			order = order + 1
			addCard(item, order)
		end
	end
	emptyLabel.Visible = order == 0
	emptyLabel.Text = order == 0 and "Sin favoritos." or ""
end

local function pickSortType(popular)
	if popular then
		local ok, value = pcall(function()
			return Enum.CatalogSortType.MostFavorited
		end)
		if ok and value then
			return value
		end
	end
	local ok2, value2 = pcall(function()
		return Enum.CatalogSortType.RecentlyUpdated
	end)
	if ok2 and value2 then
		return value2
	end
	return Enum.CatalogSortType.Relevance
end

local function loadNextPage(token)
	if loadingPage then
		return
	end
	if token and token ~= searchToken then
		return
	end
	if usingFallback then
		renderFallbackPage()
		return
	end
	if catalogPages == nil then
		return
	end
	loadingPage = true
	task.spawn(function()
		local okPage, page = pcall(function()
			return catalogPages:GetCurrentPage()
		end)
		if not okPage or type(page) ~= "table" then
			loadingPage = false
			usingFallback = true
			fallbackCursor = 0
			renderFallbackPage()
			return
		end

		local order = 0
		for _, child in ipairs(grid:GetChildren()) do
			if child:IsA("GuiObject") then
				order = order + 1
			end
		end

		for _, raw in ipairs(page) do
			local item = normalize(raw)
			if item then
				order = order + 1
				addCard(item, order)
			end
		end

		emptyLabel.Visible = order == 0
		emptyLabel.Text = order == 0 and "No se encontraron emotes." or ""

		local finished = true
		pcall(function()
			finished = catalogPages.IsFinished
		end)
		if not finished then
			pcall(function()
				catalogPages:AdvanceToNextPageAsync()
			end)
		else
			catalogPages = nil
		end
		loadingPage = false
	end)
end

local function beginSearch()
	searchToken = searchToken + 1
	local token = searchToken
	loadingPage = false
	catalogPages = nil
	usingFallback = false
	fallbackCursor = 0
	clearGrid()
	emptyLabel.Visible = true
	emptyLabel.Text = "Cargando emotes UGC..."

	if showFavorites then
		rebuildFromFavorites()
		return
	end

	task.spawn(function()
		local params = CatalogSearchParams.new()
		params.AssetTypes = { Enum.AvatarAssetType.EmoteAnimation }
		if searchQuery ~= "" then
			params.SearchKeyword = searchQuery
		end
		pcall(function()
			params.SortType = pickSortType(showPopular)
		end)

		local pages = nil
		local ok = pcall(function()
			if AvatarEditorService.SearchCatalogAsync then
				pages = AvatarEditorService:SearchCatalogAsync(params)
			else
				pages = AvatarEditorService:SearchCatalog(params)
			end
		end)

		if token ~= searchToken then
			return
		end

		if not ok or pages == nil then
			usingFallback = true
			emptyLabel.Text = ""
			renderFallbackPage()
			return
		end

		catalogPages = pages
		loadNextPage(token)
	end)
end

local searchThread = nil
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	searchQuery = searchBox.Text
	if searchThread then
		task.cancel(searchThread)
	end
	searchThread = task.delay(0.35, function()
		beginSearch()
	end)
end)

refreshBtn.MouseButton1Click:Connect(function()
	pcall(function()
		TweenService:Create(refreshBtn, TweenInfo.new(0.45), { Rotation = refreshBtn.Rotation + 360 }):Play()
	end)
	beginSearch()
end)

favBtn.MouseButton1Click:Connect(function()
	showFavorites = not showFavorites
	setButtonActive(favBtn, showFavorites, COLORS.CyanBtn, COLORS.Card)
	beginSearch()
end)

popularBtn.MouseButton1Click:Connect(function()
	showPopular = not showPopular
	setButtonActive(popularBtn, showPopular, COLORS.Cyan, COLORS.CyanBtn)
	if not showFavorites then
		beginSearch()
	end
end)

closeBtn.MouseButton1Click:Connect(function()
	setOpen(false)
end)

reopenBtn.MouseButton1Click:Connect(function()
	setOpen(true)
end)

copyBtn.MouseButton1Click:Connect(function()
	if idBox.Text == "" then
		return
	end
	idBox:CaptureFocus()
	idBox.CursorPosition = #idBox.Text + 1
	idBox.SelectionStart = 1
	copyBtn.Text = "Seleccionado"
	task.delay(1.1, function()
		if copyBtn.Parent then
			copyBtn.Text = "Copiar ID"
		end
	end)
end)

gridWrap:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
	if showFavorites or loadingPage then
		return
	end
	local window = gridWrap.AbsoluteWindowSize.Y
	local canvas = gridWrap.AbsoluteCanvasSize.Y
	if canvas > 0 and gridWrap.CanvasPosition.Y + window >= canvas - 90 then
		if usingFallback then
			renderFallbackPage()
		else
			loadNextPage(searchToken)
		end
	end
end)

panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(resizeGrid)
grid:GetPropertyChangedSignal("AbsoluteSize"):Connect(resizeGrid)

local function adaptLayout()
	local cam = workspace.CurrentCamera
	local viewport = cam and cam.ViewportSize or Vector2.new(1280, 720)
	local margin = viewport.X < 700 and 6 or 12
	local width = viewport.X < 700 and math.min(300, viewport.X - margin * 2) or 332
	panel.Position = UDim2.new(1, -margin, 0, margin)
	panel.Size = UDim2.new(0, width, 1, -(margin * 2))
	reopenBtn.Position = UDim2.new(1, -margin, 0, margin)
	local reserved = 28 * 3 + 72 + 6 * 4
	searchHolder.Size = UDim2.new(0, math.max(84, toolbar.AbsoluteSize.X - 16 - reserved), 1, 0)
	layoutBody()
	resizeGrid()
end

if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(adaptLayout)
end
UserInputService.LastInputTypeChanged:Connect(adaptLayout)
adaptLayout()

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.Escape and isOpen then
		setOpen(false)
	end
end)

player.CharacterAdded:Connect(function()
	stopEmote()
end)

beginSearch()
