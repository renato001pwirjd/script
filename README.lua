-- Rush PvP / Generic FPS Aimbot + Strong ESP
-- Compat: Synapse, Krnl, Fluxus, Delta, Arceus X, Bacon
-- Serve em: Arsenal, Rush, Frontlines, Bad Business, Phantom Forces (genérico)

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
    -- aimbot
    AimbotEnabled = true,
    AimKey = Enum.UserInputType.MouseButton2,  -- botão direito segura pra mirar
    AimbotMode = "Hold",                        -- "Hold" | "Toggle" | "Always"
    FOV = 200,
    Smoothness = 0.25,                          -- 1.0 = instantâneo, 0.0 = nunca chega
    TargetPart = "Head",                        -- "Head" | "HumanoidRootPart" | "UpperTorso"
    Prediction = 0.13,                          -- segundos de predição de movimento
    TeamCheck = true,
    WallCheck = true,
    VisCheck = true,
    MaxDist = 1000,
    ShowFOVCircle = true,
    ShowTargetLine = true,

    -- esp
    EspEnabled = true,
    EspBox = true,
    EspName = true,
    EspHealth = true,
    EspDistance = true,
    EspTracer = true,
    EspSkeleton = true,
    EspHeadDot = true,
    EspChams = true,
    EspTeamColor = true,
    EspMaxDist = 2000,
    EspTextSize = 12,
}

-- ============================================================
-- UTILS
-- ============================================================
local function isAlive(plr)
    local char = plr and plr.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function sameTeam(plr)
    if not LocalPlayer.Team or not plr.Team then return false end
    return plr.Team == LocalPlayer.Team
end

local function hasLOS(target)
    local myChar = LocalPlayer.Character
    if not myChar then return false end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return false end
    local tChar = target.Character
    if not tChar then return false end
    local tHead = tChar:FindFirstChild("Head") or tChar:FindFirstChild("HumanoidRootPart")
    if not tHead then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { myChar, tChar, Camera }
    local ray = workspace:Raycast(myRoot.Position, tHead.Position - myRoot.Position, params)
    return ray == nil
end

local function getTargetPart(plr)
    local char = plr.Character
    if not char then return nil end
    return char:FindFirstChild(Config.TargetPart)
        or char:FindFirstChild("Head")
        or char:FindFirstChild("HumanoidRootPart")
end

local function worldToScreen(pos)
    local sp, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector3.new(sp.X, sp.Y, sp.Z), onScreen
end

local function getClosestTarget()
    local best, bestScore = nil, math.huge
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local myPos = myRoot and myRoot.Position or Camera.CFrame.Position

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        if not isAlive(plr) then continue end
        if Config.TeamCheck and sameTeam(plr) then continue end

        local part = getTargetPart(plr)
        if not part then continue end

        local dist3D = (part.Position - myPos).Magnitude
        if dist3D > Config.MaxDist then continue end

        local screenPos, onScreen = worldToScreen(part.Position)
        if not onScreen then continue end

        local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
        if dist > Config.FOV then continue end

        if Config.WallCheck and not hasLOS(plr) then continue end

        -- score: distância na tela + distância 3D (prioriza perto + centralizado)
        local score = dist + dist3D * 0.02
        if score < bestScore then
            bestScore = score
            best = plr
        end
    end
    return best, bestScore
end

local function getAimPos(plr)
    local char = plr.Character
    if not char then return nil end
    local part = char:FindFirstChild(Config.TargetPart)
        or char:FindFirstChild("Head")
        or char:FindFirstChild("HumanoidRootPart")
    if not part then return nil end
    local pos = part.Position
    if Config.Prediction > 0 then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            pos = pos + hrp.AssemblyLinearVelocity * Config.Prediction
        end
    end
    return pos
end

-- ============================================================
-- GUI
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RushPvP_Aim"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = (gethui and gethui()) or game:GetService("CoreGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 340, 0, 620)
Main.Position = UDim2.new(0.5, -170, 0.5, -310)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(255, 60, 90)
Stroke.Thickness = 1.5
Stroke.Parent = Main

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 46)
Header.BackgroundColor3 = Color3.fromRGB(25, 20, 28)
Header.BorderSizePixel = 0
Header.Parent = Main
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 14)

local HeaderFix = Instance.new("Frame")
HeaderFix.Size = UDim2.new(1, 0, 0, 12)
HeaderFix.Position = UDim2.new(0, 0, 1, -12)
HeaderFix.BackgroundColor3 = Color3.fromRGB(25, 20, 28)
HeaderFix.BorderSizePixel = 0
HeaderFix.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -80, 1, 0)
Title.Position = UDim2.new(0, 18, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "RUSH PVP  //  AIM + ESP"
Title.TextColor3 = Color3.fromRGB(255, 220, 230)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.Parent = Header

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 28, 0, 28)
MinBtn.Position = UDim2.new(1, -36, 0, 9)
MinBtn.BackgroundColor3 = Color3.fromRGB(50, 35, 45)
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.fromRGB(255, 220, 230)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 16
MinBtn.BorderSizePixel = 0
MinBtn.Parent = Header
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -24, 1, -60)
Scroll.Position = UDim2.new(0, 12, 0, 54)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 4
Scroll.ScrollBarImageColor3 = Color3.fromRGB(255, 60, 90)
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
    H.Size = UDim2.new(1, 0, 0, 22)
    H.BackgroundTransparency = 1
    H.Text = text
    H.TextColor3 = Color3.fromRGB(255, 60, 90)
    H.TextXAlignment = Enum.TextXAlignment.Left
    H.Font = Enum.Font.GothamBold
    H.TextSize = 11
    H.Parent = Scroll
end

local function makeToggle(name, default, callback)
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, 0, 0, 32)
    Row.BackgroundColor3 = Color3.fromRGB(22, 20, 26)
    Row.BorderSizePixel = 0
    Row.Parent = Scroll
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 8)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -70, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = Color3.fromRGB(220, 210, 220)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 12
    Label.Parent = Row

    local Toggle = Instance.new("TextButton")
    Toggle.Size = UDim2.new(0, 42, 0, 20)
    Toggle.Position = UDim2.new(1, -54, 0.5, -10)
    Toggle.BackgroundColor3 = default and Color3.fromRGB(255, 60, 90) or Color3.fromRGB(45, 40, 50)
    Toggle.Text = ""
    Toggle.BorderSizePixel = 0
    Toggle.AutoButtonColor = false
    Toggle.Parent = Row
    Instance.new("UICorner", Toggle).CornerRadius = UDim.new(1, 0)

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 14, 0, 14)
    Knob.Position = default and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Knob.BorderSizePixel = 0
    Knob.Parent = Toggle
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

    local state = default
    local function update(v)
        state = v
        TweenService:Create(Toggle, TweenInfo.new(0.15), {
            BackgroundColor3 = v and Color3.fromRGB(255, 60, 90) or Color3.fromRGB(45, 40, 50)
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
    Row.BackgroundColor3 = Color3.fromRGB(22, 20, 26)
    Row.BorderSizePixel = 0
    Row.Parent = Scroll
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 8)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -24, 0, 18)
    Label.Position = UDim2.new(0, 12, 0, 4)
    Label.BackgroundTransparency = 1
    Label.Text = name .. "  [" .. default .. "]"
    Label.TextColor3 = Color3.fromRGB(220, 210, 220)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 12
    Label.Parent = Row

    local Track = Instance.new("Frame")
    Track.Size = UDim2.new(1, -24, 0, 6)
    Track.Position = UDim2.new(0, 12, 0, 28)
    Track.BackgroundColor3 = Color3.fromRGB(45, 40, 50)
    Track.BorderSizePixel = 0
    Track.Parent = Row
    Instance.new("UICorner", Track).CornerRadius = UDim.new(1, 0)

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(255, 60, 90)
    Fill.BorderSizePixel = 0
    Fill.Parent = Track
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)

    local dragging = false
    local function updateFromX(x)
        local rel = math.clamp((x - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
        local val = min + (max - min) * rel
        if max - min <= 5 then
            val = math.floor(val * 100) / 100
        else
            val = math.floor(val)
        end
        Fill.Size = UDim2.new((val - min) / (max - min), 0, 1, 0)
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

-- AIMBOT CONTROLS
makeSection("— AIMBOT —")
makeToggle("Aimbot", Config.AimbotEnabled, function(v) Config.AimbotEnabled = v end)
makeToggle("Team Check", Config.TeamCheck, function(v) Config.TeamCheck = v end)
makeToggle("Wall Check", Config.WallCheck, function(v) Config.WallCheck = v end)
makeToggle("FOV Circle", Config.ShowFOVCircle, function(v) Config.ShowFOVCircle = v end)
makeToggle("Target Line", Config.ShowTargetLine, function(v) Config.ShowTargetLine = v end)
makeSlider("FOV", 30, 800, Config.FOV, function(v) Config.FOV = v end)
makeSlider("Smoothness", 0.05, 1.0, Config.Smoothness, function(v) Config.Smoothness = v end)
makeSlider("Prediction", 0, 0.5, Config.Prediction, function(v) Config.Prediction = v end)
makeSlider("Max Dist", 100, 3000, Config.MaxDist, function(v) Config.MaxDist = v end)

-- ESP CONTROLS
makeSection("— ESP —")
makeToggle("ESP", Config.EspEnabled, function(v) Config.EspEnabled = v end)
makeToggle("Box", Config.EspBox, function(v) Config.EspBox = v end)
makeToggle("Name", Config.EspName, function(v) Config.EspName = v end)
makeToggle("Health Bar", Config.EspHealth, function(v) Config.EspHealth = v end)
makeToggle("Distance", Config.EspDistance, function(v) Config.EspDistance = v end)
makeToggle("Tracer", Config.EspTracer, function(v) Config.EspTracer = v end)
makeToggle("Skeleton", Config.EspSkeleton, function(v) Config.EspSkeleton = v end)
makeToggle("Head Dot", Config.EspHeadDot, function(v) Config.EspHeadDot = v end)
makeToggle("Chams (Local)", Config.EspChams, function(v) Config.EspChams = v end)
makeToggle("Team Color", Config.EspTeamColor, function(v) Config.EspTeamColor = v end)
makeSlider("ESP Max Dist", 200, 5000, Config.EspMaxDist, function(v) Config.EspMaxDist = v end)
makeSlider("Text Size", 8, 20, Config.EspTextSize, function(v) Config.EspTextSize = v end)

-- minimize
local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
        Size = minimized and UDim2.new(0, 340, 0, 46) or UDim2.new(0, 340, 0, 620)
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
FOVCircle.Size = UDim2.new(0, 400, 0, 400)
FOVCircle.Parent = FOVGui
Instance.new("UICorner", FOVCircle).CornerRadius = UDim.new(1, 0)

local CircleStroke = Instance.new("UIStroke")
CircleStroke.Color = Color3.fromRGB(255, 60, 90)
CircleStroke.Thickness = 1.5
CircleStroke.Transparency = 0.4
CircleStroke.Parent = FOVCircle

-- Target Line (linha da câmera pro alvo)
local TargetLine = Instance.new("Frame")
TargetLine.BackgroundColor3 = Color3.fromRGB(255, 60, 90)
TargetLine.BorderSizePixel = 0
TargetLine.BackgroundTransparency = 0.3
TargetLine.Visible = false
TargetLine.ZIndex = 0
TargetLine.Parent = FOVGui

-- ============================================================
-- ESP
-- ============================================================
local EspGui = Instance.new("ScreenGui")
EspGui.Name = "RushPvP_ESP"
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
    stroke.Color = Color3.fromRGB(255, 60, 90)
    stroke.Thickness = 1.5
    stroke.Parent = box

    local info = Instance.new("TextLabel")
    info.BackgroundTransparency = 1
    info.TextColor3 = Color3.fromRGB(255, 255, 255)
    info.TextStrokeTransparency = 0
    info.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    info.Font = Enum.Font.GothamBold
    info.TextSize = Config.EspTextSize
    info.TextXAlignment = Enum.TextXAlignment.Center
    info.TextYAlignment = Enum.TextYAlignment.Bottom
    info.Size = UDim2.new(0, 220, 0, 60)
    info.AnchorPoint = Vector2.new(0.5, 1)
    info.ZIndex = 2
    info.Parent = box

    local dist = Instance.new("TextLabel")
    dist.BackgroundTransparency = 1
    dist.TextColor3 = Color3.fromRGB(220, 220, 230)
    dist.TextStrokeTransparency = 0
    dist.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    dist.Font = Enum.Font.Gotham
    dist.TextSize = Config.EspTextSize - 1
    dist.TextXAlignment = Enum.TextXAlignment.Center
    dist.AnchorPoint = Vector2.new(0.5, 0)
    dist.Size = UDim2.new(0, 120, 0, 14)
    dist.ZIndex = 2
    dist.Parent = box

    local healthBarBg = Instance.new("Frame")
    healthBarBg.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
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

    local headDot = Instance.new("Frame")
    headDot.Size = UDim2.new(0, 6, 0, 6)
    headDot.AnchorPoint = Vector2.new(0.5, 0.5)
    headDot.BackgroundColor3 = Color3.fromRGB(255, 60, 90)
    headDot.BorderSizePixel = 0
    headDot.Visible = false
    headDot.ZIndex = 3
    headDot.Parent = EspFolder
    Instance.new("UICorner", headDot).CornerRadius = UDim.new(1, 0)

    local tracer = Instance.new("Frame")
    tracer.BackgroundColor3 = Color3.fromRGB(255, 60, 90)
    tracer.BorderSizePixel = 0
    tracer.AnchorPoint = Vector2.new(0.5, 0)
    tracer.Visible = false
    tracer.ZIndex = 1
    tracer.Parent = EspFolder

    local cache = {
        box = box, info = info, dist = dist,
        healthBar = healthBar, healthBarBg = healthBarBg,
        headDot = headDot, tracer = tracer, stroke = stroke,
        skeletonLines = {}
    }
    espCache[plr] = cache
    return cache
end

local function removeEspFor(plr)
    if espCache[plr] then
        espCache[plr].box:Destroy()
        espCache[plr].headDot:Destroy()
        espCache[plr].tracer:Destroy()
        for _, l in ipairs(espCache[plr].skeletonLines) do l:Destroy() end
        espCache[plr] = nil
    end
end

-- Skeleton connection map (R6 e R15)
local SKELETON_R6 = {
    {"Head", "Torso"},
    {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
    {"Torso", "Left Leg"}, {"Torso", "Right Leg"},
}
local SKELETON_R15 = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
}

local function drawSkeleton(cache, char, color)
    local layout = char:FindFirstChild("Head") and char:FindFirstChild("UpperTorso") and SKELETON_R15 or SKELETON_R6
    for i, pair in ipairs(layout) do
        local a = char:FindFirstChild(pair[1])
        local b = char:FindFirstChild(pair[2])
        if not (a and b) then continue end
        local spA, onA = worldToScreen(a.Position)
        local spB, onB = worldToScreen(b.Position)
        if not (onA and onB) then
            if cache.skeletonLines[i] then cache.skeletonLines[i].Visible = false end
            continue
        end
        local line = cache.skeletonLines[i]
        if not line then
            line = Instance.new("Frame")
            line.BorderSizePixel = 0
            line.ZIndex = 2
            line.Parent = EspFolder
            cache.skeletonLines[i] = line
        end
        line.Visible = true
        line.BackgroundColor3 = color
        local dx = spB.X - spA.X
        local dy = spB.Y - spA.Y
        local len = math.sqrt(dx*dx + dy*dy)
        local ang = math.atan2(dy, dx)
        line.AnchorPoint = Vector2.new(0.5, 0.5)
        line.Size = UDim2.new(0, len, 0, 1)
        line.Position = UDim2.new(0, (spA.X + spB.X) / 2, 0, (spA.Y + spB.Y) / 2)
        line.Rotation = math.deg(ang)
    end
end

-- ============================================================
-- INPUT STATE
-- ============================================================
local aimActive = false
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Config.AimKey then aimActive = true end
    if input.KeyCode == Enum.KeyCode.RightShift then
        Config.AimbotEnabled = not Config.AimbotEnabled
    elseif input.KeyCode == Enum.KeyCode.Insert then
        Config.EspEnabled = not Config.EspEnabled
    end
end)
UserInputService.InputEnded:Connect(function(input, gp)
    if input.UserInputType == Config.AimKey then aimActive = false end
end)

-- ============================================================
-- MAIN LOOP
-- ============================================================
local currentTarget = nil

RunService.RenderStepped:Connect(function()
    -- FOV circle
    if Config.ShowFOVCircle then
        FOVCircle.Visible = true
        FOVCircle.Position = UDim2.new(0, Camera.ViewportSize.X / 2, 0, Camera.ViewportSize.Y / 2)
        FOVCircle.Size = UDim2.new(0, Config.FOV * 2, 0, Config.FOV * 2)
        CircleStroke.Color = Config.AimbotEnabled and Color3.fromRGB(255, 60, 90) or Color3.fromRGB(100, 100, 100)
    else
        FOVCircle.Visible = false
    end

    -- AIMBOT
    local target = nil
    if Config.AimbotEnabled and aimActive then
        target = getClosestTarget()
    end
    currentTarget = target

    if target then
        local aimPos = getAimPos(target)
        if aimPos then
            local camCF = Camera.CFrame
            local dir = (aimPos - camCF.Position).Unit
            local targetCF = CFrame.new(camCF.Position, camCF.Position + dir)
            Camera.CFrame = camCF:Lerp(targetCF, 1 - Config.Smoothness)

            -- target line
            if Config.ShowTargetLine then
                local sp, on = worldToScreen(aimPos)
                if on then
                    local startPos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    local endPos = Vector2.new(sp.X, sp.Y)
                    local dx = endPos.X - startPos.X
                    local dy = endPos.Y - startPos.Y
                    local len = math.sqrt(dx*dx + dy*dy)
                    TargetLine.Visible = true
                    TargetLine.AnchorPoint = Vector2.new(0.5, 0.5)
                    TargetLine.Size = UDim2.new(0, len, 0, 1)
                    TargetLine.Position = UDim2.new(0, (startPos.X + endPos.X) / 2, 0, (startPos.Y + endPos.Y) / 2)
                    TargetLine.Rotation = math.deg(math.atan2(dy, dx))
                end
            else
                TargetLine.Visible = false
            end
        end
    else
        TargetLine.Visible = false
    end

    -- ESP
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local myPos = myRoot and myRoot.Position or Camera.CFrame.Position

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        local cache = espCache[plr]
        if not Config.EspEnabled or not isAlive(plr) then
            if cache then
                cache.box.Visible = false
                cache.headDot.Visible = false
                cache.tracer.Visible = false
                for _, l in ipairs(cache.skeletonLines) do l.Visible = false end
            end
            continue
        end

        local char = plr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not (hrp and head and hum) then continue end

        local dist3D = (hrp.Position - myPos).Magnitude
        if dist3D > Config.EspMaxDist then
            if cache then cache.box.Visible = false; cache.headDot.Visible = false; cache.tracer.Visible = false end
            continue
        end

        -- Box corners
        local top = (head.Position + Vector3.new(0, 1.8, 0))
        local bottom = (hrp.Position - Vector3.new(0, 3, 0))
        local topSP, onA = worldToScreen(top)
        local bottomSP, onB = worldToScreen(bottom)
        if not (onA and onB) then
            if cache then cache.box.Visible = false; cache.headDot.Visible = false; cache.tracer.Visible = false end
            continue
        end

        cache = createEspFor(plr)
        cache.box.Visible = Config.EspBox
        cache.headDot.Visible = Config.EspHeadDot
        cache.tracer.Visible = Config.EspTracer

        local height = math.abs(bottomSP.Y - topSP.Y)
        local width = height * 0.5
        local cx = (topSP.X + bottomSP.X) / 2

        cache.box.Position = UDim2.new(0, cx - width / 2, 0, topSP.Y)
        cache.box.Size = UDim2.new(0, width, 0, height)

        -- cor: team ou inimigo
        local color = Color3.fromRGB(255, 60, 90)
        if Config.EspTeamColor then
            if LocalPlayer.Team and plr.Team then
                if plr.Team == LocalPlayer.Team then
                    color = Color3.fromRGB(80, 220, 120)
                else
                    color = Color3.fromRGB(255, 60, 90)
                end
            elseif plr.Team then
                color = plr.Team.TeamColor.Color
            end
        end
        local vis = hasLOS(plr)
        cache.stroke.Color = color
        cache.stroke.Transparency = vis and 0.1 or 0.65

        -- info
        local lines = {}
        if Config.EspName then table.insert(lines, plr.Name) end
        cache.info.Text = table.concat(lines, "  •  ")
        cache.info.Position = UDim2.new(0.5, 0, 0, -2)
        cache.info.Visible = #lines > 0
        cache.info.TextColor3 = color
        cache.info.TextSize = Config.EspTextSize

        -- distance
        if Config.EspDistance then
            cache.dist.Visible = true
            cache.dist.Text = string.format("%d m", math.floor(dist3D))
            cache.dist.Position = UDim2.new(0.5, 0, 1, 2)
            cache.dist.TextSize = Config.EspTextSize - 1
        else
            cache.dist.Visible = false
        end

        -- health
        if Config.EspHealth then
            cache.healthBarBg.Visible = true
            local hpct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            cache.healthBar.Size = UDim2.new(hpct, 0, 1, 0)
            cache.healthBar.BackgroundColor3 = Color3.fromRGB(
                math.floor(255 * (1 - hpct) + 60 * hpct),
                math.floor(220 * hpct + 40),
                60
            )
            cache.healthBarBg.Size = UDim2.new(0, width + 4, 0, 4)
            cache.healthBarBg.Position = UDim2.new(0.5, 0, 1, 16)
            cache.healthBarBg.AnchorPoint = Vector2.new(0.5, 0)
        else
            cache.healthBarBg.Visible = false
        end

        -- head dot
        if Config.EspHeadDot then
            local hsp, hon = worldToScreen(head.Position)
            if hon then
                cache.headDot.Position = UDim2.new(0, hsp.X, 0, hsp.Y)
                cache.headDot.BackgroundColor3 = color
            else
                cache.headDot.Visible = false
            end
        end

        -- tracer
        if Config.EspTracer then
            local startPos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            local endPos = Vector2.new(bottomSP.X, bottomSP.Y)
            local dx = endPos.X - startPos.X
            local dy = endPos.Y - startPos.Y
            local len = math.sqrt(dx*dx + dy*dy)
            cache.tracer.AnchorPoint = Vector2.new(0.5, 0.5)
            cache.tracer.Size = UDim2.new(0, len, 0, 1)
            cache.tracer.Position = UDim2.new(0, (startPos.X + endPos.X) / 2, 0, (startPos.Y + endPos.Y) / 2)
            cache.tracer.Rotation = math.deg(math.atan2(dy, dx))
            cache.tracer.BackgroundColor3 = color
        end

        -- skeleton
        if Config.EspSkeleton then
            drawSkeleton(cache, char, color)
        else
            for _, l in ipairs(cache.skeletonLines) do l.Visible = false end
        end

        -- chams local (highlight via Instances temporário)
        if Config.EspChams then
            local hl = char:FindFirstChild("__ESP_HL")
            if not hl then
                hl = Instance.new("Highlight")
                hl.Name = "__ESP_HL"
                hl.FillTransparency = 0.5
                hl.OutlineTransparency = 0
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Parent = char
            end
            hl.FillColor = color
            hl.OutlineColor = color
        else
            local hl = char:FindFirstChild("__ESP_HL")
            if hl then hl:Destroy() end
        end
    end
end)

-- limpar ESP quando player sair
Players.PlayerRemoving:Connect(function(plr)
    removeEspFor(plr)
end)

print("[Rush PvP Aim+ESP] carregado")
print("Hotkeys: RightShift=Aimbot | Insert=ESP | Botão direito = segurar mira")
