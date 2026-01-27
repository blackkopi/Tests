-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local FileName = "Waypoints_" .. tostring(game.PlaceId) .. ".json"

-- ================= THEME =================
local THEME = {
    Bg = Color3.fromRGB(12, 12, 18),
    Header = Color3.fromRGB(18, 18, 25),
    Accent = Color3.fromRGB(90, 140, 255),
    Text = Color3.fromRGB(245, 245, 255),
    TextDim = Color3.fromRGB(140, 140, 160),
    Stroke = Color3.fromRGB(45, 45, 65),
    Red = Color3.fromRGB(255, 60, 70),
    Green = Color3.fromRGB(80, 255, 140)
}

-- ================= UTILS =================
local Waypoints = {}
local AutoTPTarget = nil
local CurrentAutoTPName = nil

local function SaveData()
    if writefile then writefile(FileName, HttpService:JSONEncode(Waypoints)) end
end

local function LoadData()
    if isfile and isfile(FileName) then
        pcall(function() Waypoints = HttpService:JSONDecode(readfile(FileName)) end)
    end
end
LoadData()

-- Sound Manager
local SoundManager = {}
local SoundRoot = Instance.new("Folder", SoundService)
SoundRoot.Name = "WaypointSounds"
local Sounds = {
    Click = "rbxassetid://6895079853",
    Open = "rbxassetid://241837157",
    Toggle = "rbxassetid://6895079853"
}
function SoundManager.Play(name)
    local s = Instance.new("Sound", SoundRoot)
    s.SoundId = Sounds[name]
    s.Volume = 0.5
    s:Play()
    game.Debris:AddItem(s, 2)
end

local function CreateTween(obj, props, time)
    TweenService:Create(obj, TweenInfo.new(time or 0.25, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), props):Play()
end

-- ================= UI CONSTRUCTION =================
if CoreGui:FindFirstChild("KOPI_WAYPOINTS_UI") then CoreGui.KOPI_WAYPOINTS_UI:Destroy() end
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "KOPI_WAYPOINTS_UI"
ScreenGui.ResetOnSpawn = false

-- [[ DRAGGING SYSTEM (EXACT COPY FROM SOURCE) ]]
local dragging, dragInput, dragStart, startPos, activeFrame
local isMoving = false

local function UpdateDrag(input)
    if not activeFrame then return end
    local delta = input.Position - dragStart
    [span_2](start_span)if delta.Magnitude > 3 then isMoving = true end --[span_2](end_span)
    
    local targetX = startPos.X.Offset + delta.X
    local targetY = startPos.Y.Offset + delta.Y
    local vp = Camera.ViewportSize
    local frameSize = activeFrame.AbsoluteSize
    
    -- Clamp to screen
    local clampedX = math.clamp(targetX, 0, vp.X - frameSize.X)
    local clampedY = math.clamp(targetY, 0, vp.Y - frameSize.Y)
    
    [span_3](start_span)CreateTween(activeFrame, {Position = UDim2.fromOffset(clampedX, clampedY)}, 0.08) --[span_3](end_span)
end

local function MakeDraggable(trigger, frameToMove, onClick)
    trigger.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            isMoving = false
            dragStart = input.Position
            startPos = frameToMove.Position
            [span_4](start_span)activeFrame = frameToMove --[span_4](end_span)
            
            local con
            con = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    con:Disconnect()
                    -[span_5](start_span)- Click Trigger[span_5](end_span)
                    if not isMoving and onClick then onClick() end
                end
            end)
        end
    end)
end

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        [span_6](start_span)UpdateDrag(input) --[span_6](end_span)
    end
end)

-- [[ MAIN FRAME ]]
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.fromOffset(320, 140) -- Starts small (Header + Input)
MainFrame.Position = UDim2.fromOffset(100, 100)
MainFrame.BackgroundColor3 = THEME.Bg
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 16)

-- Glow & Bg
local UIStroke = Instance.new("UIStroke", MainFrame)
UIStroke.Color = Color3.fromRGB(255, 255, 255); UIStroke.Thickness = 2.5; UIStroke.Transparency = 0
local StrokeGradient = Instance.new("UIGradient", UIStroke)
StrokeGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, THEME.Stroke), ColorSequenceKeypoint.new(0.5, THEME.Accent), ColorSequenceKeypoint.new(1, THEME.Stroke)}
StrokeGradient.Rotation = 45
local BgGradient = Instance.new("UIGradient", MainFrame)
BgGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.new(1,1,1)), ColorSequenceKeypoint.new(1, Color3.fromRGB(150,150,160))}
BgGradient.Rotation = 90

-- [[ PILL (MINIMIZED) ]]
local MiniFrame = Instance.new("Frame", ScreenGui)
MiniFrame.Size = UDim2.fromOffset(120, 36)
MiniFrame.Position = MainFrame.Position
MiniFrame.BackgroundColor3 = THEME.Header
MiniFrame.Visible = false
Instance.new("UICorner", MiniFrame).CornerRadius = UDim.new(1, 0)
local MiniStroke = Instance.new("UIStroke", MiniFrame)
MiniStroke.Color = THEME.Accent; MiniStroke.Thickness = 2
local MiniLabel = Instance.new("TextLabel", MiniFrame)
MiniLabel.Size = UDim2.new(1,0,1,0); MiniLabel.BackgroundTransparency=1; MiniLabel.Text="WAYPOINTS"; MiniLabel.Font=Enum.Font.GothamBlack; MiniLabel.TextSize=12; MiniLabel.TextColor3=THEME.Accent

-- [[ HEADER ]]
local Header = Instance.new("Frame", MainFrame)
Header.Size = UDim2.new(1, 0, 0, 48)
Header.BackgroundColor3 = THEME.Header
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 16)
local Title = Instance.new("TextLabel", Header)
Title.Text = "WAYPOINT <font color=\"rgb(90,140,255)\">MANAGER</font>"; Title.RichText=true; Title.Font=Enum.Font.GothamBlack; Title.TextSize=18; Title.TextColor3=THEME.Text; Title.Position=UDim2.new(0, 16, 0, 0); Title.Size=UDim2.new(1, -60, 1, 0); Title.BackgroundTransparency=1; Title.TextXAlignment=Enum.TextXAlignment.Left

local MinimizeBtn = Instance.new("TextButton", Header)
MinimizeBtn.Size = UDim2.fromOffset(32, 32); MinimizeBtn.Position = UDim2.new(1, -44, 0.5, -16)
MinimizeBtn.Text = "-"; MinimizeBtn.Font=Enum.Font.GothamBlack; MinimizeBtn.TextSize=20; MinimizeBtn.TextColor3=THEME.TextDim; MinimizeBtn.BackgroundColor3=Color3.fromRGB(35,35,45)
Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0, 10)

-- Logic: Switch Views
local function OpenMain()
    SoundManager.Play("Open")
    MainFrame.Position = MiniFrame.Position
    MiniFrame.Visible = false
    MainFrame.Visible = true
end

local function OpenMini()
    SoundManager.Play("Click")
    MiniFrame.Position = MainFrame.Position
    MainFrame.Visible = false
    MiniFrame.Visible = true
end

MakeDraggable(Header, MainFrame, nil) -- Drag Main
[span_7](start_span)MakeDraggable(MiniFrame, MiniFrame, OpenMain) -- Drag Mini + Click to Open[span_7](end_span)
MinimizeBtn.MouseButton1Click:Connect(OpenMini)

-- [[ CONTENT ]]
local InputContainer = Instance.new("Frame", MainFrame)
InputContainer.Size = UDim2.new(1, -24, 0, 80)
InputContainer.Position = UDim2.new(0, 12, 0, 56)
InputContainer.BackgroundTransparency = 1

local WPInput = Instance.new("TextBox", InputContainer)
WPInput.Size = UDim2.new(1, 0, 0, 40)
WPInput.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
WPInput.TextColor3 = THEME.Text
WPInput.PlaceholderText = "Enter Waypoint Name..."
WPInput.Font = Enum.Font.GothamSemibold
WPInput.TextSize = 14
Instance.new("UICorner", WPInput).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", WPInput).Color = THEME.Stroke

local AddBtn = Instance.new("TextButton", InputContainer)
AddBtn.Size = UDim2.new(1, 0, 0, 34); AddBtn.Position = UDim2.new(0, 0, 0, 46)
AddBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40); AddBtn.Text = "CREATE WAYPOINT"; AddBtn.TextColor3 = THEME.Accent; AddBtn.Font = Enum.Font.GothamBold; AddBtn.TextSize = 12
Instance.new("UICorner", AddBtn).CornerRadius = UDim.new(0, 8); Instance.new("UIStroke", AddBtn).Color = THEME.Accent; Instance.new("UIStroke", AddBtn).Thickness = 1

-- Scroll List
local ScrollBox = Instance.new("ScrollingFrame", MainFrame)
ScrollBox.Size = UDim2.new(1, -24, 0, 0) -- Start Height 0
ScrollBox.Position = UDim2.new(0, 12, 0, 145)
ScrollBox.BackgroundTransparency = 1
ScrollBox.BorderSizePixel = 0
ScrollBox.ScrollBarThickness = 3
ScrollBox.ScrollBarImageColor3 = THEME.Accent

local ListLayout = Instance.new("UIListLayout", ScrollBox)
ListLayout.Padding = UDim.new(0, 6)

-- [[ DYNAMIC RESIZING LOGIC ]]
ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    local contentHeight = ListLayout.AbsoluteContentSize.Y
    
    -- Limit growth to 300px, then scroll
    local displayHeight = math.clamp(contentHeight, 0, 300) 
    
    -- Resize ScrollBox
    ScrollBox.Size = UDim2.new(1, -24, 0, displayHeight)
    ScrollBox.CanvasSize = UDim2.fromOffset(0, contentHeight)
    
    -- Resize MainFrame (Header(48) + Input(80) + Spacing(20) + ListHeight)
    local targetHeight = 148 + displayHeight + 10 -- Added padding
    CreateTween(MainFrame, {Size = UDim2.fromOffset(320, targetHeight)}, 0.2)
end)

-- [[ FUNCTIONALITY ]]
local function RefreshList()
    for _, c in ipairs(ScrollBox:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    
    for name, posData in pairs(Waypoints) do
        local Item = Instance.new("Frame", ScrollBox)
        Item.Size = UDim2.new(1, -6, 0, 38)
        Item.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        Instance.new("UICorner", Item).CornerRadius = UDim.new(0, 8)
        
        local NameLabel = Instance.new("TextLabel", Item)
        NameLabel.Text = name; NameLabel.Size = UDim2.new(0.4, 0, 1, 0); NameLabel.Position = UDim2.new(0, 12, 0, 0); NameLabel.Font = Enum.Font.GothamSemibold; NameLabel.TextColor3 = THEME.Text; NameLabel.TextXAlignment = Enum.TextXAlignment.Left; NameLabel.BackgroundTransparency = 1; NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        
        local DelBtn = Instance.new("TextButton", Item); DelBtn.Size = UDim2.fromOffset(24, 24); DelBtn.Position = UDim2.new(1, -28, 0.5, -12); DelBtn.Text = "✕"; DelBtn.BackgroundColor3 = THEME.Red; DelBtn.TextColor3 = Color3.new(1, 1, 1); Instance.new("UICorner", DelBtn).CornerRadius = UDim.new(0, 6)
        
        local TpBtn = Instance.new("TextButton", Item); TpBtn.Size = UDim2.new(0, 40, 0, 24); TpBtn.Position = UDim2.new(1, -75, 0.5, -12); TpBtn.Text = "TP"; TpBtn.BackgroundColor3 = THEME.Accent; TpBtn.TextColor3 = Color3.new(1, 1, 1); TpBtn.Font = Enum.Font.GothamBold; TpBtn.TextSize = 10; Instance.new("UICorner", TpBtn).CornerRadius = UDim.new(0, 6)
        
        local LoopBtn = Instance.new("TextButton", Item); LoopBtn.Size = UDim2.new(0, 40, 0, 24); LoopBtn.Position = UDim2.new(1, -120, 0.5, -12); LoopBtn.Text = "LOOP"; LoopBtn.BackgroundColor3 = (CurrentAutoTPName == name) and THEME.Green or Color3.fromRGB(50, 50, 60); LoopBtn.TextColor3 = Color3.new(1, 1, 1); LoopBtn.Font = Enum.Font.GothamBold; LoopBtn.TextSize = 9; Instance.new("UICorner", LoopBtn).CornerRadius = UDim.new(0, 6)
        
        DelBtn.MouseButton1Click:Connect(function()
            SoundManager.Play("Click")
            Waypoints[name] = nil
            if CurrentAutoTPName == name then CurrentAutoTPName = nil; AutoTPTarget = nil end
            SaveData(); RefreshList()
        end)
        
        TpBtn.MouseButton1Click:Connect(function()
            SoundManager.Play("Click")
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(posData.x, posData.y, posData.z)
            end
        end)
        
        LoopBtn.MouseButton1Click:Connect(function()
            SoundManager.Play("Toggle")
            if CurrentAutoTPName == name then
                CurrentAutoTPName = nil; AutoTPTarget = nil
            else
                CurrentAutoTPName = name; AutoTPTarget = Vector3.new(posData.x, posData.y, posData.z)
            end
            RefreshList()
        end)
    end
end

AddBtn.MouseButton1Click:Connect(function()
    local name = WPInput.Text
    if name == "" then name = "WP " .. tostring(math.floor(os.clock())) end
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        SoundManager.Play("Open")
        local pos = LocalPlayer.Character.HumanoidRootPart.Position
        Waypoints[name] = {x = pos.X, y = pos.Y, z = pos.Z}
        SaveData(); WPInput.Text = ""; RefreshList()
    end
end)

-- Animation Loops
task.spawn(function()
    while task.wait() do
        StrokeGradient.Rotation = (StrokeGradient.Rotation + 1) % 360
        BgGradient.Rotation = (BgGradient.Rotation + 0.2) % 360
    end
end)

RunService.RenderStepped:Connect(function()
    if AutoTPTarget and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local currentRot = LocalPlayer.Character.HumanoidRootPart.CFrame.Rotation
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(AutoTPTarget) * currentRot
        if LocalPlayer.Character.HumanoidRootPart:FindFirstChild("AssemblyLinearVelocity") then
            LocalPlayer.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
        end
    end
end)

RefreshList()
