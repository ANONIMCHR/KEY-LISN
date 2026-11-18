--[[
    NX OFFICIAL CHEAT ENGINE V1.5.2
    Dev  : Chris Official
    Team : NX OFFICIAL STUDIO
    Changelog V1.5.2:
      FIX: Aim lock — re-evaluates closest target every 100ms, short stickiness
      FIX: Aim lock — skips dead / respawning players, drops target instantly on death
      FIX: ESP — auto-clears drawings on Humanoid.Died / CharacterRemoving / PlayerRemoving
      FIX: Brutal — re-validates target each tick, re-acquires if target dies
      FIX: ESP skeleton — dedicated bone thickness (default 3, slider 1-8)
      KEPT: V1.5.1 crash fixes, throttled coroutines, Scriptable camera handling
]]--

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local CoreGui          = game:GetService("CoreGui")
local HttpService      = game:GetService("HttpService")
local Workspace        = game:GetService("Workspace")
local ReplicatedStorage= game:GetService("ReplicatedStorage")

local LP = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local CONFIG = {
    VERSION = "V1.5.2",
    DEV     = "Chris Official",
    TEAM    = "NX OFFICIAL STUDIO",
    KEY_URL = "https://raw.githubusercontent.com/ANONIMCHR/KEY-LISN/refs/heads/main/loginkey.JSON",
    LOGO_URL= "https://files.catbox.moe/nxlogo.png",
    TITLE   = "NX CHEAT ENGINE",
    FOOTER  = "NX OFFICIAL CHEAT ENGINE",
}

-- ==========================================================
-- HTTP / LOGO
-- ==========================================================
local function httpGet(url)
    local ok, res
    if syn and syn.request then ok, res = pcall(function() return syn.request({Url=url, Method="GET"}).Body end)
    elseif fluxus and fluxus.request then ok, res = pcall(function() return fluxus.request({Url=url, Method="GET"}).Body end)
    elseif http and http.request then ok, res = pcall(function() return http.request({Url=url, Method="GET"}).Body end)
    elseif request then ok, res = pcall(function() return request({Url=url, Method="GET"}).Body end)
    else ok, res = pcall(function() return game:HttpGet(url) end) end
    return ok and res or nil
end

local function loadLogo()
    local fname = "nx_logo_v152.png"
    if not (isfile and isfile(fname)) then
        local bin = httpGet(CONFIG.LOGO_URL)
        if bin and #bin > 100 and writefile then pcall(writefile, fname, bin) end
    end
    if getcustomasset and isfile and isfile(fname) then
        local ok, a = pcall(getcustomasset, fname)
        if ok and a then return a end
    end
    return nil
end
local LOGO_ASSET = loadLogo()

-- ==========================================================
-- UTILS
-- ==========================================================
local function new(c, p)
    local o = Instance.new(c)
    if p then for k,v in pairs(p) do o[k] = v end end
    return o
end

local function makeDraggable(frame, dragBar)
    local dragging, startPos, startInput
    dragBar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging, startPos, startInput = true, frame.Position, i.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - startInput
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

local function addRainbow(parent, th)
    th = th or 2
    local s = new("UIStroke", {Thickness = th, Color = Color3.fromRGB(255,0,128), ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = parent})
    task.spawn(function()
        local h = 0
        while s.Parent do h = (h + 0.006) % 1; s.Color = Color3.fromHSV(h, 0.9, 1); RunService.Heartbeat:Wait() end
    end)
    return s
end

local C = {
    BG = Color3.fromRGB(11,11,18), BG2 = Color3.fromRGB(20,20,30), BG3 = Color3.fromRGB(30,30,44),
    ACCENT = Color3.fromRGB(0,180,255), ACCENT2 = Color3.fromRGB(255,0,150),
    TEXT = Color3.fromRGB(245,245,255), DIM = Color3.fromRGB(130,130,150),
    OK = Color3.fromRGB(0,220,130), ERR = Color3.fromRGB(255,70,70),
    ON = Color3.fromRGB(0,200,255), OFF = Color3.fromRGB(55,55,70),
}
local F = Enum.Font.GothamBlack

local okCore = pcall(function() return CoreGui:GetChildren() end)
local guiParent = okCore and CoreGui or LP:WaitForChild("PlayerGui")

-- ==========================================================
-- LOGIN UI
-- ==========================================================
local loginGui = new("ScreenGui", {Name="NX_Login", ResetOnSpawn=false, IgnoreGuiInset=true, ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
loginGui.Parent = guiParent

local loginFrame = new("Frame", {Size=UDim2.fromOffset(440, 400), Position=UDim2.new(0.5,-220,0.5,-200), BackgroundColor3=C.BG, BorderSizePixel=0, Parent=loginGui})
new("UICorner", {CornerRadius=UDim.new(0,16), Parent=loginFrame})
addRainbow(loginFrame, 2)
makeDraggable(loginFrame, loginFrame)

local titleY = 22
if LOGO_ASSET then
    new("ImageLabel", {Size=UDim2.fromOffset(72,72), Position=UDim2.new(0.5,-36,0,16), BackgroundTransparency=1, Image=LOGO_ASSET, ScaleType=Enum.ScaleType.Fit, Parent=loginFrame})
    titleY = 96
end
new("TextLabel", {Size=UDim2.new(1,0,0,40), Position=UDim2.fromOffset(0,titleY), BackgroundTransparency=1, Text=CONFIG.TITLE, Font=F, TextSize=26, TextColor3=C.TEXT, Parent=loginFrame})
new("TextLabel", {Size=UDim2.new(1,0,0,20), Position=UDim2.fromOffset(0,titleY+42), BackgroundTransparency=1, Text="Dev "..CONFIG.DEV.."  •  By "..CONFIG.TEAM, Font=F, TextSize=12, TextColor3=C.DIM, Parent=loginFrame})

local keyFrame = new("Frame", {Size=UDim2.fromOffset(360,48), Position=UDim2.new(0.5,-180,0,titleY+78), BackgroundColor3=C.BG2, BorderSizePixel=0, Parent=loginFrame})
new("UICorner", {CornerRadius=UDim.new(0,10), Parent=keyFrame})
new("UIStroke", {Thickness=1, Color=C.ACCENT, Transparency=0.4, Parent=keyFrame})

local keyBox = new("TextBox", {Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text="", PlaceholderText="Masukan Key Disini...", PlaceholderColor3=C.DIM, Font=F, TextSize=16, TextColor3=C.TEXT, TextXAlignment=Enum.TextXAlignment.Center, ClearTextOnFocus=false, Parent=keyFrame})
local keyRaw, masking = "", false
keyBox:GetPropertyChangedSignal("Text"):Connect(function()
    if masking then return end
    masking = true
    local c = keyBox.Text:gsub("•","")
    if #c > #keyRaw then keyRaw = keyRaw..c:sub(#keyRaw+1) elseif #c < #keyRaw then keyRaw = keyRaw:sub(1,#c) end
    keyBox.Text = string.rep("•", #keyRaw)
    masking = false
end)

local statusLbl = new("TextLabel", {Size=UDim2.new(1,0,0,20), Position=UDim2.fromOffset(0,titleY+136), BackgroundTransparency=1, Text="", Font=F, TextSize=12, TextColor3=C.DIM, Parent=loginFrame})
local loginBtn = new("TextButton", {Size=UDim2.fromOffset(360,46), Position=UDim2.new(0.5,-180,0,titleY+168), BackgroundColor3=C.ACCENT, BorderSizePixel=0, Text="LOGIN", Font=F, TextSize=17, TextColor3=Color3.fromRGB(255,255,255), AutoButtonColor=false, Parent=loginFrame})
new("UICorner", {CornerRadius=UDim.new(0,10), Parent=loginBtn})
local grad = new("UIGradient", {Rotation=0, Color=ColorSequence.new{ColorSequenceKeypoint.new(0,C.ACCENT), ColorSequenceKeypoint.new(1,C.ACCENT2)}, Parent=loginBtn})
task.spawn(function() while grad.Parent do TweenService:Create(grad, TweenInfo.new(2, Enum.EasingStyle.Linear), {Rotation=grad.Rotation+360}):Play(); task.wait(2) end end)
new("TextLabel", {Size=UDim2.new(1,0,0,20), Position=UDim2.new(0,0,1,-30), BackgroundTransparency=1, Text=CONFIG.FOOTER, Font=F, TextSize=11, TextColor3=C.DIM, Parent=loginFrame})

-- ==========================================================
-- KEY VALIDATION
-- ==========================================================
local function parseISO(s)
    if not s or s=="" then return nil end
    local y,mo,d,h,mi,se = s:match("(%d+)-(%d+)-(%d+)T?(%d*):?(%d*):?(%d*)")
    if not y then return nil end
    local ok, t = pcall(function() return os.time({year=tonumber(y),month=tonumber(mo),day=tonumber(d),hour=tonumber(h)or 0,min=tonumber(mi)or 0,sec=tonumber(se)or 0}) end)
    return ok and t or nil
end

local function validateKey(k)
    if not k or k=="" then return false, "Key Kosong." end
    local body = httpGet(CONFIG.KEY_URL)
    if not body or body=="" then return false, "Gagal Fetch Server." end
    local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
    if not ok or not data or not data.keys then return false, "Format JSON Salah." end
    local entry = data.keys[k]
    if not entry then return false, "Key Tidak Valid." end
    local expiry = parseISO(entry.expires)
    if not expiry then return false, "Expiry Rusak." end
    if os.time() >= expiry then return false, "Key Expired." end
    return true, entry, expiry
end

-- ==========================================================
-- EVENT SYSTEM — CACHED, NO GetDescendants IN LOOP
-- ==========================================================
local EventSys = {
    autoClaim = false, autoTeleport = false, autoPrompt = false,
    claimRadius = 400, pollRate = 0.5,
    knownPrompts = {}, knownClicks = {},
    targetCache = {},
    targetCacheBuilt = false,
    lastScan = 0,
}

local CLAIM_KW = {"claim","event","chest","reward","pickup","coin","token","orb","gift","present","supply","drop","box","loot","spin","collect","harvest"}

local function kwMatch(name)
    if not name then return false end
    local l = string.lower(name)
    for _, k in ipairs(CLAIM_KW) do if string.find(l, k, 1, true) then return true end end
    return false
end

local hasFPP = (type(fireproximityprompt) == "function")
local hasFCD = (type(fireclickdetector) == "function")

local function triggerPrompt(pp)
    if hasFPP then
        pcall(fireproximityprompt, pp)
    else
        local hd = pp.HoldDuration or 0
        pcall(function() pp:InputHoldBegin() end)
        if hd > 0 then task.wait(hd) end
        pcall(function() pp:InputHoldEnd() end)
    end
end

local function triggerClick(cd)
    if hasFCD then pcall(fireclickdetector, cd) end
end

local function buildTeleportCache()
    EventSys.targetCache = {}
    EventSys.targetCacheBuilt = false
    task.spawn(function()
        local i = 0
        for _, inst in ipairs(Workspace:GetDescendants()) do
            if inst:IsA("BasePart") and kwMatch(inst.Name) then
                EventSys.targetCache[inst] = true
            end
            i = i + 1
            if i % 500 == 0 then task.wait() end
        end
        EventSys.targetCacheBuilt = true
    end)
end

Workspace.DescendantAdded:Connect(function(inst)
    if inst:IsA("ProximityPrompt") then
        EventSys.knownPrompts[inst] = true
        if EventSys.autoPrompt then task.spawn(function() triggerPrompt(inst) end) end
    elseif inst:IsA("ClickDetector") then
        EventSys.knownClicks[inst] = true
        if EventSys.autoClaim and inst.Parent and kwMatch(inst.Parent.Name) then
            task.spawn(function() triggerClick(inst) end)
        end
    elseif inst:IsA("BasePart") and EventSys.targetCacheBuilt and kwMatch(inst.Name) then
        EventSys.targetCache[inst] = true
    end
end)

local function lightScan()
    if not EventSys.autoClaim and not EventSys.autoTeleport and not EventSys.autoPrompt then return end
    local now = os.clock()
    if now - EventSys.lastScan < EventSys.pollRate then return end
    EventSys.lastScan = now

    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local myPos = root.Position

    if EventSys.autoPrompt then
        for pp in pairs(EventSys.knownPrompts) do
            if not pp.Parent then
                EventSys.knownPrompts[pp] = nil
            else
                local parentPart = pp.Parent
                if parentPart:IsA("BasePart") then
                    if (parentPart.Position - myPos).Magnitude < EventSys.claimRadius then
                        task.spawn(function() triggerPrompt(pp) end)
                    end
                end
            end
        end
    end

    if EventSys.autoTeleport and EventSys.targetCacheBuilt then
        local closest, closestDist = nil, EventSys.claimRadius
        for part in pairs(EventSys.targetCache) do
            if not part.Parent then
                EventSys.targetCache[part] = nil
            else
                local d = (part.Position - myPos).Magnitude
                if d < closestDist and d > 4 then closest, closestDist = part, d end
            end
        end
        if closest then
            pcall(function() root.CFrame = CFrame.new(closest.Position + Vector3.new(0,3,0)) end)
        end
    end
end

task.spawn(function()
    local i = 0
    for _, inst in ipairs(Workspace:GetDescendants()) do
        if inst:IsA("ProximityPrompt") then EventSys.knownPrompts[inst] = true
        elseif inst:IsA("ClickDetector") then EventSys.knownClicks[inst] = true end
        i = i + 1
        if i % 500 == 0 then task.wait() end
    end
end)

-- ==========================================================
-- MAIN GUI
-- ==========================================================
local function buildMain(entry, expiry)
    local mainGui = new("ScreenGui", {Name="NX_Main", ResetOnSpawn=false, IgnoreGuiInset=true, ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
    mainGui.Parent = guiParent

    local main = new("Frame", {Size=UDim2.fromOffset(760,560), Position=UDim2.new(0.5,-380,0.5,-280), BackgroundColor3=C.BG, BorderSizePixel=0, Parent=mainGui})
    new("UICorner", {CornerRadius=UDim.new(0,16), Parent=main})
    addRainbow(main, 2)
    makeDraggable(main, main)

    local topBar = new("Frame", {Size=UDim2.new(1,0,0,60), BackgroundColor3=C.BG2, BorderSizePixel=0, Parent=main})
    new("UICorner", {CornerRadius=UDim.new(0,16), Parent=topBar})
    new("Frame", {Size=UDim2.new(1,0,0,20), Position=UDim2.new(0,0,1,-20), BackgroundColor3=C.BG2, BorderSizePixel=0, Parent=topBar})
    if LOGO_ASSET then new("ImageLabel", {Size=UDim2.fromOffset(42,42), Position=UDim2.fromOffset(16,9), BackgroundTransparency=1, Image=LOGO_ASSET, ScaleType=Enum.ScaleType.Fit, Parent=topBar}) end
    new("TextLabel", {Size=UDim2.new(1,-180,1,0), Position=UDim2.fromOffset(LOGO_ASSET and 70 or 24,0), BackgroundTransparency=1, Text=CONFIG.TITLE, Font=F, TextSize=22, TextColor3=C.TEXT, TextXAlignment=Enum.TextXAlignment.Left, Parent=topBar})

    local closeBtn = new("TextButton", {Size=UDim2.fromOffset(34,34), Position=UDim2.new(1,-46,0,13), BackgroundColor3=Color3.fromRGB(230,60,60), Text="×", Font=F, TextSize=22, TextColor3=Color3.fromRGB(255,255,255), BorderSizePixel=0, AutoButtonColor=false, Parent=topBar})
    new("UICorner", {CornerRadius=UDim.new(0,10), Parent=closeBtn})

    local reopen = new("TextButton", {Size=UDim2.fromOffset(64,64), Position=UDim2.new(0,30,0.5,60), BackgroundColor3=C.ACCENT, Text="", Font=F, TextSize=16, TextColor3=Color3.fromRGB(255,255,255), BorderSizePixel=0, Visible=false, Parent=mainGui})
    new("UICorner", {CornerRadius=UDim.new(0,16), Parent=reopen})
    addRainbow(reopen, 2)
    makeDraggable(reopen, reopen)
    if LOGO_ASSET then new("ImageLabel", {Size=UDim2.fromScale(0.82,0.82), Position=UDim2.fromScale(0.09,0.09), BackgroundTransparency=1, Image=LOGO_ASSET, ScaleType=Enum.ScaleType.Fit, Parent=reopen}) else reopen.Text = "NX" end
    closeBtn.MouseButton1Click:Connect(function() main.Visible=false; reopen.Visible=true end)
    reopen.MouseButton1Click:Connect(function() main.Visible=true; reopen.Visible=false end)

    local sidebar = new("Frame", {Size=UDim2.new(0,160,1,-120), Position=UDim2.fromOffset(12,72), BackgroundColor3=C.BG2, BorderSizePixel=0, Parent=main})
    new("UICorner", {CornerRadius=UDim.new(0,12), Parent=sidebar})
    addRainbow(sidebar, 1.5)

    local content = new("Frame", {Size=UDim2.new(1,-194,1,-120), Position=UDim2.fromOffset(182,72), BackgroundTransparency=1, Parent=main})
    local footer = new("Frame", {Size=UDim2.new(1,-24,0,40), Position=UDim2.new(0,12,1,-52), BackgroundColor3=C.BG2, BorderSizePixel=0, Parent=main})
    new("UICorner", {CornerRadius=UDim.new(0,10), Parent=footer})
    new("TextLabel", {Size=UDim2.new(1,-24,1,0), Position=UDim2.fromOffset(16,0), BackgroundTransparency=1, Text=string.format("v%s  •  %s  •  %s", CONFIG.VERSION, CONFIG.DEV, CONFIG.TEAM), Font=F, TextSize=12, TextColor3=C.DIM, TextXAlignment=Enum.TextXAlignment.Left, Parent=footer})

    local dropLayer = new("Frame", {Size=UDim2.fromScale(1,1), BackgroundTransparency=1, ZIndex=900, Visible=true, Parent=mainGui})

    local pages = {}
    local function newPage(n)
        local p = new("ScrollingFrame", {Name=n, Size=UDim2.fromScale(1,1), BackgroundTransparency=1, BorderSizePixel=0, ScrollBarThickness=4, ScrollBarImageColor3=C.ACCENT, Visible=false, CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y, Parent=content})
        pages[n] = p
        new("UIListLayout", {SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,8), Parent=p})
        new("UIPadding", {PaddingLeft=UDim.new(0,4), PaddingRight=UDim.new(0,4), PaddingTop=UDim.new(0,4), PaddingBottom=UDim.new(0,4), Parent=p})
        return p
    end
    local espPage = newPage("ESP"); local aimPage = newPage("AIM"); local eventPage = newPage("EVENT"); local miscPage = newPage("MISC"); local statusPage = newPage("STATUS")

    local function showPage(n)
        for k, p in pairs(pages) do p.Visible = (k==n) end
        for _, o in ipairs(dropLayer:GetChildren()) do if o:IsA("Frame") then o:Destroy() end end
    end
    showPage("ESP")

    local function header(parent, txt)
        new("TextLabel", {Size=UDim2.new(1,0,0,26), BackgroundTransparency=1, Text="  "..txt, Font=F, TextSize=13, TextColor3=C.ACCENT, TextXAlignment=Enum.TextXAlignment.Left, Parent=parent})
    end

    local function panel(parent, h)
        local p = new("Frame", {Size=UDim2.new(1,0,0,h or 56), BackgroundColor3=C.BG2, BorderSizePixel=0, Parent=parent})
        new("UICorner", {CornerRadius=UDim.new(0,12), Parent=p})
        addRainbow(p, 1.2)
        return p
    end

    local function makeToggle(parent, label, default, cb)
        local row = panel(parent, 50)
        new("TextLabel", {Size=UDim2.new(1,-140,1,0), Position=UDim2.fromOffset(18,0), BackgroundTransparency=1, Text=label, Font=F, TextSize=14, TextColor3=C.TEXT, TextXAlignment=Enum.TextXAlignment.Left, Parent=row})
        local stateLbl = new("TextLabel", {Size=UDim2.new(0,40,1,0), Position=UDim2.new(1,-124,0,0), BackgroundTransparency=1, Text=default and "ON" or "OFF", Font=F, TextSize=12, TextColor3=default and C.OK or C.DIM, Parent=row})
        local btn = new("TextButton", {Size=UDim2.fromOffset(56,28), Position=UDim2.new(1,-74,0.5,-14), BackgroundColor3=default and C.ON or C.OFF, Text="", BorderSizePixel=0, AutoButtonColor=false, Parent=row})
        new("UICorner", {CornerRadius=UDim.new(1,0), Parent=btn})
        local knob = new("Frame", {Size=UDim2.fromOffset(22,22), Position=UDim2.new(0,default and 31 or 3,0.5,-11), BackgroundColor3=Color3.fromRGB(255,255,255), BorderSizePixel=0, Parent=btn})
        new("UICorner", {CornerRadius=UDim.new(1,0), Parent=knob})
        local state = default
        btn.MouseButton1Click:Connect(function()
            state = not state
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3=state and C.ON or C.OFF}):Play()
            TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Back), {Position=UDim2.new(0,state and 31 or 3,0.5,-11)}):Play()
            stateLbl.Text = state and "ON" or "OFF"; stateLbl.TextColor3 = state and C.OK or C.DIM
            if cb then cb(state) end
        end)
        return row
    end

    local function makeSlider(parent, label, minV, maxV, default, cb)
        local row = panel(parent, 74)
        local lbl = new("TextLabel", {Size=UDim2.new(1,-24,0,22), Position=UDim2.fromOffset(18,12), BackgroundTransparency=1, Text=label..": "..default, Font=F, TextSize=13, TextColor3=C.TEXT, TextXAlignment=Enum.TextXAlignment.Left, Parent=row})
        local bar = new("Frame", {Size=UDim2.new(1,-36,0,6), Position=UDim2.new(0,18,1,-24), BackgroundColor3=C.BG3, BorderSizePixel=0, Parent=row})
        new("UICorner", {CornerRadius=UDim.new(1,0), Parent=bar})
        local fill = new("Frame", {Size=UDim2.new((default-minV)/(maxV-minV),0,1,0), BackgroundColor3=C.ACCENT, BorderSizePixel=0, Parent=bar})
        new("UICorner", {CornerRadius=UDim.new(1,0), Parent=fill})
        local dragging = false
        local function setFromX(x)
            local rel = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
            fill.Size = UDim2.fromScale(rel, 1)
            local v = math.floor(minV + rel*(maxV-minV))
            lbl.Text = label..": "..v
            if cb then cb(v) end
        end
        bar.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true; setFromX(i.Position.X) end
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then setFromX(i.Position.X) end
        end)
        return row
    end

    local function makeDropdown(parent, label, options, default, cb)
        local row = panel(parent, 58)
        new("TextLabel", {Size=UDim2.new(0,120,1,0), Position=UDim2.fromOffset(18,0), BackgroundTransparency=1, Text=label, Font=F, TextSize=14, TextColor3=C.TEXT, TextXAlignment=Enum.TextXAlignment.Left, Parent=row})
        local cur = default
        local btn = new("TextButton", {Size=UDim2.new(0,140,0,34), Position=UDim2.new(1,-156,0.5,-17), BackgroundColor3=C.BG3, Text=cur, Font=F, TextSize=13, TextColor3=C.TEXT, BorderSizePixel=0, AutoButtonColor=false, ZIndex=10, Parent=row})
        new("UICorner", {CornerRadius=UDim.new(0,8), Parent=btn})

        btn.MouseButton1Click:Connect(function()
            for _, o in ipairs(dropLayer:GetChildren()) do if o:IsA("Frame") then o:Destroy() end end
            local pos = btn.AbsolutePosition
            local sz = btn.AbsoluteSize
            local listH = #options * 36
            local yPos = pos.Y + sz.Y + 4
            if yPos + listH > main.AbsolutePosition.Y + main.AbsoluteSize.Y then
                yPos = pos.Y - listH - 4
            end
            local list = new("Frame", {Size=UDim2.fromOffset(sz.X, listH), Position=UDim2.fromOffset(pos.X, yPos), BackgroundColor3=C.BG3, BorderSizePixel=0, ZIndex=910, Parent=dropLayer})
            new("UICorner", {CornerRadius=UDim.new(0,8), Parent=list})
            addRainbow(list, 1.5)
            for i, opt in ipairs(options) do
                local ob = new("TextButton", {Size=UDim2.new(1,0,0,36), Position=UDim2.fromOffset(0,(i-1)*36), BackgroundColor3=C.BG3, Text=opt, Font=F, TextSize=13, TextColor3=C.TEXT, BorderSizePixel=0, AutoButtonColor=false, Active=true, ZIndex=911, Parent=list})
                new("UICorner", {CornerRadius=UDim.new(0,6), Parent=ob})
                ob.MouseButton1Click:Connect(function()
                    cur = opt; btn.Text = opt
                    list:Destroy()
                    if cb then cb(opt) end
                end)
            end
        end)
        return row, function() return cur end
    end

    local sideBtns, sideY = {}, 10
    local function sideBtn(label)
        local b = new("TextButton", {Size=UDim2.new(1,-20,0,42), Position=UDim2.fromOffset(10,sideY), BackgroundColor3=C.BG, Text=label, Font=F, TextSize=14, TextColor3=C.TEXT, BorderSizePixel=0, AutoButtonColor=false, Parent=sidebar})
        new("UICorner", {CornerRadius=UDim.new(0,10), Parent=b})
        sideY = sideY + 48
        table.insert(sideBtns, b)
        b.MouseButton1Click:Connect(function()
            showPage(label)
            for _, x in ipairs(sideBtns) do TweenService:Create(x, TweenInfo.new(0.2), {BackgroundColor3=C.BG}):Play() end
            TweenService:Create(b, TweenInfo.new(0.2), {BackgroundColor3=C.ACCENT}):Play()
        end)
        return b
    end
    sideBtn("ESP").BackgroundColor3 = C.ACCENT
    sideBtn("AIM"); sideBtn("EVENT"); sideBtn("MISC"); sideBtn("STATUS")

    -- ======================================================
    -- ESP (V1.5.2)
    -- ======================================================
    local ESP = {
        enabled=false, bones=false, box=false, names=false,
        lines=false, health=false,
        thickness=2,
        boneThickness=3,
        hue=0, drawings={},
    }

    local R15_BONES = {{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"}}
    local R6_BONES = {{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}}
    local function bonesFor(ch) if ch:FindFirstChild("UpperTorso") then return R15_BONES end if ch:FindFirstChild("Torso") then return R6_BONES end return R15_BONES end
    local function pColor(plr) local i=1; for n,p in ipairs(Players:GetPlayers()) do if p==plr then i=n break end end; return Color3.fromHSV((ESP.hue+i*0.17)%1, 0.9, 1) end
    local function w2s(pos) local sp,on = Camera:WorldToViewportPoint(pos); if on then return Vector2.new(sp.X,sp.Y) end return nil end
    local function clearESP(plr) if ESP.drawings[plr] then for _,d in ipairs(ESP.drawings[plr]) do pcall(function() d:Remove() end) end ESP.drawings[plr]=nil end end
    local function clearAll() for p in pairs(ESP.drawings) do clearESP(p) end end

    local deathHooks = {}
    local function hookDeath(plr)
        local ch = plr.Character
        if not ch then return end
        if deathHooks[plr] then
            for _,c in ipairs(deathHooks[plr]) do pcall(function() c:Disconnect() end) end
            deathHooks[plr] = nil
        end
        local conns = {}
        local hum = ch:FindFirstChildOfClass("Humanoid")
        if hum then
            table.insert(conns, hum.Died:Connect(function() clearESP(plr) end))
        end
        table.insert(conns, ch.AncestryChanged:Connect(function(_, parent)
            if not parent then clearESP(plr) end
        end))
        deathHooks[plr] = conns
    end

    Players.PlayerAdded:Connect(function(plr)
        plr.CharacterAdded:Connect(function() task.wait(0.2); hookDeath(plr) end)
    end)
    Players.PlayerRemoving:Connect(function(plr)
        clearESP(plr)
        if deathHooks[plr] then
            for _,c in ipairs(deathHooks[plr]) do pcall(function() c:Disconnect() end) end
            deathHooks[plr] = nil
        end
    end)
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP then
            if plr.Character then hookDeath(plr) end
            plr.CharacterAdded:Connect(function() task.wait(0.2); hookDeath(plr) end)
        end
    end

    local function setupESP(plr)
        if plr==LP then return end
        clearESP(plr)
        if not plr.Character then return end
        local d = {}; ESP.drawings[plr] = d; local col = pColor(plr)
        if ESP.bones then
            for _=1,14 do
                local l=Drawing.new("Line")
                l.Visible=false
                l.Thickness=ESP.boneThickness
                l.Color=col
                table.insert(d,l)
            end
        end
        if ESP.box then local b=Drawing.new("Square"); b.Visible=false; b.Thickness=ESP.thickness; b.Color=col; b.Filled=false; table.insert(d,b) end
        if ESP.names then local t=Drawing.new("Text"); t.Visible=false; t.Size=15; t.Center=true; t.Outline=true; t.Color=col; t.Font=2; table.insert(d,t) end
        if ESP.health then local hbg=Drawing.new("Square"); hbg.Visible=false; hbg.Filled=true; hbg.Color=Color3.fromRGB(0,0,0); table.insert(d,hbg); local hb=Drawing.new("Square"); hb.Visible=false; hb.Filled=true; table.insert(d,hb) end
        if ESP.lines then local tr=Drawing.new("Line"); tr.Visible=false; tr.Thickness=ESP.thickness; tr.Color=col; table.insert(d,tr) end
    end

    local function updateESP()
        if not ESP.enabled then
            for _,dd in pairs(ESP.drawings) do for _,x in ipairs(dd) do x.Visible=false end end
            return
        end
        ESP.hue = (ESP.hue+0.003)%1
        for _,plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP then
                local ch = plr.Character
                local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
                local hum = ch and ch:FindFirstChildOfClass("Humanoid")
                if ch and hrp and hum and hum.Health>0 then
                    if not ESP.drawings[plr] then setupESP(plr) end
                    local d = ESP.drawings[plr]; if not d then continue end
                    local col = pColor(plr); local idx = 1
                    if ESP.bones then
                        local bn = bonesFor(ch)
                        for bi,pair in ipairs(bn) do
                            local a,b = ch:FindFirstChild(pair[1]), ch:FindFirstChild(pair[2])
                            local line = d[bi]
                            if a and b and line then
                                local pa,pb = w2s(a.Position), w2s(b.Position)
                                if pa and pb then
                                    line.From=pa; line.To=pb
                                    line.Color=col
                                    line.Thickness=ESP.boneThickness
                                    line.Visible=true
                                else line.Visible=false end
                            elseif line then line.Visible=false end
                        end
                        for j=#bn+1,14 do local l=d[j]; if l then l.Visible=false end end
                        idx = #bn+1
                    end
                    if ESP.box then local sq=d[idx]; idx=idx+1; if sq then local head=ch:FindFirstChild("Head"); local hp=w2s(hrp.Position); local hd=head and w2s(head.Position); if hp and hd then local h=math.abs(hp.Y-hd.Y)*2.3; local w=h*0.55; sq.Size=Vector2.new(w,h); sq.Position=Vector2.new(hp.X-w/2,hp.Y-h/2); sq.Color=col; sq.Thickness=ESP.thickness; sq.Visible=true else sq.Visible=false end end end
                    if ESP.names then local txt=d[idx]; idx=idx+1; if txt then local head=ch:FindFirstChild("Head"); local p=head and w2s(head.Position+Vector3.new(0,1.2,0)); if p then txt.Text=string.format("%s [%d]",plr.Name,math.floor(hum.Health)); txt.Position=p; txt.Color=col; txt.Visible=true else txt.Visible=false end end end
                    if ESP.health then local hbg=d[idx]; idx=idx+1; local hb=d[idx]; idx=idx+1; if hbg and hb then local head=ch:FindFirstChild("Head"); local hp=w2s(hrp.Position); local hd=head and w2s(head.Position); if hp and hd then local h=math.abs(hp.Y-hd.Y)*2.3; local x=hp.X-h*0.55/2-9; local y=hp.Y-h/2; local pct=math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1); hbg.Size=Vector2.new(5,h); hbg.Position=Vector2.new(x,y); hbg.Visible=true; hb.Size=Vector2.new(5,h*pct); hb.Position=Vector2.new(x,y+h*(1-pct)); hb.Color=Color3.fromHSV(0.33*pct,1,1); hb.Visible=true else hbg.Visible=false; hb.Visible=false end end end
                    if ESP.lines then local tr=d[idx]; if tr then local head=ch:FindFirstChild("Head"); local p=head and w2s(head.Position); if p then local vp=Camera.ViewportSize; tr.From=Vector2.new(vp.X/2,vp.Y); tr.To=p; tr.Color=col; tr.Thickness=ESP.thickness; tr.Visible=true else tr.Visible=false end end end
                else
                    if ESP.drawings[plr] then
                        for _,x in ipairs(ESP.drawings[plr]) do x.Visible=false end
                        clearESP(plr)
                    end
                end
            end
        end
    end

    -- ======================================================
    -- AIM (V1.5.2)
    -- ======================================================
    local AIM = {
        lock=false, autokill=false, smooth=true,
        smoothSpeed=0.35, aimPart="Head",
        accuracyPx=250, currentTarget=nil,
        savedCamType=nil,
        stickyUntil=0,
        stickyTarget=nil,
        switchInterval=0.10,
        lastSwitch=0,
    }

    local fovCircle = Drawing.new("Circle")
    fovCircle.Visible=false; fovCircle.Thickness=2; fovCircle.Color=C.ACCENT; fovCircle.Filled=false; fovCircle.NumSides=64

    local function isAlive(plr)
        local ch = plr and plr.Character
        if not ch then return false end
        local hum = ch:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return false end
        if not ch:FindFirstChild("HumanoidRootPart") then return false end
        return true
    end

    local function getAimPart(plr)
        local ch = plr.Character; if not ch then return nil end
        local name = AIM.aimPart
        if name=="Random" then name = math.random()>0.5 and "Head" or (ch:FindFirstChild("UpperTorso") and "UpperTorso" or "Torso") end
        local p = ch:FindFirstChild(name)
        if not p and name=="UpperTorso" then p = ch:FindFirstChild("Torso") end
        return p or ch:FindFirstChild("HumanoidRootPart")
    end

    local function closestTarget(maxPx)
        local vp = Camera.ViewportSize; local center = Vector2.new(vp.X/2, vp.Y/2)
        local best, bestD = nil, maxPx
        for _,plr in ipairs(Players:GetPlayers()) do
            if plr~=LP and isAlive(plr) then
                local part=getAimPart(plr)
                if part then
                    local sp,on=Camera:WorldToViewportPoint(part.Position)
                    if on and sp.Z>0 then
                        local d=(Vector2.new(sp.X,sp.Y)-center).Magnitude
                        if d<bestD then bestD=d; best=plr end
                    end
                end
            end
        end
        return best
    end

    local function updateTarget()
        local now = os.clock()

        if AIM.currentTarget then
            if not isAlive(AIM.currentTarget) then
                AIM.currentTarget = nil
                AIM.stickyTarget = nil
                AIM.stickyUntil = 0
            else
                local part = getAimPart(AIM.currentTarget)
                if part then
                    local sp,on = Camera:WorldToViewportPoint(part.Position)
                    local vp = Camera.ViewportSize
                    local center = Vector2.new(vp.X/2, vp.Y/2)
                    local inFov = on and sp.Z>0 and (Vector2.new(sp.X,sp.Y)-center).Magnitude <= AIM.accuracyPx
                    if not inFov then
                        AIM.currentTarget = nil
                        AIM.stickyTarget = nil
                        AIM.stickyUntil = 0
                    end
                else
                    AIM.currentTarget = nil
                end
            end
        end

        if AIM.currentTarget and now < AIM.stickyUntil and AIM.stickyTarget == AIM.currentTarget then
            return AIM.currentTarget
        end

        if now - AIM.lastSwitch >= AIM.switchInterval or not AIM.currentTarget then
            AIM.lastSwitch = now
            local fresh = closestTarget(AIM.accuracyPx)
            if fresh then
                AIM.currentTarget = fresh
                AIM.stickyTarget = fresh
                AIM.stickyUntil = now + AIM.switchInterval
            else
                AIM.currentTarget = nil
                AIM.stickyTarget = nil
                AIM.stickyUntil = 0
            end
        end

        return AIM.currentTarget
    end

    local function updateAimCameraType()
        local wantScriptable = (AIM.lock or AIM.autokill)
        if wantScriptable then
            if Camera.CameraType ~= Enum.CameraType.Scriptable then
                AIM.savedCamType = Camera.CameraType
                Camera.CameraType = Enum.CameraType.Scriptable
            end
        else
            if AIM.savedCamType and Camera.CameraType == Enum.CameraType.Scriptable then
                Camera.CameraType = AIM.savedCamType
            end
            AIM.savedCamType = nil
        end
    end

    pcall(function() RunService:UnbindFromRenderStep("NX_AimLock") end)
    RunService:BindToRenderStep("NX_AimLock", Enum.RenderPriority.Camera.Value + 1, function(dt)
        updateAimCameraType()
        if not (AIM.lock or AIM.autokill) then
            fovCircle.Visible = false
            AIM.currentTarget = nil
            AIM.stickyTarget = nil
            return
        end
        local vp = Camera.ViewportSize
        fovCircle.Visible = true
        fovCircle.Position = Vector2.new(vp.X/2, vp.Y/2)
        fovCircle.Radius = AIM.accuracyPx

        local t = updateTarget()
        if not t then return end
        local part = getAimPart(t)
        if not part then return end

        local camPos = Camera.CFrame.Position
        local newCF = CFrame.lookAt(camPos, part.Position)
        if AIM.smooth and not AIM.autokill then
            Camera.CFrame = Camera.CFrame:Lerp(newCF, math.clamp(AIM.smoothSpeed, 0.05, 1))
        else
            Camera.CFrame = newCF
        end
    end)

    -- ======================================================
    -- BRUTAL FIRE (V1.5.2)
    -- ======================================================
    local brutalRunning = false
    local function brutalFireOnce(targetPart)
        local ch = LP.Character
        if not ch or not targetPart or not targetPart.Parent then return end
        local tool = ch:FindFirstChildOfClass("Tool")

        local hrp = ch:FindFirstChild("HumanoidRootPart")
        if hrp then
            local myPos = hrp.Position
            local tgtPos = targetPart.Position
            local flat = Vector3.new(tgtPos.X, myPos.Y, tgtPos.Z)
            if (flat - myPos).Magnitude > 0.1 then
                pcall(function() hrp.CFrame = CFrame.lookAt(myPos, flat) end)
            end
        end

        pcall(function()
            Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, targetPart.Position)
        end)

        if tool then
            pcall(function() tool:Activate() end)
            for _, d in ipairs(tool:GetDescendants()) do
                if d:IsA("RemoteEvent") then
                    pcall(function() d:FireServer(targetPart) end)
                elseif d:IsA("RemoteFunction") then
                    pcall(function() d:InvokeServer(targetPart) end)
                end
            end
        end
    end

    local function startBrutal()
        if brutalRunning then return end
        brutalRunning = true
        task.spawn(function()
            while brutalRunning and AIM.autokill do
                local t = AIM.currentTarget
                if not (t and isAlive(t)) then
                    AIM.currentTarget = nil
                    AIM.stickyTarget = nil
                    AIM.stickyUntil = 0
                    t = updateTarget()
                end
                if t and isAlive(t) then
                    local part = getAimPart(t)
                    if part and part.Parent then brutalFireOnce(part) end
                end
                task.wait(0.033)
            end
            brutalRunning = false
        end)
    end
    local function stopBrutal() brutalRunning = false end

    -- ======================================================
    -- FLY
    -- ======================================================
    local Fly = {enabled=false, speed=80, conn=nil, vel=nil, att=nil}
    local function stopFly()
        if Fly.conn then Fly.conn:Disconnect(); Fly.conn=nil end
        if Fly.vel then pcall(function() Fly.vel:Destroy() end); Fly.vel=nil end
        if Fly.att then pcall(function() Fly.att:Destroy() end); Fly.att=nil end
        local ch = LP.Character
        if ch then local hum = ch:FindFirstChildOfClass("Humanoid"); if hum then hum.PlatformStand=false end end
    end
    local function startFly()
        stopFly()
        local ch = LP.Character; if not ch then return end
        local hrp = ch:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        local hum = ch:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = true end
        Fly.att = new("Attachment", {Parent = hrp})
        Fly.vel = new("LinearVelocity", {Attachment0 = Fly.att, MaxForce = math.huge, Velocity = Vector3.zero, Parent = hrp})
        Fly.conn = RunService.RenderStepped:Connect(function()
            if not Fly.enabled then return end
            local cam = Camera
            local move = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0,1,0) end
            if move.Magnitude>0 then move = move.Unit * Fly.speed end
            if Fly.vel then Fly.vel.Velocity = move end
        end)
    end

    -- Noclip
    local Noclip = {enabled=false, conn=nil}
    local function startNoclip()
        if Noclip.conn then return end
        Noclip.conn = RunService.Stepped:Connect(function()
            local ch=LP.Character; if not ch then return end
            for _,p in ipairs(ch:GetDescendants()) do if p:IsA("BasePart") and p.CanCollide then p.CanCollide=false end end
        end)
    end
    local function stopNoclip() if Noclip.conn then Noclip.conn:Disconnect(); Noclip.conn=nil end end

    local Speed = {enabled=false, value=60}
    local Jump = {enabled=false, value=100}
    local InfJump = {enabled=false}
    local AutoClick = {enabled=false, delay=0.1, last=0}

    -- ======================================================
    -- MAIN LOOP
    -- ======================================================
    local espFrame = 0
    RunService.Heartbeat:Connect(function()
        espFrame = espFrame + 1
        if espFrame % 2 == 0 then updateESP() end
        lightScan()

        if Speed.enabled then local hum=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid"); if hum and hum.WalkSpeed~=Speed.value then hum.WalkSpeed=Speed.value end end
        if Jump.enabled then local hum=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid"); if hum and hum.JumpPower~=Jump.value then hum.JumpPower=Jump.value end end
        if InfJump.enabled then local hum=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid"); if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end end
        if AutoClick.enabled then local now=os.clock(); if now-AutoClick.last>=AutoClick.delay then AutoClick.last=now; pcall(function() if mouse1click then mouse1click() elseif mouse1press and mouse1release then mouse1press(); task.wait(0.005); mouse1release() end end) end end
    end)

    LP.CharacterAdded:Connect(function()
        task.wait(1)
        if Fly.enabled then startFly() end
        if Noclip.enabled then startNoclip() end
    end)

    -- ======================================================
    -- PAGE BUILD
    -- ======================================================
    header(espPage, "VISUAL")
    makeToggle(espPage, "ESP Bone / Skeleton", false, function(s) ESP.bones=s; ESP.enabled=s or ESP.box or ESP.names or ESP.lines or ESP.health; clearAll() end)
    makeToggle(espPage, "ESP Box", false, function(s) ESP.box=s; ESP.enabled=s or ESP.bones or ESP.names or ESP.lines or ESP.health; clearAll() end)
    makeToggle(espPage, "ESP Name", false, function(s) ESP.names=s; ESP.enabled=s or ESP.bones or ESP.box or ESP.lines or ESP.health; clearAll() end)
    makeToggle(espPage, "ESP Tracer Line", false, function(s) ESP.lines=s; ESP.enabled=s or ESP.bones or ESP.box or ESP.names or ESP.health; clearAll() end)
    makeToggle(espPage, "ESP Health Bar", false, function(s) ESP.health=s; ESP.enabled=s or ESP.bones or ESP.box or ESP.names or ESP.lines; clearAll() end)
    header(espPage, "STYLE")
    makeSlider(espPage, "Line Thickness", 1, 6, 2, function(v) ESP.thickness=v end)
    makeSlider(espPage, "Skeleton Thickness", 1, 8, 3, function(v) ESP.boneThickness=v end)

    header(aimPage, "AIMBOT")
    makeToggle(aimPage, "Aim Lock", false, function(s) AIM.lock=s end)
    makeToggle(aimPage, "Auto Kill (BRUTAL)", false, function(s) AIM.autokill=s; if s then startBrutal() else stopBrutal() end end)
    makeToggle(aimPage, "Smooth Aim", true, function(s) AIM.smooth=s end)
    makeDropdown(aimPage, "Aim Part", {"Head", "UpperTorso", "Random"}, "Head", function(v) AIM.aimPart=v end)
    makeSlider(aimPage, "Accuracy Radius (px)", 50, 800, 250, function(v) AIM.accuracyPx=v end)
    makeSlider(aimPage, "Smooth Speed", 5, 100, 35, function(v) AIM.smoothSpeed=v/100 end)

    header(eventPage, "AUTO EVENT")
    makeToggle(eventPage, "Auto Prompt (Proximity)", false, function(s) EventSys.autoPrompt=s end)
    makeToggle(eventPage, "Auto Click (ClickDetector)", false, function(s) EventSys.autoClaim=s end)
    makeToggle(eventPage, "Auto Teleport (Name Match)", false, function(s)
        EventSys.autoTeleport = s
        if s and not EventSys.targetCacheBuilt then buildTeleportCache() end
    end)
    makeSlider(eventPage, "Radius", 50, 2000, 400, function(v) EventSys.claimRadius=v end)
    makeSlider(eventPage, "Scan Interval (ms)", 200, 3000, 500, function(v) EventSys.pollRate=v/1000 end)

    header(miscPage, "MOVEMENT")
    makeToggle(miscPage, "Speed Hack", false, function(s) Speed.enabled=s end)
    makeSlider(miscPage, "Walk Speed", 16, 300, 60, function(v) Speed.value=v end)
    makeToggle(miscPage, "Jump Power", false, function(s) Jump.enabled=s end)
    makeSlider(miscPage, "Jump Value", 50, 500, 100, function(v) Jump.value=v end)
    makeToggle(miscPage, "Infinite Jump", false, function(s) InfJump.enabled=s end)
    makeToggle(miscPage, "Fly (LinearVelocity)", false, function(s)
        Fly.enabled=s
        if s then startFly() else stopFly() end
    end)
    makeSlider(miscPage, "Fly Speed", 20, 400, 80, function(v) Fly.speed=v end)
    makeToggle(miscPage, "Noclip", false, function(s)
        Noclip.enabled=s
        if s then startNoclip() else stopNoclip() end
    end)
    header(miscPage, "CLICK")
    makeToggle(miscPage, "Auto Click (Mouse)", false, function(s) AutoClick.enabled=s end)
    makeSlider(miscPage, "Click Delay (ms)", 20, 500, 100, function(v) AutoClick.delay=v/1000 end)

    header(statusPage, "KEY INFO")
    local p1 = panel(statusPage, 100)
    new("TextLabel", {Size=UDim2.new(1,-36,0,22), Position=UDim2.fromOffset(18,12), BackgroundTransparency=1, Text="Role / Tier: "..(entry.tier or "unknown"), Font=F, TextSize=14, TextColor3=C.ACCENT, TextXAlignment=Enum.TextXAlignment.Left, Parent=p1})
    new("TextLabel", {Size=UDim2.new(1,-36,0,22), Position=UDim2.fromOffset(18,40), BackgroundTransparency=1, Text="Expired: "..os.date("%Y-%m-%d %H:%M", expiry), Font=F, TextSize=13, TextColor3=C.TEXT, TextXAlignment=Enum.TextXAlignment.Left, Parent=p1})
    new("TextLabel", {Size=UDim2.new(1,-36,0,22), Position=UDim2.fromOffset(18,68), BackgroundTransparency=1, Text="Sisa: "..math.floor((expiry-os.time())/86400).." hari", Font=F, TextSize=13, TextColor3=C.OK, TextXAlignment=Enum.TextXAlignment.Left, Parent=p1})

    header(statusPage, "SESSION")
    local p2 = panel(statusPage, 120)
    local fpsL = new("TextLabel", {Size=UDim2.new(1,-36,0,22), Position=UDim2.fromOffset(18,12), BackgroundTransparency=1, Text="FPS: --", Font=F, TextSize=13, TextColor3=C.TEXT, TextXAlignment=Enum.TextXAlignment.Left, Parent=p2})
    local plrL = new("TextLabel", {Size=UDim2.new(1,-36,0,22), Position=UDim2.fromOffset(18,40), BackgroundTransparency=1, Text="Players: --", Font=F, TextSize=13, TextColor3=C.TEXT, TextXAlignment=Enum.TextXAlignment.Left, Parent=p2})
    local upL = new("TextLabel", {Size=UDim2.new(1,-36,0,22), Position=UDim2.fromOffset(18,68), BackgroundTransparency=1, Text="Uptime: --", Font=F, TextSize=13, TextColor3=C.TEXT, TextXAlignment=Enum.TextXAlignment.Left, Parent=p2})
    new("TextLabel", {Size=UDim2.new(1,-36,0,22), Position=UDim2.fromOffset(18,96), BackgroundTransparency=1, Text="Executor: "..(identifyexecutor and identifyexecutor() or "Unknown"), Font=F, TextSize=12, TextColor3=C.DIM, TextXAlignment=Enum.TextXAlignment.Left, Parent=p2})

    local startTime=os.time(); local frames, accum = 0, 0
    RunService.RenderStepped:Connect(function(dt)
        frames=frames+1; accum=accum+dt
        if accum>=1 then fpsL.Text="FPS: "..math.floor(frames/accum); frames,accum=0,0 end
        plrL.Text="Players: "..#Players:GetPlayers()
        local up=os.time()-startTime
        upL.Text=string.format("Uptime: %02d:%02d:%02d", math.floor(up/3600), math.floor((up%3600)/60), up%60)
    end)

    header(statusPage, "ABOUT")
    local p3 = panel(statusPage, 100)
    new("TextLabel", {Size=UDim2.new(1,-36,0,22), Position=UDim2.fromOffset(18,12), BackgroundTransparency=1, Text="Version: "..CONFIG.VERSION, Font=F, TextSize=14, TextColor3=C.ACCENT, TextXAlignment=Enum.TextXAlignment.Left, Parent=p3})
    new("TextLabel", {Size=UDim2.new(1,-36,0,22), Position=UDim2.fromOffset(18,40), BackgroundTransparency=1, Text="Dev: "..CONFIG.DEV, Font=F, TextSize=13, TextColor3=C.TEXT, TextXAlignment=Enum.TextXAlignment.Left, Parent=p3})
    new("TextLabel", {Size=UDim2.new(1,-36,0,22), Position=UDim2.fromOffset(18,68), BackgroundTransparency=1, Text="By: "..CONFIG.TEAM, Font=F, TextSize=13, TextColor3=C.TEXT, TextXAlignment=Enum.TextXAlignment.Left, Parent=p3})

    return mainGui
end

-- ==========================================================
-- LOGIN CLICK
-- ==========================================================
local loggingIn = false
loginBtn.MouseButton1Click:Connect(function()
    if loggingIn then return end
    loggingIn = true
    statusLbl.Text = "Memeriksa Key..."
    statusLbl.TextColor3 = C.DIM
    task.spawn(function()
        local ok, entry, expiry = validateKey(keyRaw)
        if ok then
            statusLbl.Text = "Sukses. Memuat Menu..."
            statusLbl.TextColor3 = C.OK
            buildMain(entry, expiry)
            task.wait(0.6)
            if loginGui then loginGui:Destroy() end
        else
            statusLbl.Text = entry or "Gagal."
            statusLbl.TextColor3 = C.ERR
            loggingIn = false
        end
    end)
end)
