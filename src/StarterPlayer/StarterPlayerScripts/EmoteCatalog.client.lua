--!strict
--[[
	Catálogo de emotes UGC
	LocalScript → StarterPlayer.StarterPlayerScripts

	Consulta el Marketplace con AvatarEditorService:SearchCatalog
	(método oficial usable desde el cliente). No usa HttpService ni
	endpoints bloqueados desde LocalScript.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local AvatarEditorService = game:GetService("AvatarEditorService")

local player = Players.LocalPlayer
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
local PAGE_IDLE = 0.15
local SEARCH_DELAY = 0.35

type EmoteItem = {
	id: number,
	name: string,
	price: number?,
	priceStatus: string?,
}

local favorites: { [number]: EmoteItem } = {}
local selectedId: number? = nil
local showFavorites = false
local showPopular = false
local searchQuery = ""
local catalogPages: any = nil
local loadingPage = false
local searchToken = 0
local isOpen = true
local cardRefs: { [number]: Frame } = {}
local knownItems: { [number]: EmoteItem } = {}
local playingTrack: AnimationTrack? = nil
local playingId: number? = nil
local playingConn: RBXScriptConnection? = nil

local beginSearch: () -> ()
local loadNextPage: (number?) -> ()
local rebuildFromFavorites: () -> ()

local function create(className: string, props: { [string]: any }?): any
	local inst = Instance.new(className)
	if props then
		for key, value in props do
			if key ~= "Parent" then
				(inst :: any)[key] = value
			end
		end
		if props.Parent then
			inst.Parent = props.Parent
		end
	end
	return inst
end

local function corner(parent: Instance, px: number)
	return create("UICorner", { CornerRadius = UDim.new(0, px), Parent = parent })
end

local function stroke(parent: Instance, color: Color3, thickness: number, transparency: number)
	return create("UIStroke", {
		Color = color,
		Thickness = thickness,
		Transparency = transparency,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

local function pad(parent: Instance, t: number, r: number, b: number, l: number)
	return create("UIPadding", {
		PaddingTop = UDim.new(0, t),
		PaddingRight = UDim.new(0, r),
		PaddingBottom = UDim.new(0, b),
		PaddingLeft = UDim.new(0, l),
		Parent = parent,
	})
end

local function thumbUri(id: number): string
	return ("rbxthumb://type=Asset&id=%d&w=150&h=150"):format(id)
end

local function formatPrice(item: EmoteItem): string
	if item.priceStatus == "Free" or item.price == 0 then
		return "Gratis"
	end
	if item.price == nil then
		return "—"
	end
	return tostring(item.price)
end

local function normalize(raw: any): EmoteItem?
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
	if typeof(status) ~= "string" then
		status = nil
	end
	return {
		id = id,
		name = name,
		price = price,
		priceStatus = status,
	}
end

local gui = create("ScreenGui", {
	Name = "UGCEmoteCatalog",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 120,
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
	Size = UDim2.new(0, 120, 1, 0),
	BackgroundColor3 = COLORS.Inset,
	BackgroundTransparency = 0.15,
	BorderSizePixel = 0,
	Parent = toolbar,
})
pcall(function()
	local flex = Instance.new("UIFlexItem")
	flex.FlexMode = Enum.UIFlexMode.Fill
	flex.Parent = searchHolder
end)
corner(searchHolder, 7)
stroke(searchHolder, COLORS.Stroke, 1, 0.7)

local searchIcon = create("TextLabel", {
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

local function makeIconButton(name: string, order: number, text: string, bg: Color3, parent: Instance): TextButton
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
	BackgroundTransparency = 0,
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
;(closeBtn:FindFirstChildOfClass("UIStroke") :: UIStroke).Transparency = 0.85

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
	Size = UDim2.new(1, 0, 0, 48),
	Position = UDim2.new(0, 0, 0, 24),
	Text = "",
	TextColor3 = COLORS.Muted,
	TextSize = 12,
	Font = FONT_MED,
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

local function setButtonActive(btn: TextButton, active: boolean, activeColor: Color3, idleColor: Color3)
	btn.BackgroundColor3 = if active then activeColor else idleColor
	if btn == popularBtn then
		btn.TextColor3 = if active then Color3.fromRGB(6, 33, 38) else COLORS.White
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

local function setOpen(open: boolean)
	isOpen = open
	panel.Visible = open
	reopenBtn.Visible = not open
end

local function highlight(id: number?)
	selectedId = id
	for cardId, card in cardRefs do
		local selected = cardId == id
		card.BackgroundColor3 = if selected then COLORS.CardSelected else COLORS.Card
		local s = card:FindFirstChildOfClass("UIStroke")
		if s then
			s.Color = if selected then COLORS.Selected else COLORS.Stroke
			s.Transparency = if selected then 0.15 else 0.7
		end
	end
end

local function layoutBody()
	local bottom = if details.Visible then 54 else 0
	gridWrap.Size = UDim2.new(1, 0, 1, -(42 + bottom))
end

local function stopEmote()
	if playingConn then
		playingConn:Disconnect()
		playingConn = nil
	end
	if playingTrack then
		pcall(function()
			playingTrack:Stop(0.12)
		end)
		playingTrack = nil
	end
	playingId = nil
end

local function getHumanoid(): Humanoid?
	local character = player.Character
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	return humanoid
end

local function bindTrack(track: AnimationTrack, itemId: number)
	playingTrack = track
	playingId = itemId
	pcall(function()
		track.Priority = Enum.AnimationPriority.Action4
		track.Looped = true
		if not track.IsPlaying then
			track:Play(0.12)
		end
	end)
	if playingConn then
		playingConn:Disconnect()
	end
	playingConn = track.Stopped:Connect(function()
		if playingTrack == track then
			playingTrack = nil
			if playingId == itemId then
				playingId = nil
			end
		end
	end)
end

local function playEmoteOnAvatar(item: EmoteItem): boolean
	local humanoid = getHumanoid()
	if not humanoid then
		return false
	end

	if playingId == item.id and playingTrack and playingTrack.IsPlaying then
		stopEmote()
		return false
	end

	stopEmote()

	local okId, track = pcall(function()
		return (humanoid :: any):PlayEmoteAndGetAnimTrackById(item.id)
	end)
	if okId and typeof(track) == "Instance" and track:IsA("AnimationTrack") then
		bindTrack(track, item.id)
		return true
	end

	local okName, played = pcall(function()
		return humanoid:PlayEmote(item.name)
	end)
	if okName and played then
		playingId = item.id
		return true
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = humanoid:FindFirstChild("Animator") :: Animator?
	end
	if animator then
		local animation = Instance.new("Animation")
		animation.Name = "UGCEmotePreview"
		animation.AnimationId = "rbxassetid://" .. tostring(item.id)
		local okLoad, loaded = pcall(function()
			return animator:LoadAnimation(animation)
		end)
		if okLoad and typeof(loaded) == "Instance" and loaded:IsA("AnimationTrack") then
			bindTrack(loaded, item.id)
			return true
		end
	end

	return false
end

local function showDetails(item: EmoteItem)
	details.Visible = true
	layoutBody()
	idBox.Text = tostring(item.id)
	detailsPrice.Text = "R$ " .. formatPrice(item)
	highlight(item.id)

	local playing = playEmoteOnAvatar(item)
	if playing then
		detailsName.Text = "▶  " .. item.name
	else
		detailsName.Text = item.name
	end
end

local function clearGrid()
	for _, child in grid:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	table.clear(cardRefs)
end

local function addCard(item: EmoteItem, order: number)
	if cardRefs[item.id] then
		return
	end
	knownItems[item.id] = item

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
		Text = if favorites[item.id] then "★" else "☆",
		TextColor3 = if favorites[item.id] then Color3.fromRGB(255, 213, 106) else COLORS.White,
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
		if showFavorites then
			rebuildFromFavorites()
		end
	end)

	if selectedId == item.id then
		highlight(item.id)
	end
end

rebuildFromFavorites = function()
	clearGrid()
	local order = 1
	local query = string.lower(searchQuery)
	for _, item in favorites do
		local matches = query == "" or string.find(string.lower(item.name), query, 1, true) ~= nil
		if matches then
			addCard(item, order)
			order += 1
		end
	end
	emptyLabel.Visible = order == 1
	emptyLabel.Text = if order == 1 then "Sin favoritos." else ""
end

local function pickSortType(popular: boolean): Enum.CatalogSortType
	if popular then
		local ok, value = pcall(function()
			return (Enum.CatalogSortType :: any).MostFavorited
		end)
		if ok and value then
			return value
		end
		ok, value = pcall(function()
			return (Enum.CatalogSortType :: any).Bestselling
		end)
		if ok and value then
			return value
		end
	else
		local ok, value = pcall(function()
			return (Enum.CatalogSortType :: any).RecentlyUpdated
		end)
		if ok and value then
			return value
		end
	end
	return Enum.CatalogSortType.Relevance
end

beginSearch = function()
	searchToken += 1
	local token = searchToken
	loadingPage = false
	catalogPages = nil
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
			params.IncludeOffSale = false
		end)
		pcall(function()
			params.SortType = pickSortType(showPopular)
		end)

		local ok, pagesOrErr = pcall(function()
			return AvatarEditorService:SearchCatalog(params)
		end)
		if token ~= searchToken then
			return
		end
		if not ok then
			emptyLabel.Text = "No se pudo consultar el catálogo.\nAvatarEditorService no está disponible."
			return
		end
		catalogPages = pagesOrErr
		loadNextPage(token)
	end)
end

function loadNextPage(token: number?)
	if loadingPage or catalogPages == nil then
		return
	end
	if token and token ~= searchToken then
		return
	end
	loadingPage = true

	task.spawn(function()
		local okPage, page = pcall(function()
			return catalogPages:GetCurrentPage()
		end)
		if not okPage or type(page) ~= "table" then
			loadingPage = false
			emptyLabel.Text = "No hay resultados."
			emptyLabel.Visible = true
			return
		end

		local order = 0
		for _, child in grid:GetChildren() do
			if child:IsA("GuiObject") then
				order += 1
			end
		end

		local added = 0
		for _, raw in page do
			local item = normalize(raw)
			if item then
				order += 1
				addCard(item, order)
				added += 1
			end
		end

		emptyLabel.Visible = order == 0
		emptyLabel.Text = if order == 0 then "No se encontraron emotes." else ""

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

		task.wait(PAGE_IDLE)
		loadingPage = false
	end)
end

local searchThread: thread? = nil
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	searchQuery = searchBox.Text
	if searchThread then
		task.cancel(searchThread)
	end
	searchThread = task.delay(SEARCH_DELAY, function()
		beginSearch()
	end)
end)

refreshBtn.MouseButton1Click:Connect(function()
	TweenService:Create(refreshBtn, TweenInfo.new(0.45), { Rotation = refreshBtn.Rotation + 360 }):Play()
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
	if showFavorites or catalogPages == nil or loadingPage then
		return
	end
	local window = gridWrap.AbsoluteWindowSize.Y
	local canvas = gridWrap.AbsoluteCanvasSize.Y
	if canvas > 0 and gridWrap.CanvasPosition.Y + window >= canvas - 90 then
		loadNextPage(searchToken)
	end
end)

panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(resizeGrid)
grid:GetPropertyChangedSignal("AbsoluteSize"):Connect(resizeGrid)

local function adaptLayout()
	local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local margin = if viewport.X < 700 then 6 else 12
	local width = if viewport.X < 700 then math.min(300, viewport.X - margin * 2) else 332
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

beginSearch()
