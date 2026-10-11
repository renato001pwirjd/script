-- Blox Fruits Aim + Auto-Skill + Movement + Infinite Jump + Infinite Energy + ESP
-- Compat: Synapse, Krnl, Fluxus, Delta, Arceus X

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- ============================================================
-- CONFIG
-- ============================================================
local Config = {
    -- aim
    AimbotEnabled = true,
    AutoSkillEnabled = true,
    FOV = 250,
    Smoothness = 0.15,
    Prediction = 0.165,
    SkillDelay = 0.12,
    TeamCheck = true,
    WallCheck = true,
    ShowFOVCircle = true,

    -- movement
    MoveBoostEnabled = false,
    WalkSpeed = 120,
    JumpPower = 180,
    InfiniteJump = false,
    InfiniteEnergy = false,

    -- esp
    EspEnabled = true,
    EspBox = true,
    EspName = true,
    EspLevel = true,
    EspFruit = true,
    EspFightingStyle = true,
    EspHealth = true,
    EspDistance = true,
    EspTeamColor = true,
    EspMaxDist = 2000,
}

local SkillKeys = {
    Enum.KeyCode.Z, Enum.KeyCode.X, Enum.KeyCode.C,
    Enum.KeyCode.V, Enum.KeyCode.F,
}

local FruitCache = {}
local StyleCache = {}

-- ============================================================
-- UTILS
-- ============================================================
local function isAlive(plr)
    local char = plr and plr.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function hasLineOfSight(target)
    if not Config.WallCheck then return true end
    local myChar = LocalPlayer.Character
    if not myChar then return false end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    local tRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if not (myRoot and tRoot) then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { myChar, target.Character }
    local result = workspace:Raycast(myRoot.Position, (tRoot.Position - myRoot.Position), params)
    return result == nil
end

local function getTargetPart(plr)
    local char = plr.Character
    if not char then return nil end
    return char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
end

local function worldToScreen(pos)
    local sp, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector3.new(sp.X, sp.Y, sp.Z), onScreen
end

local function getClosestTarget()
    local best, bestDist = nil, Config.FOV
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        if not isAlive(plr) then continue end
        if Config.TeamCheck and plr.Team == LocalPlayer.Team and plr.Team ~= nil then continue end
        local part = getTargetPart(plr)
        if not part then continue end
        local screenPos, onScreen = worldToScreen(part.Position)
        if not onScreen then continue end
        local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
        if dist < bestDist and hasLineOfSight(plr) then
            bestDist = dist
            best = plr
        end
    end
    return best
end

-- ============================================================
-- DETECÇÃO LEVEL / FRUTA / STYLE
-- ============================================================
local function getPlayerLevel(plr)
    local data = plr:FindFirstChild("Data")
    if data then
        local lvl = data:FindFirstChild("Level")
        if lvl and lvl.Value then return lvl.Value end
    end
    return "?"
end

local function getPlayerFruit(plr)
    local char = plr.Character
    if char then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool and tool.Name then
            local n = tool.Name
            if n:lower():find("fruit") or n:lower():find("dough") or n:lower():find("leopard")
                or n:lower():find("dragon") or n:lower():find("kitsune") or n:lower():find("portal") then
                local fruitName = n:gsub("%s*Fruit%s*", ""):gsub("%s+$", "")
                FruitCache[plr.Name] = fruitName
                return fruitName
            end
        end
    end
    if FruitCache[plr.Name] then return FruitCache[plr.Name] end
    return "?"
end

local function getPlayerStyle(plr)
    local data = plr:FindFirstChild("Data")
    if data then
        local s = data:FindFirstChild("FightingStyle") or data:FindFirstChild("Style")
        if s and s.Value and s.Value ~= "" then return s.Value end
    end
    return StyleCache[plr.Name] or "?"
end

local function hookSkillDetection()
    local fruits = {
        "dough","leopard","dragon","kitsune","portal","venom","control","spirit",
        "mammoth","t-rex","trex","gas","rumble","magma","ice","light","dark",
        "buddha","rubber","blizzard","pain","phoenix","sound","spider","love",
        "creation","eagle","gravity","shadow","barrier","bomb","chop",
        "spring","smoke","spike","flame","falcon","sand","revive","diamond",
        "ghost","quake","rocket","spin"
    }
    workspace.DescendantAdded:Connect(function(inst)
        pcall(function()
            if not (inst:IsA("BasePart") or inst:IsA("ParticleEmitter") or inst:IsA("Explosion")
                or inst:IsA("Sound") or inst:IsA("Attachment") or inst:IsA("Beam") or inst:IsA("Trail")) then
                return
            end
            local n = inst.Name:lower()
            local matched
            for _, f in ipairs(fruits) do
                if n:find(f) then matched = f; break end
            end
            if not matched then return end
            local ep = inst:IsA("BasePart") and inst.Position
                or (inst.Parent and inst.Parent:IsA("BasePart") and inst.Parent.Position)
            if not ep then return end
            local closest, cd = nil, 60
            for _, plr in ipairs(Players:GetPlayers()) do
                local c = plr.Character
                if c and c:FindFirstChild("HumanoidRootPart") then
                    local d = (c.HumanoidRootPart.Position - ep).Magnitude
                    if d < cd then cd = d; closest = plr end
                end
            end
            if closest then
                FruitCache[closest.Name] = matched:sub(1,1):upper() .. matched:sub(2)
            end
        end)
    end)
end
hookSkillDetection()

-- ============================================================
-- GUI
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BloxFruitsAimGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = (gethui and gethui()) or game:GetService("CoreGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 320, 0, 660)
Main.Position = UDim2.new(0.5, -160, 0.5, -330)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(80, 120, 255)
Stroke.Thickness = 1.5
Stroke.Transparency = 0.2
Stroke.Parent = Main

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 44)
Header.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
Header.BorderSizePixel = 0
Header.Parent = Main
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 12)

local HeaderFix = Instance.new("Frame")
HeaderFix.Size = UDim2.new(1, 0, 0, 12)
HeaderFix.Position = UDim2.new(0, 0, 1, -12)
HeaderFix.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
HeaderFix.BorderSizePixel = 0
HeaderFix.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -80, 1, 0)
Title.Position = UDim2.new(0, 16, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "BLOX FRUITS  //  AIM + ESP"
Title.TextColor3 = Color3.fromRGB(220, 230, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.Parent = Header

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 28, 0, 28)
MinBtn.Position = UDim2.new(1, -36, 0, 8)
MinBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 16
MinBtn.BorderSizePixel = 0
MinBtn.Parent = Header
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -24, 1, -60)
Scroll.Position = UDim2.new(0, 12, 0, 52)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 4
Scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 120, 255)
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.Parent = Main

local UIList = Instance.new("UIListLayout")
UIList.Padding = UDim.new(0, 6)
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Parent = Scroll

UIList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Scroll.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y + 8)
end)

local function makeSection(text)
    local H = Instance.new("TextLabel")
    H.Size = UDim2.new(1, 0, 0, 24)
    H.BackgroundTransparency = 1
    H.Text = text
    H.TextColor3 = Color3.fromRGB(80, 120, 255)
    H.TextXAlignment = Enum.TextXAlignment.Left
    H.Font = Enum.Font.GothamBold
    H.TextSize = 11
    H.Parent = Scroll
end

local function makeToggle(name, default, callback)
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, 0, 0, 32)
    Row.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
    Row.BorderSizePixel = 0
    Row.Parent = Scroll
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 8)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -70, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = Color3.fromRGB(200, 210, 230)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 12
    Label.Parent = Row

    local Toggle = Instance.new("TextButton")
    Toggle.Size = UDim2.new(0, 42, 0, 20)
    Toggle.Position = UDim2.new(1, -54, 0.5, -10)
    Toggle.BackgroundColor3 = default and Color3.fromRGB(60, 110, 240) or Color3.fromRGB(45, 45, 58)
    Toggle.Text = ""
    Toggle.BorderSizePixel = 0
    Toggle.AutoButtonColor = false
    Toggle.Parent = Row
    Instance.new("UICorner", Toggle).CornerRadius = UDim.new(1, 0)

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 14, 0, 14)
    Knob.Position = default and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    Knob.BackgroundColor3 = Color3.fromRGB(240, 240, 250)
    Knob.BorderSizePixel = 0
    Knob.Parent = Toggle
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

    local state = default
    local function update(v)
        state = v
        TweenService:Create(Toggle, TweenInfo.new(0.15), {
            BackgroundColor3 = v and Color3.fromRGB(60, 110, 240) or Color3.fromRGB(45, 45, 58)
        }):Play()
        TweenService:Create(Knob, TweenInfo.new(0.15), {
            Position = v and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        }):Play()
        if callback then callback(v) end
    end
    Toggle.MouseButton1Click:Connect(function() update(not state) end)
    return { Set = update, Get = function() return state end }
end

local function makeSlider(name, min, max, default, callback)
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, 0, 0, 46)
    Row.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
    Row.BorderSizePixel = 0
    Row.Parent = Scroll
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 8)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -24, 0, 18)
    Label.Position = UDim2.new(0, 12, 0, 4)
    Label.BackgroundTransparency = 1
    Label.Text = name .. "  [" .. default .. "]"
    Label.TextColor3 = Color3.fromRGB(200, 210, 230)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 12
    Label.Parent = Row

    local Track = Instance.new("Frame")
    Track.Size = UDim2.new(1, -24, 0, 6)
    Track.Position = UDim2.new(0, 12, 0, 28)
    Track.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
    Track.BorderSizePixel = 0
    Track.Parent = Row
    Instance.new("UICorner", Track).CornerRadius = UDim.new(1, 0)

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(60, 110, 240)
    Fill.BorderSizePixel = 0
    Fill.Parent = Track
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)

    local dragging = false
    local function updateFromX(x)
        local rel = math.clamp((x - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max - min) * rel)
        Fill.Size = UDim2.new(rel, 0, 1, 0)
        Label.Text = name .. "  [" .. val .. "]"
        if callback then callback(val) end
    end

    Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; updateFromX(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- CONTROLES
makeSection("— AIMBOT —")
makeToggle("Aimbot", Config.AimbotEnabled, function(v) Config.AimbotEnabled = v end)
makeToggle("Auto-Skill Executor", Config.AutoSkillEnabled, function(v) Config.AutoSkillEnabled = v end)
makeToggle("Team Check", Config.TeamCheck, function(v) Config.TeamCheck = v end)
makeToggle("Wall Check", Config.WallCheck, function(v) Config.WallCheck = v end)
makeToggle("FOV Circle", Config.ShowFOVCircle, function(v) Config.ShowFOVCircle = v end)
makeSlider("FOV", 50, 600, Config.FOV, function(v) Config.FOV = v end)
makeSlider("Smoothness %", 1, 100, math.floor(Config.Smoothness * 100), function(v) Config.Smoothness = v / 100 end)
makeSlider("Prediction", 0, 50, math.floor(Config.Prediction * 100), function(v) Config.Prediction = v / 100 end)
makeSlider("Skill Delay (ms)", 0, 500, math.floor(Config.SkillDelay * 1000), function(v) Config.SkillDelay = v / 1000 end)

makeSection("— MOVEMENT —")
makeToggle("Move Boost", Config.MoveBoostEnabled, function(v) Config.MoveBoostEnabled = v end)
makeToggle("Infinite Jump", Config.InfiniteJump, function(v) Config.InfiniteJump = v end)
makeToggle("Infinite Energy", Config.InfiniteEnergy, function(v) Config.InfiniteEnergy = v end)
makeSlider("Walk Speed", 16, 500, Config.WalkSpeed, function(v) Config.WalkSpeed = v end)
makeSlider("Jump Power", 50, 500, Config.JumpPower, function(v) Config.JumpPower = v end)

makeSection("— ESP —")
makeToggle("ESP", Config.EspEnabled, function(v) Config.EspEnabled = v end)
makeToggle("Box", Config.EspBox, function(v) Config.EspBox = v end)
makeToggle("Name", Config.EspName, function(v) Config.EspName = v end)
makeToggle("Level", Config.EspLevel, function(v) Config.EspLevel = v end)
makeToggle("Fruit", Config.EspFruit, function(v) Config.EspFruit = v end)
makeToggle("Fighting Style", Config.EspFightingStyle, function(v) Config.EspFightingStyle = v end)
makeToggle("Health Bar", Config.EspHealth, function(v) Config.EspHealth = v end)
makeToggle("Distance", Config.EspDistance, function(v) Config.EspDistance = v end)
makeToggle("Team Color", Config.EspTeamColor, function(v) Config.EspTeamColor = v end)
makeSlider("ESP Max Dist", 200, 5000, Config.EspMaxDist, function(v) Config.EspMaxDist = v end)

local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
        Size = minimized and UDim2.new(0, 320, 0, 44) or UDim2.new(0, 320, 0, 660)
    }):Play()
    Scroll.Visible = not minimized
end)

-- ============================================================
-- FOV CIRCLE
-- ============================================================
local FOVGui = Instance.new("ScreenGui")
FOVGui.Name = "FOVCircle"
FOVGui.ResetOnSpawn = false
FOVGui.IgnoreGuiInset = true
FOVGui.Parent = ScreenGui.Parent

local FOVCircle = Instance.new("Frame")
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.BackgroundTransparency = 1
FOVCircle.Size = UDim2.new(0, 500, 0, 500)
FOVCircle.Parent = FOVGui
Instance.new("UICorner", FOVCircle).CornerRadius = UDim.new(1, 0)

local CircleStroke = Instance.new("UIStroke")
CircleStroke.Color = Color3.fromRGB(60, 110, 240)
CircleStroke.Thickness = 1.5
CircleStroke.Transparency = 0.35
CircleStroke.Parent = FOVCircle

-- ============================================================
-- ESP
-- ============================================================
local EspGui = Instance.new("ScreenGui")
EspGui.Name = "BloxFruitsESP"
EspGui.ResetOnSpawn = false
EspGui.IgnoreGuiInset = true
EspGui.Parent = ScreenGui.Parent

local EspFolder = Instance.new("Folder")
EspFolder.Parent = EspGui

local espCache = {}

local function createEspFor(plr)
    if espCache[plr] then return espCache[plr] end

    local box = Instance.new("Frame")
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Visible = false
    box.Parent = EspFolder

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(60, 110, 240)
    stroke.Thickness = 1.5
    stroke.Parent = box

    local info = Instance.new("TextLabel")
    info.BackgroundTransparency = 1
    info.TextColor3 = Color3.fromRGB(255, 255, 255)
    info.TextStrokeTransparency = 0
    info.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    info.Font = Enum.Font.GothamBold
    info.TextSize = 11
    info.TextXAlignment = Enum.TextXAlignment.Center
    info.TextYAlignment = Enum.TextYAlignment.Bottom
    info.Size = UDim2.new(0, 240, 0, 70)
    info.AnchorPoint = Vector2.new(0.5, 1)
    info.ZIndex = 2
    info.Parent = box

    local dist = Instance.new("TextLabel")
    dist.BackgroundTransparency = 1
    dist.TextColor3 = Color3.fromRGB(200, 210, 230)
    dist.TextStrokeTransparency = 0
    dist.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    dist.Font = Enum.Font.Gotham
    dist.TextSize = 10
    dist.TextXAlignment = Enum.TextXAlignment.Center
    dist.AnchorPoint = Vector2.new(0.5, 0)
    dist.Size = UDim2.new(0, 120, 0, 14)
    dist.ZIndex = 2
    dist.Parent = box

    local healthBarBg = Instance.new("Frame")
    healthBarBg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    healthBarBg.BorderSizePixel = 0
    healthBarBg.ZIndex = 2
    healthBarBg.Parent = box
    Instance.new("UICorner", healthBarBg).CornerRadius = UDim.new(0, 3)

    local healthBar = Instance.new("Frame")
    healthBar.BackgroundColor3 = Color3.fromRGB(60, 220, 90)
    healthBar.BorderSizePixel = 0
    healthBar.Size = UDim2.new(1, 0, 1, 0)
    healthBar.Parent = healthBarBg
    Instance.new("UICorner", healthBar).CornerRadius = UDim.new(0, 3)

    local cache = { box = box, info = info, dist = dist, healthBar = healthBar, healthBarBg = healthBarBg, stroke = stroke }
    espCache[plr] = cache
    return cache
end

-- ============================================================
-- AIMBOT
-- ============================================================
local lastSkillTime = 0

local function getAimPosition(plr)
    local char = plr.Character
    if not char then return nil end
    local part = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
    if not part then return nil end
    local pos = part.Position
    if Config.Prediction > 0 then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then pos = pos + hrp.AssemblyLinearVelocity * Config.Prediction end
    end
    return pos
end

local function castAllSkills()
    local now = tick()
    if now - lastSkillTime < Config.SkillDelay then return end
    lastSkillTime = now
    local vim = game:GetService("VirtualInputManager")
    for _, key in ipairs(SkillKeys) do
        pcall(function()
            vim:SendKeyEvent(true, key, false, game)
            task.wait(0.03)
            vim:SendKeyEvent(false, key, false, game)
        end)
    end
    pcall(function()
        vim:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, game, 0)
        task.wait(0.02)
        vim:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, game, 0)
    end)
end

RunService.RenderStepped:Connect(function()
    if Config.ShowFOVCircle then
        FOVCircle.Visible = true
        FOVCircle.Position = UDim2.new(0, Camera.ViewportSize.X / 2, 0, Camera.ViewportSize.Y / 2)
        FOVCircle.Size = UDim2.new(0, Config.FOV * 2, 0, Config.FOV * 2)
        CircleStroke.Color = Config.AimbotEnabled and Color3.fromRGB(60, 110, 240) or Color3.fromRGB(80, 80, 90)
    else
        FOVCircle.Visible = false
    end

    if Config.AimbotEnabled then
        local target = getClosestTarget()
        if target then
            local aimPos = getAimPosition(target)
            if aimPos then
                local camCF = Camera.CFrame
                local direction = (aimPos - camCF.Position).Unit
                local targetCF = CFrame.new(camCF.Position, camCF.Position + direction)
                Camera.CFrame = camCF:Lerp(targetCF, 1 - Config.Smoothness)

                if Config.AutoSkillEnabled then
                    local screenPos, onScreen = worldToScreen(aimPos)
                    if onScreen then
                        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                        if (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude < 30 then
                            castAllSkills()
                        end
                    end
                end
            end
        end
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        local cache = espCache[plr]
        if not Config.EspEnabled or not isAlive(plr) then
            if cache then cache.box.Visible = false end
            continue
        end

        local char = plr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not (hrp and head and hum) then
            if cache then cache.box.Visible = false end
            continue
        end

        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local myPos = myRoot and myRoot.Position or Camera.CFrame.Position
        local dist3D = (hrp.Position - myPos).Magnitude
        if dist3D > Config.EspMaxDist then
            if cache then cache.box.Visible = false end
            continue
        end

        local top, topOn = worldToScreen(head.Position + Vector3.new(0, 2, 0))
        local bottom, botOn = worldToScreen(hrp.Position - Vector3.new(0, 3, 0))
        if not (topOn and botOn) then
            if cache then cache.box.Visible = false end
            continue
        end

        cache = createEspFor(plr)
        cache.box.Visible = true

        local height = math.abs(bottom.Y - top.Y)
        local width = height * 0.55
        local cx = (top.X + bottom.X) / 2

        cache.box.Position = UDim2.new(0, cx - width / 2, 0, top.Y)
        cache.box.Size = UDim2.new(0, width, 0, height)

        local color = Color3.fromRGB(255, 80, 80)
        if Config.EspTeamColor and plr.Team then
            color = plr.Team.TeamColor.Color
        elseif plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team then
            color = Color3.fromRGB(80, 255, 120)
        end
        cache.stroke.Color = color
        cache.stroke.Transparency = (not hasLineOfSight(plr)) and 0.6 or 0.1
        cache.box.Visible = Config.EspBox
        cache.stroke.Enabled = Config.EspBox

        local lines = {}
        if Config.EspName then table.insert(lines, plr.Name) end
        if Config.EspLevel then table.insert(lines, "Lv. " .. tostring(getPlayerLevel(plr))) end
        if Config.EspFruit then table.insert(lines, getPlayerFruit(plr)) end
        if Config.EspFightingStyle then table.insert(lines, getPlayerStyle(plr)) end
        cache.info.Text = table.concat(lines, "  •  ")
        cache.info.Position = UDim2.new(0.5, 0, 0, -4)
        cache.info.Visible = #lines > 0
        cache.info.TextColor3 = color

        if Config.EspDistance then
            cache.dist.Visible = true
            cache.dist.Text = string.format("%d m", math.floor(dist3D))
            cache.dist.Position = UDim2.new(0.5, 0, 1, 2)
        else
            cache.dist.Visible = false
        end

        if Config.EspHealth then
            cache.healthBarBg.Visible = true
            local hpct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            cache.healthBar.Size = UDim2.new(hpct, 0, 1, 0)
            cache.healthBar.BackgroundColor3 = Color3.fromRGB(255 * (1 - hpct) + 60 * hpct, 220 * hpct + 40, 60)
            cache.healthBarBg.Size = UDim2.new(0, width + 4, 0, 4)
            cache.healthBarBg.Position = UDim2.new(0.5, 0, 1, 16)
            cache.healthBarBg.AnchorPoint = Vector2.new(0.5, 0)
        else
            cache.healthBarBg.Visible = false
        end
    end
end)

-- ============================================================
-- MOVEMENT / INFINITE JUMP / INFINITE ENERGY
-- ============================================================
local lastJumpTick = 0

local function applyMovement()
    if not Config.MoveBoostEnabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    hum.WalkSpeed = Config.WalkSpeed
    hum.JumpPower = Config.JumpPower
end

local function freezeEnergy()
    if not Config.InfiniteEnergy then return end
    local char = LocalPlayer.Character
    if not char then return end

    -- via Humanoid (Energia/Stamina do char)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function() hum.Health = hum.MaxHealth end)
    end

    -- via Data.Energy (Blox Fruits usa Energy como stamina de dash)
    local data = LocalPlayer:FindFirstChild("Data")
    if data then
        local energy = data:FindFirstChild("Energy")
        if energy and typeof(energy) == "Instance" and energy:IsA("ValueBase") then
            pcall(function() energy.Value = 100 end)
        end
        local maxEnergy = data:FindFirstChild("MaxEnergy")
        if maxEnergy and typeof(maxEnergy) == "Instance" and maxEnergy:IsA("ValueBase") then
            pcall(function() energy.Value = maxEnergy.Value end)
        end
    end

    -- via atributo (algumas versões usam Attributes)
    pcall(function()
        LocalPlayer:SetAttribute("Energy", 100)
        char:SetAttribute("Energy", 100)
    end)
end

local function infiniteJumpLoop()
    if not Config.InfiniteJump then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local state = hum:GetState()
    -- se está no ar (Freefall/Jumping) e a barra de pulo esgotou, re-empurra
    if state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping then
        local now = tick()
        if now - lastJumpTick > 0.05 then
            lastJumpTick = now
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
        end
    end
end

RunService.Heartbeat:Connect(function()
    applyMovement()
    freezeEnergy()
    infiniteJumpLoop()
end)

-- Infinite Jump via input também (cobre o caso do user segurar espaço)
UserInputService.JumpRequest:Connect(function()
    if Config.InfiniteJump then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
            end
        end
    end
end)

-- Loop que também pulinho no ar quando user aperta espaço repetido
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.Space and Config.InfiniteJump then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
            end
        end
    end
end)

-- ============================================================
-- HOTKEYS
-- ============================================================
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        Config.AimbotEnabled = not Config.AimbotEnabled
    elseif input.KeyCode == Enum.KeyCode.RightControl then
        Config.AutoSkillEnabled = not Config.AutoSkillEnabled
    elseif input.KeyCode == Enum.KeyCode.RightAlt then
        Config.MoveBoostEnabled = not Config.MoveBoostEnabled
    elseif input.KeyCode == Enum.KeyCode.Insert then
        Config.EspEnabled = not Config.EspEnabled
    elseif input.KeyCode == Enum.KeyCode.KeypadOne then
        Config.InfiniteJump = not Config.InfiniteJump
    elseif input.KeyCode == Enum.KeyCode.KeypadTwo then
        Config.InfiniteEnergy = not Config.InfiniteEnergy
    end
end)

print("[BloxFruits Aim+ESP] carregado")
print("Hotkeys: RShift=Aim | RCtrl=Skills | RAlt=Move | Insert=ESP | Num1=InfJump | Num2=InfEnergy")
