if not game:IsLoaded() then game.Loaded:Wait() end
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local hotbar = PlayerGui:WaitForChild("ReactUniversalHotbar")
local frame = hotbar:WaitForChild("Frame")
frame:WaitForChild("troops") 

local rs = game:GetService("ReplicatedStorage")
local uis = game:GetService("UserInputService")
local workspace = game:GetService("Workspace")
local runService = game:GetService("RunService")
local tweenService = game:GetService("TweenService")
local soundService = game:GetService("SoundService")
local coreGui = game:GetService("CoreGui")
local players = game:GetService("Players")

getgenv().config = {
    autofire = true,
    autoCaliber = true, 
    smartTargeting = true, 
    mode = "First", 
    multiply = 10,
    cooldown = 0.05,
    norecoil = true,
    chams = true,
    pierceLogic = true
}

local DAMAGE_VALUES = { [0]=5, [1]=8, [2]=12, [3]=16, [4]=25, [5]=45, [6]=85 }

local THEME = {
    Bg = Color3.fromRGB(12, 12, 18), 
    Header = Color3.fromRGB(18, 18, 25),
    Accent = Color3.fromRGB(90, 140, 255),
    Text = Color3.fromRGB(245, 245, 255),
    TextDim = Color3.fromRGB(140, 140, 160),
    Stroke = Color3.fromRGB(45, 45, 65),
}

local SoundManager = {}
local SoundRoot = Instance.new("Folder", soundService)
SoundRoot.Name = "KopiSounds"
local function CreateSound(id, vol)
    local s = Instance.new("Sound", SoundRoot);
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
            local s = Sounds[name]:Clone(); s.Parent = SoundRoot
            if name=="Toggle" then s.PlaybackSpeed=1.1 end
            s:Play(); game.Debris:AddItem(s,2)
        end
    end)
end

local function CreateTween(obj, props, time)
    tweenService:Create(obj, TweenInfo.new(time or 0.25, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), props):Play()
end

local StatusLabel = nil

if getgenv().RunningTowers then
    for _, taskConn in pairs(getgenv().RunningTowers) do
        if typeof(taskConn) == "thread" then task.cancel(taskConn) end
    end
end
getgenv().RunningTowers = {}

if coreGui:FindFirstChild("KOPI_GATLING_UI") then coreGui.KOPI_GATLING_UI:Destroy() end
if players.LocalPlayer.PlayerGui:FindFirstChild("KOPI_GATLING_UI") then players.LocalPlayer.PlayerGui.KOPI_GATLING_UI:Destroy() end
if getgenv().BulletHitCleaner then getgenv().BulletHitCleaner:Disconnect() end

if getgenv().HitmarkerListener then getgenv().HitmarkerListener:Disconnect() end
local function DestroyHitmarkers()
    local pGui = players.LocalPlayer:FindFirstChild("PlayerGui")
    if pGui then
        local view = pGui:FindFirstChild("ReactGameHitmarkerView")
        if view then view:Destroy() end
    end
end
DestroyHitmarkers()
getgenv().HitmarkerListener = players.LocalPlayer:WaitForChild("PlayerGui").ChildAdded:Connect(function(child)
    if child.Name == "ReactGameHitmarkerView" then
        task.wait()
        child:Destroy()
    end
end)

local function RemoveDamageDisplay()
    local net = rs:WaitForChild("Network", 5)
    if net then
        local dmgFolder = net:WaitForChild("Damage", 5)
        if dmgFolder then
            local remote = dmgFolder:FindFirstChild("URE:DisplayDamage")
            if remote then remote:Destroy() end
        end
    end
end
pcall(RemoveDamageDisplay)

local function CreateUI()
    local parent = coreGui
    pcall(function() if not parent then parent = players.LocalPlayer.PlayerGui end end)
    
    local ScreenGui = Instance.new("ScreenGui", parent)
    ScreenGui.Name = "KOPI_GATLING_UI"
    ScreenGui.ResetOnSpawn = false

    local MainFrame = Instance.new("Frame", ScreenGui)
    MainFrame.Size = UDim2.fromOffset(300, 420)
    MainFrame.Position = UDim2.fromOffset(100, 200)
    MainFrame.BackgroundColor3 = THEME.Bg
    MainFrame.BorderSizePixel = 0
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 16)

    local UIStroke = Instance.new("UIStroke", MainFrame)
    UIStroke.Color = Color3.fromRGB(255, 255, 255);
    UIStroke.Thickness = 2.5; UIStroke.Transparency = 0
    local StrokeGradient = Instance.new("UIGradient", UIStroke)
    StrokeGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, THEME.Stroke), ColorSequenceKeypoint.new(0.5, THEME.Accent), ColorSequenceKeypoint.new(1, THEME.Stroke)
    }
    StrokeGradient.Rotation = 45

    local BgGradient = Instance.new("UIGradient", MainFrame)
    BgGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(1,1,1)), ColorSequenceKeypoint.new(1, Color3.fromRGB(150,150,160))
    }
    BgGradient.Rotation = 90

    task.spawn(function()
        while task.wait() do
            StrokeGradient.Rotation = (StrokeGradient.Rotation + 1) % 360
            BgGradient.Rotation = (BgGradient.Rotation + 0.2) % 360
        end
    end)

    local Header = Instance.new("Frame", MainFrame)
    Header.Size = UDim2.new(1, 0, 0, 48)
    Header.BackgroundColor3 = THEME.Header
    Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 16)
    
    local Title = Instance.new("TextLabel", Header)
    Title.Text = "KOPI'S <font color=\"rgb(90,140,255)\">GATLING</font>"
    Title.RichText = true;
    Title.Font = Enum.Font.GothamBlack;
    Title.TextSize = 18; Title.TextColor3 = THEME.Text; 
    Title.Position = UDim2.new(0, 16, 0, 0);
    Title.Size = UDim2.new(1, -60, 1, 0);
    Title.BackgroundTransparency = 1; Title.TextXAlignment = Enum.TextXAlignment.Left

    local MiniFrame = Instance.new("Frame", ScreenGui)
    MiniFrame.Size = UDim2.fromOffset(120, 36);
    MiniFrame.BackgroundColor3 = THEME.Header
    MiniFrame.Visible = false; MiniFrame.Position = MainFrame.Position 
    Instance.new("UICorner", MiniFrame).CornerRadius = UDim.new(1, 0)
    local MiniStroke = Instance.new("UIStroke", MiniFrame);
    MiniStroke.Color = THEME.Accent; MiniStroke.Thickness = 2
    local MiniLabel = Instance.new("TextLabel", MiniFrame);
    MiniLabel.Size = UDim2.new(1,0,1,0);
    MiniLabel.BackgroundTransparency=1
    MiniLabel.Text = "OPEN HUB"; MiniLabel.Font=Enum.Font.GothamBlack; MiniLabel.TextColor3=THEME.Accent

    local function MakeDraggable(trigger, target, onClick)
        trigger.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                local dragStart = input.Position; local startPos = target.Position; local dragging = true; local isMoving = false
                local con
                con = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false; con:Disconnect()
                        if not isMoving and onClick then onClick() end
                    end
                end)
                uis.InputChanged:Connect(function(moveInput)
                    if dragging and (moveInput.UserInputType == Enum.UserInputType.MouseMovement or moveInput.UserInputType == Enum.UserInputType.Touch) then
                        local delta = moveInput.Position - dragStart
                        if delta.Magnitude > 3 then isMoving = true end
                        target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                    end
                end)
            end
        end)
    end
    MakeDraggable(Header, MainFrame)
    MakeDraggable(MiniFrame, MiniFrame, function() 
        SoundManager.Play("Open")
        MainFrame.Position = MiniFrame.Position
        MiniFrame.Visible = false 
        MainFrame.Visible = true 
    end)

    local MinimizeBtn = Instance.new("TextButton", Header)
    MinimizeBtn.Size = UDim2.fromOffset(32, 32); MinimizeBtn.Position = UDim2.new(1, -44, 0.5, -16)
    MinimizeBtn.Text = "-";
    MinimizeBtn.Font = Enum.Font.GothamBlack; MinimizeBtn.TextSize = 20
    MinimizeBtn.TextColor3 = THEME.TextDim;
    MinimizeBtn.BackgroundColor3 = Color3.fromRGB(35,35,45)
    Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0, 10)
    MinimizeBtn.MouseButton1Click:Connect(function() 
        SoundManager.Play("Click")
        MiniFrame.Position = MainFrame.Position
        MainFrame.Visible = false
        MiniFrame.Visible = true 
    end)

    local Content = Instance.new("Frame", MainFrame)
    Content.Position = UDim2.new(0, 12, 0, 60);
    Content.Size = UDim2.new(1, -24, 1, -90); Content.BackgroundTransparency = 1
    local List = Instance.new("UIListLayout", Content);
    List.Padding = UDim.new(0, 10)

    local function CreateToggle(text, configKey)
        local Btn = Instance.new("TextButton", Content)
        Btn.Size = UDim2.new(1, 0, 0, 38);
        Btn.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
        Btn.AutoButtonColor = false; Btn.Text = "";
        Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 10)
        
        local Lbl = Instance.new("TextLabel", Btn);
        Lbl.Text = text; Lbl.Font = Enum.Font.GothamSemibold; Lbl.TextSize = 13; Lbl.TextColor3 = THEME.Text
        Lbl.Size = UDim2.new(0.7, 0, 1, 0);
        Lbl.Position = UDim2.new(0, 14, 0, 0); Lbl.TextXAlignment = Enum.TextXAlignment.Left; Lbl.BackgroundTransparency = 1
        
        local Sw = Instance.new("Frame", Btn);
        Sw.Size = UDim2.fromOffset(44, 22); Sw.Position = UDim2.new(1, -54, 0.5, -11)
        Sw.BackgroundColor3 = getgenv().config[configKey] and THEME.Accent or Color3.fromRGB(45,45,55)
        Instance.new("UICorner", Sw).CornerRadius = UDim.new(1, 0)
        local Circ = Instance.new("Frame", Sw);
        Circ.Size = UDim2.fromOffset(18, 18)
        Circ.Position = getgenv().config[configKey] and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
        Circ.BackgroundColor3 = Color3.new(1,1,1);
        Instance.new("UICorner", Circ).CornerRadius = UDim.new(1, 0)

        Btn.MouseButton1Click:Connect(function()
            getgenv().config[configKey] = not getgenv().config[configKey]
            SoundManager.Play("Toggle")
            if getgenv().config[configKey] then CreateTween(Sw, {BackgroundColor3 = THEME.Accent}); CreateTween(Circ, {Position = UDim2.new(1, -20, 0.5, -9)})
            else CreateTween(Sw, {BackgroundColor3 = Color3.fromRGB(45,45,55)}); CreateTween(Circ, {Position = UDim2.new(0, 2, 0.5, -9)}) end
        end)
    end

    local function CreateButton(text, cb)
        local b = Instance.new("TextButton", Content);
        b.Size = UDim2.new(1,0,0,36); b.BackgroundColor3 = Color3.fromRGB(30,30,40)
        b.Text = text; b.TextColor3 = THEME.Text;
        b.Font = Enum.Font.GothamBold; b.TextSize = 12
        Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
        b.MouseButton1Click:Connect(function() SoundManager.Play("Click"); cb(b) end)
    end

    local function CreateInput(placeholder)
        local frame = Instance.new("Frame", Content)
        frame.Size = UDim2.new(1,0,0,36);
        frame.BackgroundTransparency = 1
        local box = Instance.new("TextBox", frame)
        box.Size = UDim2.new(1, 0, 1, 0);
        box.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        box.TextColor3 = THEME.Text; box.Font = Enum.Font.GothamBold;
        box.TextSize = 12
        box.PlaceholderText = placeholder;
        box.Text = tostring(getgenv().config.multiply)
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)
        box.FocusLost:Connect(function()
            local num = tonumber(box.Text)
            if num then getgenv().config.multiply = math.clamp(num, 1, 100); box.Text = tostring(getgenv().config.multiply)
            else box.Text = tostring(getgenv().config.multiply) end
        end)
    end

    CreateToggle("Auto Fire", "autofire")
    CreateToggle("Auto Caliber", "autoCaliber")
    CreateToggle("Smart Targeting", "smartTargeting")
    CreateToggle("Enable Pierce Logic", "pierceLogic")
    CreateToggle("Show Targets (Chams)", "chams")
    
    CreateButton("Target Mode: " .. getgenv().config.mode, function(b)
        local m = getgenv().config.mode
        if m == "Strongest" then m = "First" elseif m == "First" then m = "Close" else m = "Strongest" end
        getgenv().config.mode = m; b.Text = "Target Mode: " .. m
    end)
 
   CreateInput("Custom Multiplier (e.g. 10)")

    StatusLabel = Instance.new("TextLabel", MainFrame)
    StatusLabel.Position = UDim2.new(0,0,1,-25); StatusLabel.Size = UDim2.new(1,0,0,20)
    StatusLabel.BackgroundTransparency = 1; StatusLabel.TextColor3 = THEME.TextDim
    StatusLabel.Font = Enum.Font.Gotham; StatusLabel.TextSize = 11
    StatusLabel.Text = "Status: Waiting for Towers..."

    uis.InputBegan:Connect(function(i) if i.KeyCode == Enum.KeyCode.RightControl then ScreenGui.Enabled = not ScreenGui.Enabled end end)
    SoundManager.Play("Open")
end
CreateUI()

local function get_base_position()
    for _, name in pairs({"Exit", "End", "EndPoint", "Lives"}) do
        local found = workspace:FindFirstChild(name, true)
        if found and found:IsA("BasePart") then return found.Position end
    end
    return Vector3.new(0, 10, 0)
end

local function GetReplicator(model)
    if not model then return nil end
    local ptr = model:FindFirstChild("RootPointer")
    if ptr and ptr:IsA("ObjectValue") and ptr.Value then return ptr.Value end
    local hrp = model:FindFirstChild("HumanoidRootPart")
    if hrp then
        local ptr2 = hrp:FindFirstChild("RootPointer")
        if ptr2 and ptr2:IsA("ObjectValue") and ptr2.Value then return ptr2.Value end
    end
    local stateRep = rs:FindFirstChild("StateReplicators")
    local npcRep = stateRep and stateRep:FindFirstChild("NPCReplicator")
    if npcRep then
        local exact = npcRep:FindFirstChild(model.Name)
        if exact then return exact end
        for _, folder in ipairs(npcRep:GetChildren()) do
            if string.find(folder.Name, model.Name) then return folder end
        end
    end
    return nil
end

local function get_stats_from_rep(rep)
    if not rep then return 0, 0, -1, 0 end
    if rep:GetAttribute("NoHealth") == true then return 0, 0, -1, 0 end
    
    local hp = rep:GetAttribute("Health")
    local shield = rep:GetAttribute("Shield")
    local defense = rep:GetAttribute("Defense") or 0
    
    local path = rep:GetAttribute("PathDistance")
    if not path then
         local pVal = rep:FindFirstChild("PathDistance")
         if pVal then path = pVal.Value end
    end
    return hp or 0, shield or 0, path or -1, defense
end

local function get_stats(model)
    local rep = GetReplicator(model)
    return get_stats_from_rep(rep)
end

local function IsRevived(rep)
    if rep and rep:GetAttribute("Revived") == true then return true end
    return false
end

local function IsEnemyLead(rep)
    if not rep then return false end
    if rep:GetAttribute("5") == true then return true end
    local modsChild = rep:FindFirstChild("Modifiers")
    if modsChild then
        if modsChild:GetAttribute("5") == true then return true end
        if modsChild:FindFirstChild("5") then return true end
    end
    for key, val in pairs(rep:GetAttributes()) do
        if tostring(key) == "5" and val == true then return true end
        if (key == "Defense" or key == "Modifier" or key == "Modifiers") and val == 5 then return true end
        if type(val) == "string" and string.find(string.lower(val), "lead") then return true end
    end
    return false
end

local ChamFolder = Instance.new("Folder", coreGui)
ChamFolder.Name = "KopiChams"
local function UpdateChams(targets)
    ChamFolder:ClearAllChildren() 
    if not getgenv().config.chams then return end

    for i, tData in ipairs(targets) do
        if i > 20 then break end 
        if tData.Model then
            local hl = Instance.new("Highlight", ChamFolder)
            hl.Adornee = tData.Model
            hl.FillColor = THEME.Accent
            hl.OutlineColor = THEME.Accent
            hl.FillTransparency = 0.6
            hl.OutlineTransparency = 0.2
        end
    end
end

local function GetSortedTargets(activeTower)
    local candidates = {}
    local processedModels = {}
    
    local basePos = get_base_position()
    local towerPos = activeTower and activeTower:FindFirstChild("HumanoidRootPart") and activeTower.HumanoidRootPart.Position or workspace.CurrentCamera.CFrame.Position
    
    local canHitLead = false
    if activeTower then
        local rep = activeTower:FindFirstChild("TowerReplicator")
        if rep then
            local mods = rep:FindFirstChild("Modifiers")
            if mods and mods:GetAttribute("30") == true then canHitLead = true end
        end
    end

    local function AddCandidate(model, rep)
        if processedModels[model] then return end
        local pivotCFrame = model:GetPivot()
        local pivotPos = pivotCFrame.Position
        local hrp = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Head")
        
        if not hrp then return end
        
        local hp, shield, pathDist, defense
        if rep then
            hp, shield, pathDist, defense = get_stats_from_rep(rep)
        else
            hp, shield, pathDist, defense = get_stats(model)
            rep = GetReplicator(model) 
        end

        if hp > 0 and not IsRevived(rep) then
            local isImmune = false
            if not canHitLead then isImmune = IsEnemyLead(rep) end
            
            if not isImmune then
                processedModels[model] = true
                table.insert(candidates, {
                    Model = model, 
                    HRP = hrp, 
                    PivotPos = pivotPos,
                    HP = hp + shield, 
                    Path = pathDist,
                    Defense = defense,
                    DistToBase = (pivotPos - basePos).Magnitude,
                    DistToTower = (pivotPos - towerPos).Magnitude
                })
            end
        end
    end

    local folders = {workspace:FindFirstChild("NPCs"), workspace:FindFirstChild("Enemies")}
    local function RecurseScan(parent)
        for _, v in ipairs(parent:GetChildren()) do
            if v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") then
                AddCandidate(v, nil)
            end
            if v:IsA("Folder") or v:IsA("Model") then
                RecurseScan(v)
            end
        end
    end
    for _, f in pairs(folders) do if f then RecurseScan(f) end end

    local stateRep = rs:FindFirstChild("StateReplicators")
    if stateRep then
        local searchFolders = {stateRep, stateRep:FindFirstChild("NPCReplicator")}
        for _, folder in pairs(searchFolders) do
            if folder then
                for _, rep in ipairs(folder:GetChildren()) do
                    if rep:GetAttribute("Health") and rep:GetAttribute("MaxHealth") then
                        local foundModel = workspace:FindFirstChild(rep.Name, true)
                        if foundModel and foundModel:IsA("Model") then
                             AddCandidate(foundModel, rep)
                        end
                    end
                end
            end
        end
    end

    if #candidates > 0 then
        if getgenv().config.mode == "First" then
            table.sort(candidates, function(a, b) if a.Path > -1 and b.Path > -1 then return a.Path > b.Path end return a.DistToBase < b.DistToBase end)
        elseif getgenv().config.mode == "Strongest" then
            table.sort(candidates, function(a, b) return a.HP > b.HP end)
        elseif getgenv().config.mode == "Close" then
            table.sort(candidates, function(a, b) return a.DistToTower < b.DistToTower end)
        end
    end
    
    UpdateChams(candidates)
    return candidates
end

local function StopSpecificHook(Tower)
    if getgenv().RunningTowers[Tower] then
        task.cancel(getgenv().RunningTowers[Tower])
        getgenv().RunningTowers[Tower] = nil
    end
end

getgenv().StartHooks = function(Tower)
    if getgenv().RunningTowers[Tower] then return end
    
    local success, err = pcall(function()
        task.spawn(function()
            local args = { "Troops", "Abilities", "Activate", { Troop = Tower, Name = "FPS", Data = { enabled = true } } }
            rs:WaitForChild("RemoteFunction"):InvokeServer(unpack(args))
        end)

        local Replicator = Tower:WaitForChild("TowerReplicator", 5)
        local ReloadRemote = rs:WaitForChild("Network"):WaitForChild("GatlingGun"):WaitForChild("RE:Reload")
        local BulletHitRemote = rs:WaitForChild("Network"):WaitForChild("GatlingGun"):FindFirstChild("RE:BulletHit")
    
        if BulletHitRemote and BulletHitRemote:IsA("RemoteEvent") and not getgenv().BulletHitCleaner then
            getgenv().BulletHitCleaner = BulletHitRemote.OnClientEvent:Connect(function() end)
        end

        local ggchannel = require(rs.Resources.Universal.NewNetwork).Channel("GatlingGun")
        local gganim = require(rs.Content.Tower["Gatling Gun"].Animator)
        gganim._fireGun = function() end 

        local cleanupConnection
        cleanupConnection = Tower.AncestryChanged:Connect(function(_, parent) 
            if not parent then 
                StopSpecificHook(Tower) 
                if cleanupConnection then cleanupConnection:Disconnect() end
            end 
        end)

        local muscleTask = task.spawn(function()
            while true do
                if getgenv().config.autofire then
                    if not Replicator or not Replicator.Parent then break end
                    
                    local currentAmmo = Replicator:GetAttribute("Ammo")
                    
                    if currentAmmo and currentAmmo <= 0 then
                        ReloadRemote:FireServer()
                        task.wait(0.5) 
                    else
                        local targetList = GetSortedTargets(Tower) 
                        
                        if #targetList > 0 then
                            local sync = workspace:GetAttribute("Sync")
                            local sTime = workspace:GetServerTimeNow()
                            local maxBudget = 60
                            local shotsFired = 0
                            
                            for _, targetData in ipairs(targetList) do
                                if shotsFired >= maxBudget then break end

                                if not getgenv().config.smartTargeting and shotsFired > 0 then break end
                
                                local hp = targetData.HP
                                local shotsNeeded = 5 
                                if getgenv().config.autoCaliber then
                                    local baseDmg = Replicator:GetAttribute("Damage")
                                    local buff = Replicator:GetAttribute("DamageBuff") or 0
                                    local finalDmg = baseDmg and (baseDmg * (1 + (buff / 100))) or (DAMAGE_VALUES[Replicator:GetAttribute("Level") or 0] or 5)
                                    
                                    local defense = targetData.Defense or 0
                                    local defenseMult = math.max(0, 1 - (defense / 100))
                                    local effectiveDmg = finalDmg * defenseMult
                                    if effectiveDmg < 1 then effectiveDmg = 1 end
                                    
                                    shotsNeeded = math.ceil(hp / effectiveDmg)
                                else
                                    shotsNeeded = getgenv().config.multiply
                                end
                                
                                if shotsNeeded < 1 then shotsNeeded = 1 end

                                local actualShots = math.min(shotsNeeded, maxBudget - shotsFired)
                                
                                if actualShots > 0 then
                                    local tPos = targetData.PivotPos 
                                    local vel = targetData.HRP.AssemblyLinearVelocity
                                    local aimPos
                                    
                                    if getgenv().config.pierceLogic and vel.Magnitude > 0.5 then
                                        aimPos = tPos - (vel.Unit * 1.5) 
                                    else
                                        if vel.Magnitude > 0.5 then
                                            aimPos = tPos + (vel * 0.035)
                                        else
                                            aimPos = tPos
                                        end
                                    end
                                    
                                    for i = 1, actualShots do ggchannel:fireServer("Fire", aimPos, sync, sTime) end
                                    shotsFired = shotsFired + actualShots
                                end
                            end
                        end
                    end
                end
                task.wait(getgenv().config.cooldown)
            end
        end)
        getgenv().RunningTowers[Tower] = muscleTask
    end)
    
    if not success then warn("Hook Error: " .. tostring(err)); StopSpecificHook(Tower) end
end

local towersFolder = workspace:WaitForChild("Towers") 
if StatusLabel then StatusLabel.Text = "Status: Monitoring Towers..." end

if towersFolder then
    local function checkTower(Tower)
        task.spawn(function()
            local Replicator = Tower:WaitForChild("TowerReplicator", 10)
            if not Replicator then return end
            if string.find(string.lower(Replicator:GetAttribute("Name") or ""), "gatling") then 
                getgenv().StartHooks(Tower) 
            end
        end)
    end
    towersFolder.ChildAdded:Connect(checkTower)
    for _, t in pairs(towersFolder:GetChildren()) do checkTower(t) end
end
