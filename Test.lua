local rs = game:GetService("ReplicatedStorage")
local uis = game:GetService("UserInputService")
local workspace = game:GetService("Workspace")
local runService = game:GetService("RunService")
local tweenService = game:GetService("TweenService")
local soundService = game:GetService("SoundService")
local coreGui = game:GetService("CoreGui")
local players = game:GetService("Players")

-- // CONFIGURATION //
getgenv().config = {
    autofire = true,
    fps_mode = true, -- Auto Enter FPS
    mode = "Strongest",     
    multiply = 10,
    cooldown = 0.05,
    norecoil = true
}

-- // THEME //
local THEME = {
    Bg = Color3.fromRGB(12, 12, 18), 
    Header = Color3.fromRGB(18, 18, 25),
    Accent = Color3.fromRGB(90, 140, 255), 
    Text = Color3.fromRGB(245, 245, 255),
    TextDim = Color3.fromRGB(140, 140, 160),
    Stroke = Color3.fromRGB(45, 45, 65),
}

-- // SOUNDS //
local SoundManager = {}
local SoundRoot = Instance.new("Folder", soundService)
SoundRoot.Name = "KopiSounds"
local function CreateSound(id, vol)
    local s = Instance.new("Sound", SoundRoot)
    s.SoundId = id; s.Volume = vol; return s
end
local Sounds = {
    Click = CreateSound("rbxassetid://6895079853", 0.4),
    Open = CreateSound("rbxassetid://241837157", 0.4),
    Toggle = CreateSound("rbxassetid://6895079853", 0.3)
}
function SoundManager.Play(name)
    pcall(function()
        if Sounds[name] then
            local s = Sounds[name]:Clone()
            s.Parent = SoundRoot
            if name=="Toggle" then s.PlaybackSpeed=1.1 end
            s:Play(); game.Debris:AddItem(s,2)
        end
    end)
end

-- // UTILS //
local function CreateTween(obj, props, time)
    tweenService:Create(obj, TweenInfo.new(time or 0.25, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), props):Play()
end

local function MakeDraggable(trigger, target)
    trigger.Active = true
    trigger.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local dragStart = input.Position
            local startPos = target.Position
            local dragging = true
            
            local inputChanged
            inputChanged = uis.InputChanged:Connect(function(moveInput)
                if dragging and (moveInput.UserInputType == Enum.UserInputType.MouseMovement or moveInput.UserInputType == Enum.UserInputType.Touch) then
                    local delta = moveInput.Position - dragStart
                    target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                end
            end)
            
            local inputEnded
            inputEnded = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    inputChanged:Disconnect()
                    inputEnded:Disconnect()
                end
            end)
        end
    end)
end

-- // STATE //
local initialized = false
local currentTarget = nil
local activeTowerPos = nil
local activeTower = nil
local StatusLabel = nil

-- // CLEANUP //
if getgenv().GatlingBrain then getgenv().GatlingBrain:Disconnect() end
if getgenv().GatlingMuscle then getgenv().GatlingMuscle:Disconnect() end
if coreGui:FindFirstChild("KOPI_GATLING_UI") then coreGui.KOPI_GATLING_UI:Destroy() end
if players.LocalPlayer.PlayerGui:FindFirstChild("KOPI_GATLING_UI") then players.LocalPlayer.PlayerGui.KOPI_GATLING_UI:Destroy() end

-- // UI CREATION (Run First) //
local function CreateUI()
    local parent = nil
    -- Try CoreGui first, fallback to PlayerGui
    local success = pcall(function() 
        coreGui:FindFirstChild("RobloxGui") -- Just a check
        parent = coreGui 
    end)
    
    if not success or not parent then 
        parent = players.LocalPlayer:WaitForChild("PlayerGui") 
    end
    
    local ScreenGui = Instance.new("ScreenGui", parent)
    ScreenGui.Name = "KOPI_GATLING_UI"
    ScreenGui.ResetOnSpawn = false
    -- Higher ZIndex to ensure it sits on top of game UI
    ScreenGui.DisplayOrder = 10000 

    local MainFrame = Instance.new("Frame", ScreenGui)
    MainFrame.Size = UDim2.fromOffset(280, 320)
    MainFrame.Position = UDim2.fromOffset(100, 200)
    MainFrame.BackgroundColor3 = THEME.Bg
    MainFrame.BorderSizePixel = 0
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 16)

    local UIStroke = Instance.new("UIStroke", MainFrame)
    UIStroke.Color = Color3.fromRGB(255, 255, 255)
    UIStroke.Thickness = 2.5
    local StrokeGradient = Instance.new("UIGradient", UIStroke)
    StrokeGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, THEME.Stroke), ColorSequenceKeypoint.new(0.5, THEME.Accent), ColorSequenceKeypoint.new(1, THEME.Stroke)}
    StrokeGradient.Rotation = 45

    local BgGradient = Instance.new("UIGradient", MainFrame)
    BgGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.new(1,1,1)), ColorSequenceKeypoint.new(1, Color3.fromRGB(150,150,160))}
    BgGradient.Rotation = 90

    task.spawn(function()
        while task.wait() do
            if StrokeGradient.Parent then
                StrokeGradient.Rotation = (StrokeGradient.Rotation + 1) % 360
                BgGradient.Rotation = (BgGradient.Rotation + 0.2) % 360
            else
                break
            end
        end
    end)

    local Header = Instance.new("Frame", MainFrame)
    Header.Size = UDim2.new(1, 0, 0, 48)
    Header.BackgroundColor3 = THEME.Header
    Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 16)
    
    local Title = Instance.new("TextLabel", Header)
    Title.Text = "KOPI'S <font color=\"rgb(90,140,255)\">GATLING</font>"
    Title.RichText = true; Title.Font = Enum.Font.GothamBlack; Title.TextSize = 18
    Title.TextColor3 = THEME.Text; Title.Position = UDim2.new(0, 16, 0, 0)
    Title.Size = UDim2.new(1, -60, 1, 0); Title.BackgroundTransparency = 1; Title.TextXAlignment = Enum.TextXAlignment.Left

    local MiniFrame = Instance.new("Frame", ScreenGui)
    MiniFrame.Size = UDim2.fromOffset(120, 36); MiniFrame.BackgroundColor3 = THEME.Header; MiniFrame.Visible = false
    MiniFrame.Position = MainFrame.Position 
    Instance.new("UICorner", MiniFrame).CornerRadius = UDim.new(1, 0)
    local MiniStroke = Instance.new("UIStroke", MiniFrame); MiniStroke.Color = THEME.Accent; MiniStroke.Thickness = 2
    local MiniLabel = Instance.new("TextLabel", MiniFrame); MiniLabel.Size = UDim2.new(1,0,1,0); MiniLabel.BackgroundTransparency=1
    MiniLabel.Text = "OPEN HUB"; MiniLabel.Font=Enum.Font.GothamBlack; MiniLabel.TextColor3=THEME.Accent
    MiniLabel.ZIndex = 2 

    MakeDraggable(Header, MainFrame)
    MakeDraggable(MiniFrame, MiniFrame)

    local MinimizeBtn = Instance.new("TextButton", Header)
    MinimizeBtn.Size = UDim2.fromOffset(32, 32); MinimizeBtn.Position = UDim2.new(1, -44, 0.5, -16)
    MinimizeBtn.Text = "-"; MinimizeBtn.Font = Enum.Font.GothamBlack; MinimizeBtn.TextSize = 20
    MinimizeBtn.TextColor3 = THEME.TextDim; MinimizeBtn.BackgroundColor3 = Color3.fromRGB(35,35,45)
    Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0, 10)
    
    MinimizeBtn.MouseButton1Click:Connect(function() 
        SoundManager.Play("Click")
        MiniFrame.Position = MainFrame.Position 
        MainFrame.Visible = false; MiniFrame.Visible = true 
    end)
    
    local MiniToggle = Instance.new("TextButton", MiniFrame)
    MiniToggle.Size = UDim2.new(1,0,1,0); MiniToggle.BackgroundTransparency=1; MiniToggle.Text=""; MiniToggle.ZIndex = 5
    MiniToggle.MouseButton1Click:Connect(function() 
        SoundManager.Play("Open")
        MainFrame.Position = MiniFrame.Position
        MiniFrame.Visible = false; MainFrame.Visible = true 
    end)

    local Content = Instance.new("Frame", MainFrame)
    Content.Position = UDim2.new(0, 12, 0, 60); Content.Size = UDim2.new(1, -24, 1, -90); Content.BackgroundTransparency = 1
    local List = Instance.new("UIListLayout", Content); List.Padding = UDim.new(0, 10)

    local function CreateToggle(text, configKey, callback)
        local Btn = Instance.new("TextButton", Content)
        Btn.Size = UDim2.new(1, 0, 0, 38); Btn.BackgroundColor3 = Color3.fromRGB(22, 22, 30); Btn.AutoButtonColor = false; Btn.Text = ""
        Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 10)
        local Lbl = Instance.new("TextLabel", Btn); Lbl.Text = text; Lbl.Font = Enum.Font.GothamSemibold; Lbl.TextSize = 13; Lbl.TextColor3 = THEME.Text
        Lbl.Size = UDim2.new(0.7, 0, 1, 0); Lbl.Position = UDim2.new(0, 14, 0, 0); Lbl.TextXAlignment = Enum.TextXAlignment.Left; Lbl.BackgroundTransparency = 1
        local Sw = Instance.new("Frame", Btn); Sw.Size = UDim2.fromOffset(44, 22); Sw.Position = UDim2.new(1, -54, 0.5, -11)
        Sw.BackgroundColor3 = getgenv().config[configKey] and THEME.Accent or Color3.fromRGB(45,45,55)
        Instance.new("UICorner", Sw).CornerRadius = UDim.new(1, 0)
        local Circ = Instance.new("Frame", Sw); Circ.Size = UDim2.fromOffset(18, 18)
        Circ.Position = getgenv().config[configKey] and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
        Circ.BackgroundColor3 = Color3.new(1,1,1); Instance.new("UICorner", Circ).CornerRadius = UDim.new(1, 0)
        
        Btn.MouseButton1Click:Connect(function()
            getgenv().config[configKey] = not getgenv().config[configKey]
            SoundManager.Play("Toggle")
            if getgenv().config[configKey] then 
                CreateTween(Sw, {BackgroundColor3 = THEME.Accent})
                CreateTween(Circ, {Position = UDim2.new(1, -20, 0.5, -9)})
            else 
                CreateTween(Sw, {BackgroundColor3 = Color3.fromRGB(45,45,55)})
                CreateTween(Circ, {Position = UDim2.new(0, 2, 0.5, -9)}) 
            end
            if callback then callback(getgenv().config[configKey]) end
        end)
    end

    local function CreateButton(text, cb)
        local b = Instance.new("TextButton", Content); b.Size = UDim2.new(1,0,0,36); b.BackgroundColor3 = Color3.fromRGB(30,30,40)
        b.Text = text; b.TextColor3 = THEME.Text; b.Font = Enum.Font.GothamBold; b.TextSize = 12
        Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
        b.MouseButton1Click:Connect(function() SoundManager.Play("Click"); cb(b) end)
    end

    CreateToggle("Auto Fire", "autofire")
    
    CreateButton("Target Mode: " .. getgenv().config.mode, function(b)
        local m = getgenv().config.mode
        if m == "Strongest" then m = "First" elseif m == "First" then m = "Close" else m = "Strongest" end
        getgenv().config.mode = m; b.Text = "Target Mode: " .. m
    end)

    CreateButton("Multiplier: " .. getgenv().config.multiply .. "x", function(b)
        local m = getgenv().config.multiply
        if m == 10 then m = 20 elseif m == 20 then m = 50 else m = 10 end
        getgenv().config.multiply = m; b.Text = "Multiplier: " .. m .. "x"
    end)
    
    CreateButton("Hide UI (Right Ctrl)", function() ScreenGui.Enabled = false end)

    StatusLabel = Instance.new("TextLabel", MainFrame)
    StatusLabel.Position = UDim2.new(0,0,1,-25); StatusLabel.Size = UDim2.new(1,0,0,20)
    StatusLabel.BackgroundTransparency = 1; StatusLabel.TextColor3 = THEME.TextDim
    StatusLabel.Font = Enum.Font.Gotham; StatusLabel.TextSize = 11
    StatusLabel.Text = "Status: Initializing..."

    uis.InputBegan:Connect(function(i) if i.KeyCode == Enum.KeyCode.RightControl then ScreenGui.Enabled = not ScreenGui.Enabled end end)
    SoundManager.Play("Open")
end

-- Call UI creation immediately
CreateUI()

-- // LOGIC START (Spawned separately so UI doesn't freeze) //
task.spawn(function()
    if StatusLabel then StatusLabel.Text = "Status: Waiting for game data..." end
    
    local fpsRemote = rs:WaitForChild("RemoteFunction", 10)
    local reloadEvent
    local success, err = pcall(function()
         reloadEvent = rs:WaitForChild("Network", 10):WaitForChild("GatlingGun", 10):WaitForChild("RE:Reload", 10)
    end)
    
    if not fpsRemote or not reloadEvent then
        if StatusLabel then StatusLabel.Text = "Status: <font color=\"rgb(255,100,100)\">Failed to find Remotes!</font>"; StatusLabel.RichText = true end
        return
    end

    local function ToggleFPS(state)
        if not activeTower then return end
        local args = {
            "Troops", "Abilities", "Activate",
            { Troop = activeTower, Name = "FPS", Data = { enabled = state } }
        }
        task.spawn(function() fpsRemote:InvokeServer(unpack(args)) end)
    end

    local function DoReload()
        if StatusLabel then 
            local oldText = StatusLabel.Text
            StatusLabel.Text = "Status: <font color=\"rgb(255,200,50)\">Auto Reloading...</font>"; StatusLabel.RichText = true
            task.delay(1, function() StatusLabel.Text = oldText end)
        end
        reloadEvent:FireServer()
    end

    -- // LOGIC FUNCTIONS //
    local function get_base_position()
        local commonNames = {"Base", "Exit", "End", "EndPoint", "Lives"}
        for _, name in pairs(commonNames) do
            local found = workspace:FindFirstChild(name, true)
            if found and found:IsA("BasePart") then return found.Position end
        end
        local map = workspace:FindFirstChild("Map")
        if map and map:FindFirstChild("Paths") then
            local path = map.Paths:GetChildren()[1]
            local max, node = -1, nil
            for _, n in ipairs(path:GetChildren()) do
                local num = tonumber(n.Name)
                if num and num > max then max = num; node = n end
            end
            if node then return node.Position end
        end
        return Vector3.new(0, 10, 0)
    end

    local function get_replicator(model)
        local ptr = model:FindFirstChild("RootPointer")
        if ptr and ptr:IsA("ObjectValue") then return ptr.Value end
        return nil
    end

    local function get_stats(model)
        if not model then return 0, 0 end 
        local rep = get_replicator(model)
        if rep then
            if rep:GetAttribute("NoHealth") == true then return 0, 0 end
            local hp = rep:GetAttribute("Health") or rep:GetAttribute("HP") or 0
            local shield = rep:GetAttribute("Shield") or 0
            return hp, shield
        end
        return 0, 0
    end

    local function UpdateTarget()
        local enemies = workspace:FindFirstChild("NPCs") or workspace:FindFirstChild("Enemies")
        if not enemies then return end
        
        local bestTarget = nil
        local bestVal = (getgenv().config.mode == "Strongest") and -1 or 9e9
        
        local basePos = get_base_position()
        local towerPos = activeTowerPos or workspace.CurrentCamera.CFrame.Position

        for _, v in ipairs(enemies:GetChildren()) do
            local hrp = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChild("Head")
            local hp, shield = get_stats(v)
            
            if hrp and hp > 0 then
                local val = 0
                if getgenv().config.mode == "Strongest" then 
                    val = hp + shield
                    if val > bestVal then bestVal = val; bestTarget = hrp end
                elseif getgenv().config.mode == "First" then 
                    val = (hrp.Position - basePos).Magnitude
                    if val < bestVal then bestVal = val; bestTarget = hrp end
                elseif getgenv().config.mode == "Close" then 
                    val = (hrp.Position - towerPos).Magnitude
                    if val < bestVal then bestVal = val; bestTarget = hrp end
                end
            end
        end
        currentTarget = bestTarget
    end

    local function StartHooks(Tower)
        if initialized then return end
        
        local success, err = pcall(function()
            local ggchannel = require(rs.Resources.Universal.NewNetwork).Channel("GatlingGun")
            local gganim = require(rs.Content.Tower["Gatling Gun"].Animator)
            gganim._fireGun = function() end 
            
            getgenv().GatlingMuscle = task.spawn(function()
                while true do
                    if getgenv().config.autofire and currentTarget then
                        local hp, _ = get_stats(currentTarget.Parent)
                        if currentTarget.Parent and hp > 0 then
                            local pos = currentTarget.Position
                            local sync = workspace:GetAttribute("Sync")
                            local sTime = workspace:GetServerTimeNow()
                            for i = 1, getgenv().config.multiply do
                                ggchannel:fireServer("Fire", pos, sync, sTime)
                            end
                        else
                            UpdateTarget()
                        end
                    end
                    task.wait(getgenv().config.cooldown)
                end
            end)
        end)
        
        if not success then
            warn("Hook Error: " .. tostring(err))
            if StatusLabel then StatusLabel.Text = "Status: Error hooking modules" end
            return
        end

        initialized = true
        if Tower then
            activeTower = Tower 
            if Tower:FindFirstChild("HumanoidRootPart") then 
                activeTowerPos = Tower.HumanoidRootPart.Position 
            end

            -- [[ AUTO FPS ENTRY ]]
            if getgenv().config.fps_mode then
                ToggleFPS(true)
            end

            -- [[ AUTO RELOAD MONITOR ]]
            local rep = Tower:WaitForChild("TowerReplicator", 5)
            if rep then
                task.spawn(function()
                    while task.wait(0.2) do
                        local ammo = rep:GetAttribute("Ammo")
                        if ammo and ammo <= 0 then
                            DoReload()
                            task.wait(1.5) 
                        end
                    end
                end)
            end
        end
        
        if StatusLabel then StatusLabel.Text = "Status: <font color=\"rgb(80,255,140)\">Attached & Auto-Active</font>"; StatusLabel.RichText = true end

        getgenv().GatlingBrain = runService.Heartbeat:Connect(function()
            if not getgenv().config.autofire then return end
            UpdateTarget()
        end)
    end

    if StatusLabel then StatusLabel.Text = "Status: Searching for Gatling Gun..." end

    local towersFolder = workspace:WaitForChild("Towers", 5)
    if towersFolder then
        local function checkTower(Tower)
            task.spawn(function()
                local Replicator = Tower:WaitForChild("TowerReplicator", 5)
                if not Replicator then return end
                if string.find(string.lower(Replicator:GetAttribute("Name") or ""), "gatling") then
                    StartHooks(Tower)
                end
            end)
        end
        towersFolder.ChildAdded:Connect(checkTower)
        for _, t in pairs(towersFolder:GetChildren()) do checkTower(t) end
    else
        if StatusLabel then StatusLabel.Text = "Status: 'Towers' folder not found." end
    end
end)
