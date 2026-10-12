-- ═══════════════════════════════════════════════════════════
--   ZEUS AIMBOT  //  CRUSH PVP EDITION
--   Design: pvp hack menu
--   Compat: Synapse, Krnl, Fluxus, Delta, Arceus X, Bacon
-- ═══════════════════════════════════════════════════════════

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local LocalPlayer      = Players.LocalPlayer
local Camera           = workspace.CurrentCamera
local Mouse            = LocalPlayer:GetMouse()

-- ═══════════════════════════════════════════════════════════
--  CONFIG  (tudo OFF por padrão)
-- ═══════════════════════════════════════════════════════════
local Config = {
    -- AIMBOT
    Aimbot        = false,
    AimKey        = Enum.UserInputType.MouseButton2,
    FOV           = 200,
    Smoothness    = 0.25,
    Prediction    = 0.13,
    TeamCheck     = true,
    WallCheck     = true,
    MaxDist       = 1500,
    FovCircle     = false,
    TargetLine    = false,

    -- ESP
    Esp           = false,
    EspBox        = false,
    EspName       = false,
    EspHealth     = false,
    EspDistance   = false,
    EspTracer     = false,
    EspSkeleton   = false,
    EspHeadDot    = false,
    EspChams      = false,
    EspTeamColor  = true,
    EspMaxDist    = 2500,
    EspTextSize   = 12,
}

-- ═══════════════════════════════════════════════════════════
--  UTILS
-- ═══════════════════════════════════════════════════════════
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

local function getHead(plr)
    local char = plr.Character
    if not char then return nil end
    local h = char:FindFirstChild("Head")
    if h and h:IsA("BasePart") then return h end
    for _, n in ipairs({ "HeadHitbox", "HeadPart", "head", "HEAD", "Hitbox_Head" }) do
        local p = char:FindFirstChild(n)
        if p and p:IsA("BasePart") then return p end
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        for _, d in ipairs(hum:GetDescendants()) do
            if d:IsA("BasePart") and d.Name:lower():find("head") then return d end
        end
    end
    return nil
end

local function hasLOS(target)
    local myChar = LocalPlayer.Character
    if not myChar then return false end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return false end
    local tHead = getHead(target)
    if not tHead then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { myChar, target.Character, Camera }
    local ray = workspace:Raycast(myRoot.Position, tHead.Position - myRoot.Position, params)
    return ray == nil
end

local function worldToScreen(pos)
    local sp, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector3.new(sp.X, sp.Y, sp.Z), onScreen
end

local function getAimPos(plr)
    local head = getHead(plr)
    if not head then return nil end
    local pos = head.Position
    if Config.Prediction > 0 then
        local char = plr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            pos = pos + hrp.AssemblyLinearVelocity * Config.Prediction
        end
    end
    return pos
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

        local head = getHead(plr)
        if not head then continue end

        local dist3D = (head.Position - myPos).Magnitude
        if dist3D > Config.MaxDist then continue end

        local screenPos, onScreen = worldToScreen(head.Position)
        if not onScreen then continue end

        local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
        if dist > Config.FOV then continue end

        if Config.WallCheck and not hasLOS(plr) then continue end

        local score = dist + dist3D * 0.02
        if score < bestScore then
            bestScore = score
            best = plr
        end
    end
    return best
end

-- ═══════════════════════════════════════════════════════════
--  THEME
-- ═══════════════════════════════════════════════════════════
local Theme = {
    Bg          = Color3.fromRGB(10, 10, 14),
    BgAlt       = Color3.fromRGB(16, 16, 22),
    Card        = Color3.fromRGB(20, 20, 28),
    CardHover   = Color3.fromRGB(26, 26, 36),
    Border      = Color3.fromRGB(40, 40, 55),
    Text        = Color3.fromRGB(235, 235, 245),
    TextDim     = Color3.fromRGB(140, 140, 160),
    Accent      = Color3.fromRGB(120, 100, 255),   -- roxo zeus
    AccentAlt   = Color3.fromRGB(255, 200, 80),    -- dourado
    Danger      = Color3.fromRGB(255, 70, 100),
    Success     = Color3.fromRGB(80, 220, 130),
}

-- ═══════════════════════════════════════════════════════════
--  GUI ROOT
-- ═══════════════════════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZeusAimbot"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = (gethui and gethui()) or game:GetService("CoreGui")

-- ═══════════════════════════════════════════════════════════
--  TOGGLE BUTTON (floating, canto sup esq)
-- ═══════════════════════════════════════════════════════════
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "ZeusToggle"
ToggleBtn.Size = UDim2.new(0, 46, 0, 46)
ToggleBtn.Position = UDim2.new(0, 20, 0, 80)
ToggleBtn.BackgroundColor3 = Theme.Bg
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Text = "Z"
ToggleBtn.TextColor3 = Theme.AccentAlt
ToggleBtn.Font = Enum.Font.GothamBlack
ToggleBtn.TextSize = 22
ToggleBtn.AutoButtonColor = false
ToggleBtn.Parent = ScreenGui
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 12)

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color = Theme.Accent
ToggleStroke.Thickness = 2
ToggleStroke.Parent = ToggleBtn

local ToggleGlow = Instance.new("ImageLabel")
ToggleGlow.Size = UDim2.new(1, 24, 1, 24)
ToggleGlow.Position = UDim2.new(0, -12, 0, -12)
ToggleGlow.BackgroundTransparency = 1
ToggleGlow.Image = "rbxassetid://5028857084"
ToggleGlow.ImageColor3 = Theme.Accent
ToggleGlow.ImageTransparency = 0.6
ToggleGlow.ZIndex = 0
ToggleGlow.Parent = ToggleBtn

ToggleBtn.MouseEnter:Connect(function()
    TweenService:Create(ToggleStroke, TweenInfo.new(0.15), { Thickness = 3, Color = Theme.AccentAlt }):Play()
end)
ToggleBtn.MouseLeave:Connect(function()
    TweenService:Create(ToggleStroke, TweenInfo.new(0.15), { Thickness = 2, Color = Theme.Accent }):Play()
end)

-- ═══════════════════════════════════════════════════════════
--  MAIN WINDOW
-- ═══════════════════════════════════════════════════════════
local Main = Instance.new("Frame")
Main.Name = "ZeusMain"
Main.Size = UDim2.new(0, 400, 0, 340)
Main.Position = UDim2.new(0.5, -200, 0.5, -170)
Main.BackgroundColor3 = Theme.Bg
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Visible = true
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Theme.Accent
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.3
MainStroke.Parent = Main

-- glow externo
local MainGlow = Instance.new("ImageLabel")
MainGlow.Size = UDim2.new(1, 60, 1, 60)
MainGlow.Position = UDim2.new(0, -30, 0, -30)
MainGlow.BackgroundTransparency = 1
MainGlow.Image = "rbxassetid://5028857084"
MainGlow.ImageColor3 = Theme.Accent
MainGlow.ImageTransparency = 0.75
MainGlow.ZIndex = 0
MainGlow.Parent = Main

-- ─────────── HEADER ───────────
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 54)
Header.BackgroundColor3 = Theme.BgAlt
Header.BorderSizePixel = 0
Header.Parent = Main
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 14)

local HeaderFix = Instance.new("Frame")
HeaderFix.Size = UDim2.new(1, 0, 0, 14)
HeaderFix.Position = UDim2.new(0, 0, 1, -14)
HeaderFix.BackgroundColor3 = Theme.BgAlt
HeaderFix.BorderSizePixel = 0
HeaderFix.Parent = Header

-- header gradient
local HeaderGrad = Instance.new("UIGradient")
HeaderGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Theme.BgAlt),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(28, 22, 45)),
}
HeaderGrad.Rotation = 25
HeaderGrad.Parent = Header

-- logo "Z"
local LogoFrame = Instance.new("Frame")
LogoFrame.Size = UDim2.new(0, 36, 0, 36)
LogoFrame.Position = UDim2.new(0, 12, 0.5, -18)
LogoFrame.BackgroundColor3 = Theme.Accent
LogoFrame.BorderSizePixel = 0
LogoFrame.Parent = Header
Instance.new("UICorner", LogoFrame).CornerRadius = UDim.new(0, 10)

local LogoText = Instance.new("TextLabel")
LogoText.Size = UDim2.new(1, 0, 1, 0)
LogoText.BackgroundTransparency = 1
LogoText.Text = "Z"
LogoText.TextColor3 = Color3.fromRGB(255, 255, 255)
LogoText.Font = Enum.Font.GothamBlack
LogoText.TextSize = 20
LogoText.Parent = LogoFrame

-- título
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -180, 0, 18)
Title.Position = UDim2.new(0, 58, 0, 10)
Title.BackgroundTransparency = 1
Title.Text = "ZEUS AIMBOT"
Title.TextColor3 = Theme.Text
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 16
Title.Parent = Header

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(1, -180, 0, 14)
Subtitle.Position = UDim2.new(0, 58, 0, 28)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "crush pvp edition"
Subtitle.TextColor3 = Theme.AccentAlt
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Font = Enum.Font.Gotham
Subtitle.TextSize = 11
Subtitle.Parent = Header

-- botão fechar
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Position = UDim2.new(1, -34, 0.5, -12)
CloseBtn.BackgroundColor3 = Color3.fromRGB(40, 20, 30)
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Theme.Danger
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 18
CloseBtn.BorderSizePixel = 0
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = Header
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

CloseBtn.MouseButton1Click:Connect(function()
    TweenService:Create(Main, TweenInfo.new(0.15), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
    }):Play()
    task.wait(0.15)
    Main.Visible = false
end)

-- ─────────── TAB BAR ───────────
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -24, 0, 32)
TabBar.Position = UDim2.new(0, 12, 0, 60)
TabBar.BackgroundColor3 = Theme.BgAlt
TabBar.BorderSizePixel = 0
TabBar.Parent = Main
Instance.new("UICorner", TabBar).CornerRadius = UDim.new(0, 8)

local TabList = Instance.new("UIListLayout")
TabList.FillDirection = Enum.FillDirection.Horizontal
TabList.Padding = UDim.new(0, 4)
TabList.SortOrder = Enum.SortOrder.LayoutOrder
TabList.VerticalAlignment = Enum.VerticalAlignment.Center
TabList.Parent = TabBar

local TabPad = Instance.new("UIPadding")
TabPad.PaddingLeft = UDim.new(0, 4)
TabPad.PaddingRight = UDim.new(0, 4)
TabPad.Parent = TabBar

local Tabs = {}
local TabContent = {}

local function switchTab(name)
    for tname, btn in pairs(Tabs) do
        local active = (tname == name)
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = active and Theme.Accent or Theme.BgAlt,
        }):Play()
        btn.TextColor3 = active and Color3.fromRGB(255, 255, 255) or Theme.TextDim
    end
    for cname, frame in pairs(TabContent) do
        frame.Visible = (cname == name)
    end
end

local function makeTab(name, label)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 90, 0, 24)
    btn.BackgroundColor3 = Theme.BgAlt
    btn.Text = label
    btn.TextColor3 = Theme.TextDim
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Parent = TabBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    Tabs[name] = btn

    local frame = Instance.new("ScrollingFrame")
    frame.Size = UDim2.new(1, -24, 1, -156)
    frame.Position = UDim2.new(0, 12, 0, 100)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.ScrollBarThickness = 3
    frame.ScrollBarImageColor3 = Theme.Accent
    frame.CanvasSize = UDim2.new(0, 0, 0, 0)
    frame.Visible = false
    frame.Parent = Main
    TabContent[name] = frame

    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 6)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = frame

    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        frame.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 8)
    end)

    btn.MouseButton1Click:Connect(function() switchTab(name) end)
    return frame
end

-- ─────────── WIDGETS ───────────
local function makeSection(parent, text)
    local sec = Instance.new("Frame")
    sec.Size = UDim2.new(1, 0, 0, 26)
    sec.BackgroundTransparency = 1
    sec.Parent = parent

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 3, 0, 14)
    bar.Position = UDim2.new(0, 0, 0.5, -7)
    bar.BackgroundColor3 = Theme.Accent
    bar.BorderSizePixel = 0
    bar.Parent = sec
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -12, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text:upper()
    lbl.TextColor3 = Theme.AccentAlt
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.Parent = sec
end

local function makeToggle(parent, name, default, callback)
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, 0, 0, 34)
    Row.BackgroundColor3 = Theme.Card
    Row.BorderSizePixel = 0
    Row.Parent = parent
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 8)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -70, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = Theme.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 13
    Label.Parent = Row

    local Toggle = Instance.new("TextButton")
    Toggle.Size = UDim2.new(0, 42, 0, 20)
    Toggle.Position = UDim2.new(1, -54, 0.5, -10)
    Toggle.BackgroundColor3 = default and Theme.Accent or Color3.fromRGB(45, 45, 58)
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
            BackgroundColor3 = v and Theme.Accent or Color3.fromRGB(45, 45, 58)
        }):Play()
        TweenService:Create(Knob, TweenInfo.new(0.15), {
            Position = v and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        }):Play()
        if callback then callback(v) end
    end
    Toggle.MouseButton1Click:Connect(function() update(not state) end)

    Row.MouseEnter:Connect(function()
        TweenService:Create(Row, TweenInfo.new(0.15), { BackgroundColor3 = Theme.CardHover }):Play()
    end)
    Row.MouseLeave:Connect(function()
        TweenService:Create(Row, TweenInfo.new(0.15), { BackgroundColor3 = Theme.Card }):Play()
    end)

    return { Set = update, Get = function() return state end }
end

local function makeSlider(parent, name, min, max, default, callback)
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, 0, 0, 48)
    Row.BackgroundColor3 = Theme.Card
    Row.BorderSizePixel = 0
    Row.Parent = parent
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 8)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -24, 0, 18)
    Label.Position = UDim2.new(0, 12, 0, 5)
    Label.BackgroundTransparency = 1
    Label.Text = name .. "  [" .. default .. "]"
    Label.TextColor3 = Theme.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 12
    Label.Parent = Row

    local Track = Instance.new("Frame")
    Track.Size = UDim2.new(1, -24, 0, 6)
    Track.Position = UDim2.new(0, 12, 0, 30)
    Track.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
    Track.BorderSizePixel = 0
    Track.Parent = Row
    Instance.new("UICorner", Track).CornerRadius = UDim.new(1, 0)

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    Fill.BackgroundColor3 = Theme.Accent
    Fill.BorderSizePixel = 0
    Fill.Parent = Track
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)

    local FillGrad = Instance.new("UIGradient")
    FillGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Theme.Accent),
        ColorSequenceKeypoint.new(1, Theme.AccentAlt),
    }
    FillGrad.Parent = Fill

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

    return { Set = function(v) updateFromX(Track.AbsolutePosition.X + (v - min) / (max - min) * Track.AbsoluteSize.X) end }
end

-- ─────────── CREATE TABS ───────────
local CombatTab = makeTab("Combat", "COMBAT")
local VisualTab = makeTab("Visual", "VISUAL")

-- ▓▓▓ COMBAT TAB ▓▓▓
makeSection(CombatTab, "Aimbot")
makeToggle(CombatTab, "Aimbot Master Switch", Config.Aimbot, function(v) Config.Aimbot = v end)
makeToggle(CombatTab, "Team Check", Config.TeamCheck, function(v) Config.TeamCheck = v end)
makeToggle(CombatTab, "Wall Check", Config.WallCheck, function(v) Config.WallCheck = v end)
makeSlider(CombatTab, "FOV", 30, 800, Config.FOV, function(v) Config.FOV = v end)
makeSlider(CombatTab, "Smoothness", 0.05, 1.0, Config.Smoothness, function(v) Config.Smoothness = v end)
makeSlider(CombatTab, "Prediction", 0, 0.5, Config.Prediction, function(v) Config.Prediction = v end)
makeSlider(CombatTab, "Max Dist", 100, 3000, Config.MaxDist, function(v) Config.MaxDist = v end)

makeSection(CombatTab, "Aimbot Visuals")
makeToggle(CombatTab, "FOV Circle", Config.FovCircle, function(v) Config.FovCircle = v end)
makeToggle(CombatTab, "Target Line", Config.TargetLine, function(v) Config.TargetLine = v end)

-- ▓▓▓ VISUAL TAB ▓▓▓
makeSection(VisualTab, "ESP Master")
makeToggle(VisualTab, "ESP", Config.Esp, function(v) Config.Esp = v end)
makeToggle(VisualTab, "Box", Config.EspBox, function(v) Config.EspBox = v end)
makeToggle(VisualTab, "Name", Config.EspName, function(v) Config.EspName = v end)
makeToggle(VisualTab, "Health Bar", Config.EspHealth, function(v) Config.EspHealth = v end)
makeToggle(VisualTab, "Distance", Config.EspDistance, function(v) Config.EspDistance = v end)
makeToggle(VisualTab, "Tracer", Config.EspTracer, function(v) Config.EspTracer = v end)
makeToggle(VisualTab, "Skeleton", Config.EspSkeleton, function(v) Config.EspSkeleton = v end)
makeToggle(VisualTab, "Head Dot", Config.EspHeadDot, function(v) Config.EspHeadDot = v end)
makeToggle(VisualTab, "Chams (Local)", Config.EspChams, function(v) Config.EspChams = v end)
makeToggle(VisualTab, "Team Color", Config.EspTeamColor, function(v) Config.EspTeamColor = v end)

makeSection(VisualTab, "ESP Settings")
makeSlider(VisualTab, "ESP Max Dist", 200, 5000, Config.EspMaxDist, function(v) Config.EspMaxDist = v end)
makeSlider(VisualTab, "Text Size", 8, 20, Config.EspTextSize, function(v) Config.EspTextSize = v end)

switchTab("Combat")

-- ═══════════════════════════════════════════════════════════
--  TOGGLE WINDOW
-- ═══════════════════════════════════════════════════════════
local windowOpen = true
ToggleBtn.MouseButton1Click:Connect(function()
    windowOpen = not windowOpen
    if windowOpen then
        Main.Visible = true
        Main.Size = UDim2.new(0, 0, 0, 0)
        Main.Position = UDim2.new(0.5, 0, 0.5, 0)
        TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 400, 0, 340),
            Position = UDim2.new(0.5, -200, 0.5, -170),
        }):Play()
    else
        TweenService:Create(Main, TweenInfo.new(0.15), {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0),
        }):Play()
        task.wait(0.15)
        Main.Visible = false
    end
end)

-- ═══════════════════════════════════════════════════════════
--  OVERLAYS (FOV, TARGET LINE, HEAD MARKER)
-- ═══════════════════════════════════════════════════════════
local OverlayGui = Instance.new("ScreenGui")
OverlayGui.Name = "ZeusOverlays"
OverlayGui.ResetOnSpawn = false
OverlayGui.IgnoreGuiInset = true
OverlayGui.Parent = ScreenGui.Parent

local FOVCircle = Instance.new("Frame")
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.BackgroundTransparency = 1
FOVCircle.Size = UDim2.new(0, 400, 0, 400)
FOVCircle.Visible = false
FOVCircle.Parent = OverlayGui
Instance.new("UICorner", FOVCircle).CornerRadius = UDim.new(1, 0)

local CircleStroke = Instance.new("UIStroke")
CircleStroke.Color = Theme.Accent
CircleStroke.Thickness = 1.5
CircleStroke.Transparency = 0.35
CircleStroke.Parent = FOVCircle

local TargetLine = Instance.new("Frame")
TargetLine.BackgroundColor3 = Theme.Accent
TargetLine.BorderSizePixel = 0
TargetLine.BackgroundTransparency = 0.35
TargetLine.Visible = false
TargetLine.ZIndex = 0
TargetLine.Parent = OverlayGui

local HeadMarker = Instance.new("Frame")
HeadMarker.Size = UDim2.new(0, 18, 0, 18)
HeadMarker.AnchorPoint = Vector2.new(0.5, 0.5)
HeadMarker.BackgroundTransparency = 1
HeadMarker.Visible = false
HeadMarker.Parent = OverlayGui

local HeadMarkerStroke = Instance.new("UIStroke")
HeadMarkerStroke.Color = Theme.Accent
HeadMarkerStroke.Thickness = 2
HeadMarkerStroke.Parent = HeadMarker
Instance.new("UICorner", HeadMarker).CornerRadius = UDim.new(1, 0)

-- ═══════════════════════════════════════════════════════════
--  ESP
-- ═══════════════════════════════════════════════════════════
local EspGui = Instance.new("ScreenGui")
EspGui.Name = "ZeusESP"
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
    stroke.Color = Theme.Accent
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
    healthBar.BackgroundColor3 = Theme.Success
    healthBar.BorderSizePixel = 0
    healthBar.Size = UDim2.new(1, 0, 1, 0)
    healthBar.Parent = healthBarBg
    Instance.new("UICorner", healthBar).CornerRadius = UDim.new(0, 3)

    local headDot = Instance.new("Frame")
    headDot.Size = UDim2.new(0, 6, 0, 6)
    headDot.AnchorPoint = Vector2.new(0.5, 0.5)
    headDot.BackgroundColor3 = Theme.Accent
    headDot.BorderSizePixel = 0
    headDot.Visible = false
    headDot.ZIndex = 3
    headDot.Parent = EspFolder
    Instance.new("UICorner", headDot).CornerRadius = UDim.new(1, 0)

    local tracer = Instance.new("Frame")
    tracer.BackgroundColor3 = Theme.Accent
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

-- ═══════════════════════════════════════════════════════════
--  INPUT
-- ═══════════════════════════════════════════════════════════
local aimActive = false

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Config.AimKey then aimActive = true end

    if input.KeyCode == Enum.KeyCode.RightShift then
        Config.Aimbot = not Config.Aimbot
    elseif input.KeyCode == Enum.KeyCode.Insert then
        Config.Esp = not Config.Esp
    elseif input.KeyCode == Enum.KeyCode.RightControl then
        ToggleBtn.MouseButton1Click:Fire()
    end
end)

UserInputService.InputEnded:Connect(function(input, gp)
    if input.UserInputType == Config.AimKey then aimActive = false end
end)

-- ═══════════════════════════════════════════════════════════
--  MAIN LOOP
-- ═══════════════════════════════════════════════════════════
RunService.RenderStepped:Connect(function()
    -- FOV circle
    if Config.FovCircle then
        FOVCircle.Visible = true
        FOVCircle.Position = UDim2.new(0, Camera.ViewportSize.X / 2, 0, Camera.ViewportSize.Y / 2)
        FOVCircle.Size = UDim2.new(0, Config.FOV * 2, 0, Config.FOV * 2)
        CircleStroke.Color = Config.Aimbot and Theme.Accent or Color3.fromRGB(80, 80, 90)
    else
        FOVCircle.Visible = false
    end

    -- AIMBOT
    local target = nil
    if Config.Aimbot and aimActive then
        target = getClosestTarget()
    end

    if target then
        local aimPos = getAimPos(target)
        if aimPos then
            local camCF = Camera.CFrame
            local dir = (aimPos - camCF.Position).Unit
            local targetCF = CFrame.new(camCF.Position, camCF.Position + dir)
            Camera.CFrame = camCF:Lerp(targetCF, 1 - Config.Smoothness)

            local hsp, hon = worldToScreen(aimPos)
            if hon then
                HeadMarker.Visible = true
                HeadMarker.Position = UDim2.new(0, hsp.X, 0, hsp.Y)
                HeadMarkerStroke.Color = Theme.Accent
            else
                HeadMarker.Visible = false
            end

            if Config.TargetLine then
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
                    TargetLine.BackgroundColor3 = Theme.Accent
                end
            else
                TargetLine.Visible = false
            end
        end
    else
        TargetLine.Visible = false
        HeadMarker.Visible = false
    end

    -- ESP
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local myPos = myRoot and myRoot.Position or Camera.CFrame.Position

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        local cache = espCache[plr]
        if not Config.Esp or not isAlive(plr) then
            if cache then
                cache.box.Visible = false
                cache.headDot.Visible = false
                cache.tracer.Visible = false
                for _, l in ipairs(cache.skeletonLines) do l.Visible = false end
                local hl = plr.Character and plr.Character:FindFirstChild("__ZEUS_HL")
                if hl then hl:Destroy() end
            end
            continue
        end

        local char = plr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local head = getHead(plr)
        if not (hrp and hum and head) then continue end

        local dist3D = (hrp.Position - myPos).Magnitude
        if dist3D > Config.EspMaxDist then
            if cache then
                cache.box.Visible = false; cache.headDot.Visible = false; cache.tracer.Visible = false
                for _, l in ipairs(cache.skeletonLines) do l.Visible = false end
            end
            continue
        end

        local topSP, onA = worldToScreen(head.Position + Vector3.new(0, 1.2, 0))
        local bottomSP, onB = worldToScreen(hrp.Position - Vector3.new(0, 3, 0))
        if not (onA and onB) then
            if cache then
                cache.box.Visible = false; cache.headDot.Visible = false; cache.tracer.Visible = false
                for _, l in ipairs(cache.skeletonLines) do l.Visible = false end
            end
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

        local color = Theme.Accent
        if Config.EspTeamColor then
            if LocalPlayer.Team and plr.Team then
                color = (plr.Team == LocalPlayer.Team) and Theme.Success or Theme.Danger
            elseif plr.Team then
                color = plr.Team.TeamColor.Color
            end
        end
        local vis = hasLOS(plr)
        cache.stroke.Color = color
        cache.stroke.Transparency = vis and 0.1 or 0.65

        local lines = {}
        if Config.EspName then table.insert(lines, plr.Name) end
        cache.info.Text = table.concat(lines, "  •  ")
        cache.info.Position = UDim2.new(0.5, 0, 0, -2)
        cache.info.Visible = #lines > 0
        cache.info.TextColor3 = color
        cache.info.TextSize = Config.EspTextSize

        if Config.EspDistance then
            cache.dist.Visible = true
            cache.dist.Text = string.format("%d m", math.floor(dist3D))
            cache.dist.Position = UDim2.new(0.5, 0, 1, 2)
            cache.dist.TextSize = Config.EspTextSize - 1
        else
            cache.dist.Visible = false
        end

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

        if Config.EspHeadDot then
            local hsp, hon = worldToScreen(head.Position)
            if hon then
                cache.headDot.Position = UDim2.new(0, hsp.X, 0, hsp.Y)
                cache.headDot.BackgroundColor3 = color
            else
                cache.headDot.Visible = false
            end
        end

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

        if Config.EspSkeleton then
            drawSkeleton(cache, char, color)
        else
            for _, l in ipairs(cache.skeletonLines) do l.Visible = false end
        end

        if Config.EspChams then
            local hl = char:FindFirstChild("__ZEUS_HL")
            if not hl then
                hl = Instance.new("Highlight")
                hl.Name = "__ZEUS_HL"
                hl.FillTransparency = 0.5
                hl.OutlineTransparency = 0
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Parent = char
            end
            hl.FillColor = color
            hl.OutlineColor = color
        else
            local hl = char:FindFirstChild("__ZEUS_HL")
            if hl then hl:Destroy() end
        end
    end
end)

Players.PlayerRemoving:Connect(function(plr)
    removeEspFor(plr)
end)

print("[Zeus Aimbot] carregado")
print("  RightShift   → toggle Aimbot")
print("  Insert       → toggle ESP")
print("  RightControl → abrir/fechar painel")
print("  Botão direito → segurar mira (quando aimbot ON)")
