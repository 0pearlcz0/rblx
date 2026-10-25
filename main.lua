-- ══════════════════════════════════════════════════════════════
--  MM2 SHORT — PHASE 1B (ESP + Fling + UI)
--  INSERT = menu · DELETE = panic · END = watermark
-- ══════════════════════════════════════════════════════════════
local BUILD = "PHASE-1B"

pcall(function() if _G.__MM2Short_Destroy then _G.__MM2Short_Destroy() end end)

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Workspace        = game:GetService("Workspace")
local Lighting         = game:GetService("Lighting")
local StarterGui       = game:GetService("StarterGui")
local Camera           = Workspace.CurrentCamera
local LP               = Players.LocalPlayer

-- ══════════════════════════════════════════════════════════════
--  THEME
-- ══════════════════════════════════════════════════════════════
local T = {
    BG      = Color3.fromRGB(10,10,13),
    Surface = Color3.fromRGB(18,18,22),
    Accent  = Color3.fromRGB(214,40,56),
    AccentDrk=Color3.fromRGB(140,20,35),
    Text    = Color3.fromRGB(240,240,245),
    Dim     = Color3.fromRGB(140,140,150),
    Faint   = Color3.fromRGB(80,80,90),
    Good    = Color3.fromRGB(72,199,116),
    Warn    = Color3.fromRGB(232,172,62),
    Bad     = Color3.fromRGB(226,72,72),
    Border  = Color3.fromRGB(35,35,42),
    Murd    = Color3.fromRGB(255,60,60),
    Sher    = Color3.fromRGB(255,200,50),
    Inno    = Color3.fromRGB(80,160,255),
}

-- ══════════════════════════════════════════════════════════════
--  HELPERS
-- ══════════════════════════════════════════════════════════════
local function tw(i,p,t,s,d)
    local tween = TweenService:Create(i, TweenInfo.new(t or 0.25, s or Enum.EasingStyle.Quint, d or Enum.EasingDirection.Out), p)
    tween:Play() return tween
end
local function corner(i,r)
    local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,r or 8) c.Parent=i return c
end
local function stroke(i,c,t,tr)
    local s=Instance.new("UIStroke") s.Color=c or T.Border s.Thickness=t or 1 s.Transparency=tr or 0
    s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border s.Parent=i return s
end
local function lbl(p,txt,sz,col,fnt,xa,pos,s2)
    local l=Instance.new("TextLabel") l.Parent=p l.BackgroundTransparency=1 l.Text=txt or ""
    l.TextSize=sz or 13 l.TextColor3=col or T.Text l.Font=fnt or Enum.Font.Gotham
    l.TextXAlignment=xa or Enum.TextXAlignment.Left l.Position=pos or UDim2.new(0,0,0,0)
    l.Size=s2 or UDim2.new(1,0,1,0) l.TextTruncate=Enum.TextTruncate.AtEnd return l
end
local function mount(g)
    local ok=pcall(function()
        if typeof(gethui)=="function" then g.Parent=gethui()
        else g.Parent=game:GetService("CoreGui") end
    end)
    if not ok or not g.Parent then g.Parent=LP:WaitForChild("PlayerGui") end
    return g
end
local function clearOld(n)
    for _,p in ipairs({LP:FindFirstChild("PlayerGui"),game:FindFirstChild("CoreGui")}) do
        if p then pcall(function() local o=p:FindFirstChild(n) if o then o:Destroy() end end) end
    end
    pcall(function() if typeof(gethui)=="function" then local o=gethui():FindFirstChild(n) if o then o:Destroy() end end end)
end
for _,n in ipairs({"MM2Short","MM2ShortVis","MM2ShortWM"}) do clearOld(n) end

local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = 3})
    end)
    print("[" .. title .. "] " .. text)
end

-- ══════════════════════════════════════════════════════════════
--  WATERMARK
-- ══════════════════════════════════════════════════════════════
local WM=mount(Instance.new("ScreenGui"))
WM.Name="MM2ShortWM" WM.ResetOnSpawn=false WM.DisplayOrder=996
local wmFrame=Instance.new("Frame") wmFrame.Size=UDim2.new(0,220,0,30) wmFrame.Position=UDim2.new(0,10,0,10)
wmFrame.BackgroundColor3=T.Surface wmFrame.BackgroundTransparency=0.1 wmFrame.BorderSizePixel=0 wmFrame.Parent=WM
corner(wmFrame,6) stroke(wmFrame,T.Accent,1,0.3)
lbl(wmFrame,"🔪 MM2 Short",12,T.Text,Enum.Font.GothamBold,Enum.TextXAlignment.Left,UDim2.new(0,10,0,0),UDim2.new(0.6,0,1,0))
local wmInfo=lbl(wmFrame,"",10,T.Sher,Enum.Font.GothamBold,Enum.TextXAlignment.Right,UDim2.new(0.6,0,0,0),UDim2.new(0.4,-10,1,0))

-- ══════════════════════════════════════════════════════════════
--  ROLE DETECTION
-- ══════════════════════════════════════════════════════════════
local roleMemory = {}

local function clearRoleMemory() roleMemory = {} end

local function checkToolName(tn)
    if not tn then return nil end
    tn = tn:lower()
    if tn:find("knife") or tn:find("blade") or tn:find("machete") or tn:find("dagger") then return "murderer" end
    if tn:find("gun") or tn:find("revolver") or tn:find("pistol") then return "sheriff" end
    return nil
end

local function scanForTools(container)
    if not container then return nil end
    local ok, result = pcall(function()
        for _, obj in pairs(container:GetChildren()) do
            if obj:IsA("Tool") then
                local r = checkToolName(obj.Name)
                if r then return r end
            end
        end
        return nil
    end)
    return ok and result or nil
end

local function getPlayerRole(player)
    if not player then return "innocent" end
    local pname = player.Name
    if roleMemory[pname] then return roleMemory[pname] end
    local found = scanForTools(player.Character) or scanForTools(player:FindFirstChild("Backpack"))
    if found then roleMemory[pname] = found; return found end
    return "innocent"
end

local watchedChars = {}
local function watchPlayer(p)
    if p == LP then return end
    local function hookCharacter(charObj)
        if not charObj then return end
        if watchedChars[charObj] then return end
        watchedChars[charObj] = true
        charObj.ChildAdded:Connect(function(child)
            if not child:IsA("Tool") then return end
            local r = checkToolName(child.Name)
            if r then roleMemory[p.Name] = r end
        end)
        task.spawn(function()
            task.wait(0.2)
            for _, child in pairs(charObj:GetChildren()) do
                if child:IsA("Tool") then
                    local r = checkToolName(child.Name)
                    if r then roleMemory[p.Name] = r break end
                end
            end
        end)
    end
    if p.Character then hookCharacter(p.Character) end
    p.CharacterAdded:Connect(hookCharacter)
end
for _,p in pairs(Players:GetPlayers()) do pcall(watchPlayer, p) end
Players.PlayerAdded:Connect(function(p) pcall(watchPlayer, p) end)

local function roleColor(role, isDead)
    if isDead then return T.Faint end
    return role=="murderer" and T.Murd or role=="sheriff" and T.Sher or T.Inno
end
local function roleText(role, isDead)
    if isDead then return "DEAD" end
    return role=="murderer" and "MURDERER" or role=="sheriff" and "SHERIFF" or "INNOCENT"
end

-- ══════════════════════════════════════════════════════════════
--  FLING (starý princip: fake part + AlignPosition)
-- ══════════════════════════════════════════════════════════════
local flingState = {active=false}

local function flingPlayer(targetName)
    local target = Players:FindFirstChild(targetName)
    if not target or not target.Character then
        notify("Fling", "Player not found")
        return false
    end
    local myChar = LP.Character
    if not myChar then
        notify("Fling", "Your character not found")
        return false
    end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar:FindFirstChildOfClass("Humanoid")
    local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot or not myHum or not targetRoot then
        notify("Fling", "Missing HumanoidRootPart")
        return false
    end

    if flingState.active then
        notify("Fling", "Already flinging")
        return false
    end
    flingState.active = true

    notify("Fling", "Flinging " .. target.Name .. "...")

    -- Fake part + AlignPosition k targetovi
    local fakePart = Instance.new("Part")
    fakePart.Name = "_mm2fling"
    fakePart.Size = Vector3.new(2, 2, 2)
    fakePart.Transparency = 1
    fakePart.CanCollide = false
    fakePart.Anchored = true
    fakePart.Parent = Workspace

    local attTarget = Instance.new("Attachment", targetRoot)
    local attFake = Instance.new("Attachment", fakePart)

    local align = Instance.new("AlignPosition")
    align.Attachment0 = attFake
    align.Attachment1 = attTarget
    align.RigidityEnabled = true
    align.MaxForce = math.huge
    align.MaxVelocity = math.huge
    align.Responsiveness = math.huge
    align.Parent = fakePart

    fakePart.CFrame = targetRoot.CFrame

    -- Roztočit sebe
    local oldState = myHum:GetState()
    pcall(function() myHum:ChangeState(Enum.HumanoidStateType.StrafingNoPhysics) end)

    local spinCount = 0
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not flingState.active then return end
        spinCount = spinCount + 1
        if spinCount > 30 then
            if conn then conn:Disconnect() end
            return
        end
        pcall(function()
            myRoot.AssemblyAngularVelocity = Vector3.new(math.random(-500,500), math.random(-500,500), math.random(-500,500))
            myRoot.AssemblyLinearVelocity = Vector3.new(math.random(-250,250), math.random(-500,500), math.random(-250,250))
            myRoot.CFrame = fakePart.CFrame
        end)
    end)

    task.delay(1.5, function()
        flingState.active = false
        if conn then conn:Disconnect() end
        pcall(function() align:Destroy() end)
        pcall(function() attTarget:Destroy() end)
        pcall(function() attFake:Destroy() end)
        pcall(function() fakePart:Destroy() end)
        pcall(function() myHum:ChangeState(oldState) end)
        notify("Fling", "Done")
    end)

    return true
end

-- ══════════════════════════════════════════════════════════════
--  MAIN UI
-- ══════════════════════════════════════════════════════════════
local GUI = mount(Instance.new("ScreenGui"))
GUI.Name = "MM2Short" GUI.ResetOnSpawn = false GUI.DisplayOrder = 999

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 320, 0, 440)
Main.Position = UDim2.new(0.5, -160, 0.5, -220)
Main.BackgroundColor3 = T.BG
Main.BorderSizePixel = 0
Main.Active = true
Main.Visible = false
Main.Parent = GUI
corner(Main, 10) stroke(Main, T.Border, 1)

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = T.Surface
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main
corner(TitleBar, 10)
lbl(TitleBar, "🔪  MM2 Short", 15, T.Text, Enum.Font.GothamBold, Enum.TextXAlignment.Left, UDim2.new(0,14,0,0), UDim2.new(1,-100,1,0))
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 26, 0, 26)
closeBtn.Position = UDim2.new(1, -32, 0.5, -13)
closeBtn.BackgroundColor3 = T.Bad
closeBtn.BackgroundTransparency = 0.4
closeBtn.Text = "✕"
closeBtn.TextColor3 = T.Text
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 13
closeBtn.BorderSizePixel = 0
closeBtn.Parent = TitleBar
corner(closeBtn, 6)
closeBtn.MouseButton1Click:Connect(function() Main.Visible = false end)

do
    local dragging=false local dragStart=nil local startPos=nil
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true dragStart=input.Position startPos=Main.Position
            input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then dragging=false end end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then
            local delta=input.Position-dragStart
            local vs=Camera.ViewportSize
            local ax=math.clamp(startPos.X.Offset+delta.X, 0, vs.X-Main.AbsoluteSize.X)
            local ay=math.clamp(startPos.Y.Offset+delta.Y, 0, vs.Y-Main.AbsoluteSize.Y)
            Main.Position=UDim2.new(0,ax,0,ay)
        end
    end)
end

local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, 0, 0, 36)
TabBar.Position = UDim2.new(0, 0, 0, 40)
TabBar.BackgroundColor3 = Color3.fromRGB(14,14,17)
TabBar.BorderSizePixel = 0
TabBar.Parent = Main

local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, 0, 1, -76)
ContentArea.Position = UDim2.new(0, 0, 0, 76)
ContentArea.BackgroundTransparency = 1
ContentArea.ClipsDescendants = true
ContentArea.Parent = Main

local tabs = {}
local activeTab = nil
local function makeTab(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1/3, -2, 1, 0)
    btn.BackgroundColor3 = T.Surface
    btn.BackgroundTransparency = 1
    btn.Text = name
    btn.TextColor3 = T.Faint
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Parent = TabBar
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.CanvasSize = UDim2.new()
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = T.Accent
    scroll.Visible = false
    scroll.Parent = ContentArea
    local sl = Instance.new("UIListLayout") sl.Padding = UDim.new(0,6) sl.Parent = scroll
    local sp = Instance.new("UIPadding") sp.PaddingLeft = UDim.new(0,10) sp.PaddingRight = UDim.new(0,10) sp.PaddingTop = UDim.new(0,10) sp.PaddingBottom = UDim.new(0,10) sp.Parent = scroll
    local tab = {btn=btn, scroll=scroll}
    btn.MouseButton1Click:Connect(function()
        if activeTab then activeTab.scroll.Visible=false tw(activeTab.btn,{TextColor3=T.Faint,BackgroundTransparency=1}) end
        activeTab=tab scroll.Visible=true tw(btn,{TextColor3=T.Text,BackgroundTransparency=0.6})
    end)
    tabs[name]=tab
    if not activeTab then activeTab=tab scroll.Visible=true btn.TextColor3=T.Text btn.BackgroundTransparency=0.6 end
    return tab
end

local function makeSection(tab, title)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = T.Surface
    card.BorderSizePixel = 0
    card.Parent = tab.scroll
    corner(card, 8) stroke(card, T.Border, 1, 0.3)
    local cl = Instance.new("UIListLayout") cl.Padding = UDim.new(0,5) cl.Parent = card
    local cp = Instance.new("UIPadding") cp.PaddingLeft = UDim.new(0,10) cp.PaddingRight = UDim.new(0,10) cp.PaddingTop = UDim.new(0,8) cp.PaddingBottom = UDim.new(0,8) cp.Parent = card
    lbl(card, title:upper(), 11, T.Accent, Enum.Font.GothamBold, Enum.TextXAlignment.Left, UDim2.new(0,0,0,0), UDim2.new(1,0,0,18))
    return card
end

local function makeToggle(parent, name, desc, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, desc and 46 or 36)
    row.BackgroundColor3 = T.BG
    row.BorderSizePixel = 0
    row.Parent = parent
    corner(row, 6)
    lbl(row, name, 12, T.Text, Enum.Font.GothamMedium, Enum.TextXAlignment.Left, UDim2.new(0,10,0,desc and 5 or 0), UDim2.new(0.7,0,0,desc and 18 or 36))
    if desc then lbl(row, desc, 10, T.Faint, Enum.Font.Gotham, Enum.TextXAlignment.Left, UDim2.new(0,10,0,23), UDim2.new(0.7,0,0,14)) end
    local track = Instance.new("Frame")
    track.Size = UDim2.new(0, 40, 0, 20)
    track.Position = UDim2.new(1, -50, 0.5, -10)
    track.BackgroundColor3 = Color3.fromRGB(45,45,52)
    track.BorderSizePixel = 0
    track.Parent = row
    corner(track, 10)
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new(0, 3, 0.5, -7)
    knob.BackgroundColor3 = T.Dim
    knob.BorderSizePixel = 0
    knob.Parent = track
    corner(knob, 7)
    local on = false
    local h = {}
    function h:get() return on end
    function h:set(v, fire)
        on = v
        tw(track,{BackgroundColor3=on and T.Accent or Color3.fromRGB(45,45,52)})
        tw(knob,{Position=on and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7),BackgroundColor3=on and T.Text or T.Dim},0.2,Enum.EasingStyle.Back)
        if fire~=false then pcall(callback,on) end
    end
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,1,0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = row
    btn.MouseButton1Click:Connect(function() h:set(not on) end)
    return h
end

local function makeButton(parent, name, col, cb)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,0,32)
    btn.BackgroundColor3 = col or T.AccentDrk
    btn.Text = name
    btn.TextColor3 = T.Text
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Parent = parent
    corner(btn, 6) stroke(btn, col or T.Accent, 1, 0.5)
    btn.MouseEnter:Connect(function() tw(btn,{BackgroundColor3=T.Accent}) end)
    btn.MouseLeave:Connect(function() tw(btn,{BackgroundColor3=col or T.AccentDrk}) end)
    btn.MouseButton1Click:Connect(function() pcall(cb) end)
    return btn
end

local function makeInput(parent, placeholder)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1,0,0,30)
    box.BackgroundColor3 = T.BG
    box.BorderSizePixel = 0
    box.Text = ""
    box.PlaceholderText = placeholder
    box.PlaceholderColor3 = T.Faint
    box.TextColor3 = T.Text
    box.Font = Enum.Font.GothamMedium
    box.TextSize = 12
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.ClearTextOnFocus = false
    box.Parent = parent
    corner(box, 6) stroke(box, T.Border, 1, 0.5)
    local pad = Instance.new("UIPadding") pad.PaddingLeft = UDim.new(0,8) pad.Parent = box
    return box
end

local function makeLive(parent, text, initial, color)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,28)
    row.BackgroundColor3 = T.BG
    row.BorderSizePixel = 0
    row.Parent = parent
    corner(row, 6)
    lbl(row, text, 11, T.Dim, Enum.Font.Gotham, Enum.TextXAlignment.Left, UDim2.new(0,10,0,0), UDim2.new(0.5,0,1,0))
    local val = lbl(row, initial or "—", 11, color or T.Text, Enum.Font.GothamBold, Enum.TextXAlignment.Right, UDim2.new(0.5,0,0,0), UDim2.new(0.5,-10,1,0))
    return {set=function(txt,col) val.Text=tostring(txt) if col then val.TextColor3=col end end}
end

-- ══════════════════════════════════════════════════════════════
--  TABS
-- ══════════════════════════════════════════════════════════════
local tInfo = makeTab("Info")
local tESP  = makeTab("ESP")
local tFun  = makeTab("Fun")

-- INFO
local secRoles = makeSection(tInfo, "Role Info")
local lblMurd = makeLive(secRoles, "🔪 Murderer", "Detecting...", T.Murd)
local lblSher = makeLive(secRoles, "🔫 Sheriff", "Detecting...", T.Sher)
local lblMyRole = makeLive(secRoles, "👤 Your Role", "?", T.Text)

local secStats = makeSection(tInfo, "Stats")
local lblPlayers = makeLive(secStats, "Players", "0")
local lblAlive = makeLive(secStats, "Alive", "0", T.Good)
local lblDead = makeLive(secStats, "Dead", "0", T.Bad)
local lblFPS = makeLive(secStats, "FPS", "?")

local secActions = makeSection(tInfo, "Actions")
makeButton(secActions, "🧠 Clear Role Memory", Color3.fromRGB(50,30,60), function()
    clearRoleMemory()
    notify("Memory", "Role memory cleared")
end)

-- ESP
local secESP = makeSection(tESP, "ESP Settings")
local espMurd = makeToggle(secESP, "Murderer ESP", "Red highlight")
local espSher = makeToggle(secESP, "Sheriff ESP", "Yellow highlight")
local espInno = makeToggle(secESP, "Innocent ESP", "Blue highlight")
local espDead = makeToggle(secESP, "Dead ESP", "Show ghosts")
local espBox = makeToggle(secESP, "Box", "Draw box around players")
local espName = makeToggle(secESP, "Name", "Show player name")
local espRole = makeToggle(secESP, "Role Text", "Show role under name")

-- FUN
local secFling = makeSection(tFun, "Fling")
local flingInput = makeInput(secFling, "Player name...")
makeButton(secFling, "💥 Fling by Name", T.AccentDrk, function()
    local name = flingInput.Text
    if name == "" then notify("Fling", "Enter a name"); return end
    flingPlayer(name)
end)
makeButton(secFling, "💥 Fling Murderer", Color3.fromRGB(100,20,20), function()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and getPlayerRole(p) == "murderer" then
            flingPlayer(p.Name)
            return
        end
    end
    notify("Fling", "No murderer detected")
end)
makeButton(secFling, "💥 Fling Sheriff", Color3.fromRGB(100,70,0), function()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and getPlayerRole(p) == "sheriff" then
            flingPlayer(p.Name)
            return
        end
    end
    notify("Fling", "No sheriff detected")
end)

-- ══════════════════════════════════════════════════════════════
--  ESP (Highlight + BillboardGui, běží KAŽDÝ FRAME)
-- ══════════════════════════════════════════════════════════════
local espHighlights = {}
local espBillboards = {}

local function removeESP(name)
    if espHighlights[name] then pcall(function() espHighlights[name]:Destroy() end) espHighlights[name]=nil end
    if espBillboards[name] then pcall(function() espBillboards[name]:Destroy() end) espBillboards[name]=nil end
end

local function updateESP()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local role = getPlayerRole(p)
            local pHum = p.Character:FindFirstChildOfClass("Humanoid")
            local isDead = pHum and pHum.Health <= 0
            local show = (role=="murderer" and espMurd:get()) or (role=="sheriff" and espSher:get()) or (role=="innocent" and espInno:get()) or (isDead and espDead:get())
            local color = roleColor(role, isDead)

            if show then
                -- Highlight (box)
                if espBox:get() then
                    if not espHighlights[p.Name] or not espHighlights[p.Name].Parent then
                        local hl = Instance.new("Highlight")
                        hl.Name = "_mm2hl"
                        hl.FillColor = color
                        hl.FillTransparency = 0.6
                        hl.OutlineColor = color
                        hl.OutlineTransparency = 0
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.Parent = p.Character
                        espHighlights[p.Name] = hl
                    else
                        espHighlights[p.Name].FillColor = color
                        espHighlights[p.Name].OutlineColor = color
                    end
                else
                    if espHighlights[p.Name] then pcall(function() espHighlights[p.Name]:Destroy() end) espHighlights[p.Name]=nil end
                end

                -- Billboard (name + role)
                if espName:get() or espRole:get() then
                    local head = p.Character:FindFirstChild("Head")
                    if head then
                        if not espBillboards[p.Name] or not espBillboards[p.Name].Parent then
                            local bb = Instance.new("BillboardGui")
                            bb.Name = "_mm2bb"
                            bb.Size = UDim2.new(0, 120, 0, 32)
                            bb.StudsOffset = Vector3.new(0, 2, 0)
                            bb.AlwaysOnTop = true
                            bb.Parent = head
                            local txt = Instance.new("TextLabel")
                            txt.Size = UDim2.new(1, 0, 0, 16)
                            txt.Position = UDim2.new(0, 0, 0, 0)
                            txt.BackgroundTransparency = 1
                            txt.Font = Enum.Font.GothamBold
                            txt.TextSize = 11
                            txt.TextStrokeTransparency = 0
                            txt.TextXAlignment = Enum.TextXAlignment.Center
                            txt.Parent = bb
                            local rtxt = Instance.new("TextLabel")
                            rtxt.Size = UDim2.new(1, 0, 0, 14)
                            rtxt.Position = UDim2.new(0, 0, 0, 16)
                            rtxt.BackgroundTransparency = 1
                            rtxt.Font = Enum.Font.GothamMedium
                            rtxt.TextSize = 10
                            rtxt.TextStrokeTransparency = 0
                            rtxt.TextXAlignment = Enum.TextXAlignment.Center
                            rtxt.Parent = bb
                            espBillboards[p.Name] = {bb=bb, txt=txt, rtxt=rtxt}
                        end
                        local data = espBillboards[p.Name]
                        data.txt.Text = espName:get() and p.Name or ""
                        data.txt.TextColor3 = color
                        data.rtxt.Text = espRole:get() and roleText(role, isDead) or ""
                        data.rtxt.TextColor3 = color
                    end
                else
                    if espBillboards[p.Name] then pcall(function() espBillboards[p.Name].bb:Destroy() end) espBillboards[p.Name]=nil end
                end
            else
                removeESP(p.Name)
            end
        end
    end
end

-- ══════════════════════════════════════════════════════════════
--  CLEANUP
-- ══════════════════════════════════════════════════════════════
Players.PlayerRemoving:Connect(function(p)
    removeESP(p.Name)
    if roleMemory[p.Name] then roleMemory[p.Name]=nil end
end)
LP.CharacterAdded:Connect(function()
    task.wait(1)
    clearRoleMemory()
    for name in pairs(espHighlights) do removeESP(name) end
end)

-- ══════════════════════════════════════════════════════════════
--  KEYS
-- ══════════════════════════════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        Main.Visible = not Main.Visible
    elseif input.KeyCode == Enum.KeyCode.Delete then
        espMurd:set(false) espSher:set(false) espInno:set(false) espDead:set(false) espBox:set(false) espName:set(false) espRole:set(false)
        pcall(function() Lighting.Brightness = 1 end)
        notify("Panic", "All features disabled")
    elseif input.KeyCode == Enum.KeyCode.End then
        wmFrame.Visible = not wmFrame.Visible
    end
end)

-- ══════════════════════════════════════════════════════════════
--  MAIN LOOP
-- ══════════════════════════════════════════════════════════════
local fpsCount, fpsAccum = 0, 0
local heavyTimer = 0
local HEAVY_INTERVAL = 0.1

RunService.Heartbeat:Connect(function(dt)
    fpsCount = fpsCount + 1
    fpsAccum = fpsAccum + dt
    heavyTimer = heavyTimer + dt

    -- ESP každý frame (okamžitá reakce)
    pcall(updateESP)

    if fpsAccum >= 1 then
        local fps = math.floor(fpsCount / fpsAccum)
        pcall(function() lblFPS.set(fps .. " FPS") wmInfo.Text = fps .. " FPS" end)
        fpsCount = 0 fpsAccum = 0
    end

    if heavyTimer < HEAVY_INTERVAL then return end
    heavyTimer = 0

    local char = LP.Character
    if not char then return end

    -- Role labels
    local murderer, sheriff = nil, nil
    local alive, dead = 0, 0
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character then
            local h = p.Character:FindFirstChildOfClass("Humanoid")
            if h then
                if h.Health > 0 then alive = alive + 1 else dead = dead + 1 end
            end
            if p ~= LP then
                local r = getPlayerRole(p)
                if r == "murderer" then murderer = p.Name end
                if r == "sheriff" then sheriff = p.Name end
            end
        end
    end

    pcall(function()
        lblMurd.set(murderer or "Unknown", murderer and T.Murd or T.Faint)
        lblSher.set(sheriff or "Unknown", sheriff and T.Sher or T.Faint)
        lblMyRole.set(roleText(getPlayerRole(LP), false), roleColor(getPlayerRole(LP), false))
        lblPlayers.set(#Players:GetPlayers())
        lblAlive.set(alive, T.Good)
        lblDead.set(dead, T.Bad)
    end)
end)

_G.__MM2Short_Destroy = function()
    pcall(function() GUI:Destroy() end)
    pcall(function() WM:Destroy() end)
    for name in pairs(espHighlights) do removeESP(name) end
end

print("[MM2 Short] " .. BUILD .. " loaded")
