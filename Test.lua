local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ================= CONFIG =================
getgenv().ESP_SETTINGS = {
	-- Visuals
	Box = true,
	Tracers = true,
	Skeleton = false,
	Chams = false,
	Names = true,
	Distance = true,
	HealthBar = true,
	HideTeam = false,
	WallCheck = false, 
	-- Hitbox
	Hitbox = false,      
	HitboxSize = 20,
	UniversalColor = true,
	HitboxTeamCheck = false, -- [[ ADDED: New Config ]]
	-- Aimbot
	Aimbot = false,
	AimPart = "Head",       
	AimTeamCheck = true,
	AimWallCheck = false,   
	AimFOV = true,      
	AimRadius = 100,
	AimSmartDist = false
}
getgenv().RainbowTargets = {}

-- ================= PREMIUM THEME =================
local THEME = {
	Bg = Color3.fromRGB(12, 12, 18), -- Deep Midnight
	Header = Color3.fromRGB(18, 18, 25),
	Accent = Color3.fromRGB(90, 140, 255), -- Electric Blue
	Text = Color3.fromRGB(245, 245, 255),
	TextDim = Color3.fromRGB(140, 140, 160),
	Stroke = Color3.fromRGB(45, 45, 65),
	Red = Color3.fromRGB(255, 60, 70),
	Green = Color3.fromRGB(80, 255, 140),
	Purple = Color3.fromRGB(140, 60, 255)
}

-- ================= SOUNDS =================
local SoundManager = {}
local SoundRoot = Instance.new("Folder", SoundService)
SoundRoot.Name = "KopiSounds"
local function CreateSound(id, vol)
	local s = Instance.new("Sound", SoundRoot)
	s.SoundId = id;
	s.Volume = vol; return s
end
local Sounds = {
	Click = CreateSound("rbxassetid://6895079853", 0.4),
	Open = CreateSound("rbxassetid://241837157", 0.4),
	Toggle = CreateSound("rbxassetid://6895079853", 0.3)
}
function SoundManager.Play(name)
	if Sounds[name] then
		local s = Sounds[name]:Clone()
		s.Parent = SoundRoot
		if name=="Toggle" then s.PlaybackSpeed=1.1 end
		s:Play();
		game.Debris:AddItem(s,2)
	end
end

-- ================= UTILS =================
local function CreateTween(obj, props, time)
	TweenService:Create(obj, TweenInfo.new(time or 0.25, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), props):Play()
end

getgenv().KOPI_POS = getgenv().KOPI_POS or {X = 150, Y = 150}
local function SavePosition(pos) getgenv().KOPI_POS = {X = pos.X.Offset, Y = pos.Y.Offset} end
local function LoadPosition() return UDim2.fromOffset(getgenv().KOPI_POS.X, getgenv().KOPI_POS.Y) end

-- ================= PREMIUM UI BUILD =================
if CoreGui:FindFirstChild("KOPI_PREMIUM_UI") then CoreGui.KOPI_PREMIUM_UI:Destroy() end
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "KOPI_PREMIUM_UI"
ScreenGui.ResetOnSpawn = false

-- [[ MAIN FRAME ]]
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.fromOffset(350, 400) 
MainFrame.Position = LoadPosition()
MainFrame.BackgroundColor3 = THEME.Bg
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 16) -- Rounded Look

-- [[ GLOWING BORDER ]]
local UIStroke = Instance.new("UIStroke", MainFrame)
UIStroke.Color = Color3.fromRGB(255, 255, 255) 
UIStroke.Thickness = 2.5
UIStroke.Transparency = 0

local StrokeGradient = Instance.new("UIGradient", UIStroke)
StrokeGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, THEME.Stroke),
	ColorSequenceKeypoint.new(0.5, THEME.Accent), 
	ColorSequenceKeypoint.new(1, THEME.Stroke)
}
StrokeGradient.Rotation = 45

-- [[ BACKGROUND AMBIENCE ]]
local BgGradient = Instance.new("UIGradient", MainFrame)
BgGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(150,150,160))
}
BgGradient.Rotation = 90

-- [[ PILL (MINIMIZED) ]]
local MiniFrame = Instance.new("Frame", ScreenGui)
MiniFrame.Size = UDim2.fromOffset(120, 36)
MiniFrame.Position = MainFrame.Position
MiniFrame.BackgroundColor3 = THEME.Header
MiniFrame.Visible = false
MiniFrame.BorderSizePixel = 0
Instance.new("UICorner", MiniFrame).CornerRadius = UDim.new(1, 0)
local MiniStroke = Instance.new("UIStroke", MiniFrame)
MiniStroke.Color = THEME.Accent;
MiniStroke.Thickness = 2

local MiniLabel = Instance.new("TextLabel", MiniFrame)
MiniLabel.Size = UDim2.new(1,0,1,0)
MiniLabel.BackgroundTransparency = 1
MiniLabel.Text = "OPEN HUB"
MiniLabel.Font = Enum.Font.GothamBlack
MiniLabel.TextSize = 12
MiniLabel.TextColor3 = THEME.Accent

-- [[ DRAGGING SYSTEM ]]
local dragging, dragInput, dragStart, startPos, activeFrame
local isMoving = false

local function UpdateDrag(input)
	if not activeFrame then return end
	local delta = input.Position - dragStart
	if delta.Magnitude > 3 then isMoving = true end
	local targetX = startPos.X.Offset + delta.X
	local targetY = startPos.Y.Offset + delta.Y
	local vp = Camera.ViewportSize
	local frameSize = activeFrame.AbsoluteSize
	local clampedX = math.clamp(targetX, 0, vp.X - frameSize.X)
	local clampedY = math.clamp(targetY, 0, vp.Y - frameSize.Y)
	CreateTween(activeFrame, {Position = UDim2.fromOffset(clampedX, clampedY)}, 0.08)
end

local function MakeDraggable(trigger, frameToMove, onClick)
	trigger.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true; isMoving = false; dragStart = input.Position; startPos = frameToMove.Position; activeFrame = frameToMove
			local con;
			con = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false; con:Disconnect(); SavePosition(frameToMove.Position)
					if not isMoving and onClick then onClick() end
				end
			end)
		end
	end)
end

-- [[ HEADER & TABS ]]
local Header = Instance.new("Frame", MainFrame)
Header.Size = UDim2.new(1, 0, 0, 48)
Header.BackgroundColor3 = THEME.Header
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 16)
local Title = Instance.new("TextLabel", Header)
Title.Text = "KOPI'S <font color=\"rgb(90,140,255)\">HUB</font>"
Title.RichText = true;
Title.Font = Enum.Font.GothamBlack; Title.TextSize = 18
Title.TextColor3 = THEME.Text; Title.Position = UDim2.new(0, 16, 0, 0);
Title.Size = UDim2.new(1, -60, 1, 0)
Title.BackgroundTransparency = 1; Title.TextXAlignment = Enum.TextXAlignment.Left

MakeDraggable(Header, MainFrame, nil)
MakeDraggable(MiniFrame, MiniFrame, function()
	SoundManager.Play("Open")
	MainFrame.Position = MiniFrame.Position
	MiniFrame.Visible = false
	MainFrame.Visible = true
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then UpdateDrag(input) end
end)

local MinimizeBtn = Instance.new("TextButton", Header)
MinimizeBtn.Size = UDim2.fromOffset(32, 32)
MinimizeBtn.Position = UDim2.new(1, -44, 0.5, -16)
MinimizeBtn.Text = "-"
MinimizeBtn.Font = Enum.Font.GothamBlack;
MinimizeBtn.TextSize = 20
MinimizeBtn.TextColor3 = THEME.TextDim; MinimizeBtn.BackgroundColor3 = Color3.fromRGB(35,35,45)
Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0, 10)
MinimizeBtn.MouseButton1Click:Connect(function() SoundManager.Play("Click"); MiniFrame.Position = MainFrame.Position; MainFrame.Visible = false; MiniFrame.Visible = true end)

-- [[ TABS SYSTEM ]]
local TabContainer = Instance.new("Frame", MainFrame)
TabContainer.Position = UDim2.new(0, 12, 0, 56);
TabContainer.Size = UDim2.new(1, -24, 0, 36)
TabContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
Instance.new("UICorner", TabContainer).CornerRadius = UDim.new(0, 10)
local TabHighlight = Instance.new("Frame", TabContainer)
TabHighlight.Size = UDim2.new(0.25, -4, 1, -4);
TabHighlight.Position = UDim2.new(0, 2, 0, 2)
TabHighlight.BackgroundColor3 = THEME.Accent; Instance.new("UICorner", TabHighlight).CornerRadius = UDim.new(0, 8)

local PageContainer = Instance.new("Frame", MainFrame)
PageContainer.Position = UDim2.new(0, 12, 0, 100);
PageContainer.Size = UDim2.new(1, -24, 1, -112)
PageContainer.BackgroundTransparency = 1; PageContainer.ClipsDescendants = true

-- Pages
local function CreatePage(visible)
	local p = Instance.new("ScrollingFrame", PageContainer)
	p.Size = UDim2.new(1,0,1,0);
	p.BackgroundTransparency = 1; p.Visible = visible
	p.ScrollBarThickness = 2; p.BorderSizePixel = 0; p.ScrollBarImageColor3 = THEME.Accent
	local l = Instance.new("UIListLayout", p);
	l.Padding = UDim.new(0, 10)
	l:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() p.CanvasSize = UDim2.fromOffset(0, l.AbsoluteContentSize.Y + 10) end)
	return p, l
end

local VisPage, VisLayout = CreatePage(true)
local TargPage = Instance.new("Frame", PageContainer);
TargPage.Size = UDim2.new(1,0,1,0); TargPage.BackgroundTransparency=1; TargPage.Visible=false 
local HitboxPage, HitboxLayout = CreatePage(false)

-- [[ AIMBOT PAGE (Custom Layout) ]]
local AimPage = Instance.new("Frame", PageContainer)
AimPage.Size = UDim2.new(1,0,1,0);
AimPage.BackgroundTransparency = 1; AimPage.Visible = false

-- FOV Input (Fixed Top)
local FOVInput = Instance.new("TextBox", AimPage)
FOVInput.Size = UDim2.new(1, 0, 0, 40);
FOVInput.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
FOVInput.TextColor3 = THEME.Text; FOVInput.PlaceholderText = "FOV Radius (Default: 100)"; FOVInput.Font = Enum.Font.GothamSemibold;
FOVInput.TextSize = 14
Instance.new("UICorner", FOVInput).CornerRadius = UDim.new(0, 10); Instance.new("UIStroke", FOVInput).Color = THEME.Stroke
FOVInput.FocusLost:Connect(function(enter)
	if enter then
		local num = tonumber(FOVInput.Text)
		if num then 
			ESP_SETTINGS.AimRadius = num
			FOVInput.Text = "FOV Radius: " .. num
			SoundManager.Play("Open") 
		end
	end
end)

-- Scrollable Buttons (Bottom)
local AimScroll = Instance.new("ScrollingFrame", AimPage)
AimScroll.Size = UDim2.new(1, 0, 1, -48)
AimScroll.Position = UDim2.new(0, 0, 0, 48)
AimScroll.BackgroundTransparency = 1
AimScroll.ScrollBarThickness = 2
AimScroll.BorderSizePixel = 0
local AimLayout = Instance.new("UIListLayout", AimScroll);
AimLayout.Padding = UDim.new(0, 10)
AimLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() AimScroll.CanvasSize = UDim2.fromOffset(0, AimLayout.AbsoluteContentSize.Y + 10) end)

-- Function to switch tabs
local function CreateTabBtn(text, posScale, pageToShow)
	local b = Instance.new("TextButton", TabContainer)
	b.Size = UDim2.new(0.25, 0, 1, 0);
	b.Position = UDim2.new(posScale, 0, 0, 0)
	b.BackgroundTransparency = 1; b.Text = text; b.Font = Enum.Font.GothamBold
	b.TextSize = 10; b.TextColor3 = THEME.Text;
	b.ZIndex = 2
	b.MouseButton1Click:Connect(function() 
		SoundManager.Play("Click")
		CreateTween(TabHighlight, {Position = UDim2.new(posScale, 2, 0, 2)})
		VisPage.Visible = false; TargPage.Visible = false; HitboxPage.Visible = false; AimPage.Visible = false
		pageToShow.Visible = true
	end)
end

CreateTabBtn("VISUALS", 0, VisPage)
CreateTabBtn("TARGETS", 0.25, TargPage)
CreateTabBtn("HITBOX", 0.5, HitboxPage)
CreateTabBtn("AIMBOT", 0.75, AimPage)

-- [[ UI COMPONENT FACTORY ]]
local function CreateToggle(parent, text, configKey, callback)
	local Btn = Instance.new("TextButton", parent)
	Btn.Size = UDim2.new(1, 0, 0, 38);
	Btn.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
	Btn.AutoButtonColor = false; Btn.Text = "";
	Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 10)
	local Lbl = Instance.new("TextLabel", Btn)
	Lbl.Text = text; Lbl.Font = Enum.Font.GothamSemibold; Lbl.TextSize = 13
	Lbl.TextColor3 = THEME.Text;
	Lbl.Size = UDim2.new(0.7, 0, 1, 0); Lbl.Position = UDim2.new(0, 14, 0, 0)
	Lbl.TextXAlignment = Enum.TextXAlignment.Left;
	Lbl.BackgroundTransparency = 1
	local Sw = Instance.new("Frame", Btn)
	Sw.Size = UDim2.fromOffset(44, 22);
	Sw.Position = UDim2.new(1, -54, 0.5, -11)
	Sw.BackgroundColor3 = ESP_SETTINGS[configKey] and THEME.Accent or Color3.fromRGB(45,45,55)
	Instance.new("UICorner", Sw).CornerRadius = UDim.new(1, 0)
	local Circ = Instance.new("Frame", Sw)
	Circ.Size = UDim2.fromOffset(18, 18)
	Circ.Position = ESP_SETTINGS[configKey] and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
	Circ.BackgroundColor3 = Color3.new(1,1,1);
	Instance.new("UICorner", Circ).CornerRadius = UDim.new(1, 0)
	
	Btn.MouseButton1Click:Connect(function()
		ESP_SETTINGS[configKey] = not ESP_SETTINGS[configKey]; SoundManager.Play("Toggle")
		if ESP_SETTINGS[configKey] then CreateTween(Sw, {BackgroundColor3 = THEME.Accent}); CreateTween(Circ, {Position = UDim2.new(1, -20, 0.5, -9)})
		else CreateTween(Sw, {BackgroundColor3 = Color3.fromRGB(45,45,55)}); CreateTween(Circ, {Position = UDim2.new(0, 2, 0.5, -9)}) end
		if callback then callback(ESP_SETTINGS[configKey]) end
	end)
	return Btn 
end

local function CreateButton(parent, text, cb)
	local b = Instance.new("TextButton", parent)
	b.Size = UDim2.new(1,0,0,36);
	b.BackgroundColor3 = Color3.fromRGB(30,30,40)
	b.Text = text; b.TextColor3 = THEME.Text; b.Font = Enum.Font.GothamBold;
	b.TextSize = 12
	Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
	b.MouseButton1Click:Connect(function() SoundManager.Play("Click"); cb(b) end)
end

-- [[ BUILD VISUALS ]]
CreateToggle(VisPage, "ESP Boxes", "Box")
CreateToggle(VisPage, "Skeleton", "Skeleton")
CreateToggle(VisPage, "Chams", "Chams")
CreateToggle(VisPage, "Tracers", "Tracers")
CreateToggle(VisPage, "Names", "Names")
CreateToggle(VisPage, "Distance", "Distance")
CreateToggle(VisPage, "Health Gauge", "HealthBar")
CreateToggle(VisPage, "Hide Team", "HideTeam")
CreateToggle(VisPage, "Wall Check", "WallCheck") 
-- [[ BUILD TARGETS ]]
local TargInput = Instance.new("TextBox", TargPage)
TargInput.Size = UDim2.new(1, 0, 0, 40);
TargInput.BackgroundColor3 = Color3.fromRGB(25,25,32)
TargInput.TextColor3 = Color3.new(1,1,1); TargInput.PlaceholderText = "Add Target Name..."; TargInput.Font = Enum.Font.Gotham; TargInput.TextSize = 13
Instance.new("UICorner", TargInput).CornerRadius = UDim.new(0,10);
Instance.new("UIStroke", TargInput).Color = THEME.Stroke
local ClearBtn = Instance.new("TextButton", TargPage)
ClearBtn.Size = UDim2.new(1, 0, 0, 36);
ClearBtn.Position = UDim2.new(0, 0, 1, -36)
ClearBtn.BackgroundColor3 = Color3.fromRGB(40,20,20); ClearBtn.Text = "CLEAR ALL TARGETS"; ClearBtn.TextColor3 = THEME.Red; ClearBtn.Font = Enum.Font.GothamBold;
ClearBtn.TextSize = 12
Instance.new("UICorner", ClearBtn).CornerRadius = UDim.new(0, 8); Instance.new("UIStroke", ClearBtn).Color = THEME.Red;
Instance.new("UIStroke", ClearBtn).Thickness = 1
local TargScroll = Instance.new("ScrollingFrame", TargPage)
TargScroll.Position = UDim2.fromOffset(0, 48); TargScroll.Size = UDim2.new(1,0,1,-90); TargScroll.BackgroundTransparency = 1;
TargScroll.BorderSizePixel = 0
local TLayout = Instance.new("UIListLayout", TargScroll); TLayout.Padding = UDim.new(0, 6)

local function RefreshTargets()
	for _,c in ipairs(TargScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	for i, v in ipairs(RainbowTargets) do
		local f = Instance.new("Frame", TargScroll);
		f.Size = UDim2.new(1,0,0,32); f.BackgroundColor3 = Color3.fromRGB(30,30,40)
		Instance.new("UICorner", f).CornerRadius = UDim.new(0,8)
		local t = Instance.new("TextLabel", f); t.Text = v; t.Size = UDim2.new(1,-30,1,0);
		t.Position = UDim2.new(0,12,0,0); t.Font = Enum.Font.GothamSemibold; t.TextColor3 = THEME.Text; t.TextXAlignment = Enum.TextXAlignment.Left; t.BackgroundTransparency = 1
		local del = Instance.new("TextButton", f);
		del.Size = UDim2.fromOffset(24,24); del.Position = UDim2.new(1,-28,0,4); del.Text = "✕"; del.BackgroundColor3 = THEME.Red; del.TextColor3 = Color3.new(1,1,1)
		Instance.new("UICorner", del).CornerRadius = UDim.new(0,6);
		del.MouseButton1Click:Connect(function() table.remove(RainbowTargets, i); SoundManager.Play("Click"); RefreshTargets() end)
	end
end
TargInput.FocusLost:Connect(function(enter)
	if enter and TargInput.Text ~= "" then table.insert(RainbowTargets, TargInput.Text:lower()); TargInput.Text = ""; SoundManager.Play("Open"); RefreshTargets() end
end)
ClearBtn.MouseButton1Click:Connect(function() table.clear(RainbowTargets); SoundManager.Play("Click"); RefreshTargets() end)

-- [[ BUILD HITBOX ]]
local function ResetHitboxLogic()
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character then
			local hrp = p.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				hrp.Size = Vector3.new(2, 2, 1);
				hrp.Transparency = 1; hrp.CanCollide = true; hrp.Color = Color3.new(0.63, 0.63, 0.63)
			end
		end
	end
end

local HitToggleBtn = CreateToggle(HitboxPage, "Enable Hitbox", "Hitbox", function(state) if state == false then ResetHitboxLogic() end end)
CreateToggle(HitboxPage, "Team Check", "HitboxTeamCheck", function() ResetHitboxLogic() end) -- [[ ADDED: Toggle ]]
CreateToggle(HitboxPage, "Universal Color", "UniversalColor")

local CustomInput = Instance.new("TextBox", HitboxPage)
CustomInput.Size = UDim2.new(1, 0, 0, 40);
CustomInput.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
CustomInput.TextColor3 = THEME.Text; CustomInput.PlaceholderText = tostring(ESP_SETTINGS.HitboxSize); CustomInput.Font = Enum.Font.GothamSemibold; CustomInput.TextSize = 14
Instance.new("UICorner", CustomInput).CornerRadius = UDim.new(0, 10);
Instance.new("UIStroke", CustomInput).Color = THEME.Stroke
CustomInput.FocusLost:Connect(function(enter)
	if enter then
		local num = tonumber(CustomInput.Text)
		if num then ESP_SETTINGS.HitboxSize = num; CustomInput.Text = "Size: " .. num; SoundManager.Play("Open")
		else CustomInput.Text = ""; CustomInput.PlaceholderText = "Invalid Number" end
	end
end)

local PresetsFrame = Instance.new("Frame", HitboxPage)
PresetsFrame.Size = UDim2.new(1, 0, 0, 34);
PresetsFrame.BackgroundTransparency = 1
local PresetsLayout = Instance.new("UIListLayout", PresetsFrame); PresetsLayout.FillDirection = Enum.FillDirection.Horizontal;
PresetsLayout.Padding = UDim.new(0, 8)
local function CreatePreset(text, sizeVal)
	local b = Instance.new("TextButton", PresetsFrame); b.Size = UDim2.new(0.31, 0, 1, 0);
	b.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	b.Text = text; b.Font = Enum.Font.GothamBold; b.TextColor3 = THEME.Text;
	b.TextSize = 11
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	b.MouseButton1Click:Connect(function() ESP_SETTINGS.HitboxSize = sizeVal; CustomInput.Text = "Size: " .. sizeVal; SoundManager.Play("Click") end)
end
CreatePreset("Small (10)", 10);
CreatePreset("Normal (20)", 20); CreatePreset("Big (50)", 50)

local ResetBtn = Instance.new("TextButton", HitboxPage)
ResetBtn.Size = UDim2.new(1, 0, 0, 36);
ResetBtn.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
ResetBtn.Text = "RESET DEFAULT"; ResetBtn.TextColor3 = THEME.Red; ResetBtn.Font = Enum.Font.GothamBold;
ResetBtn.TextSize = 12
Instance.new("UICorner", ResetBtn).CornerRadius = UDim.new(0, 10); Instance.new("UIStroke", ResetBtn).Color = THEME.Red;
Instance.new("UIStroke", ResetBtn).Thickness = 1
ResetBtn.MouseButton1Click:Connect(function()
	SoundManager.Play("Click"); ESP_SETTINGS.Hitbox = false
	local sw = HitToggleBtn:FindFirstChild("Frame"); if sw then CreateTween(sw, {BackgroundColor3 = Color3.fromRGB(45,45,55)}); local c = sw:FindFirstChild("Frame"); if c then CreateTween(c, {Position = UDim2.new(0, 2, 0.5, -9)}) end end
	ResetHitboxLogic()
end)
-- [[ BUILD AIMBOT (PARENTED TO AIMSCROLL) ]]
CreateToggle(AimScroll, "Enable Aimbot", "Aimbot")
CreateToggle(AimScroll, "Team Check", "AimTeamCheck")
CreateToggle(AimScroll, "Show FOV", "AimFOV")
CreateToggle(AimScroll, "Prioritize Distance", "AimSmartDist")
CreateToggle(AimScroll, "Wall Check", "AimWallCheck")

CreateButton(AimScroll, "Target Part: Head", function(btn) 
	if ESP_SETTINGS.AimPart == "Head" then ESP_SETTINGS.AimPart = "Torso" else ESP_SETTINGS.AimPart = "Head" end
	btn.Text = "Target Part: " .. ESP_SETTINGS.AimPart
end)

-- [[ KOPI'S HUB - LOGIC ]]

local ESPStore = {}

-- [[ 1:1 SNIPPET VARS ]]
local FOVring = Drawing.new("Circle")
FOVring.Visible = false 
FOVring.Thickness = 1.5
FOVring.Color = Color3.fromRGB(90, 140, 255)
FOVring.Filled = false
FOVring.Radius = ESP_SETTINGS.AimRadius
FOVring.Position = Camera.ViewportSize / 2

local function D(t,p)
	local d=Drawing.new(t)
	for k,v in pairs(p) do d[k]=v end
	return d
end

local function cleanup(p)
	if ESPStore[p] then
		for _,d in pairs(ESPStore[p]) do
			if typeof(d)=="table" then for _,s in pairs(d) do s:Remove() end else d:Remove() end
		end
		ESPStore[p]=nil
	end
end

-- [[ FIXED CHAMS LOGIC ]]
local function ApplyChams(character)
	local old = character:FindFirstChild("KopiHighlight")
	if old then old:Destroy() end
	local h = Instance.new("Highlight", character)
	h.Name = "KopiHighlight"
	h.FillTransparency = 0.35
	h.OutlineTransparency = 0.1
	h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
end

local function PlayerSetup(p)
	if p.Character then ApplyChams(p.Character) end
	p.CharacterAdded:Connect(function(char)
		task.wait(0.5)
		ApplyChams(char)
	end)
end

for _, p in ipairs(Players:GetPlayers()) do
	if p ~= LocalPlayer then PlayerSetup(p) end
end
Players.PlayerAdded:Connect(PlayerSetup)

local function isRainbowTarget(name)
	name = name:lower()
	for _,p in ipairs(RainbowTargets) do if name:sub(1,#p) == p then return true 
end end
	return false
end

local function GetRainbow() return Color3.fromHSV((tick()*0.5)%1, 0.8, 1) end

-- [[ SNIPPET LOGIC FUNCTIONS ]]
local function updateDrawings()
    local camViewportSize = Camera.ViewportSize
    FOVring.Position = camViewportSize / 2
	FOVring.Radius = ESP_SETTINGS.AimRadius -- Dynamic Update
	
	-- Visibility Logic
	if ESP_SETTINGS.Aimbot and ESP_SETTINGS.AimFOV then
		FOVring.Visible = true
	else
		FOVring.Visible = false
	end
end

local function lookAt(target)
    local lookVector = (target - Camera.CFrame.Position).unit
    local newCFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + lookVector)
    Camera.CFrame = newCFrame
end

local function getClosestPlayerInFOV(trg_part)
    local nearest = nil
    local last = math.huge
    local playerMousePos = Camera.ViewportSize / 2

  
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer then
			-- [[ TEAM CHECK ]]
			if ESP_SETTINGS.AimTeamCheck and player.Team == LocalPlayer.Team then
				-- Skip
			else
				local character = player.Character
				if character then
					-- [[ DEAD CHECK: Added Health Check ]]
					local humanoid = character:FindFirstChild("Humanoid")
					if humanoid and humanoid.Health > 0 then
					
						-- [[ INTELLIGENT R15/R6 PART FINDER ]]
						local part = character:FindFirstChild(trg_part)
						if not part and trg_part == "Torso" then part = character:FindFirstChild("UpperTorso") end
						if not part then part = character:FindFirstChild("HumanoidRootPart") end
	
			            if part then
			        
                local ePos, isVisible = Camera:WorldToViewportPoint(part.Position)
			                local dist2D = (Vector2.new(ePos.x, ePos.y) - playerMousePos).Magnitude
			
			                if isVisible and dist2D < ESP_SETTINGS.AimRadius then
								
								-- [[ WALL CHECK ]]
								local isObstructed = false
								if ESP_SETTINGS.AimWallCheck then
									local params = RaycastParams.new()
									params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
									params.FilterType = Enum.RaycastFilterType.Exclude
									
									local direction = part.Position - Camera.CFrame.Position
									local result = workspace:Raycast(Camera.CFrame.Position, direction, params)
									
									if result and not result.Instance:IsDescendantOf(character) then
										isObstructed = true
									end
								end
								
								if not isObstructed then
									-- [[ DISTANCE PRIORITY LOGIC ]]
									if ESP_SETTINGS.AimSmartDist 
then
										local dist3D = (LocalPlayer.Character.HumanoidRootPart.Position - part.Position).Magnitude
										if dist3D < last then
											last = dist3D
											nearest = player
										end
									else
										if dist2D < last then
											last = dist2D
											nearest = player
										end
									end
								end
			                end
			            end
					end
				end
			end
        end
    end

    return nearest
end

-- [[ PASSIVE ANIMATION LOOP ]]
task.spawn(function()
	while task.wait() do
		StrokeGradient.Rotation = (StrokeGradient.Rotation + 1) % 360
		BgGradient.Rotation = (BgGradient.Rotation + 0.2) % 360
	end
end)
-- [[ MAIN LOOP ]]
RunService.RenderStepped:Connect(function()
	local vp = Camera.ViewportSize
	local center = Vector2.new(vp.X/2, vp.Y/2)
	
	-- [[ AIMBOT EXECUTION ]]
	updateDrawings() 
	
	if ESP_SETTINGS.Aimbot then
	    local closest = getClosestPlayerInFOV(ESP_SETTINGS.AimPart)
	    if closest and closest.Character then
			FOVring.Color = Color3.fromRGB(255, 60, 70) -- Red when locked
			local part = closest.Character:FindFirstChild(ESP_SETTINGS.AimPart)
			if not part and ESP_SETTINGS.AimPart == "Torso" then part = closest.Character:FindFirstChild("UpperTorso") end
			if not part then part = closest.Character:FindFirstChild("HumanoidRootPart") end
			if part then lookAt(part.Position) end
		else
			FOVring.Color = Color3.fromRGB(140, 60, 255) -- Searching
	    end
	else
		FOVring.Visible = false
	end

	-- [[ ESP & HITBOX ]]
	local R15_LINKS = {
		{"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"}, {"LowerTorso", "LeftUpperLeg"},
		{"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"}, {"LowerTorso", "RightUpperLeg"},
		{"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}, {"UpperTorso", "LeftUpperArm"},
		{"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"}, {"UpperTorso", "RightUpperArm"},
		{"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"}
	}
	local R6_LINKS = {{"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"}}

	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character then
			local hum = p.Character:FindFirstChild("Humanoid")
			local hrp = p.Character:FindFirstChild("HumanoidRootPart")
			
			if hum and hrp and hum.Health > 0 then
				
				local isTeammate = (p.Team == LocalPlayer.Team)
				
				if ESP_SETTINGS.Hitbox then
					-- [[ MODIFIED: Using HitboxTeamCheck ]]
					if not (ESP_SETTINGS.HitboxTeamCheck and isTeammate) then
						pcall(function()
							hrp.Size = Vector3.new(ESP_SETTINGS.HitboxSize, ESP_SETTINGS.HitboxSize, ESP_SETTINGS.HitboxSize)
							hrp.Transparency = 0.7
							hrp.CanCollide = false
							
							if ESP_SETTINGS.UniversalColor then
								hrp.Color = Color3.fromRGB(0, 0, 255)
								hrp.Material = Enum.Material.Neon
							else
								if isRainbowTarget(p.Name) then
									hrp.Color = GetRainbow();
                                    hrp.Material = Enum.Material.Neon
								else
									hrp.Color = p.TeamColor.Color; hrp.Material = Enum.Material.ForceField
								end
							end
						end)
					end
				end

				if ESP_SETTINGS.HideTeam and isTeammate then
					cleanup(p);
                    local h = p.Character:FindFirstChild("KopiHighlight")
					if h then h.Enabled = false end
					continue
				end
				
				if not ESPStore[p] then
					ESPStore[p] = {
						-- Using thin lines for premium box look
						Box = D("Square", {Thickness=1, Filled=false, Transparency=1}),
						BoxOutline = D("Square", {Thickness=2, Filled=false, Transparency=0.6, Color=Color3.new(0,0,0)}),
						Tracer = D("Line", {Thickness=1, Transparency=1}),
						Name = D("Text", {Size=13, Center=true, Outline=true, Font=3}), 
						Info = D("Text", {Size=11, Center=true, Outline=true, Font=3}),
						-- [[ PREMIUM HEALTH BAR OBJECTS ]]
						BarBorder = D("Square", {Thickness=1, Filled=false, Transparency=1, Color=Color3.new(0,0,0)}), -- New Outline
						BarTrack = D("Square", {Filled=true, Transparency=0.6, Color=Color3.fromRGB(20,20,25)}),
						Bar = D("Square", {Filled=true, Transparency=1}), 
						HPText = D("Text", {Size=10, Center=true, Outline=true, Font=2, Color=Color3.new(1,1,1)}),
						
						Head = D("Circle", {Thickness=1, NumSides=30, Radius=0, Filled=false}),
						Skeleton = {}
					}
					for i=1, 15 do table.insert(ESPStore[p].Skeleton, D("Line", {Thickness=1.5, Color=Color3.new(1,1,1)})) end
				end
				
				local esp = ESPStore[p]
				local col = isRainbowTarget(p.Name) and GetRainbow() or p.TeamColor.Color
				local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
				
				-- [[ NEW WALLCHECK LOGIC ]]
                local behindWall = false
                if ESP_SETTINGS.WallCheck and onScreen then
                    local params = RaycastParams.new()
                    params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
                    params.FilterType = Enum.RaycastFilterType.Exclude
                    local castTarget = p.Character:FindFirstChild("Head") or hrp
                    local dir = castTarget.Position - Camera.CFrame.Position
                    local result = workspace:Raycast(Camera.CFrame.Position, dir, params)
                    if result and not result.Instance:IsDescendantOf(p.Character) then
                        behindWall = true
                    end
                end

				local cham = p.Character:FindFirstChild("KopiHighlight")
				if not cham then if ESP_SETTINGS.Chams then ApplyChams(p.Character) end
				else 
					cham.Enabled = ESP_SETTINGS.Chams;
                    cham.FillColor = col; cham.OutlineColor = Color3.new(1,1,1)
					cham.FillTransparency = 0.35; cham.OutlineTransparency = 0.1
				end
				
				if onScreen then
					-- Dynamic Size for Box (Still needed for perspective of the box itself)
					local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
					local size = math.clamp(2000/pos.Z, 25, 300)
					local w, h = size, size*1.5
					
					esp.BoxOutline.Visible = ESP_SETTINGS.Box; esp.Box.Visible = ESP_SETTINGS.Box
                    if ESP_SETTINGS.Box then
                        esp.Box.Size = Vector2.new(w, h); esp.Box.Position = Vector2.new(pos.X - w/2, pos.Y - h/2); esp.Box.Color = col
                        esp.Box.Transparency = behindWall and 0.3 or 1  -- Add this line
                        esp.BoxOutline.Size = Vector2.new(w, h); esp.BoxOutline.Position = esp.Box.Position
                        esp.BoxOutline.Transparency = behindWall and 0.15 or 0.6  -- Add this line
                    end
					
					esp.Tracer.Visible = ESP_SETTINGS.Tracers
                    if ESP_SETTINGS.Tracers then
                        esp.Tracer.From = Vector2.new(center.X, vp.Y); esp.Tracer.To = Vector2.new(pos.X, pos.Y + h/2); esp.Tracer.Color = col
                        esp.Tracer.Transparency = behindWall and 0.3 or 1  -- Add this line
                    end
					
					esp.Name.Visible = ESP_SETTINGS.Names
                    if ESP_SETTINGS.Names then
                        esp.Name.Text = p.Name; esp.Name.Position = Vector2.new(pos.X, pos.Y - h/2 - 16); esp.Name.Color = col
                        esp.Name.Transparency = behindWall and 0.4 or 1  -- Add this line
                    end
					
					esp.Info.Visible = ESP_SETTINGS.Distance
                    if esp.Info.Visible then
                        esp.Info.Text = math.floor(dist).."m"; esp.Info.Position = Vector2.new(pos.X, pos.Y + h/2 + 2); esp.Info.Color = col
                        esp.Info.Transparency = behindWall and 0.4 or 1  -- Add this line
                    end
					
					-- [[ PREMIUM FIXED HEIGHT BAR ]]
					esp.Bar.Visible = ESP_SETTINGS.HealthBar
					esp.BarTrack.Visible = ESP_SETTINGS.HealthBar
					esp.BarBorder.Visible = ESP_SETTINGS.HealthBar
					esp.HPText.Visible = ESP_SETTINGS.HealthBar

					if ESP_SETTINGS.HealthBar then
						local hp = math.clamp(hum.Health/hum.MaxHealth, 0, 1)
						
						-- STATIC SETTINGS (LOCKED):
						local staticHeight = 50 
						local staticWidth = 5  -- Thin Premium Line
						
						-- Position relative to box edge
						local barX = pos.X - w/2 - (staticWidth + 6)
						
						-- Vertical Centers
						local barTop = pos.Y - staticHeight/2
						local barBot = pos.Y + staticHeight/2
						local filledHeight = staticHeight * hp
						
						-- Border (1px bigger)
						esp.BarBorder.Size = Vector2.new(staticWidth + 2, staticHeight + 2)
						esp.BarBorder.Position = Vector2.new(barX - 1, barTop - 1)
						
						-- Track
						esp.BarTrack.Size = Vector2.new(staticWidth, staticHeight)
						esp.BarTrack.Position = Vector2.new(barX, barTop)
						
						-- Fill
                        esp.Bar.Size = Vector2.new(staticWidth, filledHeight)
                        esp.Bar.Position = Vector2.new(barX, barBot - filledHeight)
                        esp.Bar.Color = Color3.fromHSV(hp * 0.33, 0.9, 1)
                        esp.Bar.Transparency = behindWall and 0.3 or 1  -- Add this line

                        esp.HPText.Text = tostring(math.floor(hum.Health))
                        esp.HPText.Position = Vector2.new(barX + (staticWidth/2), pos.Y - 5)
                        esp.HPText.Transparency = behindWall and 0.4 or 1  -- Add this line
					end
					
					local doSkel = ESP_SETTINGS.Skeleton
					for _, l in ipairs(esp.Skeleton) do l.Visible = false end
					esp.Head.Visible = false
					
					if doSkel then
						local hObj = p.Character:FindFirstChild("Head")
						if hObj then
							local hp, hon = Camera:WorldToViewportPoint(hObj.Position)
							if hon then
								esp.Head.Visible = true; esp.Head.Position = Vector2.new(hp.X, hp.Y); esp.Head.Radius = math.clamp(400/pos.Z, 4, 15); esp.Head.Color = col
                                esp.Head.Transparency = behindWall and 0.3 or 1  -- Add this line
							end
						end
						local links = (hum.RigType == Enum.HumanoidRigType.R15) and R15_LINKS or R6_LINKS
						for i, lnk in ipairs(links) do
							local l = esp.Skeleton[i]
							if l then
								local p1 = p.Character:FindFirstChild(lnk[1]);
                                local p2 = p.Character:FindFirstChild(lnk[2])
								if p1 and p2 then
									local s1, o1 = Camera:WorldToViewportPoint(p1.Position);
                                    local s2, o2 = Camera:WorldToViewportPoint(p2.Position)
                                    if o1 and o2 then
                                        l.Visible = true; l.From = Vector2.new(s1.X, s1.Y); l.To = Vector2.new(s2.X, s2.Y); l.Color = col
                                        l.Transparency = behindWall and 0.3 or 1  -- Add this line
                                    end
								end
							end
						end
					end
				else
					for _, d in pairs(esp) do
						if typeof(d)=="table" then for _,s in pairs(d) do s.Visible=false end else d.Visible=false end
					end
				end
			else
				cleanup(p)
			end
		end
	end
end)

Players.PlayerRemoving:Connect(cleanup)
if CoreGui:FindFirstChild("KOPI_PREMIUM_UI") then
	local mf = CoreGui.KOPI_PREMIUM_UI:FindFirstChild("Frame")
	if mf then mf.Visible = true end
end
