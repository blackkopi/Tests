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

-- ================= LOAD RAYFIELD =================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Kopi's Hub",
   LoadingTitle = "Loading Kopi's Hub...",
   ConfigurationSaving = {
      Enabled = false,
      FolderName = nil, 
      FileName = "KopiHub"
   },
   Discord = {
      Enabled = false,
      Invite = "noinvitelink", 
      RememberJoins = true 
   },
   KeySystem = false, 
})

-- ================= UI TABS =================
local VisualsTab = Window:CreateTab("Visuals", 4483362458) 
local AimbotTab = Window:CreateTab("Aimbot", 4483362458)
local HitboxTab = Window:CreateTab("Hitbox", 4483362458)
local TargetsTab = Window:CreateTab("Targets", 4483362458)

-- ================= VISUALS TAB =================
VisualsTab:CreateSection("ESP Options")

VisualsTab:CreateToggle({
   Name = "ESP Boxes",
   CurrentValue = ESP_SETTINGS.Box,
   Flag = "Box", 
   Callback = function(Value) ESP_SETTINGS.Box = Value end
})

VisualsTab:CreateToggle({
   Name = "Skeleton",
   CurrentValue = ESP_SETTINGS.Skeleton,
   Flag = "Skeleton", 
   Callback = function(Value) ESP_SETTINGS.Skeleton = Value end
})

VisualsTab:CreateToggle({
   Name = "Chams",
   CurrentValue = ESP_SETTINGS.Chams,
   Flag = "Chams", 
   Callback = function(Value) ESP_SETTINGS.Chams = Value end
})

VisualsTab:CreateToggle({
   Name = "Tracers",
   CurrentValue = ESP_SETTINGS.Tracers,
   Flag = "Tracers", 
   Callback = function(Value) ESP_SETTINGS.Tracers = Value end
})

VisualsTab:CreateToggle({
   Name = "Names",
   CurrentValue = ESP_SETTINGS.Names,
   Flag = "Names", 
   Callback = function(Value) ESP_SETTINGS.Names = Value end
})

VisualsTab:CreateToggle({
   Name = "Distance",
   CurrentValue = ESP_SETTINGS.Distance,
   Flag = "Distance", 
   Callback = function(Value) ESP_SETTINGS.Distance = Value end
})

VisualsTab:CreateToggle({
   Name = "Health Gauge",
   CurrentValue = ESP_SETTINGS.HealthBar,
   Flag = "HealthBar", 
   Callback = function(Value) ESP_SETTINGS.HealthBar = Value end
})

VisualsTab:CreateToggle({
   Name = "Hide Team",
   CurrentValue = ESP_SETTINGS.HideTeam,
   Flag = "HideTeam", 
   Callback = function(Value) ESP_SETTINGS.HideTeam = Value end
})

VisualsTab:CreateToggle({
   Name = "Wall Check (Visuals)",
   CurrentValue = ESP_SETTINGS.WallCheck,
   Flag = "WallCheck", 
   Callback = function(Value) ESP_SETTINGS.WallCheck = Value end
})

-- ================= TARGETS TAB =================
TargetsTab:CreateSection("Manage Targets")

-- Logic to update the list
local TargetListLabel -- Placeholder

local function UpdateTargetDisplay()
    if TargetListLabel then
        local content = ""
        if #RainbowTargets == 0 then
            content = "No targets added."
        else
            content = table.concat(RainbowTargets, ", ")
        end
        TargetListLabel:Set({Title = "Current Targets List:", Content = content})
    end
end

TargetsTab:CreateInput({
   Name = "Add Target (Name)",
   PlaceholderText = "Player Name...",
   RemoveTextAfterFocusLost = true,
   Callback = function(Text)
        if Text ~= "" then
            table.insert(RainbowTargets, Text:lower())
            UpdateTargetDisplay() -- Refresh list
            Rayfield:Notify({
               Title = "Target Added",
               Content = "Added " .. Text,
               Duration = 2,
               Image = 4483362458,
            })
        end
   end
})

TargetsTab:CreateButton({
   Name = "Clear All Targets",
   Callback = function()
        table.clear(RainbowTargets)
        UpdateTargetDisplay() -- Refresh list
        Rayfield:Notify({
           Title = "Cleared",
           Content = "All targets removed.",
           Duration = 2,
           Image = 4483362458,
        })
   end
})

-- The display paragraph
TargetListLabel = TargetsTab:CreateParagraph({Title = "Current Targets List:", Content = "No targets added."})

-- ================= AIMBOT TAB =================
AimbotTab:CreateSection("Main")

AimbotTab:CreateToggle({
   Name = "Enable Aimbot",
   CurrentValue = ESP_SETTINGS.Aimbot,
   Flag = "Aimbot", 
   Callback = function(Value) ESP_SETTINGS.Aimbot = Value end
})

AimbotTab:CreateDropdown({
   Name = "Target Part",
   Options = {"Head", "Torso"},
   CurrentOption = {"Head"},
   MultipleOptions = false,
   Flag = "AimPart",
   Callback = function(Option) ESP_SETTINGS.AimPart = Option[1] end
})

AimbotTab:CreateSection("Settings")

AimbotTab:CreateToggle({
   Name = "Show FOV Circle",
   CurrentValue = ESP_SETTINGS.AimFOV,
   Flag = "AimFOV", 
   Callback = function(Value) ESP_SETTINGS.AimFOV = Value end
})

-- CHANGED TO INPUT
AimbotTab:CreateInput({
   Name = "FOV Radius (Size)",
   PlaceholderText = "100",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
        local num = tonumber(Text)
        if num then
            ESP_SETTINGS.AimRadius = num
        end
   end
})

AimbotTab:CreateToggle({
   Name = "Team Check",
   CurrentValue = ESP_SETTINGS.AimTeamCheck,
   Flag = "AimTeamCheck", 
   Callback = function(Value) ESP_SETTINGS.AimTeamCheck = Value end
})

AimbotTab:CreateToggle({
   Name = "Wall Check",
   CurrentValue = ESP_SETTINGS.AimWallCheck,
   Flag = "AimWallCheck", 
   Callback = function(Value) ESP_SETTINGS.AimWallCheck = Value end
})

AimbotTab:CreateToggle({
   Name = "Prioritize Distance",
   CurrentValue = ESP_SETTINGS.AimSmartDist,
   Flag = "AimSmartDist", 
   Callback = function(Value) ESP_SETTINGS.AimSmartDist = Value end
})

-- END OF PART 1
-- PASTE THIS UNDER PART 1

-- ================= HITBOX TAB =================
local function ResetHitboxLogic()
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character then
			local hrp = p.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				hrp.Size = Vector3.new(2, 2, 1)
				hrp.Transparency = 1
                hrp.CanCollide = true
                hrp.Color = Color3.new(0.63, 0.63, 0.63)
			end
		end
	end
end

HitboxTab:CreateToggle({
   Name = "Enable Hitbox Expander",
   CurrentValue = ESP_SETTINGS.Hitbox,
   Flag = "Hitbox", 
   Callback = function(Value) 
        ESP_SETTINGS.Hitbox = Value 
        if not Value then ResetHitboxLogic() end
   end
})

-- CHANGED TO INPUT
HitboxTab:CreateInput({
   Name = "Hitbox Size",
   PlaceholderText = "20",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
        local num = tonumber(Text)
        if num then
            ESP_SETTINGS.HitboxSize = num
        end
   end
})

HitboxTab:CreateToggle({
   Name = "Universal Blue Color",
   CurrentValue = ESP_SETTINGS.UniversalColor,
   Flag = "UniversalColor", 
   Callback = function(Value) ESP_SETTINGS.UniversalColor = Value end
})

HitboxTab:CreateButton({
   Name = "Reset Hitboxes",
   Callback = function()
        ESP_SETTINGS.Hitbox = false
        ResetHitboxLogic()
   end
})

-- ================= LOGIC & LOOPS =================
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
	for _,p in ipairs(RainbowTargets) do if name:sub(1,#p) == p then return true end end
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
									if ESP_SETTINGS.AimSmartDist then
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
					if not (ESP_SETTINGS.HideTeam and isTeammate) then
						pcall(function()
							hrp.Size = Vector3.new(ESP_SETTINGS.HitboxSize, ESP_SETTINGS.HitboxSize, ESP_SETTINGS.HitboxSize)
							hrp.Transparency = 0.7
							hrp.CanCollide = false
							
							if ESP_SETTINGS.UniversalColor then
								hrp.Color = Color3.fromRGB(0, 0, 255)
								hrp.Material = Enum.Material.Neon
							else
								if isRainbowTarget(p.Name) then
									hrp.Color = GetRainbow(); hrp.Material = Enum.Material.Neon
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
						Box = D("Square", {Thickness=1, Filled=false, Transparency=1}),
						BoxOutline = D("Square", {Thickness=2, Filled=false, Transparency=0.6, Color=Color3.new(0,0,0)}),
						Tracer = D("Line", {Thickness=1, Transparency=1}),
						Name = D("Text", {Size=13, Center=true, Outline=true, Font=3}), 
						Info = D("Text", {Size=11, Center=true, Outline=true, Font=3}),
						-- [[ PREMIUM HEALTH BAR OBJECTS ]]
						BarBorder = D("Square", {Thickness=1, Filled=false, Transparency=1, Color=Color3.new(0,0,0)}), 
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
				
				if ESP_SETTINGS.WallCheck and onScreen then
					local params = RaycastParams.new()
					params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
					params.FilterType = Enum.RaycastFilterType.Exclude
					local castTarget = p.Character:FindFirstChild("Head") or hrp
					local dir = castTarget.Position - Camera.CFrame.Position
					local result = workspace:Raycast(Camera.CFrame.Position, dir, params)
					if result and not result.Instance:IsDescendantOf(p.Character) then
						col = col:Lerp(Color3.new(0,0,0), 0.75)
					end
				end

				local cham = p.Character:FindFirstChild("KopiHighlight")
				if not cham then if ESP_SETTINGS.Chams then ApplyChams(p.Character) end
				else 
					cham.Enabled = ESP_SETTINGS.Chams; cham.FillColor = col; cham.OutlineColor = Color3.new(1,1,1)
					cham.FillTransparency = 0.35; cham.OutlineTransparency = 0.1
				end
				
				if onScreen then
					-- Dynamic Size for Box
					local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
					local size = math.clamp(2000/pos.Z, 25, 300)
					local w, h = size, size*1.5
					
					esp.BoxOutline.Visible = ESP_SETTINGS.Box; esp.Box.Visible = ESP_SETTINGS.Box
					if ESP_SETTINGS.Box then
						esp.Box.Size = Vector2.new(w, h); esp.Box.Position = Vector2.new(pos.X - w/2, pos.Y - h/2); esp.Box.Color = col
						esp.BoxOutline.Size = Vector2.new(w, h); esp.BoxOutline.Position = esp.Box.Position
					end
					
					esp.Tracer.Visible = ESP_SETTINGS.Tracers
					if ESP_SETTINGS.Tracers then
						esp.Tracer.From = Vector2.new(center.X, vp.Y); esp.Tracer.To = Vector2.new(pos.X, pos.Y + h/2); esp.Tracer.Color = col
					end
					
					esp.Name.Visible = ESP_SETTINGS.Names
					if ESP_SETTINGS.Names then
						esp.Name.Text = p.Name; esp.Name.Position = Vector2.new(pos.X, pos.Y - h/2 - 16); esp.Name.Color = col
					end
					
					esp.Info.Visible = ESP_SETTINGS.Distance
					if esp.Info.Visible then
						esp.Info.Text = math.floor(dist).."m"; esp.Info.Position = Vector2.new(pos.X, pos.Y + h/2 + 2); esp.Info.Color = col 
					end
					
					-- [[ PREMIUM FIXED HEIGHT BAR ]]
					esp.Bar.Visible = ESP_SETTINGS.HealthBar
					esp.BarTrack.Visible = ESP_SETTINGS.HealthBar
					esp.BarBorder.Visible = ESP_SETTINGS.HealthBar
					esp.HPText.Visible = ESP_SETTINGS.HealthBar

					if ESP_SETTINGS.HealthBar then
						local hp = math.clamp(hum.Health/hum.MaxHealth, 0, 1)
						local staticHeight = 50 
						local staticWidth = 5  
						local barX = pos.X - w/2 - (staticWidth + 6)
						local barTop = pos.Y - staticHeight/2
						local barBot = pos.Y + staticHeight/2
						local filledHeight = staticHeight * hp
						
						esp.BarBorder.Size = Vector2.new(staticWidth + 2, staticHeight + 2)
						esp.BarBorder.Position = Vector2.new(barX - 1, barTop - 1)
						esp.BarTrack.Size = Vector2.new(staticWidth, staticHeight)
						esp.BarTrack.Position = Vector2.new(barX, barTop)
						esp.Bar.Size = Vector2.new(staticWidth, filledHeight)
						esp.Bar.Position = Vector2.new(barX, barBot - filledHeight)
						esp.Bar.Color = Color3.fromHSV(hp * 0.33, 0.9, 1)
						esp.HPText.Text = tostring(math.floor(hum.Health))
						esp.HPText.Position = Vector2.new(barX + (staticWidth/2), pos.Y - 5) 
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
							end
						end
						local links = (hum.RigType == Enum.HumanoidRigType.R15) and R15_LINKS or R6_LINKS
						for i, lnk in ipairs(links) do
							local l = esp.Skeleton[i]
							if l then
								local p1 = p.Character:FindFirstChild(lnk[1]); local p2 = p.Character:FindFirstChild(lnk[2])
								if p1 and p2 then
									local s1, o1 = Camera:WorldToViewportPoint(p1.Position); local s2, o2 = Camera:WorldToViewportPoint(p2.Position)
									if o1 and o2 then
										l.Visible = true; l.From = Vector2.new(s1.X, s1.Y); l.To = Vector2.new(s2.X, s2.Y); l.Color = col
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
