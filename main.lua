-- ══════════════════════════════════════════════════════════════
--  MM2 SHORT — PHASE 1K
--  INSERT = menu · DELETE = panic · END = watermark · E = aim
--  Nové: CRC role detect, Radar, Fake Weapons, Rainbow, Trail,
--        Spin, FOV/Fog/Monochrome/Transparency, Weapon color
--        pickery, Kill Aura (Murd), Teleport Kill All (Murd),
--        Aim Assist (RMB), Coin collect
-- ══════════════════════════════════════════════════════════════
local BUILD = "PHASE-1K"

pcall(function() if _G.__MM2Short_Destroy then _G.__MM2Short_Destroy() end end)

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Workspace        = game:GetService("Workspace")
local Lighting         = game:GetService("Lighting")
local StarterGui       = game:GetService("StarterGui")
local VirtualUser      = game:GetService("VirtualUser")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local Camera           = Workspace.CurrentCamera
local LP               = Players.LocalPlayer

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
    Sher    = Color3.fromRGB(80,160,255),
    Inno    = Color3.fromRGB(72,199,116),
    Hero    = Color3.fromRGB(255,200,50),
    Gun     = Color3.fromRGB(0,120,255),
    Knife   = Color3.fromRGB(255,30,30),
    None    = Color3.fromRGB(0,220,80),
}

-- HELPERS
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
for _,n in ipairs({"MM2Short","MM2ShortVis","MM2ShortWM","MM2GunDrop","MM2Radar"}) do clearOld(n) end

local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = 3})
    end)
    print("[" .. title .. "] " .. text)
end

-- WATERMARK
local WM=mount(Instance.new("ScreenGui"))
WM.Name="MM2ShortWM" WM.ResetOnSpawn=false WM.DisplayOrder=996
local wmFrame=Instance.new("Frame") wmFrame.Size=UDim2.new(0,220,0,30) wmFrame.Position=UDim2.new(0,10,0,10)
wmFrame.BackgroundColor3=T.Surface wmFrame.BackgroundTransparency=0.1 wmFrame.BorderSizePixel=0 wmFrame.Parent=WM
corner(wmFrame,6) stroke(wmFrame,T.Accent,1,0.3)
lbl(wmFrame,"🔪 MM2 Short 1K",12,T.Text,Enum.Font.GothamBold,Enum.TextXAlignment.Left,UDim2.new(0,10,0,0),UDim2.new(0.6,0,1,0))
local wmInfo=lbl(wmFrame,"",10,T.Hero,Enum.Font.GothamBold,Enum.TextXAlignment.Right,UDim2.new(0.6,0,0,0),UDim2.new(0.4,-10,1,0))

-- CRC (CurrentRoundClient) ROLE DETECTION
local CRC = nil
pcall(function()
    local mod = ReplicatedStorage:FindFirstChild("Modules")
    if mod then
        local crc = mod:FindFirstChild("CurrentRoundClient")
        if crc then CRC = require(crc) end
    end
end)

local roleMemory = {}
local function clearRoleMemory() roleMemory = {} end
local function checkToolName(tn)
    if not tn then return nil end
    tn = tn:lower()
    if tn:find("knife") or tn:find("blade") or tn:find("machete") or tn:find("dagger") then return "murderer" end
    if tn:find("gun") or tn:find("revolver") or tn:find("pistol") then return "sheriff" end
    if tn:find("hero") or tn:find("hack") then return "hero" end
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
    -- 1) CRC - nejpřesnější
    if CRC and CRC.PlayerData then
        local ok, data = pcall(function() return CRC.PlayerData[player.Name] end)
        if ok and data and data.Role then
            local r = tostring(data.Role):lower()
            if r:find("murder") then return "murderer" end
            if r:find("sheriff") then return "sheriff" end
            if r:find("hero") then return "hero" end
            if r:find("innoc") then return "innocent" end
        end
    end
    -- 2) Atributy
    local ok, attr = pcall(function() return player:GetAttribute("Role") end)
    if ok and type(attr) == "string" then
        local a = attr:lower()
        if a:find("murder") then return "murderer" end
        if a:find("sheriff") then return "sheriff" end
        if a:find("hero") then return "hero" end
        if a:find("innoc") then return "innocent" end
    end
    -- 3) Paměť
    local pname = player.Name
    if roleMemory[pname] then return roleMemory[pname] end
    -- 4) Tool scan
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
    end
    if p.Character then hookCharacter(p.Character) end
    p.CharacterAdded:Connect(hookCharacter)
end
for _,p in pairs(Players:GetPlayers()) do pcall(watchPlayer, p) end
Players.PlayerAdded:Connect(function(p) pcall(watchPlayer, p) end)

local function roleColor(role, isDead)
    if isDead then return T.Faint end
    if role=="murderer" then return T.Murd end
    if role=="sheriff"  then return T.Sher end
    if role=="hero"     then return T.Hero end
    return T.Inno
end
local function roleText(role, isDead)
    if isDead then return "DEAD" end
    if role=="murderer" then return "MURDERER" end
    if role=="sheriff"  then return "SHERIFF" end
    if role=="hero"     then return "HERO" end
    return "INNOCENT"
end
local function getWeaponType(p)
    if not p or p == LP then return "None" end
    local function scan(container)
        if not container then return nil end
        for _, item in ipairs(container:GetChildren()) do
            if item:IsA("Tool") then
                local n = item.Name:lower()
                if n:find("gun") or n:find("revolver") or n:find("pistol") then return "Gun" end
                if n:find("knife") or n:find("blade") then return "Knife" end
            end
        end
        return nil
    end
    return scan(p.Character) or scan(p:FindFirstChild("Backpack")) or "None"
end

-- SKIDFLING + BAYBLADE
local FlingActive = false
local FlingOldPos = nil
local FlingFPDH = Workspace.FallenPartsDestroyHeight
local BaybladeActive = false

local function SkidFling(TargetPlayer, offset)
    local Character = LP.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart
    local TCharacter = TargetPlayer.Character
    if not TCharacter then return end
    local THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
    local TRootPart = THumanoid and THumanoid.RootPart
    local THead = TCharacter:FindFirstChild("Head")
    local Accessory = TCharacter:FindFirstChildOfClass("Accessory")
    local Handle = Accessory and Accessory:FindFirstChild("Handle")
    if not (Character and Humanoid and RootPart) then return end
    if RootPart.Velocity.Magnitude < 50 then FlingOldPos = RootPart.CFrame end
    if THumanoid and THumanoid.Sit then return end
    if THead then Workspace.CurrentCamera.CameraSubject = THead
    elseif Handle then Workspace.CurrentCamera.CameraSubject = Handle
    elseif THumanoid and TRootPart then Workspace.CurrentCamera.CameraSubject = THumanoid end
    if not TCharacter:FindFirstChildWhichIsA("BasePart") then return end
    offset = offset or 0
    local FPos = function(BasePart, Pos, Ang)
        RootPart.CFrame = CFrame.new(BasePart.Position) * CFrame.new(0, 0, -offset) * Pos * Ang
        Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * CFrame.new(0, 0, -offset) * Pos * Ang)
        RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
        RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
    end
    local SFBasePart = function(BasePart)
        local TimeToWait = 2
        local Time = tick()
        local Angle = 0
        repeat
            if RootPart and THumanoid then
                if BasePart.Velocity.Magnitude < 50 then
                    Angle = Angle + 100
                    FPos(BasePart, CFrame.new(0, 1.5, 0), CFrame.Angles(math.rad(Angle), 0, 0)) task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(Angle), 0, 0)) task.wait()
                    FPos(BasePart, CFrame.new(0, 1.5, 0), CFrame.Angles(math.rad(Angle), 0, 0)) task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(Angle), 0, 0)) task.wait()
                else
                    FPos(BasePart, CFrame.new(0, 1.5, 0), CFrame.Angles(math.rad(90), 0, 0)) task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0)) task.wait()
                    FPos(BasePart, CFrame.new(0, 1.5, 0), CFrame.Angles(math.rad(90), 0, 0)) task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0)) task.wait()
                end
            end
        until Time + TimeToWait < tick() or not FlingActive
    end
    Workspace.FallenPartsDestroyHeight = 0/0
    local BV = Instance.new("BodyVelocity") BV.Parent = RootPart
    BV.Velocity = Vector3.new(0, 0, 0) BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
    if TRootPart then SFBasePart(TRootPart)
    elseif THead then SFBasePart(THead)
    elseif Handle then SFBasePart(Handle) end
    BV:Destroy()
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    Workspace.CurrentCamera.CameraSubject = Humanoid
    if FlingOldPos then
        repeat
            RootPart.CFrame = FlingOldPos * CFrame.new(0, .5, 0)
            Character:SetPrimaryPartCFrame(FlingOldPos * CFrame.new(0, .5, 0))
            Humanoid:ChangeState("GettingUp")
            for _, part in pairs(Character:GetChildren()) do
                if part:IsA("BasePart") then part.Velocity, part.RotVelocity = Vector3.new(), Vector3.new() end
            end
            task.wait()
        until (RootPart.Position - FlingOldPos.p).Magnitude < 25
        Workspace.FallenPartsDestroyHeight = FlingFPDH
    end
end

local function flingPlayer(targetName)
    local target = Players:FindFirstChild(targetName)
    if not target or not target.Character then notify("Fling", "Player not found"); return false end
    if FlingActive then notify("Fling", "Already flinging"); return false end
    FlingActive = true
    notify("Fling", "Flinging " .. target.Name .. "...")
    task.spawn(function()
        pcall(SkidFling, target, 0)
        FlingActive = false
        notify("Fling", "Done")
    end)
    return true
end

local function baybladePlayer(targetName)
    local target = Players:FindFirstChild(targetName)
    if not target or not target.Character then notify("Bayblade", "Player not found"); return false end
    if BaybladeActive then notify("Bayblade", "Already active"); return false end
    BaybladeActive = true
    notify("Bayblade", "Started on " .. target.Name)
    task.spawn(function()
        local Timeout = tick() + 10
        while BaybladeActive and tick() < Timeout do
            if not target.Character then break end
            local trp = target.Character:FindFirstChild("HumanoidRootPart")
            local myChar = LP.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if trp and myRoot then
                local behind = trp.CFrame * CFrame.new(0, 0, -1)
                pcall(function()
                    myRoot.CFrame = behind
                    myRoot.AssemblyAngularVelocity = Vector3.new(9e8, 9e8, 9e8)
                    myRoot.AssemblyLinearVelocity = Vector3.new(9e7, 9e7, 9e7)
                end)
                local tv = trp.AssemblyLinearVelocity
                if tv.Magnitude > 200 then break end
            else break end
            task.wait()
        end
        BaybladeActive = false
        pcall(function()
            local myChar = LP.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if myRoot and FlingOldPos then myRoot.CFrame = FlingOldPos end
            Workspace.FallenPartsDestroyHeight = FlingFPDH
        end)
        notify("Bayblade", "Done")
    end)
    return true
end

-- UI
local GUI = mount(Instance.new("ScreenGui"))
GUI.Name = "MM2Short" GUI.ResetOnSpawn = false GUI.DisplayOrder = 999

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 380, 0, 540)
Main.Position = UDim2.new(0.5, -190, 0.5, -270)
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
lbl(TitleBar, "🔪  MM2 Short 1K", 15, T.Text, Enum.Font.GothamBold, Enum.TextXAlignment.Left, UDim2.new(0,14,0,0), UDim2.new(1,-100,1,0))
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
closeBtn.Active = true
closeBtn.Parent = TitleBar
corner(closeBtn, 6)
closeBtn.Activated:Connect(function() Main.Visible = false end)

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

-- TAB BAR (7 tabů)
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, 0, 0, 36)
TabBar.Position = UDim2.new(0, 0, 0, 40)
TabBar.BackgroundColor3 = Color3.fromRGB(14,14,17)
TabBar.BorderSizePixel = 0
TabBar.ZIndex = 1
TabBar.Parent = Main
local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
TabLayout.Padding = UDim.new(0, 2)
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Parent = TabBar

local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, 0, 1, -76)
ContentArea.Position = UDim2.new(0, 0, 0, 76)
ContentArea.BackgroundTransparency = 1
ContentArea.ClipsDescendants = true
ContentArea.ZIndex = 2
ContentArea.Parent = Main

local tabs = {}
local activeTab = nil
local function switchTab(tab)
    if activeTab then
        activeTab.scroll.Visible = false
        activeTab.btn.TextColor3 = T.Faint
        activeTab.btn.BackgroundTransparency = 1
    end
    activeTab = tab
    tab.scroll.Visible = true
    tab.btn.TextColor3 = T.Text
    tab.btn.BackgroundTransparency = 0.6
end
local tabOrder = 0
local TAB_COUNT = 7
local function makeTab(name)
    tabOrder = tabOrder + 1
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1/TAB_COUNT, -3, 1, -4)
    btn.BackgroundColor3 = T.Surface
    btn.BackgroundTransparency = 1
    btn.Text = name
    btn.TextColor3 = T.Faint
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 10
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Active = true
    btn.LayoutOrder = tabOrder
    btn.Parent = TabBar
    corner(btn, 4)
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.CanvasSize = UDim2.new()
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = T.Accent
    scroll.Visible = false
    scroll.ZIndex = 2
    scroll.Parent = ContentArea
    local sl = Instance.new("UIListLayout") sl.Padding = UDim.new(0,6) sl.Parent = scroll
    local sp = Instance.new("UIPadding") sp.PaddingLeft = UDim.new(0,10) sp.PaddingRight = UDim.new(0,10) sp.PaddingTop = UDim.new(0,10) sp.PaddingBottom = UDim.new(0,10) sp.Parent = scroll
    local tab = {btn=btn, scroll=scroll}
    btn.Activated:Connect(function() switchTab(tab) end)
    tabs[name]=tab
    if not activeTab then switchTab(tab) end
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
    btn.Active = true
    btn.ZIndex = 10
    btn.Parent = row
    btn.Activated:Connect(function() h:set(not on) end)
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
    btn.Active = true
    btn.Parent = parent
    corner(btn, 6) stroke(btn, col or T.Accent, 1, 0.5)
    btn.MouseEnter:Connect(function() tw(btn,{BackgroundColor3=T.Accent}) end)
    btn.MouseLeave:Connect(function() tw(btn,{BackgroundColor3=col or T.AccentDrk}) end)
    btn.Activated:Connect(function() pcall(cb) end)
    return btn
end

local function makeTextBox(parent, placeholder)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1,0,0,28)
    box.BackgroundColor3 = T.BG
    box.TextColor3 = T.Text
    box.PlaceholderText = placeholder or ""
    box.PlaceholderColor3 = T.Faint
    box.Text = ""
    box.Font = Enum.Font.Gotham
    box.TextSize = 11
    box.BorderSizePixel = 0
    box.ClearTextOnFocus = false
    box.Parent = parent
    corner(box, 6) stroke(box, T.Border, 1, 0.5)
    return box
end

local function makeSlider(parent, name, min, max, default, suffix, cb)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,46)
    row.BackgroundColor3 = T.BG
    row.BorderSizePixel = 0
    row.Parent = parent
    corner(row, 6)
    lbl(row, name, 11, T.Text, Enum.Font.GothamMedium, Enum.TextXAlignment.Left, UDim2.new(0,10,0,4), UDim2.new(0.6,0,0,16))
    local vl = lbl(row, tostring(default)..(suffix or ""), 11, T.Accent, Enum.Font.GothamBold, Enum.TextXAlignment.Right, UDim2.new(0.6,0,0,4), UDim2.new(0.4,-10,0,16))
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1,-20,0,6)
    track.Position = UDim2.new(0,10,0,30)
    track.BackgroundColor3 = Color3.fromRGB(35,35,42)
    track.BorderSizePixel = 0
    track.Parent = row
    corner(track, 3)
    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = T.Accent
    fill.BorderSizePixel = 0
    fill.Size = UDim2.new((default-min)/(max-min),0,1,0)
    fill.Parent = track
    corner(fill, 3)
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0,12,0,12)
    knob.AnchorPoint = Vector2.new(0.5,0.5)
    knob.Position = UDim2.new((default-min)/(max-min),0,0.5,0)
    knob.BackgroundColor3 = T.Text
    knob.BorderSizePixel = 0
    knob.ZIndex = 3
    knob.Parent = track
    corner(knob, 6)
    local value = default
    local grabbing = false
    local function setFromX(x)
        local alpha = math.clamp((x-track.AbsolutePosition.X)/math.max(track.AbsoluteSize.X,1),0,1)
        value = math.floor(min+(max-min)*alpha+0.5)
        vl.Text = tostring(value)..(suffix or "")
        tw(fill,{Size=UDim2.new(alpha,0,1,0)},0.08)
        tw(knob,{Position=UDim2.new(alpha,0,0.5,0)},0.08)
        pcall(cb, value)
    end
    local hit = Instance.new("TextButton")
    hit.Size = UDim2.new(1,0,0,24)
    hit.Position = UDim2.new(0,0,0,22)
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.Active = true
    hit.ZIndex = 10
    hit.Parent = row
    hit.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            grabbing = true; setFromX(i.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if grabbing and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            setFromX(i.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then grabbing = false end
    end)
    return {get=function() return value end, set=function(v) value=math.clamp(v,min,max) local a=(value-min)/(max-min) vl.Text=tostring(value)..(suffix or "") fill.Size=UDim2.new(a,0,1,0) knob.Position=UDim2.new(a,0,0.5,0) end}
end

local function makeLive(parent, text, initial, color)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,26)
    row.BackgroundColor3 = T.BG
    row.BorderSizePixel = 0
    row.Parent = parent
    corner(row, 6)
    lbl(row, text, 11, T.Dim, Enum.Font.Gotham, Enum.TextXAlignment.Left, UDim2.new(0,10,0,0), UDim2.new(0.5,0,1,0))
    local val = lbl(row, initial or "—", 11, color or T.Text, Enum.Font.GothamBold, Enum.TextXAlignment.Right, UDim2.new(0.5,0,0,0), UDim2.new(0.5,-10,1,0))
    return {set=function(txt,col) val.Text=tostring(txt) if col then val.TextColor3=col end end}
end

local function makeColorPicker(parent, name, default, cb)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,32)
    row.BackgroundColor3 = T.BG
    row.BorderSizePixel = 0
    row.Parent = parent
    corner(row, 6)
    lbl(row, name, 11, T.Text, Enum.Font.GothamMedium, Enum.TextXAlignment.Left, UDim2.new(0,10,0,0), UDim2.new(0.6,0,1,0))
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0,50,0,20)
    btn.Position = UDim2.new(1,-60,0.5,-10)
    btn.BackgroundColor3 = default
    btn.Text = ""
    btn.BorderSizePixel = 0
    btn.Active = true
    btn.Parent = row
    corner(btn, 4) stroke(btn, T.Border, 1)
    local palette = {
        Color3.fromRGB(255,60,60), Color3.fromRGB(80,160,255), Color3.fromRGB(72,199,116),
        Color3.fromRGB(255,200,50), Color3.fromRGB(180,50,255), Color3.fromRGB(255,150,0),
        Color3.fromRGB(0,240,255), Color3.fromRGB(255,255,255), Color3.fromRGB(30,30,40),
    }
    local idx = 1
    btn.Activated:Connect(function()
        idx = idx % #palette + 1
        btn.BackgroundColor3 = palette[idx]
        pcall(cb, palette[idx])
    end)
    return {get=function() return btn.BackgroundColor3 end}
end

-- TABS
local tInfo = makeTab("Info")
local tESP  = makeTab("ESP")
local tAim  = makeTab("Aim")
local tMove = makeTab("Move")
local tTP   = makeTab("TP")
local tFun  = makeTab("Fun")
local tFarm = makeTab("Farm")

-- INFO
local secRoles = makeSection(tInfo, "Role Info")
local lblMurd = makeLive(secRoles, "🔪 Murderer", "Detecting...", T.Murd)
local lblSher = makeLive(secRoles, "🔫 Sheriff", "Detecting...", T.Sher)
local lblHero = makeLive(secRoles, "🦸 Hero", "Detecting...", T.Hero)
local lblMyRole = makeLive(secRoles, "👤 Your Role", "?", T.Text)
local secStats = makeSection(tInfo, "Stats")
local lblPlayers = makeLive(secStats, "Players", "0")
local lblAlive = makeLive(secStats, "Alive", "0", T.Good)
local lblDead = makeLive(secStats, "Dead", "0", T.Bad)
local lblFPS = makeLive(secStats, "FPS", "?")

-- RADAR sekce (v Info)
local secRadar = makeSection(tInfo, "Radar")
local radarToggle = makeToggle(secRadar, "Show Radar", "Bottom-right minimap")
local radarRange = makeSlider(secRadar, "Range", 50, 400, 150, " studs", function() end)

-- Radar GUI
local RadarGui = mount(Instance.new("ScreenGui"))
RadarGui.Name = "MM2Radar" RadarGui.ResetOnSpawn = false RadarGui.DisplayOrder = 997
local RadarFrame = Instance.new("Frame")
RadarFrame.Size = UDim2.new(0,180,0,180)
RadarFrame.Position = UDim2.new(1,-190,1,-190)
RadarFrame.BackgroundColor3 = Color3.fromRGB(10,10,13)
RadarFrame.BackgroundTransparency = 0.15
RadarFrame.BorderSizePixel = 0
RadarFrame.Visible = false
RadarFrame.Parent = RadarGui
corner(RadarFrame,90) stroke(RadarFrame,T.Accent,2,0.1)
lbl(RadarFrame,"📡 RADAR",11,T.Accent,Enum.Font.GothamBold,Enum.TextXAlignment.Center,UDim2.new(0,0,0,-24),UDim2.new(1,0,0,20))
-- Kříž
do
    local h=Instance.new("Frame") h.Size=UDim2.new(1,0,0,1) h.Position=UDim2.new(0,0,0.5,0) h.BackgroundColor3=Color3.fromRGB(35,35,45) h.BackgroundTransparency=0.3 h.BorderSizePixel=0 h.Parent=RadarFrame
    local v=Instance.new("Frame") v.Size=UDim2.new(0,1,1,0) v.Position=UDim2.new(0.5,0,0,0) v.BackgroundColor3=Color3.fromRGB(35,35,45) v.BackgroundTransparency=0.3 v.BorderSizePixel=0 v.Parent=RadarFrame
    local ring=Instance.new("Frame") ring.Size=UDim2.new(0,90,0,90) ring.AnchorPoint=Vector2.new(0.5,0.5) ring.Position=UDim2.new(0.5,0,0.5,0) ring.BackgroundTransparency=1 ring.Parent=RadarFrame corner(ring,45) stroke(ring,Color3.fromRGB(35,35,45),1,0.4)
end
local RadarCenter = Instance.new("Frame")
RadarCenter.Size = UDim2.new(0,8,0,8) RadarCenter.AnchorPoint=Vector2.new(0.5,0.5) RadarCenter.Position=UDim2.new(0.5,0,0.5,0)
RadarCenter.BackgroundColor3 = T.Good RadarCenter.BorderSizePixel = 0 RadarCenter.ZIndex=3 RadarCenter.Parent=RadarFrame
corner(RadarCenter,4) stroke(RadarCenter,T.Text,1)
local radarDots = {}
local function getRadarDot(name)
    if not radarDots[name] then
        local dot = Instance.new("Frame") dot.Size=UDim2.new(0,9,0,9) dot.AnchorPoint=Vector2.new(0.5,0.5) dot.BorderSizePixel=0 dot.ZIndex=2 dot.Parent=RadarFrame
        corner(dot,5) stroke(dot,Color3.fromRGB(0,0,0),1,0.3)
        radarDots[name] = dot
    end
    return radarDots[name]
end
local function worldToRadar(wp)
    local mc = LP.Character
    local mr = mc and mc:FindFirstChild("HumanoidRootPart")
    if not mr then return nil end
    local diff = wp - mr.Position
    local x = diff:Dot(mr.CFrame.RightVector)
    local z = diff:Dot(mr.CFrame.LookVector)
    local range = radarRange.get()
    return math.clamp(x/range,-1,1)*0.45+0.5, math.clamp(-z/range,-1,1)*0.45+0.5
end

-- ESP
local secESP = makeSection(tESP, "Role ESP")
local espMurd = makeToggle(secESP, "Murderer ESP", "Red highlight")
local espSher = makeToggle(secESP, "Sheriff ESP", "Blue highlight")
local espHero = makeToggle(secESP, "Hero ESP", "Yellow highlight")
local espInno = makeToggle(secESP, "Innocent ESP", "Green highlight")
local espDead = makeToggle(secESP, "Dead ESP", "Show ghosts")
local espBox = makeToggle(secESP, "Box", "Draw box around players")
local espName = makeToggle(secESP, "Name", "Show player name")
local espRole = makeToggle(secESP, "Role Text", "Show role under name")

local secXray = makeSection(tESP, "X-Ray")
local savedLighting = nil
local xrayEnabled = makeToggle(secXray, "X-Ray (Light)", "Brighten world", function(on)
    if on then
        savedLighting = {Amb = Lighting.Ambient, Out = Lighting.OutdoorAmbient, Br = Lighting.Brightness}
        Lighting.Ambient = Color3.fromRGB(200,200,200)
        Lighting.OutdoorAmbient = Color3.fromRGB(200,200,200)
        Lighting.Brightness = 3
    else
        if savedLighting then
            Lighting.Ambient = savedLighting.Amb
            Lighting.OutdoorAmbient = savedLighting.Out
            Lighting.Brightness = savedLighting.Br
            savedLighting = nil
        end
    end
end)
local xrayPartsEnabled = makeToggle(secXray, "X-Ray (Parts)", "Transparent walls", function(on)
    if on then
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") then
                local anc = v:FindFirstAncestorOfClass("Model")
                local isChar = false
                while anc do
                    if anc:FindFirstChildOfClass("Humanoid") then isChar = true break end
                    anc = anc:FindFirstAncestorOfClass("Model")
                end
                if not isChar then v.LocalTransparencyModifier = 0.75 end
            end
        end
    else
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") then v.LocalTransparencyModifier = 0 end
        end
    end
end)

local secWeaponESP = makeSection(tESP, "Weapon ESP")
local espGun = makeToggle(secWeaponESP, "Show Gun", "Blue")
local espKnife = makeToggle(secWeaponESP, "Show Knife", "Red")
local espNone = makeToggle(secWeaponESP, "Show No Weapon", "Green")
local gunColorVal = T.Gun
local knifeColorVal = T.Knife
local noneColorVal = T.None
makeColorPicker(secWeaponESP, "Gun Color", T.Gun, function(c) gunColorVal = c end)
makeColorPicker(secWeaponESP, "Knife Color", T.Knife, function(c) knifeColorVal = c end)
makeColorPicker(secWeaponESP, "No Weapon Color", T.None, function(c) noneColorVal = c end)

local secGunDrop = makeSection(tESP, "GunDrop ESP")
local gunDropEnabled = makeToggle(secGunDrop, "Enable GunDrop ESP", "Highlight dropped gun")
local autoGrab = makeToggle(secGunDrop, "Auto Grab GunDrop", "TP + pick + return")

-- VISUALS (v ESP tabu)
local secVisuals = makeSection(tESP, "Camera / Visuals")
makeSlider(secVisuals, "Camera FOV", 1, 120, 70, "", function(v)
    if Camera then Camera.FieldOfView = v end
end)
local fogEnabled = false
local fogEndVal = 500
local fogColorVal = Color3.fromRGB(140,60,200)
local fogToggle = makeToggle(secVisuals, "Custom Fog", "Change fog color/distance", function(on)
    fogEnabled = on
    if on then
        Lighting.FogEnd = fogEndVal
        Lighting.FogStart = 0
        Lighting.FogColor = fogColorVal
        Lighting.Brightness = 0.8
    else
        Lighting.FogEnd = 1000
        Lighting.FogStart = 0
        Lighting.FogColor = Color3.fromRGB(255,255,255)
        Lighting.Brightness = 1
    end
end)
makeSlider(secVisuals, "Fog Distance", 100, 2000, 500, "", function(v)
    fogEndVal = v
    if fogEnabled then Lighting.FogEnd = v end
end)
makeColorPicker(secVisuals, "Fog Color", Color3.fromRGB(140,60,200), function(c)
    fogColorVal = c
    if fogEnabled then Lighting.FogColor = c end
end)

local monoEnabled = false
local monoData = {}
local monoListener = nil
local function applyMono(p)
    if not p:IsA("BasePart") then return end
    local m = p:FindFirstAncestorOfClass("Model")
    if m and Players:GetPlayerFromCharacter(m) then return end
    if not monoData[p] then monoData[p] = {Color = p.Color, Material = p.Material} end
    local g = (p.Color.R + p.Color.G + p.Color.B) / 3
    local d = g * 0.25
    p.Color = Color3.new(d,d,d)
    p.Material = Enum.Material.Plastic
end
local monoToggle = makeToggle(secVisuals, "Monochrome", "Dark gray map", function(on)
    monoEnabled = on
    if on then
        for _, obj in ipairs(Workspace:GetDescendants()) do applyMono(obj) end
        if monoListener then monoListener:Disconnect() end
        monoListener = Workspace.DescendantAdded:Connect(function(obj)
            if monoEnabled then applyMono(obj) end
        end)
    else
        if monoListener then monoListener:Disconnect() monoListener=nil end
        for part, data in pairs(monoData) do
            if part and part.Parent then part.Color = data.Color part.Material = data.Material end
        end
        monoData = {}
    end
end)

local transEnabled = false
local selfTransVal = 0.5
local otherTransVal = 0.8
local transToggle = makeToggle(secVisuals, "Transparency", "See through players", function(on)
    transEnabled = on
    for _, p in pairs(Players:GetPlayers()) do
        local c = p.Character
        if c then
            local t = (p == LP) and selfTransVal or otherTransVal
            for _, part in ipairs(c:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.Transparency = on and t or 0
                end
            end
        end
    end
end)
makeSlider(secVisuals, "Self Transparency %", 0, 100, 50, "%", function(v)
    selfTransVal = v/100
    if transEnabled and LP.Character then
        for _, part in ipairs(LP.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then part.Transparency = selfTransVal end
        end
    end
end)
makeSlider(secVisuals, "Others Transparency %", 0, 100, 80, "%", function(v)
    otherTransVal = v/100
    if transEnabled then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                for _, part in ipairs(p.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then part.Transparency = otherTransVal end
                end
            end
        end
    end
end)

-- AIM
local secAim = makeSection(tAim, "Aimbot")
local aimEnabled = makeToggle(secAim, "Enable Aimbot", "Press E to toggle")
local aimSmooth = makeSlider(secAim, "Smoothness", 1, 20, 8, "x", function() end)
local aimFOV = makeSlider(secAim, "FOV", 20, 400, 120, "px", function() end)
local aimTargetMode = "murderer"
makeButton(secAim, "🎯 Target: MURDERER", Color3.fromRGB(100,20,20), function()
    aimTargetMode = "murderer"; notify("Aim", "Target: Murderer")
end)
makeButton(secAim, "🎯 Target: SHERIFF", Color3.fromRGB(30,60,120), function()
    aimTargetMode = "sheriff"; notify("Aim", "Target: Sheriff")
end)
makeButton(secAim, "🎯 Target: HERO", Color3.fromRGB(120,90,0), function()
    aimTargetMode = "hero"; notify("Aim", "Target: Hero")
end)

-- Aim Assist (RMB) - jemnější verze
local secAimAssist = makeSection(tAim, "Aim Assist (RMB)")
local aimAssistEnabled = makeToggle(secAimAssist, "Enable Aim Assist", "Hold RMB to track")
local aimAssistTarget = "murderer"
local aaTargetBtn = makeButton(secAimAssist, "🎯 AA Target: MURDERER", Color3.fromRGB(80,20,20), function()
    aimAssistTarget = (aimAssistTarget == "murderer") and "sheriff" or "murderer"
    aaTargetBtn.Text = "🎯 AA Target: " .. aimAssistTarget:upper()
    notify("Aim Assist", "Target: " .. aimAssistTarget)
end)
local aaSmooth = makeSlider(secAimAssist, "AA Smoothness %", 1, 50, 20, "%", function() end)

local secAimPlayer = makeSection(tAim, "Aim at Player")
local aimPlayerBox = makeTextBox(secAimPlayer, "Player name...")
makeButton(secAimPlayer, "🎯 Aim at Player", Color3.fromRGB(60,60,120), function()
    local name = aimPlayerBox.Text
    local tgt = Players:FindFirstChild(name)
    if not tgt or not tgt.Character then notify("Aim", "Not found"); return end
    local hrp = tgt.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local cam = Workspace.CurrentCamera
    cam.CFrame = CFrame.lookAt(cam.CFrame.Position, hrp.Position)
end)

-- MOVE
local secMove = makeSection(tMove, "Movement")
makeSlider(secMove, "Gravity", 0, 500, 196, "", function(v) Workspace.Gravity = v end)
local speedVal = makeSlider(secMove, "Walk Speed", 0, 200, 16, " sp", function(v)
    local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed = v end
end)
makeSlider(secMove, "Jump Power", 0, 300, 50, "", function(v)
    local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if h then h.UseJumpPower = true h.JumpPower = v end
end)
local boostOnJump = makeToggle(secMove, "Boost on Jump", "75 speed when jumping")

local secExtraMove = makeSection(tMove, "Extra Movement")
local noclipEnabled = false
local infJumpEnabled = false
local noclipToggle = makeToggle(secExtraMove, "Noclip", "Walk through walls [C]", function(on)
    noclipEnabled = on
end)
local infJumpToggle = makeToggle(secExtraMove, "Infinite Jump", "Jump while in air [V]", function(on)
    infJumpEnabled = on
end)

-- FLY
local flyEnabled
local flySpeed = makeSlider(secMove, "Fly Speed", 10, 300, 80, " sp", function() end)
local flyConn = nil
local flyBV = nil
local function startFly()
    if flyConn then return end
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(9e9,9e9,9e9)
    flyBV.Velocity = Vector3.zero
    flyBV.Parent = hrp
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = true end
    flyConn = RunService.RenderStepped:Connect(function()
        if not flyEnabled or not flyEnabled:get() then return end
        local c = LP.Character
        local root = c and c:FindFirstChild("HumanoidRootPart")
        local cam = Workspace.CurrentCamera
        if not root or not flyBV then return end
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0,1,0) end
        if dir.Magnitude > 0 then dir = dir.Unit end
        flyBV.Velocity = dir * flySpeed.get()
    end)
end
local function stopFly()
    if flyConn then flyConn:Disconnect() flyConn = nil end
    if flyBV then flyBV:Destroy() flyBV = nil end
    local c = LP.Character
    local hum = c and c:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = false end
end
flyEnabled = makeToggle(secMove, "Fly", "WASD + Space/Ctrl", function(on)
    if on then startFly() else stopFly() end
end)

-- TELEPORT
local function tpToPlayer(p)
    if not p or not p.Character then notify("TP", "Player not in game"); return end
    local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local tr = p.Character:FindFirstChild("HumanoidRootPart")
    if myRoot and tr then
        myRoot.CFrame = tr.CFrame + Vector3.new(0, 3, 0)
        notify("TP", "To " .. p.Name)
    end
end
local function tpToRole(role)
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and getPlayerRole(p) == role then
            tpToPlayer(p) return
        end
    end
    notify("TP", "No " .. role)
end

local secTPPlayers = makeSection(tTP, "Teleport to Role")
makeButton(secTPPlayers, "🔪 TP to Murderer", Color3.fromRGB(100,20,20), function() tpToRole("murderer") end)
makeButton(secTPPlayers, "🔫 TP to Sheriff", Color3.fromRGB(30,60,120), function() tpToRole("sheriff") end)
makeButton(secTPPlayers, "🦸 TP to Hero", Color3.fromRGB(120,90,0), function() tpToRole("hero") end)

local secTPMap = makeSection(tTP, "Teleport to Map")
makeButton(secTPMap, "🏠 TP to Lobby", Color3.fromRGB(40,80,40), function()
    local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and (obj.Name:lower():find("lobby") or obj.Name:lower():find("spawn")) then
            myRoot.CFrame = obj.CFrame + Vector3.new(0, 3, 0)
            notify("TP", "Lobby") return
        end
    end
    notify("TP", "Lobby not found")
end)
makeButton(secTPMap, "🗺️ TP to Map", Color3.fromRGB(40,60,80), function()
    local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    for _, obj in ipairs(Workspace:GetChildren()) do
        local spawns = obj:FindFirstChild("Spawns")
        if spawns then
            local sp = spawns:FindFirstChild("Spawn")
            if sp and sp:IsA("BasePart") then
                myRoot.CFrame = sp.CFrame + Vector3.new(0, 3, 0)
                notify("TP", "Map") return
            end
        end
    end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("SpawnLocation") then
            myRoot.CFrame = obj.CFrame + Vector3.new(0, 3, 0)
            notify("TP", "Map (fallback)") return
        end
    end
    notify("TP", "Map not found")
end)

local secTPName = makeSection(tTP, "Teleport to Player")
local tpPlayerBox = makeTextBox(secTPName, "Player name...")
makeButton(secTPName, "📍 TP to Player", Color3.fromRGB(60,60,120), function()
    local tgt = Players:FindFirstChild(tpPlayerBox.Text)
    if tgt then tpToPlayer(tgt) else notify("TP", "Not found") end
end)

-- FUN
local secPicker = makeSection(tFun, "Select Player")
local pickerScroll = Instance.new("ScrollingFrame")
pickerScroll.Size = UDim2.new(1,0,0,120)
pickerScroll.BackgroundColor3 = T.BG
pickerScroll.BorderSizePixel = 0
pickerScroll.ScrollBarThickness = 3
pickerScroll.ScrollBarImageColor3 = T.Accent
pickerScroll.CanvasSize = UDim2.new()
pickerScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
pickerScroll.Parent = secPicker
corner(pickerScroll, 6)
local pickerLayout = Instance.new("UIListLayout")
pickerLayout.Padding = UDim.new(0,2)
pickerLayout.Parent = pickerScroll
local selectedTarget = nil
local pickerRows = {}
local function refreshPlayerPicker()
    for _, row in pairs(pickerRows) do pcall(function() row:Destroy() end) end
    pickerRows = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP then
            local row = Instance.new("TextButton")
            row.Size = UDim2.new(1,-4,0,24)
            row.BackgroundColor3 = (selectedTarget == p.Name) and T.Accent or T.Surface
            row.BorderSizePixel = 0
            row.Text = "  " .. p.Name
            row.TextColor3 = T.Text
            row.Font = Enum.Font.GothamMedium
            row.TextSize = 11
            row.TextXAlignment = Enum.TextXAlignment.Left
            row.AutoButtonColor = false
            row.Active = true
            row.Parent = pickerScroll
            corner(row, 4)
            row.Activated:Connect(function()
                selectedTarget = p.Name
                refreshPlayerPicker()
            end)
            table.insert(pickerRows, row)
        end
    end
end

local secFun = makeSection(tFun, "Actions")
makeButton(secFun, "💥 Fling Selected", T.AccentDrk, function()
    if not selectedTarget then notify("Fling", "Select a player first"); return end
    flingPlayer(selectedTarget)
end)
makeButton(secFun, "🌀 Bayblade Selected", Color3.fromRGB(80,20,120), function()
    if not selectedTarget then notify("Bayblade", "Select a player first"); return end
    baybladePlayer(selectedTarget)
end)

-- KILL AURA (Murderer)
local killAuraEnabled = false
local killAuraRange = 15
local killAuraToggle = makeToggle(tFun, "Kill Aura (Murderer)", "Auto-stab nearby players", function(on)
    killAuraEnabled = on
    notify("Kill Aura", on and "ON" or "OFF")
end)
makeSlider(tFun, "Kill Aura Range", 5, 30, 15, " studs", function(v) killAuraRange = v end)

-- TELEPORT KILL ALL (Murderer)
makeButton(tFun, "💀 Teleport Kill All (Murderer)", Color3.fromRGB(150,0,0), function()
    task.spawn(function()
        local char = LP.Character
        if not char then return end
        local knife = char:FindFirstChild("Knife") or (LP:FindFirstChild("Backpack") and LP.Backpack:FindFirstChild("Knife"))
        if not knife then notify("Kill All", "You are not murderer!"); return end
        if knife.Parent ~= char then knife.Parent = char end
        local myRoot = char:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end
        for _, target in ipairs(Players:GetPlayers()) do
            if target ~= LP and target.Character then
                local tHum = target.Character:FindFirstChildOfClass("Humanoid")
                local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
                if tHum and tHum.Health > 0 and tRoot then
                    myRoot.CFrame = tRoot.CFrame * CFrame.new(0, 0, 1.5)
                    pcall(function() knife:Activate() end)
                    pcall(function()
                        firetouchinterest(knife.Handle, tRoot, 0)
                        firetouchinterest(knife.Handle, tRoot, 1)
                    end)
                    task.wait(0.08)
                end
            end
        end
        notify("Kill All", "Done")
    end)
end)

local function killPlayerB(target)
    if not target or not target.Character then return end
    task.spawn(function()
        local myChar = LP.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local trp = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        if not (myRoot and trp) then return end
        myRoot.CFrame = trp.CFrame * CFrame.new(0, 0, -2.5)
        task.wait(0.05)
        local backpack = LP:FindFirstChild("Backpack")
        local char = LP.Character
        local tool = (char and char:FindFirstChildOfClass("Tool")) or (backpack and backpack:FindFirstChildOfClass("Tool"))
        if tool then
            if tool.Parent == backpack then
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then pcall(function() hum:EquipTool(tool) end) task.wait(0.1) end
            end
            pcall(function() tool:Activate() end)
            for _ = 1, 3 do
                task.wait(0.08)
                pcall(function() tool:Activate() end)
            end
        end
    end)
end

local secRole = makeSection(tFun, "Role Actions")
makeButton(secRole, "💥 Fling Murderer", Color3.fromRGB(100,20,20), function()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and getPlayerRole(p) == "murderer" then flingPlayer(p.Name) return end
    end
    notify("Fling", "No murderer detected")
end)
makeButton(secRole, "💥 Fling Sheriff", Color3.fromRGB(30,60,120), function()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and getPlayerRole(p) == "sheriff" then flingPlayer(p.Name) return end
    end
    notify("Fling", "No sheriff detected")
end)
makeButton(secRole, "🌀 Bayblade Murderer", Color3.fromRGB(80,20,120), function()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and getPlayerRole(p) == "murderer" then baybladePlayer(p.Name) return end
    end
    notify("Bayblade", "No murderer detected")
end)
makeButton(secRole, "🌀 Bayblade Sheriff", Color3.fromRGB(60,40,120), function()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and getPlayerRole(p) == "sheriff" then baybladePlayer(p.Name) return end
    end
    notify("Bayblade", "No sheriff detected")
end)
makeButton(secRole, "🔪 Kill Murderer (B)", Color3.fromRGB(120,0,0), function()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and getPlayerRole(p) == "murderer" then killPlayerB(p) return end
    end
    notify("Kill", "No murderer")
end)

local secKillAll = makeSection(tFun, "Kill All")
makeButton(secKillAll, "💀 Kill All (B - auto attack)", Color3.fromRGB(150,0,0), function()
    task.spawn(function()
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local h = p.Character:FindFirstChildOfClass("Humanoid")
                if h and h.Health > 0 then
                    killPlayerB(p)
                    task.wait(0.3)
                end
            end
        end
        notify("Kill All", "Done")
    end)
end)

-- COSMETICS (Fake Weapons, Rainbow, Trail, Spin)
local secFake = makeSection(tFun, "Fake Weapons (Visual only)")
local fakeWeapons = {}
local function clearFakeWeapon()
    if fakeWeapons.active then pcall(function() fakeWeapons.active:Destroy() end) fakeWeapons.active = nil end
    fakeWeapons.rainbowPart = nil
end
local function makeFakeKnife(color, neon)
    clearFakeWeapon()
    local char = LP.Character
    if not char then return end
    local hand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
    if not hand then return end
    local m = Instance.new("Model") m.Parent = Workspace
    local blade = Instance.new("Part") blade.Size = Vector3.new(0.08,0.55,0.06) blade.Color = color
    blade.Material = neon and Enum.Material.Neon or Enum.Material.Metal
    blade.CanCollide = false blade.Anchored = false blade.CastShadow = false blade.Parent = m
    local w = Instance.new("WeldConstraint") w.Part0 = blade w.Part1 = hand w.Parent = blade
    blade.CFrame = hand.CFrame * CFrame.new(0,-0.55,-0.15)
    local handle = Instance.new("Part") handle.Size = Vector3.new(0.07,0.25,0.07)
    handle.Color = Color3.fromRGB(40,25,15) handle.Material = Enum.Material.Wood
    handle.CanCollide = false handle.Anchored = false handle.Parent = m
    local w2 = Instance.new("WeldConstraint") w2.Part0 = handle w2.Part1 = hand w2.Parent = handle
    handle.CFrame = hand.CFrame * CFrame.new(0,-0.2,-0.15)
    fakeWeapons.active = m
    if neon then fakeWeapons.rainbowPart = blade end
end
makeButton(secFake, "🗡 Classic Knife", T.AccentDrk, function() makeFakeKnife(Color3.fromRGB(200,200,215)) notify("Fake", "Classic knife") end)
makeButton(secFake, "✨ Gold Knife", Color3.fromRGB(100,70,0), function() makeFakeKnife(Color3.fromRGB(255,200,0), true) notify("Fake", "Gold knife") end)
makeButton(secFake, "💎 Diamond Knife", Color3.fromRGB(0,50,100), function() makeFakeKnife(Color3.fromRGB(100,220,255), true) notify("Fake", "Diamond knife") end)
makeButton(secFake, "🟣 Purple Knife", Color3.fromRGB(60,0,100), function() makeFakeKnife(Color3.fromRGB(180,50,255), true) notify("Fake", "Purple knife") end)
makeButton(secFake, "🔴 Red Knife", T.AccentDrk, function() makeFakeKnife(Color3.fromRGB(255,30,30), true) notify("Fake", "Red knife") end)
makeButton(secFake, "🌈 Rainbow Knife", Color3.fromRGB(80,80,80), function() makeFakeKnife(Color3.fromRGB(255,255,255), true) notify("Fake", "Rainbow knife") end)
makeButton(secFake, "🔫 Sheriff Gun (Visual)", Color3.fromRGB(30,30,50), function()
    clearFakeWeapon()
    local char = LP.Character
    if not char then return end
    local hand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
    if not hand then return end
    local m = Instance.new("Model") m.Parent = Workspace
    local barrel = Instance.new("Part") barrel.Size = Vector3.new(0.09,0.09,0.5) barrel.Color = Color3.fromRGB(55,55,62)
    barrel.Material = Enum.Material.Metal barrel.CanCollide = false barrel.Anchored = false barrel.Parent = m
    local h2 = Instance.new("Part") h2.Size = Vector3.new(0.09,0.25,0.09) h2.Color = Color3.fromRGB(80,40,20)
    h2.Material = Enum.Material.Wood h2.CanCollide = false h2.Anchored = false h2.Parent = m
    local w1 = Instance.new("WeldConstraint") w1.Part0 = barrel w1.Part1 = hand w1.Parent = barrel
    barrel.CFrame = hand.CFrame * CFrame.new(0,0,-0.3)
    local w2 = Instance.new("WeldConstraint") w2.Part0 = h2 w2.Part1 = hand w2.Parent = h2
    h2.CFrame = hand.CFrame * CFrame.new(0,-0.18,-0.08)
    fakeWeapons.active = m
    notify("Fake", "Sheriff gun")
end)
makeButton(secFake, "❌ Remove Weapon", Color3.fromRGB(40,15,15), function()
    clearFakeWeapon()
    notify("Fake", "Removed")
end)

local secCosmetics = makeSection(tFun, "Cosmetics")
local rainbowEnabled = false
local trailEnabled = false
local trailPart = nil
local spinEnabled = false
local rainbowToggle = makeToggle(secCosmetics, "Rainbow Character", "Colorful body", function(on)
    rainbowEnabled = on
end)
local trailToggle = makeToggle(secCosmetics, "Rainbow Trail", "Trail behind you", function(on)
    trailEnabled = on
    if not on and trailPart then pcall(function() trailPart:Destroy() end) trailPart = nil end
end)
local spinToggle = makeToggle(secCosmetics, "Spin", "Character rotates (visual)", function(on)
    spinEnabled = on
end)

-- GUNDROP ESP
local gunDropColor = T.Gun
local gunDropObjects = {}
local gunDropGui = nil
local function isGunDrop(obj)
    if not obj then return false end
    if not (obj:IsA("Model") or obj:IsA("Tool") or obj:IsA("BasePart")) then return false end
    local anc = obj:FindFirstAncestorOfClass("Model")
    while anc do
        if anc:FindFirstChildOfClass("Humanoid") then return false end
        anc = anc:FindFirstAncestorOfClass("Model")
        if anc and anc == Workspace then break end
        if anc and anc.Parent == Workspace then break end
    end
    if obj.Parent and obj.Parent:FindFirstChildOfClass("Humanoid") then return false end
    if obj:IsA("Tool") then return false end
    local n = obj.Name:lower()
    if n == "gundrop" or n == "gun drop" or n == "gundropped" or n == "revolverdrop" then return true end
    return false
end
local function getGunDropPos(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj.Position end
    local pp = obj:FindFirstChild("PrimaryPart")
    if pp and pp:IsA("BasePart") then return pp.Position end
    local parts = {}
    for _, d in ipairs(obj:GetDescendants()) do
        if d:IsA("BasePart") then table.insert(parts, d) end
    end
    if #parts == 0 then return nil end
    local sum = Vector3.zero
    for _, p in ipairs(parts) do sum = sum + p.Position end
    return sum / #parts
end
local function createGunDropESP(obj)
    if gunDropObjects[obj] then return end
    local pos = getGunDropPos(obj)
    if not pos then return end
    if not gunDropGui then
        gunDropGui = mount(Instance.new("ScreenGui"))
        gunDropGui.Name = "MM2GunDrop" gunDropGui.ResetOnSpawn = false gunDropGui.DisplayOrder = 994
    end
    local hl = Instance.new("Highlight") hl.Parent = obj hl.FillColor = gunDropColor hl.FillTransparency = 0.4 hl.OutlineColor = gunDropColor hl.OutlineTransparency = 0.2 hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    local frame = Instance.new("Frame") frame.Size = UDim2.new(0,120,0,20) frame.BackgroundTransparency = 1 frame.Parent = gunDropGui
    local txt = Instance.new("TextLabel") txt.Size = UDim2.new(1,0,1,0) txt.BackgroundTransparency = 1 txt.Text = "GunDrop" txt.TextColor3 = gunDropColor txt.Font = Enum.Font.GothamBold txt.TextSize = 12 txt.TextStrokeTransparency = 0 txt.Parent = frame
    gunDropObjects[obj] = {hl=hl, frame=frame}
end
local function clearGunDropESP()
    for obj, data in pairs(gunDropObjects) do
        pcall(function() data.hl:Destroy() end) pcall(function() data.frame:Destroy() end)
    end
    gunDropObjects = {}
    if gunDropGui then pcall(function() gunDropGui:Destroy() end) gunDropGui=nil end
end
local function updateGunDropPositions()
    for obj, data in pairs(gunDropObjects) do
        if not obj or not obj.Parent then
            pcall(function() data.hl:Destroy() end) pcall(function() data.frame:Destroy() end)
            gunDropObjects[obj] = nil
        else
            local pos = getGunDropPos(obj)
            if pos then
                local sp, onScreen = Camera:WorldToScreenPoint(pos)
                if onScreen then
                    data.frame.Position = UDim2.new(0, sp.X - 60, 0, sp.Y - 10)
                    data.frame.Visible = true
                else data.frame.Visible = false end
            else data.frame.Visible = false end
        end
    end
end
local grabReturnPos = nil
local function tryGrabGunDrop(obj)
    local pos = getGunDropPos(obj)
    if not pos then return end
    local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    if not grabReturnPos then grabReturnPos = myRoot.CFrame end
    myRoot.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
    task.wait(0.15)
    local prox = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prox then pcall(function() fireproximityprompt(prox) end) end
    task.wait(0.2)
    if grabReturnPos then
        myRoot.CFrame = grabReturnPos * CFrame.new(0, 3, 0)
        grabReturnPos = nil
    end
end

local secGrab = makeSection(tFun, "Gun Grabber")
makeButton(secGrab, "🎯 Grab Nearest GunDrop", Color3.fromRGB(0,80,180), function()
    local best, bestD = nil, math.huge
    local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    for _, obj in ipairs(Workspace:GetChildren()) do
        if isGunDrop(obj) then
            local p = getGunDropPos(obj)
            if p then
                local d = (p - myRoot.Position).Magnitude
                if d < bestD then bestD = d best = obj end
            end
        end
    end
    if best then tryGrabGunDrop(best) else notify("Grab", "No gun drop found") end
end)

-- ANTI-LAG
local secLag = makeSection(tFun, "Performance")
makeButton(secLag, "⚡ Anti-Lag / FPS Boost", Color3.fromRGB(0,120,80), function()
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1000
        Lighting.Brightness = 0.5
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
                v.Enabled = false
            end
        end
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("PostEffect") then v.Enabled = false end
        end
    end)
    notify("Anti-Lag", "Applied")
end)

-- FARM
local secFarm = makeSection(tFarm, "Auto Farm")
local coinFarmToggle = makeToggle(secFarm, "Coin Farm", "Auto collect coins")

-- Anti-AFK
local secAFK = makeSection(tFarm, "Anti-AFK")
local antiAfkEnabled = makeToggle(secAFK, "Anti-AFK", "Prevent kick for idle", true)
local afkConn = LP.Idled:Connect(function()
    if not antiAfkEnabled:get() then return end
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

-- Coin Farm loop (přes firetouchinterest + teleport)
task.spawn(function()
    while true do
        task.wait(0.5)
        if coinFarmToggle:get() then
            pcall(function()
                local myChar = LP.Character
                local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                if not myRoot then return end
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and (obj.Name:lower():find("coin") or obj.Name:lower():find("gold")) then
                        local saved = myRoot.CFrame
                        myRoot.CFrame = CFrame.new(obj.Position + Vector3.new(0,3,0))
                        pcall(function()
                            firetouchinterest(myRoot, obj, 0)
                            firetouchinterest(myRoot, obj, 1)
                        end)
                        task.wait(0.03)
                        myRoot.CFrame = saved
                    end
                end
            end)
        end
    end
end)

-- ESP UPDATE
local espHighlights = {}
local espBillboards = {}
local weaponHighlights = {}
local function removeESP(name)
    if espHighlights[name] then pcall(function() espHighlights[name]:Destroy() end) espHighlights[name]=nil end
    if espBillboards[name] then pcall(function() espBillboards[name].bb:Destroy() end) espBillboards[name]=nil end
end
local function removeWeaponESP(name)
    if weaponHighlights[name] then pcall(function() weaponHighlights[name]:Destroy() end) weaponHighlights[name]=nil end
end
local function updateESP()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local role = getPlayerRole(p)
            local pHum = p.Character:FindFirstChildOfClass("Humanoid")
            local isDead = pHum and pHum.Health <= 0
            local showRole = (role=="murderer" and espMurd:get())
                or (role=="sheriff" and espSher:get())
                or (role=="hero" and espHero:get())
                or (role=="innocent" and espInno:get())
                or (isDead and espDead:get())
            local color = roleColor(role, isDead)
            if showRole then
                if espBox:get() then
                    if not espHighlights[p.Name] or not espHighlights[p.Name].Parent then
                        local hl = Instance.new("Highlight")
                        hl.Name = "_mm2hl" hl.FillColor = color hl.FillTransparency = 0.6
                        hl.OutlineColor = color hl.OutlineTransparency = 0
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.Parent = p.Character espHighlights[p.Name] = hl
                    else
                        espHighlights[p.Name].FillColor = color espHighlights[p.Name].OutlineColor = color
                    end
                else
                    if espHighlights[p.Name] then pcall(function() espHighlights[p.Name]:Destroy() end) espHighlights[p.Name]=nil end
                end
                if espName:get() or espRole:get() then
                    local head = p.Character:FindFirstChild("Head")
                    if head then
                        if not espBillboards[p.Name] or not espBillboards[p.Name].bb.Parent then
                            local bb = Instance.new("BillboardGui")
                            bb.Name = "_mm2bb" bb.Size = UDim2.new(0, 120, 0, 32) bb.StudsOffset = Vector3.new(0, 2, 0) bb.AlwaysOnTop = true bb.Parent = head
                            local txt = Instance.new("TextLabel") txt.Size = UDim2.new(1, 0, 0, 16) txt.BackgroundTransparency = 1 txt.Font = Enum.Font.GothamBold txt.TextSize = 11 txt.TextStrokeTransparency = 0 txt.TextXAlignment = Enum.TextXAlignment.Center txt.Parent = bb
                            local rtxt = Instance.new("TextLabel") rtxt.Size = UDim2.new(1, 0, 0, 14) rtxt.Position = UDim2.new(0, 0, 0, 16) rtxt.BackgroundTransparency = 1 rtxt.Font = Enum.Font.GothamMedium rtxt.TextSize = 10 rtxt.TextStrokeTransparency = 0 rtxt.TextXAlignment = Enum.TextXAlignment.Center rtxt.Parent = bb
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
            local wType = getWeaponType(p)
            local wShow = (wType=="Gun" and espGun:get()) or (wType=="Knife" and espKnife:get()) or (wType=="None" and espNone:get())
            local wColor = wType=="Gun" and gunColorVal or wType=="Knife" and knifeColorVal or noneColorVal
            if wShow then
                if not weaponHighlights[p.Name] or not weaponHighlights[p.Name].Parent then
                    local hl = Instance.new("Highlight")
                    hl.Name = "_mm2whl" hl.FillColor = wColor hl.FillTransparency = 0.6
                    hl.OutlineColor = wColor hl.OutlineTransparency = 0
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.Parent = p.Character weaponHighlights[p.Name] = hl
                else
                    weaponHighlights[p.Name].FillColor = wColor weaponHighlights[p.Name].OutlineColor = wColor
                end
            else
                removeWeaponESP(p.Name)
            end
        end
    end
end

-- DescendantAdded listener (GunDrop + autograb)
Workspace.DescendantAdded:Connect(function(obj)
    if gunDropEnabled:get() and isGunDrop(obj) then createGunDropESP(obj) end
    if autoGrab:get() and isGunDrop(obj) then
        task.wait(0.3)
        if obj and obj.Parent and isGunDrop(obj) then tryGrabGunDrop(obj) end
    end
end)

-- AIMBOT (hlavní)
local aimConn = nil
local function startAimbot()
    if aimConn then return end
    aimConn = RunService.Heartbeat:Connect(function(dt)
        if not aimEnabled:get() then return end
        local want = aimTargetMode
        local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        local closest = nil
        local closestDist = math.huge
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP and p.Character and getPlayerRole(p) == want then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                local h = p.Character:FindFirstChildOfClass("Humanoid")
                if hrp and h and h.Health > 0 then
                    local sp, onScreen = Camera:WorldToScreenPoint(hrp.Position)
                    if onScreen and sp.Z > 0 then
                        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                        if d < aimFOV.get() and d < closestDist then                            closestDist = d closest = hrp.Position
                        end
                    end
                end
            end
        end
        if closest then
            local camPos = Camera.CFrame.Position
            local goal = CFrame.lookAt(camPos, closest)
            Camera.CFrame = Camera.CFrame:Lerp(goal, math.clamp(dt * (aimSmooth.get()/10), 0, 1))
        end
    end)
end
startAimbot()

-- AIM ASSIST (RMB) - jemný tracking
local aaConn = nil
local function startAimAssist()
    if aaConn then return end
    aaConn = RunService.RenderStepped:Connect(function()
        if not aimAssistEnabled:get() then return end
        if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end
        local target = nil
        local mousePos = UserInputService:GetMouseLocation()
        local closestDist = math.huge
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP and p.Character and getPlayerRole(p) == aimAssistTarget then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                local h = p.Character:FindFirstChildOfClass("Humanoid")
                if hrp and h and h.Health > 0 then
                    local sp, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                    if onScreen then
                        local d = (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
                        if d < closestDist then closestDist = d target = hrp.Position end
                    end
                end
            end
        end
        if target then
            local cf = Camera.CFrame
            local goal = CFrame.lookAt(cf.Position, target)
            Camera.CFrame = cf:Lerp(goal, aaSmooth.get()/100)
        end
    end)
end
startAimAssist()

-- KILL AURA loop
task.spawn(function()
    while true do
        task.wait(0.08)
        if killAuraEnabled and getPlayerRole(LP) == "murderer" then
            pcall(function()
                local char = LP.Character
                if not char then return end
                local knife = char:FindFirstChild("Knife") or (LP:FindFirstChild("Backpack") and LP.Backpack:FindFirstChild("Knife"))
                if not knife then return end
                if knife.Parent ~= char then knife.Parent = char end
                local myRoot = char:FindFirstChild("HumanoidRootPart")
                if not myRoot or not knife:FindFirstChild("Handle") then return end
                for _, target in ipairs(Players:GetPlayers()) do
                    if target ~= LP and target.Character then
                        local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
                        local tHum = target.Character:FindFirstChildOfClass("Humanoid")
                        if tRoot and tHum and tHum.Health > 0 then
                            local dist = (myRoot.Position - tRoot.Position).Magnitude
                            if dist <= killAuraRange then
                                pcall(function() knife:Activate() end)
                                pcall(function()
                                    firetouchinterest(knife.Handle, tRoot, 0)
                                    firetouchinterest(knife.Handle, tRoot, 1)
                                end)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- RAINBOW + TRAIL + SPIN loop
RunService.Heartbeat:Connect(function(dt)
    local char = LP.Character
    -- Rainbow character
    if rainbowEnabled and char then
        local color = Color3.fromHSV(tick()%5/5, 1, 1)
        for _, p in ipairs(char:GetDescendants()) do
            pcall(function() if p:IsA("BasePart") then p.Color = color end end)
        end
    end
    -- Fake weapon rainbow
    if fakeWeapons.rainbowPart then
        fakeWeapons.rainbowPart.Color = Color3.fromHSV(tick()%2/2, 1, 1)
    end
    -- Trail
    if trailEnabled and char then
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            if not trailPart or not trailPart.Parent then
                trailPart = Instance.new("Trail")
                local a0 = Instance.new("Attachment") a0.Position = Vector3.new(0,1,0) a0.Parent = root a0.Name = "_ta0"
                local a1 = Instance.new("Attachment") a1.Position = Vector3.new(0,-1,0) a1.Parent = root a1.Name = "_ta1"
                trailPart.Attachment0 = a0 trailPart.Attachment1 = a1 trailPart.Lifetime = 0.5 trailPart.Parent = root
            end
            trailPart.Color = ColorSequence.new(Color3.fromHSV(tick()%3/3, 1, 1))
        end
    elseif trailPart then
        pcall(function() trailPart:Destroy() end) trailPart = nil
        if char then
            pcall(function() if char.HumanoidRootPart._ta0 then char.HumanoidRootPart._ta0:Destroy() end end)
            pcall(function() if char.HumanoidRootPart._ta1 then char.HumanoidRootPart._ta1:Destroy() end end)
        end
    end
    -- Spin
    if spinEnabled and char then
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            root.CFrame = root.CFrame * CFrame.Angles(0, dt * 3, 0)
        end
    end
end)

-- NOCLIP + INFJUMP loops
RunService.Stepped:Connect(function()
    if noclipEnabled and LP.Character then
        for _, p in ipairs(LP.Character:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
        end
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Physics) end) end
    end
end)
UserInputService.JumpRequest:Connect(function()
    if infJumpEnabled and LP.Character then
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end) end
    end
end)
RunService.Heartbeat:Connect(function()
    if not boostOnJump:get() then return end
    local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if h then
        if h.FloorMaterial == Enum.Material.Air then h.WalkSpeed = 75
        else h.WalkSpeed = speedVal.get() end
    end
end)

-- RADAR update
RunService.Heartbeat:Connect(function()
    RadarFrame.Visible = radarToggle:get()
    if not radarToggle:get() then return end
    for _, dot in pairs(radarDots) do dot.Visible = false end
    local char = LP.Character
    local mr = char and char:FindFirstChild("HumanoidRootPart")
    if not mr then return end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local pRoot = p.Character:FindFirstChild("HumanoidRootPart")
            if pRoot then
                local nx, ny = worldToRadar(pRoot.Position)
                if nx and ny then
                    local role = getPlayerRole(p)
                    local col = roleColor(role, false)
                    local dot = getRadarDot(p.Name)
                    dot.Visible = true
                    dot.Position = UDim2.new(nx,-4.5,ny,-4.5)
                    dot.BackgroundColor3 = col
                end
            end
        end
    end
end)

-- CLEANUP
Players.PlayerRemoving:Connect(function(p)
    removeESP(p.Name) removeWeaponESP(p.Name) roleMemory[p.Name]=nil refreshPlayerPicker()
    if radarDots[p.Name] then pcall(function() radarDots[p.Name]:Destroy() end) radarDots[p.Name]=nil end
end)
Players.PlayerAdded:Connect(function() task.wait(0.5) refreshPlayerPicker() end)
LP.CharacterAdded:Connect(function()
    task.wait(1) clearRoleMemory()
    for n in pairs(espHighlights) do removeESP(n) end
    for n in pairs(weaponHighlights) do removeWeaponESP(n) end
    trailPart = nil
    fakeWeapons.active = nil
end)

-- KEYS
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        Main.Visible = not Main.Visible
        if Main.Visible then refreshPlayerPicker() end
    elseif input.KeyCode == Enum.KeyCode.Delete then
        for _, t in ipairs({espMurd,espSher,espHero,espInno,espDead,espBox,espName,espRole,espGun,espKnife,espNone,gunDropEnabled,autoGrab,aimEnabled,aimAssistEnabled,boostOnJump,xrayEnabled,xrayPartsEnabled,flyEnabled,noclipToggle,infJumpToggle,coinFarmToggle,fogToggle,monoToggle,transToggle,radarToggle,rainbowToggle,trailToggle,spinToggle}) do t:set(false) end
        killAuraEnabled = false
        FlingActive = false BaybladeActive = false clearGunDropESP()
        clearFakeWeapon()
        pcall(stopFly)
        pcall(function() Workspace.FallenPartsDestroyHeight = FlingFPDH end)
        pcall(function() Lighting.Brightness = 1 end)
        notify("Panic", "All features disabled")
    elseif input.KeyCode == Enum.KeyCode.End then
        wmFrame.Visible = not wmFrame.Visible
    elseif input.KeyCode == Enum.KeyCode.E then
        aimEnabled:set(not aimEnabled:get())
    elseif input.KeyCode == Enum.KeyCode.C then
        noclipToggle:set(not noclipToggle:get())
    elseif input.KeyCode == Enum.KeyCode.V then
        infJumpToggle:set(not infJumpToggle:get())
    end
end)

-- MAIN LOOP
local fpsCount, fpsAccum = 0, 0
local heavyTimer = 0
local HEAVY = 0.1
RunService.Heartbeat:Connect(function(dt)
    fpsCount = fpsCount + 1 fpsAccum = fpsAccum + dt heavyTimer = heavyTimer + dt
    pcall(updateESP)
    if gunDropEnabled:get() then pcall(updateGunDropPositions) end
    if fpsAccum >= 1 then
        local fps = math.floor(fpsCount/fpsAccum)
        pcall(function() lblFPS.set(fps.." FPS") wmInfo.Text=fps.." FPS" end)
        fpsCount=0 fpsAccum=0
    end
    if heavyTimer < HEAVY then return end
    heavyTimer = 0
    local char = LP.Character if not char then return end
    local murderer, sheriff, hero = nil, nil, nil
    local alive, dead = 0, 0
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character then
            local h = p.Character:FindFirstChildOfClass("Humanoid")
            if h then
                if h.Health > 0 then alive = alive + 1 else dead = dead + 1 end
            end
            if p ~= LP then
                local r = getPlayerRole(p)
                if r=="murderer" then murderer=p.Name end
                if r=="sheriff" then sheriff=p.Name end
                if r=="hero" then hero=p.Name end
            end
        end
    end
    pcall(function()
        lblMurd.set(murderer or "Unknown", murderer and T.Murd or T.Faint)
        lblSher.set(sheriff or "Unknown", sheriff and T.Sher or T.Faint)
        lblHero.set(hero or "Unknown", hero and T.Hero or T.Faint)
        local myRole = getPlayerRole(LP)
        lblMyRole.set(roleText(myRole,false), roleColor(myRole,false))
        lblPlayers.set(#Players:GetPlayers())
        lblAlive.set(alive, T.Good)
        lblDead.set(dead, T.Bad)
    end)
end)

refreshPlayerPicker()

_G.__MM2Short_Destroy = function()
    FlingActive = false BaybladeActive = false killAuraEnabled = false
    pcall(stopFly)
    pcall(function() Workspace.FallenPartsDestroyHeight = FlingFPDH end)
    pcall(function() GUI:Destroy() end) pcall(function() WM:Destroy() end) pcall(function() RadarGui:Destroy() end)
    clearGunDropESP()
    clearFakeWeapon()
    for n in pairs(espHighlights) do removeESP(n) end
    for n in pairs(weaponHighlights) do removeWeaponESP(n) end
end

print("[MM2 Short] " .. BUILD .. " loaded")
