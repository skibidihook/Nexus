-- Exploit Environments --
cloneref = cloneref or function(i) return i; end;
clonefunction = clonefunction or function(...) return ...; end;
hookfunction = hookfunction or function(a,b) return a; end;
getgenv = getgenv or getfenv;
protect_gui = protect_gui or protectgui or (syn and syn.protect_gui) or function() end;
getgenv().LPH_NO_VIRTUALIZE = LPH_NO_VIRTUALIZE or function(f) return f end;

if game:GetService('RunService'):IsStudio() then
    local BaseWorkspace = Instance.new('Folder',game:GetService("ReplicatedFirst"));

    BaseWorkspace.Name = "WORKSPACE";

    local __get_path_c = function(path)
        return (string.find(path,'/',1,true) and string.split(path,'/')) or (string.find(path,'\\',1,true) and string.split(path,'\\')) or {path};
    end

    local __get_path = function(path)
        local main = __get_path_c(path);

        local block = BaseWorkspace;

        for i,v in next , main do
            block = block[v];
        end;

        return block;
    end;

    getgenv().readfile = function(path)
        local path : StringValue = __get_path(path);

        return path.Value;
    end;

    getgenv().isfile = function(path)
        local success , message = pcall(function()
            return __get_path(path);
        end);

        if success and not message:IsA("Folder") then
            return true;
        end;

        return false;
    end;

    getgenv().isfolder = function(path)
        local success , message = pcall(function()
            return __get_path(path);
        end);

        if success and message:IsA("Folder") then
            return true;
        end;

        return false;
    end;

    getgenv().writefile = function(path,content)
        local main = __get_path_c(path);

        local block = BaseWorkspace;

        for i,v in next , main do
            local item = block:FindFirstChild(v);
            if not item then
                local c = Instance.new('StringValue',block);

                c.Name = tostring(v);
                c.Value = content;
            else
                if item:IsA('StringValue') and tostring(item) == v then
                    item.Name = tostring(v);
                    item.Value = content;
                end;

                block = item;
            end;
        end;
    end;

    getgenv().listfiles = function(path)
        local fold = __get_path(path);
        local pa = {};

        for i,v in next , fold:GetChildren() do
            if v:IsA('StringValue') then
                table.insert(pa,path..'/'..tostring(v));
            end;
        end;

        return pa;
    end;

    getgenv().makefolder = function(path)
        local main = __get_path_c(path);

        local block = BaseWorkspace;

        for i,v in next , main do
            local item = block:FindFirstChild(v);
            if not item then
                local c = Instance.new('Folder',block);

                c.Name = tostring(v);
            else
                block = item;
            end;
        end;
    end;

    getgenv().delfile = function(path)
        local main = __get_path_c(path);

        local block = BaseWorkspace;

        for i,v in next , main do
            local item = block:FindFirstChild(v);
            if item and item:IsA('StringValue') then
                item:Destroy();
            else
                block = item;
            end;
        end;
    end;
end;

local function PlaySound(id, volume, speed)
    local notif = getgenv().notifaction
    local privacy = notif and type(notif.GetPrivacyMode) == "function" and notif:GetPrivacyMode()
    if privacy then return end

    if not id then return end

    local coregui = game:GetService("CoreGui")
    local folder = Instance.new("Folder")
    folder.Name = "snd_" .. tostring(math.random(100000,999999)) .. "_" .. os.time()
    folder.Parent = coregui
    folder.Archivable = false

    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://" .. tostring(id)
    sound.Volume = volume or 5
    sound.PlaybackSpeed = speed or 1
    sound.Parent = folder
    sound.Looped = false
    sound:Play()

    sound.Ended:Connect(function()
        sound:Destroy()
        folder:Destroy()
    end)
end

repeat
    task.wait()
until game:IsLoaded()

if not LPH_OBFUSCATED then
    LPH_ENCSTR = function(...)
        return ...
    end
    LPH_ENCNUM = function(...)
        return ...
    end
    LPH_CRASH = function(...)
        return (nil)()
    end
    LPH_JIT = function(...)
        return ...
    end
    LPH_JIT_MAX = function(...)
        return ...
    end
    LPH_NO_VIRTUALIZE = function(...)
        return ...
    end
    LPH_NO_UPVALUES = function(...)
        return ...
    end
end

--═══════════════════════════════════════════════════════════════
--	SERVICES
--═══════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local InsertService = game:GetService("InsertService")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- Utility services
local LightingService = game:GetService('Lighting')
local CoreGuiF = gethui and gethui() or CoreGui  -- For Loading Circle shi

local LocalPlayer = Players.LocalPlayer
local PlayerList = Players:GetPlayers()
local char = LocalPlayer.Character

--═══════════════════════════════════════════════════════════════
--	UTILITY FUNCTIONS / HELPERS
--═══════════════════════════════════════════════════════════════

-- wsg

--═══════════════════════════════════════════════════════════════
--	UTILITY VARIABLES
--═══════════════════════════════════════════════════════════════


--═══════════════════════════════════════════════════════════════
--	CUSTOM PRINT SYSTEM
--═══════════════════════════════════════════════════════════════

do
local function generaterandomdigits()
    local lengths = {3, 4, 5, 7, 8, 9, 10, 11, 12, 13, 14, 15}
    local length = lengths[math.random(1, #lengths)]
    local chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
    local num = ""
    for i = 1, length do
        local idx = math.random(1, #chars)
        num = num .. chars:sub(idx, idx)
    end
    return num
end

local separatorid = generaterandomdigits()
local loadingid = generaterandomdigits()
local separatorid2 = generaterandomdigits()

local starttime = tick()
local loadingduration = 2
local maxblocks = 25

local separatormsg = nil
local loadingmsg = nil
local separatormsg2 = nil

local loadingphases = {
    {min = 0, max = 20, text = "Initializing Nexus API", icon = "◇"},
    {min = 20, max = 40, text = "Establishing Secure Connection", icon = "◆"},
    {min = 40, max = 60, text = "Authenticating Credentials", icon = "◇"},
    {min = 60, max = 75, text = "Loading Nexus UI", icon = "◆"},
    {min = 75, max = 90, text = "Syncing Components", icon = "◇"},
    {min = 90, max = 100, text = "Finalizing Connection", icon = "◆"}
}



local function getphaseinfo(progress)
    for _, phase in ipairs(loadingphases) do
        if progress >= phase.min and progress < phase.max then
            return phase.text, phase.icon
        end
    end
    return loadingphases[#loadingphases].text, loadingphases[#loadingphases].icon
end

local function generateloadingbar(progress)
    local filled = math.floor((progress / 100) * maxblocks)
    local empty = maxblocks - filled

    local bar = ""
    for i = 1, filled do
        bar = bar .. "<font color='rgb(180,120,255)'>■</font>"
    end
    bar = bar .. string.rep("<font color='rgb(80,80,120)'>□</font>", empty)

    local percentage = math.floor(progress)
    local phasetext, icon = getphaseinfo(percentage)
    local pulse = math.sin(tick() * 3) * 0.5 + 0.5
    local pulsecolor = 180 + math.floor(pulse * 75)

    return string.format(
        "<font color='rgb(129,31,255)'>[ NEXUS ]</font> <font color='rgb(%d,100,255)'>%s</font> %s <font color='rgb(255,255,255)'>%d%%</font> <font color='rgb(150,150,180)'>│</font> <font color='rgb(200,180,255)'>%s</font>",
        pulsecolor, icon, bar, percentage, phasetext
    )
end

local function getcurrentprogress()
    local elapsed = tick() - starttime
    local progress = (elapsed / loadingduration) * 100
    
    if progress >= 100 then
        return 100
    end
    
    return progress
end

local function isloadingcomplete()
    return getcurrentprogress() >= 100
end

print(separatorid)
print(loadingid)
print(separatorid2)

local function findloglines(clientlog)
    local children = clientlog:GetChildren()
    for i = #children, 1, -1 do
        local logentry = children[i]
        if logentry:FindFirstChild("msg") then
            local msgobj = logentry.msg
            if msgobj:IsA("TextLabel") then
                local text = msgobj.Text
                
                if text:find(separatorid) then
                    separatormsg = msgobj
                    local timestamp = text:match("^%d+:%d+:%d+%s+") or ""
                    if not isloadingcomplete() then
                        msgobj.Text = timestamp .. "<font color='rgb(60,60,80)'>━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━</font>"
                    else
                        msgobj.Text = timestamp .. "<font color='rgb(129,31,255)'>━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━</font>"
                    end
                    msgobj.RichText = true
                elseif text:find(loadingid) then
                    loadingmsg = msgobj
                    local timestamp = text:match("^%d+:%d+:%d+%s+") or ""
                    if isloadingcomplete() then
                        msgobj.Text = timestamp .. "<font color='rgb(129,31,255)'>[ NEXUS ]</font> <font color='rgb(100,255,150)'>✓ CONNECTED</font> <font color='rgb(100,100,140)'>│</font> <font color='rgb(150,255,180)'>Script ready • All modules loaded</font>"
                    else
                        local currentprogress = getcurrentprogress()
                        msgobj.Text = timestamp .. generateloadingbar(currentprogress)
                    end
                    msgobj.RichText = true
                elseif text:find(separatorid2) then
                    separatormsg2 = msgobj
                    local timestamp = text:match("^%d+:%d+:%d+%s+") or ""
                    if not isloadingcomplete() then
                        msgobj.Text = timestamp .. "<font color='rgb(60,60,80)'>━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━</font>"
                    else
                        msgobj.Text = timestamp .. "<font color='rgb(129,31,255)'>━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━</font>"
                    end
                    msgobj.RichText = true
                end
            end
        end
    end
end

local function updatelines()
    if separatormsg and separatormsg.Parent then
        local timestamp = separatormsg.Text:match("^%d+:%d+:%d+%s+") or ""
        if not isloadingcomplete() then
            separatormsg.Text = timestamp .. "<font color='rgb(60,60,80)'>━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━</font>"
        else
            separatormsg.Text = timestamp .. "<font color='rgb(129,31,255)'>━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━</font>"
        end
        separatormsg.RichText = true
    else
        separatormsg = nil
    end
    
    if loadingmsg and loadingmsg.Parent then
        local timestamp = loadingmsg.Text:match("^%d+:%d+:%d+%s+") or ""
        if isloadingcomplete() then
            loadingmsg.Text = timestamp .. "<font color='rgb(129,31,255)'>[ NEXUS ]</font> <font color='rgb(100,255,150)'>✓ CONNECTED</font> <font color='rgb(100,100,140)'>│</font> <font color='rgb(150,255,180)'>Script ready • All modules loaded</font>"
        else
            local currentprogress = getcurrentprogress()
            loadingmsg.Text = timestamp .. generateloadingbar(currentprogress)
        end
        loadingmsg.RichText = true
    else
        loadingmsg = nil
    end
    
    if separatormsg2 and separatormsg2.Parent then
        local timestamp = separatormsg2.Text:match("^%d+:%d+:%d+%s+") or ""
        if not isloadingcomplete() then
            separatormsg2.Text = timestamp .. "<font color='rgb(60,60,80)'>━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━</font>"
        else
            separatormsg2.Text = timestamp .. "<font color='rgb(129,31,255)'>━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━</font>"
        end
        separatormsg2.RichText = true
    else
        separatormsg2 = nil
    end
end

local function console()
    local devconsole = CoreGui:FindFirstChild("DevConsoleMaster")
    if devconsole and devconsole:FindFirstChild("DevConsoleWindow") then
        local mainview = devconsole.DevConsoleWindow:FindFirstChild("DevConsoleUI") and devconsole.DevConsoleWindow.DevConsoleUI:FindFirstChild("MainView")
        if mainview and mainview:FindFirstChild("ClientLog") then
            findloglines(mainview.ClientLog)
            updatelines()
        end
    end
end

RunService.Heartbeat:Connect(console)
end

task.wait(1)

--═══════════════════════════════════════════════════════════════
--	PLAYSOUND SYSTEM
--═══════════════════════════════════════════════════════════════

local function PlaySound(id, volume, speed)
    local notif = getgenv().notifaction
    local privacy = notif and type(notif.GetPrivacyMode) == "function" and notif:GetPrivacyMode()
    if privacy then return end

    if not id then return end

    local folder = Instance.new("Folder")
    folder.Name = "snd_" .. tostring(math.random(100000,999999)) .. "_" .. os.time()
    folder.Parent = CoreGui
    folder.Archivable = false

    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://" .. tostring(id)
    sound.Volume = volume or 5
    sound.PlaybackSpeed = speed or 1
    sound.Parent = folder
    sound.Looped = false
    sound:Play()

    sound.Ended:Connect(function()
        sound:Destroy()
        folder:Destroy()
    end)
end

--═══════════════════════════════════════════════════════════════
--	NEXUS GUI SYSTEM
--═══════════════════════════════════════════════════════════════

local screenSize =      workspace.CurrentCamera.ViewportSize
local isMobile =        UserInputService.TouchEnabled or (screenSize.X < 1024 and screenSize.Y < 768)
local dragOffset =        255
local dragOffsetMobile =  150
local camera =          workspace.CurrentCamera

local sharedModule = {}
local resizing = false

local Loader =          game:GetObjects("rbxassetid://110221114597158")[1]
local Library =         game:GetObjects("rbxassetid://89761418653710")[1]

Library.Enabled = false
local loaded = false

local syde = {

	theme = {
		['Accent'] = Color3.fromRGB(129, 31, 255);
		['HitBox'] = Color3.fromRGB(255, 255, 255);
		['DropShadow']   = Color3.fromRGB(0, 0, 0);

	};
	Connections = {};
	Comms = Instance.new('BindableEvent');
	ParentOverride = nil;
	Build = 'NX3';
	ConfigEnabled = true;
	ConfigFolder = 'Nexus';
	ConfigFile = 'Config';
	Flags = {};
	SettingsFlags = {};
}


-- [ THEME MANAGEMENT ]
function syde:UpdateTheme(Config)
	if type(Config) ~= "table" then
		return
	end

	local updatedKeys = {}

	for key, value in pairs(Config) do
		if self.theme[key] ~= nil then
			if typeof(self.theme[key]) == typeof(value) then
				if type(value) == "table" then
					self:DeepMerge(self.theme[key], value)
				else
					self.theme[key] = value
				end
				table.insert(updatedKeys, key)
			else
			end
		else
		end
	end

	if #updatedKeys > 0 then
		for _, key in ipairs(updatedKeys) do
			self.Comms:Fire(key, self.theme[key])
		end
	end
end

function syde:DeepMerge(target, source)
	for k, v in pairs(source) do
		if type(v) == "table" and type(target[k]) == "table" then
			self:DeepMerge(target[k], v) 
		else
			target[k] = v
		end
	end
end

-- [UTILITIES]

function syde:getdark(Color, val, mode)
	if typeof(Color) ~= "Color3" or type(val) ~= "number" then
		return Color
	end

	local H, S, V = Color:ToHSV()

	val = math.clamp(val, 0.1, 10) 

	if mode == "subtract" then
		V = math.clamp(V - (val / 10), 0, 1)  
	else
		V = math.clamp(V / val, 0, 1)  
	end

	return Color3.fromHSV(H, S, V)
end

function syde:HidePlaceHolder(instance, placeholder, recursive)
	if typeof(instance) ~= "Instance" or type(placeholder) ~= "string" then
		return
	end

	local target = instance:FindFirstChild(placeholder)

	if not target then
		return
	end

	if target:IsA("GuiObject") then
		target.Visible = false
	else
		return
	end

	if recursive then
		for _, child in ipairs(target:GetDescendants()) do
			if child:IsA("GuiObject") then
				child.Visible = false
			end
		end
	end
end

function syde:AddConnection(Type, Callback)
	if typeof(Type) ~= "RBXScriptSignal" then
		error("[AddConnection] Invalid Type: Expected RBXScriptSignal, got " .. typeof(Type))
	end
	if typeof(Callback) ~= "function" then
		error("[AddConnection] Invalid Callback: Expected function, got " .. typeof(Callback))
	end

	local Connection = Type:Connect(Callback)
	local ConnectionData = { Connection = Connection }

	syde.Connections = syde.Connections or {}
	table.insert(syde.Connections, ConnectionData)

	local function Disconnect()
		if Connection.Connected then
			Connection:Disconnect()
		end

		for i = #syde.Connections, 1, -1 do
			if syde.Connections[i] == ConnectionData then
				table.remove(syde.Connections, i)
				break
			end
		end
	end

	task.spawn(function()
		task.wait(10)
		for i = #syde.Connections, 1, -1 do
			if not syde.Connections[i].Connection.Connected then
				table.remove(syde.Connections, i)
			end
		end
	end)

	return Connection, Disconnect
end

function syde:MakeResizable(Dragger, Object, MinSize, Callback, LockAspectRatio)
	assert(typeof(Dragger) == "Instance" and Dragger:IsA("GuiObject"), "[MakeResizable] Dragger must be a GuiObject")
	assert(typeof(Object) == "Instance" and Object:IsA("GuiObject"), "[MakeResizable] Object must be a GuiObject")
	assert(typeof(MinSize) == "Vector2", "[MakeResizable] MinSize must be a Vector2")
	assert(Callback == nil or typeof(Callback) == "function", "[MakeResizable] Callback must be a function or nil")


	local startPosition, startSize = nil, nil
	local isResizing = false

	-- helper for both mouse and touch
	local function getInputPos(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			return Vector2.new(input.Position.X, input.Position.Y)
		else
			return UserInputService:GetMouseLocation()
		end
	end

	local function onInputBegan(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isResizing = true
			resizing = true
			startPosition = getInputPos(input)
			startSize = Object.AbsoluteSize
			TweenService:Create(Library.lib.resize, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Size = UDim2.new(0, 15,0, 15)}):Play()
		end
	end

	local function onInputChanged(input)
		if isResizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local mouse = getInputPos(input)
			if startPosition and mouse then
				local delta = mouse - startPosition

				local newWidth = math.max(MinSize.X, startSize.X + delta.X)
				local newHeight = math.max(MinSize.Y, startSize.Y + delta.Y)

				if LockAspectRatio then
					local aspectRatio = startSize.X / startSize.Y
					newHeight = newWidth / aspectRatio
				end

				Object:TweenSize(
					UDim2.fromOffset(newWidth, newHeight),
					Enum.EasingDirection.Out,
					Enum.EasingStyle.Quint,
					0.7,
					true
				)

				if Callback then
					Callback(Vector2.new(newWidth, newHeight))
				end
			end
		end
	end

	local function onInputEnded(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isResizing = false
			resizing = false
			startPosition, startSize = nil, nil
			TweenService:Create(Library.lib.resize, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Size = UDim2.new(0, 20,0, 20)}):Play()
		end
	end

	syde:AddConnection(Dragger.InputBegan, onInputBegan)
	syde:AddConnection(UserInputService.InputChanged, onInputChanged)
	syde:AddConnection(Dragger.InputEnded, onInputEnded)
end

local loadTweens = {}

function syde:registerLoadTween(object, properties, initialState, tweenInfo)
	assert(typeof(object) == "Instance", "[registerLoadTween] Object must be an Instance")
	assert(typeof(properties) == "table", "[registerLoadTween] Properties must be a table")
	assert(typeof(initialState) == "table", "[registerLoadTween] Initial state must be a table")
	assert(typeof(tweenInfo) == "TweenInfo", "[registerLoadTween] TweenInfo must be of type TweenInfo")

	loadTweens[object] = {
		tween = TweenService:Create(object, tweenInfo, properties),
		properties = properties,
		initialState = initialState,
		tweenInfo = tweenInfo
	}
end

function syde:resetToInitialState(animated, resetTweenInfo)
	for object, tweenData in pairs(loadTweens) do
		if object and object.Parent then
			tweenData.tween:Cancel()

			if animated then
				local resetTween = TweenService:Create(object, resetTweenInfo or TweenInfo.new(0.3), tweenData.initialState)
				resetTween:Play()
				resetTween.Completed:Wait()
			else

				for property, value in pairs(tweenData.initialState) do
					object[property] = value
				end
			end
		end
	end
end

function syde:replayLoadTweens(targetObject)
	syde:resetToInitialState(false)

	for object, tweenData in pairs(loadTweens) do
		if object and object.Parent then
			if not targetObject or object == targetObject then
				tweenData.tween:Cancel()
				tweenData.tween:Play()
			end
		end
	end
end

function syde:removeLoadTween(object)
	if loadTweens[object] then
		loadTweens[object].tween:Cancel()
		loadTweens[object] = nil
	end
end

function syde:ColorPack(color)
	assert(typeof(color) == "Color3", "PackColor expects a Color3 value.")

	-- Convert to RGB integer values
	return {
		R = math.round(color.R * 255),
		G = math.round(color.G * 255),
		B = math.round(color.B * 255)
	}
end

function syde:ColorUnpack(color)
	assert(type(color) == "table" or type(color) == "string", "Invalid color format. Expected table (RGB) or string (HEX).")

	if type(color) == "table" then

		assert(color.R and color.G and color.B, "RGB table must contain 'R', 'G', and 'B' keys.")
		return Color3.fromRGB(math.clamp(color.R, 0, 255), math.clamp(color.G, 0, 255), math.clamp(color.B, 0, 255))
	elseif type(color) == "string" then

		local hex = color:match("^#?(%x%x%x%x%x%x)$")
		assert(hex, "Invalid HEX color format. Expected '#RRGGBB' or 'RRGGBB'.")
		local r, g, b = tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
		return Color3.fromRGB(r, g, b)
	end
end




function syde:updateLayout(container, spacing)
	spacing = spacing or 5
	local yOffset = 0
	local containerWidth = container.AbsoluteSize.X 

	for _, v in ipairs(container:GetChildren()) do
		if v:IsA('UIListLayout') then
			v:Destroy()
		end
	end

	if resizing == false then
		for _, child in ipairs(container:GetChildren()) do
			if (child:IsA("Frame") or child:IsA("ImageLabel") or child:IsA("TextLabel") or child:IsA("TextButton")) and child.Visible then
				--child.Size = UDim2.new(1, -10, 0, child.Size.Y.Offset) -- Full width, fixed height
				-- child.Position = UDim2.new(0, 0, 0, yOffset)
				TweenService:Create(child, TweenInfo.new(0.45, Enum.EasingStyle.Exponential), {Position = UDim2.new(0, 0, 0, yOffset)}):Play()
				yOffset = yOffset + child.AbsoluteSize.Y + spacing
			end
		end
	end


	container.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

local dragSpeed = 0.6
local LockToScreen = false

function syde:AddDrag(Object, Main, ConstrainToParent)
	assert(typeof(Object) == "Instance" and Object:IsA("GuiObject"), "[AddDrag] Object must be a GuiObject")
	assert(typeof(Main) == "Instance" and Main:IsA("GuiObject"), "[AddDrag] Main must be a GuiObject")


	local dragging, dragInput, startMousePos, startFramePos = false, nil, nil, nil

	local function getConstrainedPosition(newPos)
		if not LockToScreen then
			return newPos
		end

		local screenSize = workspace.CurrentCamera.ViewportSize
		local frameSize = Main.AbsoluteSize
		local anchorPoint = Main.AnchorPoint

		-- Calculate the absolute position based on newPos
		local absX = newPos.X.Offset
		local absY = newPos.Y.Offset

		local minX = 0 + (frameSize.X * anchorPoint.X)
		local maxX = screenSize.X - (frameSize.X * (1 - anchorPoint.X))

		local minY = 0 + (frameSize.Y * anchorPoint.Y)
		local maxY = screenSize.Y - (frameSize.Y * (1 - anchorPoint.Y))

		local clampedX = math.clamp(absX, minX, maxX)
		local clampedY = math.clamp(absY, minY, maxY)

		return UDim2.new(0, clampedX, 0, clampedY)
	end

	local function getInputPos(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			return Vector2.new(input.Position.X, input.Position.Y)
		else
			return UserInputService:GetMouseLocation()
		end
	end




	syde:AddConnection(Object.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			startMousePos = getInputPos(input)

			local screenSize = workspace.CurrentCamera.ViewportSize
			local absX = screenSize.X * Main.Position.X.Scale + Main.Position.X.Offset
			local absY = screenSize.Y * Main.Position.Y.Scale + Main.Position.Y.Offset

			Main.Position = UDim2.new(0, absX, 0, absY)
			startFramePos = Main.Position
		end
	end)


	syde:AddConnection(UserInputService.InputChanged, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local currentMousePos = getInputPos(input)
			if currentMousePos and startMousePos then
				local delta = currentMousePos - startMousePos

				local newPos = UDim2.new(
					startFramePos.X.Scale, startFramePos.X.Offset + delta.X,
					startFramePos.Y.Scale, startFramePos.Y.Offset + delta.Y
				)

				Main:TweenPosition(getConstrainedPosition(newPos), Enum.EasingDirection.Out, Enum.EasingStyle.Quint, dragSpeed, true)
			end
		end
	end)

	syde:AddConnection(Object.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end

local notifications = {}
local notificationSpacing = 10

local tweenInfo = TweenInfo.new(0.7, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

function updatePositions()
	local screenHeight = workspace.CurrentCamera.ViewportSize.Y - 200
	local currentY = screenHeight

	for i = #notifications, 1, -1 do
		local notif = notifications[i]
		local targetPosition = UDim2.new(0, 250, 0, currentY - notif.Size.Y.Offset + 60) 
		TweenService:Create(notif, tweenInfo, { Position = targetPosition }):Play()
		currentY = currentY - (notif.Size.Y.Offset + notificationSpacing)
	end
end

for _, temp in ipairs(Library.Notification:GetChildren()) do
	if temp:IsA("Frame") then
		temp.Visible = false
	end
end 

local activeModals = 0 -- track how many modals are currently open

function syde:Modal(Modal)
	task.spawn(function()
		local ModalData = {
			Title = Modal.Title;
			Content = Modal.Content;
			ConfirmCallBack = Modal.ConfimCallBack
		}

		local ModalInstance = Library.lib.Modal:Clone()
		ModalInstance.Visible = true
		ModalInstance.Parent = Library.lib
		ModalInstance.Title.Text = ModalData.Title
		ModalInstance.Content.Text = ModalData.Content
		--	ModalInstance.Content.Size = UDim2.new(1, ModalInstance.Content.Size.X.Offset, 1, ModalInstance.Content.TextBounds.Y)
		ModalInstance.Size = UDim2.new(0, 135,0, 144)
		ModalInstance.BackgroundTransparency = 1
		ModalInstance.Title.TextTransparency = 1
		ModalInstance.Content.TextTransparency = 1

		ModalInstance.Buttons.Confirm.BackgroundTransparency = 1
		ModalInstance.Buttons.Confirm.TextLabel.TextTransparency = 1
		ModalInstance.Buttons.Confirm.UIStroke.Transparency = 1

		ModalInstance.Buttons.Cancel.BackgroundTransparency = 1
		ModalInstance.Buttons.Cancel.TextLabel.TextTransparency = 1
		ModalInstance.Buttons.Cancel.UIStroke.Transparency = 1

		local function openModal()
			TweenService:Create(ModalInstance.Content, TweenInfo.new(0.75, Enum.EasingStyle.Quint), {Size = UDim2.new(1, ModalInstance.Content.Size.X.Offset, 1, ModalInstance.Content.TextBounds.Y)}):Play()
			activeModals += 1
			--	ModalInstance.Size = UDim2.new(0, ModalInstance.Size.X.Offset, 0, ModalInstance.Content.TextBounds.Y + 120)
			TweenService:Create(ModalInstance, TweenInfo.new(0.65, Enum.EasingStyle.Quint), {Size = UDim2.new(0, 455,0,  ModalInstance.Content.TextBounds.Y + 120)}):Play()

			TweenService:Create(ModalInstance, TweenInfo.new(1, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
			TweenService:Create(ModalInstance.UIStroke, TweenInfo.new(1, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
			TweenService:Create(ModalInstance.Title, TweenInfo.new(1, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
			TweenService:Create(ModalInstance.Content, TweenInfo.new(1, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()

			TweenService:Create(ModalInstance.Buttons.Confirm, TweenInfo.new(1, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.5}):Play()
			TweenService:Create(ModalInstance.Buttons.Confirm.TextLabel, TweenInfo.new(1, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
			TweenService:Create(ModalInstance.Buttons.Confirm.UIStroke, TweenInfo.new(1, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()

			TweenService:Create(ModalInstance.Buttons.Cancel, TweenInfo.new(1, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
			TweenService:Create(ModalInstance.Buttons.Cancel.TextLabel, TweenInfo.new(1, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
			TweenService:Create(ModalInstance.Buttons.Cancel.UIStroke, TweenInfo.new(1, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()

		end
		openModal()

		local function closeModal()
			activeModals -= 1
			-- ModalInstance.Buttons.Cancel.Interactable = false
			-- ModalInstance.Buttons.Confirm.Interactable = false
			TweenService:Create(ModalInstance, TweenInfo.new(0.75, Enum.EasingStyle.Quint), {Size = UDim2.new(0, 219,0, 147)}):Play()
			TweenService:Create(ModalInstance, TweenInfo.new(1, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
			-- TweenService:Create(ModalInstance.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
			-- TweenService:Create(ModalInstance.UIStroke, TweenInfo.new(1, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
			-- TweenService:Create(ModalInstance.Content, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()

			-- TweenService:Create(ModalInstance.Buttons.Confirm, TweenInfo.new(1, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
			-- TweenService:Create(ModalInstance.Buttons.Confirm.TextLabel, TweenInfo.new(1, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
			-- TweenService:Create(ModalInstance.Buttons.Confirm.UIStroke, TweenInfo.new(1, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()

			-- TweenService:Create(ModalInstance.Buttons.Cancel, TweenInfo.new(1, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
			-- TweenService:Create(ModalInstance.Buttons.Cancel.TextLabel, TweenInfo.new(1, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
			-- TweenService:Create(ModalInstance.Buttons.Cancel.UIStroke, TweenInfo.new(1, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
			task.wait(0.45)
			ModalInstance:Destroy()
		end



		if activeModals == 1 then
			Library.lib.dim.Visible = true
			TweenService:Create(Library.lib.dim, TweenInfo.new(0.73, Enum.EasingStyle.Exponential), {
				BackgroundTransparency = 0.3
			}):Play()
		end

		ModalInstance.Buttons.Confirm.MouseButton1Click:Connect(function()
			if typeof(ModalData.ConfirmCallBack) == "function" then
				ModalData.ConfirmCallBack()
			end


			closeModal()

			--[[if activeModals == 0 then
				TweenService:Create(Library.lib.dim, TweenInfo.new(0.73, Enum.EasingStyle.Exponential), {
					BackgroundTransparency = 1
				}):Play()
				task.wait(0.7)
				Library.lib.dim.Visible = false
			end
            --]]
		end)

		ModalInstance.Buttons.Cancel.MouseButton1Click:Connect(function()
			closeModal()
			TweenService:Create(Library.lib.dim, TweenInfo.new(0.73, Enum.EasingStyle.Exponential), {
				BackgroundTransparency = 1
			}):Play()
			task.wait(0.7)
			Library.lib.dim.Visible = false
		end)

	end)
end

--[[
function syde:Notify(Notification)
	task.spawn(function()

		local NotifData = {
			Title = Notification.Title;
			Content = Notification.Content;
			Duration = Notification.Duration or 5;
		}

		local Notification = Library.Notification.Default:Clone()
		Notification.Visible = true
		Notification.Parent = Library.Notification
		Notification.Title.Text = NotifData.Title
		Notification.Content.Text = NotifData.Content
		Notification.Content.Size = UDim2.new(0, 200,0, Notification.Content.TextBounds.Y )
		Notification.Size = UDim2.new(1, 0,0, Notification.Content.TextBounds.Y + 50)

		table.insert(notifications, Notification)
		updatePositions()

		Notification.UIScale.Scale = 0.9
		Notification.close.ImageTransparency = 0.95
		Notification.BackgroundTransparency = 0.75
		Notification.Title.TextTransparency = 0.5
		Notification.Content.TextTransparency = 0.78

		Notification.Position = UDim2.new(0, 600, 0, 637)

		local function CloseNotif()

			if Notification and Notification.Parent then
				table.remove(notifications, table.find(notifications, Notification))
				TweenService:Create(Notification.UIScale, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Scale = 0.9}):Play()
				TweenService:Create(Notification.close, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {ImageTransparency = 0.95}):Play()
				TweenService:Create(Notification, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.75}):Play()
				TweenService:Create(Notification.Title, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 0.5}):Play()
				TweenService:Create(Notification.Content, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 0.78}):Play()

				task.wait(0.15)

				TweenService:Create(Notification, TweenInfo.new(0.95, Enum.EasingStyle.Exponential), {Position = UDim2.new(0, Notification.Position.X.Offset + 400, 0, Notification.Position.Y.Offset) }):Play()
				task.wait(0.4)
				Notification:Destroy()
				updatePositions()
			end

		end

		task.wait(0.45)

		TweenService:Create(Notification.UIScale, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Scale = 1}):Play()
		TweenService:Create(Notification.close, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {ImageTransparency = 0.75}):Play()
		TweenService:Create(Notification, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
		TweenService:Create(Notification.Title, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
		TweenService:Create(Notification.Content, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()

		Notification.close.MouseEnter:Connect(function()
			TweenService:Create(Notification.close, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {ImageTransparency = 0.25}):Play()
		end)

		Notification.close.MouseLeave:Connect(function()
			TweenService:Create(Notification.close, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {ImageTransparency = 0.75}):Play()
		end)

		Notification.close.MouseButton1Click:Connect(function()
			CloseNotif()
		end)

		task.delay(NotifData.Duration, function()
			CloseNotif()
		end)
	end)
end
--]]

--[LOADER INIALIZE]
do

	function syde:Load(Config)
		local LOADER = Loader
		LOADER.Enabled = true
		LOADER.Parent = CoreGui

		-- PreLoad
		Config.Name = Config.Name or 'Nexus™'
		Config.Logo = Config.Logo or 'rbxassetid://14554547135'
		Config.ConfigFolder = Config.ConfigFolder or 'nexus'
		Config.Status = Config.Status or false
		Config.Accent = Config.Accent or syde.theme.Accent
		Config.HitBox = Config.HitBox or syde.theme.HitBox

		local LoaderConfig = {
			Name = Config.Name;
			Logo = 'rbxassetid://'..Config.Logo;
			ConfigFolder = Config.ConfigFolder;
			Status = Config.Status;
			Accent = Config.Accent or syde.theme.Accent;
			Hitbox = Config.HitBox or syde.theme.HitBox;
			Socials = {}
		}

		local TweenWorkPos = 315
		local TweenWorkAppear = 287
		local TweenWorkDisappear = 270

		local Styles = {
			GitHub = {
				BackGroundColor = Color3.fromRGB(39, 39, 39);
				GradColor = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(129, 129, 129))};
				StrokeColor = Color3.fromRGB(34, 34, 34)
			},
			Discord = {
				BackGroundColor = Color3.fromRGB(88, 141, 255);
				GradColor = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(91, 125, 147))};
				StrokeColor = Color3.fromRGB(88, 141, 255)
			},
			Site = {
				BackGroundColor = Color3.fromRGB(39, 11, 34);
				GradColor = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(181, 33, 255))};
				StrokeColor = Color3.fromRGB(67, 19, 59)
			}
		}


		if typeof(Config.Socials) == "table" and #Config.Socials > 0 then
			LOADER.load.Size = UDim2.new(0, 400, 0, 360)
			LOADER.load.social.Visible = true

			syde:HidePlaceHolder(LOADER.load.social.largeblock, 'largesocial')
			syde:HidePlaceHolder(LOADER.load.social, 'little')
			syde:HidePlaceHolder(LOADER.load.social.little, 'smallblock1')
			syde:HidePlaceHolder(LOADER.load.social.little, 'smallblock2')

			for _, social in ipairs(Config.Socials) do
				table.insert(LoaderConfig.Socials, {
					Name = social.Name or '@None';
					Discord = social.Discord or 'None';
					Style = social.Style or "Default";
					Size = social.Size or "Medium";
					CopyToClip = social.CopyToClip ~= nil and social.CopyToClip or true;
				})
			end

			local largeCount, smallCount = 0, 0

			for _, social in ipairs(LoaderConfig.Socials) do
				if social.Size == "Large" then
					largeCount += 1
				elseif social.Size == "Small" then
					smallCount += 1
				end
			end

			if largeCount > 1 or smallCount > 2 then
				LoaderConfig.Socials = nil
			else
				for _, social in ipairs(LoaderConfig.Socials) do
					if social.Size == "Large" then
						local LargeSocial = LOADER.load.social.largeblock.largesocial:Clone()
						LargeSocial.Visible = true
						LargeSocial.Parent = LOADER.load.social.largeblock

						if social.CopyToClip and LargeSocial:FindFirstChild("interact") then
							LargeSocial.interact.MouseButton1Click:Connect(function()
								if social.Style == 'Discord' then
									setclipboard(social.Discord)
								elseif social.Style == 'WebSite' then
									setclipboard(social.Name)
								elseif social.Style == 'GitHub' then
									setclipboard(social.GitHub)
								end
							end)
						end

						-- [StyleHandle]
						if social.Style == 'GitHub' then
							LargeSocial.BackgroundColor3 = Styles.GitHub.BackGroundColor
							LargeSocial.UIStroke.Color = Styles.GitHub.StrokeColor
							LargeSocial.UIGradient.Color = Styles.GitHub.GradColor

							LargeSocial.DiscordTitle.Visible  = false
							LargeSocial.Visit.Visible = false

							LargeSocial.SocialName.Position = UDim2.new(0, 45,0, 25)
							LargeSocial.SocialName.Text = 'GitHub'
							LargeSocial.GitName.Visible = true
							LargeSocial.GitName.Text = '@'..social.GitHub
							LargeSocial.ImageLabel.Image = 'rbxassetid://86992377698608'
							LargeSocial.UIStroke.UIGradient:Destroy()
						elseif social.Style == 'Discord' then
							LargeSocial.BackgroundColor3 = Styles.Discord.BackGroundColor
							LargeSocial.UIStroke.Color = Styles.Discord.StrokeColor
							LargeSocial.UIGradient.Color = Styles.Discord.GradColor
							LargeSocial.ImageLabel.Image = 'rbxassetid://108012241529487'
							LargeSocial.SocialName.Text = social.Discord

							if not LargeSocial.UIStroke.UIGradient then
								local strokeGrad = Instance.new('UIGradient', LargeSocial.UIStroke)
								strokeGrad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(91, 125, 147))}
								strokeGrad.Rotation = -34
							else
								LargeSocial.UIStroke.UIGradient.Color =  ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(91, 125, 147))}
							end


							LargeSocial.DiscordTitle.Visible  = true
							LargeSocial.Visit.Visible = true
							LargeSocial.GitName.Visible = false
							LargeSocial.SocialName.Position = UDim2.new(0, 45,0, 30)
							LargeSocial.Visit.Position = UDim2.new(1, -95,0.5, 0)
							LargeSocial.Visit.ImageLabel.Visible = true

						elseif social.Style == 'WebSite' then
							LargeSocial.BackgroundColor3 = Styles.Site.BackGroundColor
							LargeSocial.UIStroke.Color = Styles.Site.StrokeColor
							LargeSocial.UIGradient.Color = Styles.Site.GradColor
							LargeSocial.ImageLabel.Image = 'rbxassetid://74915074739925'

							LargeSocial.DiscordTitle.Visible  = false
							LargeSocial.Visit.Visible = true
							LargeSocial.GitName.Visible = false

							if not LargeSocial.UIStroke.UIGradient then
								local strokeGrad = Instance.new('UIGradient', LargeSocial.UIStroke)
								strokeGrad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(181, 33, 225))}
								strokeGrad.Rotation = -25
							else
								LargeSocial.UIStroke.UIGradient.Color =  ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(181, 33, 225))}
							end


							LargeSocial.SocialName.Text = social.Name
							LargeSocial.Visit.ImageLabel.Visible = false
							LargeSocial.Visit.TextColor3 = Color3.fromRGB(255, 255, 255)
							LargeSocial.Visit.Text = 'Visit site'
							LargeSocial.Visit.Position = UDim2.new(1, -80,0.5, 0)
						end
					end

					if social.Size == "Small" then
						LOADER.load.social.little.Visible = true
						local SmallSocial = LOADER.load.social.little.smallblock1:Clone()
						SmallSocial.Visible = true
						SmallSocial.Parent = LOADER.load.social.little

						if social.CopyToClip and SmallSocial:FindFirstChild("interact") then
							SmallSocial.interact.MouseButton1Click:Connect(function()
								--	setclipboard(social.Discord or social.Name or "No data")
								if social.Style == 'WebSite' then
									setclipboard(social.Name)
								elseif social.Style == 'GitHub' then
									setclipboard(social.GitHub)
								end
							end)
						end

						if social.Style == "GitHub" then
							SmallSocial.BackgroundColor3 = Styles.GitHub.BackGroundColor
							SmallSocial.UIStroke.Color = Styles.GitHub.StrokeColor
							SmallSocial.UIGradient.Color = Styles.GitHub.GradColor

							SmallSocial.SocialName.Text = 'GitHub'
							SmallSocial.Text.Visible = true
							SmallSocial.Text.TextColor3 = Color3.fromRGB(90, 90, 90)
							SmallSocial.Text.Text = '@'..social.Name
							SmallSocial.ImageLabel.Image = 'rbxassetid://86992377698608'
						elseif social.Style == 'WebSite' then
							SmallSocial.BackgroundColor3 = Styles.Site.BackGroundColor
							SmallSocial.UIStroke.Color = Styles.Site.StrokeColor
							SmallSocial.UIGradient.Color = Styles.Site.GradColor

							SmallSocial.SocialName.Text = social.Name
							SmallSocial.Text.Visible = true
							SmallSocial.Text.TextColor3 = Color3.fromRGB(255, 255, 255)
							SmallSocial.Text.Text = 'Visit Site'
							SmallSocial.ImageLabel.Image = 'rbxassetid://74915074739925'
							SmallSocial.ImageLabel.ImageColor3 = Color3.fromRGB(231, 160, 255)
						end
					end

					if social.CopyToClip then
					end
				end
			end

			local function updateSize()
				LOADER.load.Size = UDim2.new(LOADER.load.Size.X.Scale, LOADER.load.Size.X.Offset, 0,  LOADER.load.social.UIListLayout.AbsoluteContentSize.Y  + 235)
			end

			LOADER.load.social.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateSize)

			updateSize()

		else
			LoaderConfig.Socials = nil
		end

		if LoaderConfig.Socials == nil then
			LOADER.load.Size = UDim2.new(0, 400, 0, 250)
			LOADER.load.social.Visible = false
			TweenWorkPos = 200
			TweenWorkDisappear = 150
			TweenWorkAppear = 177
		end


		LOADER.load.logo.Image = LoaderConfig.Logo;
		syde.theme.Accent = Config.Accent;
		syde.theme.HitBox = Config.HitBox;
		LOADER.load.info.build.Text = syde.Build

		if LoaderConfig.Status == false then
			LOADER.load.logo.stroke.UIStroke.Color = Color3.fromRGB(24, 24, 24)
			LOADER.load.logo["Title/Status"].Text = 'Jannis Hub'
		end

		local statusColors = {
			Stable = { Color = Color3.fromRGB(25, 229, 22), Text = '<font color="#24bf48">Stable</font>' },
			Unstable = { Color = Color3.fromRGB(227, 229, 81), Text = '<font color="#e3e551">Unstable</font>' },
			Detected = { Color = Color3.fromRGB(229, 44, 47), Text = '<font color="#e52c2f">Detected</font>' },
			Patched = { Color = Color3.fromRGB(229, 44, 47), Text = '<font color="#e52c2f">Patched</font>' }
		}

		local statusData = statusColors[LoaderConfig.Status]
		if statusData then
			LOADER.load.logo.stroke.UIStroke.Color = statusData.Color
			LOADER.load.logo["Title/Status"].Text = string.format('%s  <font color="#363636">•</font>  %s', LoaderConfig.Name, statusData.Text)
		end

		local function initLoader()
			TweenService:Create( LOADER.load.Salt, TweenInfo.new(0.65, Enum.EasingStyle.Quint), {Size = UDim2.new(0, 25,0, 25)}):Play()
			TweenService:Create( LOADER.load.Salt, TweenInfo.new(0.65, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
		end

		local function TweenWorkLabel(Finish, icon, Text)
			LOADER.load.work.Position = UDim2.new(0.5, 0,1, -40)
			LOADER.load.work.Text = Text
			LOADER.load.work.ImageLabel.Image = icon
			TweenService:Create( LOADER.load.work, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), { TextTransparency = 0 }):Play()
			TweenService:Create( LOADER.load.work.ImageLabel, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), { ImageTransparency = 0 }):Play()
			TweenService:Create( LOADER.load.work, TweenInfo.new(0.5, Enum.EasingStyle.Quint), { Position = UDim2.new(0.5, 0,1, -73) }):Play()
			--	TweenService:Create(game.Workspace.Camera, TweenInfo.new(1, Enum.EasingStyle.Exponential), { FieldOfView  = game.Workspace.Camera.FieldOfView - 3 }):Play()
			task.wait(Finish)
			TweenService:Create( LOADER.load.work, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), { TextTransparency = 1 }):Play()
			TweenService:Create( LOADER.load.work.ImageLabel, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), { ImageTransparency = 1 }):Play()
			TweenService:Create( LOADER.load.work, TweenInfo.new(0.5, Enum.EasingStyle.Quint), { Position = UDim2.new(0.5, 0,1, -100) }):Play()
			task.wait(0.6)

			-- reset

		end

		local function load()
			TweenWorkLabel(1,'rbxassetid://136002400178503', 'Verifying Configuration...')

			if Config.ConfigurationSaving and Config.ConfigurationSaving.Enabled then
				local folderName = Config.ConfigurationSaving.FolderName or "NexusSec"
				local fileName = Config.ConfigurationSaving.FileName or "default_config"
				local fullPath = folderName .. "/" .. fileName .. ".lua"

				syde.ConfigEnabled = true
				syde.ConfigFolder = folderName  
				syde.ConfigFile = fileName     

				-- Ensure folder exists
				if isfolder and not isfolder(folderName) then
					local success, err = pcall(function()
						makefolder(folderName)
					end)
					if not success then
					end
				end

				-- File validation
				local success, err = pcall(function()
					if isfile and not isfile(fullPath) then
						writefile(fullPath, "-- Protected UI Configuration")
					else
						local content = readfile(fullPath)
					end
				end)

				if not success then
				end
			end


			TweenWorkLabel(1,'rbxassetid://105810189969774', 'Cleaning Things Up...')
			local UI_TAG = "NexusLoader"
			local MARKER_NAME = "NexusUi"
			local INTERNAL_UUID = ("NEX-" .. tostring(game.JobId):gsub("-", "") .. tostring(tick())):gsub("%.", "")
			local PROTECTION_EVENT = Instance.new("BindableEvent")

			-- Cleanup old UI 
			local function deepCleanup()
				for _, v in ipairs(CoreGui:GetChildren()) do
					if v:IsA("ScreenGui") and v:FindFirstChild(MARKER_NAME) then
						pcall(function()
							v:Destroy()
						end)
					end
				end
			end
			deepCleanup()

			-- Load the Library
			local successLibrary, Library = pcall(function()
				return Library -- Replace with actual GetObjects if needed
			end)

			if not successLibrary or not Library then
				return
			end

			Library.Name = UI_TAG
			Library.ResetOnSpawn = false

			local marker = Instance.new("StringValue")
			marker.Name = MARKER_NAME
			marker.Value = INTERNAL_UUID
			marker.Parent = Library

local coreGuiFolder = CoreGui:FindFirstChild("COREGUI")
if not coreGuiFolder then
    coreGuiFolder = Instance.new("Folder")
    coreGuiFolder.Name = "COREGUI"
    protect_gui(coreGuiFolder)
    coreGuiFolder.Parent = CoreGui
end

pcall(function()
    protect_gui(Library)
    Library.Parent = coreGuiFolder
end)

task.spawn(function()
    while Library and Library.Parent do
        task.wait(1)
        if Library.Parent ~= coreGuiFolder then
            pcall(function()
                protect_gui(Library)
                Library.Parent = coreGuiFolder
            end)
        end
    end
end)

			-- Reinject if removed
			task.spawn(function()
				while Library and Library.Parent do
					task.wait(2)
				end

				local success, lib = pcall(function()
					return Library -- Replace with GetObjects if needed
				end)
				if success and lib then
					lib.Name = UI_TAG
					local m = Instance.new("StringValue")
					m.Name = MARKER_NAME
					m.Value = INTERNAL_UUID
					m.Parent = lib
					lib.ResetOnSpawn = false
					pcall(function()
						lib.Parent = CoreGui
					end)
				end
			end)

			TweenWorkLabel(1,'rbxassetid://108012241529487', 'Checking For Discord...')

			if Config.AutoJoinDiscord and Config.AutoJoinDiscord.Enabled then
				local discordConfig = Config.AutoJoinDiscord
				local rootFolder = Config.ConfigurationSaving and Config.ConfigurationSaving.FolderName or "NexusSec"
				local discordFolder = rootFolder .. "/DiscordInvites"
				local inviteCode = discordConfig.Invite
				local inviteFilePath = discordFolder .. "/" .. inviteCode .. ".txt"

				-- Ensure folder exists
				if isfolder and not isfolder(discordFolder) then
					local folderSuccess, folderErr = pcall(function()
						makefolder(discordFolder)
					end)
					if folderSuccess then
					else
					end
				end

				local shouldPrompt = true
				if isfile and discordConfig.RememberJoins and isfile(inviteFilePath) then
					shouldPrompt = false
				end

				if shouldPrompt then
					if request then
						local reqSuccess, reqErr = pcall(function()
							request({
								Url = "http://127.0.0.1:6463/rpc?v=1",
								Method = "POST",
								Headers = {
									["Content-Type"] = "application/json",
									["Origin"] = "https://discord.com"
								},
								Body = HttpService:JSONEncode({
									cmd = "INVITE_BROWSER",
									nonce = HttpService:GenerateGUID(false),
									args = {
										code = inviteCode
									}
								})
							})
						end)

						if reqSuccess then
						else
						end
					else
					end

					if discordConfig.RememberJoins then
						local writeSuccess, writeErr = pcall(function()
							writefile(inviteFilePath, "Joined Discord via invite '" .. inviteCode .. "' at " .. os.date())
						end)

						if writeSuccess then
						else
						end
					end
				end
			end

			TweenWorkLabel(1,'rbxassetid://136405833725573', 'Loading UI...')
			task.wait(1)
			loaded = true
			TweenService:Create( LOADER.load.Salt, TweenInfo.new(0.65, Enum.EasingStyle.Quint), {Size = UDim2.new(0, 146,0, 25)}):Play()
			TweenService:Create( LOADER.load.Salt.ImageLabel, TweenInfo.new(0.65, Enum.EasingStyle.Exponential), {ImageTransparency = 0}):Play()
		end

		local TimeTillLoad = 1.5

		while TimeTillLoad > 0 do
			LOADER.load.info.TimeTill.Text = string.format("%.2f", TimeTillLoad) 
			task.wait(0.01) 
			TimeTillLoad -= 0.01 
		end

		LOADER.load.info.TimeTill.Text = '0.00'

		task.wait(TimeTillLoad)

		initLoader()
		task.wait(0.08)
		load()
		task.wait(2)

		Library.Enabled = true


		LOADER:Destroy()

	end

end

function LoadConfig(Configuration)
	local Data = HttpService:JSONDecode(Configuration)
	local changed = false

	for FlagName, Flag in pairs(syde.Flags) do
		local FlagValue = Data[FlagName]

		if FlagValue ~= nil then
			task.spawn(function()

				if Flag.Set then
					Flag:Set(Flag.Type == "ColorPicker" and syde:ColorUnpack(FlagValue) or FlagValue)
				elseif Flag.Type == "ColorPicker" and Flag.Color then
					Flag.Color = syde:ColorUnpack(FlagValue)
					changed = true
				elseif Flag.Value ~= nil then
					Flag.Value = FlagValue
					changed = true
				elseif Flag.StarterValue then
					Flag.StarterValue = FlagValue
				else
				end
			end)
		end

	end

	return changed
end


function SaveConfig()
	if not syde.ConfigEnabled then return end

	local Data = {}
	for i, v in pairs(syde.Flags) do
		if v.Type == "ColorPicker" then
			Data[i] = syde:ColorPack(v.Color)
		else
			Data[i] = v.Value or v.Color or v.StarterValue or false
		end
	end

	-- Save configuration to file
	if writefile then
		local filePath = string.format("%s/%s.lua", syde.ConfigFolder, syde.ConfigFile)
		writefile(filePath, HttpService:JSONEncode(Data))
	end
end


-- [UI SETUP]
local UI = Library
local WINDOW = UI.lib
local TOPBAR = WINDOW.Top
local TABS = WINDOW.Tab.ScrollingFrame
local PAGES = WINDOW.Pages
local settingsOpen = false
local UIClosed = false
local Connected = false
local UserInfoDisabled = false
local UIToggle = Enum.KeyCode.RightShift

function SetUserInfo()

	local PLACEHOLDER_IMAGE = "rbxassetid://0" 
	local THUMBNAIL_TYPE = Enum.ThumbnailType.HeadShot
	local THUMBNAIL_SIZE = Enum.ThumbnailSize.Size420x420

	local imageLabel = WINDOW:WaitForChild("UserInfo"):WaitForChild("ImageLabel")
	imageLabel.Image = PLACEHOLDER_IMAGE

	local success, thumbnail = pcall(function()
		return Players:GetUserThumbnailAsync(LocalPlayer.UserId, THUMBNAIL_TYPE, THUMBNAIL_SIZE)
	end)

	if success and thumbnail then
		imageLabel.Image = thumbnail
		WINDOW.UserInfo.ImageLabel.text.Username.Text = LocalPlayer.Name
		WINDOW.UserInfo.ImageLabel.text.Display.Text = "@"..LocalPlayer.DisplayName
	else
		imageLabel.Image = PLACEHOLDER_IMAGE
	end
end

function CloseUI()
    WINDOW.Visible = false
    PAGES.Visible = false
    WINDOW.Tab.Visible = false
    UIClosed = true

    WINDOW.Top.ImageLabel.ImageTransparency = 1 -- LOGO
    WINDOW.BackgroundTransparency = 1
    WINDOW.Size = UDim2.new(WINDOW.Size.X.Scale, WINDOW.Size.X.Offset, WINDOW.Size.Y.Scale, 200)
    WINDOW.Top.div.BackgroundTransparency = 1
    WINDOW.Top.Title.TextTransparency = 1
    WINDOW.Top.Title.Sub.TextTransparency = 1
    WINDOW.Shadow.ImageLabel.ImageTransparency = 1
    WINDOW.resize.ImageTransparency = 1
    WINDOW.Top.UHolder.Util.Mini.interact.ImageTransparency = 1
    WINDOW.Top.UHolder.Util.Close.interact.ImageTransparency = 1
    WINDOW.Top.UHolder.Util.Settings.interact.ImageTransparency = 1
    WINDOW.Top.UHolder.Util.Settings.BackgroundTransparency = 1
    WINDOW.Top.UHolder.Frame.BackgroundTransparency = 1
    WINDOW.UserInfo.ImageLabel.UIStroke.Transparency = 1
    WINDOW.UserInfo.ImageLabel.ImageTransparency = 1
    WINDOW.UserInfo.ImageLabel.BackgroundTransparency = 1
    WINDOW.UserInfo.ImageLabel.text.Username.TextTransparency = 1
    WINDOW.UserInfo.ImageLabel.text.Display.TextTransparency = 1
    WINDOW.UserInfo.ConnectionStatus.Status.BackgroundTransparency = 1
    WINDOW.UserInfo.ConnectionStatus.Status.TextLabel.TextTransparency = 1

    if UIClosed then

    end
end


function OpenUI()
	PAGES.Visible = true
	WINDOW.Tab.Visible = true
	WINDOW.Visible = true
	UIClosed = false
	TweenService:Create(WINDOW, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0 }):Play()
	TweenService:Create(WINDOW, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Size = UDim2.new(WINDOW.Size.X.Scale, WINDOW.Size.X.Offset, WINDOW.Size.Y.Scale, 575) }):Play()
	TweenService:Create(WINDOW.Top.div, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.7 }):Play()
	TweenService:Create(WINDOW.Top.Title, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 0 }):Play()
	TweenService:Create(WINDOW.Top.Title.Sub, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 0 }):Play()
    TweenService:Create(WINDOW.Top.ImageLabel, TweenInfo.new(1.4, Enum.EasingStyle.Exponential), {ImageTransparency = 0 }):Play()
	TweenService:Create(WINDOW.Shadow.ImageLabel, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {ImageTransparency = 0.5 }):Play()
	TweenService:Create(WINDOW.resize, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {ImageTransparency = 0 }):Play()
	TweenService:Create(WINDOW.Top.UHolder.Util.Mini.interact, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {ImageTransparency = 0 }):Play()
	TweenService:Create(WINDOW.Top.UHolder.Util.Close.interact, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {ImageTransparency = 0 }):Play()
	TweenService:Create(WINDOW.Top.UHolder.Util.Settings.interact, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {ImageTransparency = 0.7 }):Play()
	TweenService:Create(WINDOW.Top.UHolder.Util.Settings, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.05 }):Play()
	TweenService:Create(WINDOW.Top.UHolder.Frame, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0 }):Play()
	TweenService:Create(WINDOW.UserInfo.ImageLabel.UIStroke, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Transparency = 0 }):Play()
	TweenService:Create(WINDOW.UserInfo.ImageLabel, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {ImageTransparency = 0 }):Play()
	TweenService:Create(WINDOW.UserInfo.ImageLabel, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0 }):Play()
	TweenService:Create(WINDOW.UserInfo.ImageLabel.text.Username, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 0 }):Play()
	TweenService:Create(WINDOW.UserInfo.ImageLabel.text.Display, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 0 }):Play()
	TweenService:Create(WINDOW.UserInfo.ConnectionStatus.Status, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0 }):Play()
	TweenService:Create(WINDOW.UserInfo.ConnectionStatus.Status.TextLabel, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 0 }):Play()
end

local BOUNCE = false

function ToggleUI()
	if BOUNCE then return end
	BOUNCE = true

	if Library and Library.Parent == CoreGui then
		if UIClosed then
			OpenUI()
		else
			CloseUI()
		end
	end

	BOUNCE = false
end


-- [Remove PlaceHolders]
syde:HidePlaceHolder(TABS, 'Tb')
syde:HidePlaceHolder(PAGES, 'Page')


--[INITIALIZATION]

function syde:Init(library)

	Library.Enabled = true

	if loaded == false then
		local UI_TAG = "Loader"
		local MARKER_NAME = "NexusUID"
		local INTERNAL_UUID = ("NEXS-" .. tostring(game.JobId):gsub("-", "") .. tostring(tick())):gsub("%.", "")
		local PROTECTION_EVENT = Instance.new("BindableEvent")

		local function deepCleanup()
			for _, v in ipairs(CoreGui:GetChildren()) do
				if v:IsA("ScreenGui") and v:FindFirstChild(MARKER_NAME) then
					pcall(function()
						v:Destroy()
					end)
				end
			end
		end
		deepCleanup()

		-- Load the Library
		local successLibrary, Library = pcall(function()
			return Library -- Replace with actual GetObjects if needed
		end)

		if not successLibrary or not Library then
			return
		end

		Library.Name = UI_TAG
		Library.ResetOnSpawn = false

		local marker = Instance.new("StringValue")
		marker.Name = MARKER_NAME
		marker.Value = INTERNAL_UUID
		marker.Parent = Library

		pcall(function()
			Library.Parent = CoreGui
		end)

		-- Ensure Library stays in CoreGui
		task.spawn(function()
			while Library and Library.Parent do
				task.wait(1)
				if Library.Parent ~= CoreGui then
					pcall(function()
						Library.Parent = CoreGui
					end)
				end
			end
		end)

		-- Reinject if removed
		task.spawn(function()
			while Library and Library.Parent do
				task.wait(2)
			end

			local success, lib = pcall(function()
				return Library -- Replace with GetObjects if needed
			end)
			if success and lib then
				lib.Name = UI_TAG
				local m = Instance.new("StringValue")
				m.Name = MARKER_NAME
				m.Value = INTERNAL_UUID
				m.Parent = lib
				lib.ResetOnSpawn = false
				pcall(function()
					lib.Parent = CoreGui
				end)
			end
		end)
	end


	TweenService:Create(game.Workspace.Camera, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), { FieldOfView  = 70 }):Play()

	local Data = {
		Title = library.Title or "Nexus",
		SubText = library.SubText or "Nexus",
	}

	-- [Setup UI Elements]
	TOPBAR.Title.Text = Data.Title
	TOPBAR.Title.Sub.Text = Data.SubText

	-- [Setup Dragging & Resizing]
	syde:AddDrag(TOPBAR, WINDOW, true)
	syde:MakeResizable(WINDOW.resize, WINDOW, Vector2.new(654, 428))

	-- [Initial Transparency Setup]
	TOPBAR.Title.TextTransparency = 1
	TOPBAR.Title.Sub.TextTransparency = 1
	
	function applyLayout(isMobile)
		Library.lib.Size = isMobile and UDim2.new(0, 543,0, 321) or UDim2.new(0, 715, 0, 575)
		local shadow = WINDOW:FindFirstChild("Shadow")
		if shadow then
			shadow.Visible = not isMobile 
		end
	end


	local function updateLayout()
		local screenSize = camera.ViewportSize
		local mobile = UserInputService.TouchEnabled -- or (screenSize.X < 1024 and screenSize.Y < 768)
		applyLayout(mobile)
	end


	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		screenSize = workspace.CurrentCamera.ViewportSize
		isMobile = UserInputService.TouchEnabled  -- or (screenSize.X < 1024 and screenSize.Y < 768)
		updateLayout()  -- Recompute layout values
	end)

	updateLayout()

	-- Reapply on resize
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateLayout)
	UserInputService:GetPropertyChangedSignal("TouchEnabled"):Connect(updateLayout)

	-- Syde Connection (Coming Soon)
	SetUserInfo()

	if not UserInfoDisabled then
		TweenService:Create(WINDOW.Tab, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 200,1, -150) }):Play()
	else
		TweenService:Create(WINDOW.Tab, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 200,1, -50) }):Play()
	end

	--[Settings Page Init]
	if not settingsOpen then

		WINDOW.Settings.Visible = false
		WINDOW.dim.Visible = false

		WINDOW.Settings.Position = UDim2.new(0.5, 176,0.5, -200)
		WINDOW.Settings.Size = UDim2.new(0, 200,0, 110)
		WINDOW.dim.BackgroundTransparency = 1
		WINDOW.Settings.void.BackgroundTransparency = 1
		WINDOW.Settings.void2.BackgroundTransparency = 1

		WINDOW.Settings.BackgroundTransparency = 1
		WINDOW.Settings.TabBlock.UIStroke.Transparency = 1
		WINDOW.Settings.Shadow.ImageLabel.ImageTransparency = 1

		WINDOW.Settings.TabBlock.Theme.BackgroundTransparency = 1
		WINDOW.Settings.TabBlock.Theme.TextTransparency = 1
		WINDOW.Settings.TabBlock.Theme.d.BackgroundTransparency = 1
		WINDOW.Settings.TabBlock.Theme.Frame.BackgroundTransparency = 1

		WINDOW.Settings.TabBlock.Info.BackgroundTransparency = 1
		WINDOW.Settings.TabBlock.Info.TextTransparency = 1
		WINDOW.Settings.TabBlock.Info.d.BackgroundTransparency = 1
		WINDOW.Settings.TabBlock.Info.Frame.BackgroundTransparency = 1

		WINDOW.Settings.TabBlock.Privacy.BackgroundTransparency = 1
		WINDOW.Settings.TabBlock.Privacy.TextTransparency = 1
	end

	-- [Play Intro Animations]
	task.spawn(function()
		task.wait(0.5)
		local titleTween = TweenService:Create(TOPBAR.Title, TweenInfo.new(1.65, Enum.EasingStyle.Exponential), { TextTransparency = 0 })
		titleTween:Play()

		task.wait(0.1)
		local subTitleTween = TweenService:Create(TOPBAR.Title.Sub, TweenInfo.new(1.65, Enum.EasingStyle.Exponential), { TextTransparency = 0 })
		subTitleTween:Play()

		task.wait()
		local textSize = TOPBAR.Title.TextBounds.X + 5

		TweenService:Create(TOPBAR.Title, TweenInfo.new(1.55, Enum.EasingStyle.Quint), {
			Size = UDim2.new(0, textSize, 1, 0)
		}):Play()
	end)

	-- [Resize Hover Animations]
	local function animateResizeButton(isHovered)
		local targetColor = isHovered and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(35, 35, 35)
		TweenService:Create(WINDOW.resize, TweenInfo.new(0.95, Enum.EasingStyle.Exponential), { ImageColor3 = targetColor }):Play()
	end

	WINDOW.resize.MouseEnter:Connect(function() animateResizeButton(true) end)
	WINDOW.resize.MouseLeave:Connect(function() animateResizeButton(false) end)

	--[Settings Handle]
	-- Hover
	WINDOW.Settings.Close.MouseEnter:Connect(function()
		TweenService:Create(WINDOW.Settings.Close, TweenInfo.new(0.8, Enum.EasingStyle.Exponential), {ImageColor3 = Color3.fromRGB(255, 255, 255) }):Play()
	end)

	WINDOW.Settings.Close.MouseLeave:Connect(function()
		TweenService:Create(WINDOW.Settings.Close, TweenInfo.new(0.8, Enum.EasingStyle.Exponential), {ImageColor3 = Color3.fromRGB(48, 48, 48) }):Play()
	end)


	WINDOW.Top.UHolder.Util.Mini.interact.MouseButton1Click:Connect(function()
		ToggleUI()
	end)

	WINDOW.Top.UHolder.Util.Close.interact.MouseButton1Click:Connect(function()
		syde:Modal({
			Title = 'Please Confirm Below.',
			Content = 'Are You Sure You Want To Close This UI?',
			ConfimCallBack = function()
				Library:Destroy()
			end,
		})
	end)

	local tabBlock = WINDOW.Settings.TabBlock
	local pageLayout = WINDOW.Settings.Pages.UIPageLayout
	local pagesFolder = WINDOW.Settings.Pages

	for _, v in pairs(tabBlock:GetChildren()) do
		if v:IsA('TextButton') then
			v.MouseButton1Click:Connect(function()
				local targetPage = pagesFolder:FindFirstChild(v.Name)

				for _, other in pairs(tabBlock:GetChildren()) do
					if other:IsA('TextButton') then
						TweenService:Create(other, TweenInfo.new(0.8, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(15, 15, 15) }):Play()
						TweenService:Create(other, TweenInfo.new(0.8, Enum.EasingStyle.Exponential), {TextColor3 = Color3.fromRGB(44, 44, 44) }):Play()

						if other.Name == 'Theme' then
							TweenService:Create(other.d, TweenInfo.new(0.8, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(15, 15, 15) }):Play()
						elseif other.Name == 'Info' then
							TweenService:Create(other.d, TweenInfo.new(0.8, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(15, 15, 15) }):Play()
						end


					end
				end

				TweenService:Create(v, TweenInfo.new(0.8, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(26, 26, 26) }):Play()
				TweenService:Create(v, TweenInfo.new(0.8, Enum.EasingStyle.Exponential), {TextColor3 = Color3.fromRGB(255, 255, 255) }):Play()
				if v.Name == 'Theme' then
					TweenService:Create(v.d, TweenInfo.new(0.8, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(26, 26, 26) }):Play()
				elseif v.Name == 'Info' then
					TweenService:Create(v.d, TweenInfo.new(0.8, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(26, 26, 26) }):Play()
				end

				if targetPage then
					pageLayout:JumpTo(targetPage)
				else
				end
			end)
		end
	end
	
	syde:AddConnection(syde.Comms.Event, function(p, color)
		if p == 'DropShadow' then
			WINDOW.Shadow.ImageLabel.ImageColor3 = color
		end
	end)











	--[[
           __|  __| __ __| __ __| _ _|   \ |   __|   __|
         \__ \  _|     |      |     |   .  |  (_ | \__ \
         ____/ ___|   _|     _|   ___| _|\_| \___| ____/						
	]]











	do
		local SettingsElements = {
			Connections = {};
			Comms = Instance.new('BindableEvent');
		}

		function SettingsElements:AddConnection(Type, Callback)
			if typeof(Type) ~= "RBXScriptSignal" then
				error("[AddConnection] Invalid Type: Expected RBXScriptSignal, got " .. typeof(Type))
			end
			if typeof(Callback) ~= "function" then
				error("[AddConnection] Invalid Callback: Expected function, got " .. typeof(Callback))
			end

			local Connection = Type:Connect(Callback)
			local ConnectionData = { Connection = Connection }

			SettingsElements.Connections = SettingsElements.Connections or {}
			table.insert(SettingsElements.Connections, ConnectionData)

			local function Disconnect()
				if Connection.Connected then
					Connection:Disconnect()
				end

				for i = #SettingsElements.Connections, 1, -1 do
					if SettingsElements.Connections[i] == ConnectionData then
						table.remove(SettingsElements.Connections, i)
						break
					end
				end
			end

			task.spawn(function()
				task.wait(10)
				for i = #SettingsElements.Connections, 1, -1 do
					if not SettingsElements.Connections[i].Connection.Connected then
						table.remove(SettingsElements.Connections, i)
					end
				end
			end)

			return Connection, Disconnect
		end

		function SettingsElements:GetSettingsElements()
			local element = {}

			function element:CreateButton(Button, Parent)
				local ButtonData = {
					Title = Button.Title or "Temp Button";
					CallBack = Button.CallBack;
					Desc = Button.Description or "";
					Type = Button.Type or 'Default';
					HoldTime = Button.HoldTime or 3;
				}

				local button = Library.Settings.Button:Clone()
				button.Visible = true
				button.Parent = Parent
				button.Title.Text = Button.Title
				button.Name = ButtonData.Title
				button.Title.Size = UDim2.new(0, button.Title.TextBounds.X + 15,0, 35)


				local fOTween = TweenInfo.new(0.7, Enum.EasingStyle.Exponential)
				local fITween = TweenInfo.new(0.7, Enum.EasingStyle.Exponential)

				if ButtonData.Type == 'Default' then
					-- UI Stroke effect on button press

					button.interact.MouseButton1Down:Connect(function()
						TweenService:Create(button.UIStroke, fOTween, { Transparency = 1 }):Play()
						TweenService:Create(button.ImageLabel, fOTween, { ImageTransparency = 1 }):Play()
						TweenService:Create(button.ImageLabel, TweenInfo.new(0.8, Enum.EasingStyle.Exponential), { ImageTransparency = 1 }):Play()
					end)

					button.interact.MouseButton1Up:Connect(function()
						TweenService:Create(button.UIStroke, fITween, { Transparency = 0 }):Play()
						TweenService:Create(button.ImageLabel, TweenInfo.new(0.8, Enum.EasingStyle.Exponential), { ImageTransparency = 0.95 }):Play()


					end)

					button.interact.MouseButton1Click:Connect(function()
						if ButtonData.CallBack then
							local success, errorMsg = pcall(ButtonData.CallBack)
							if not success then
							end
						else
						end
					end)

					-- Extra Check 
					button.interact.MouseLeave:Connect(function()
						TweenService:Create(button.UIStroke, fITween, { Transparency = 0 }):Play()
						TweenService:Create(button.ImageLabel, TweenInfo.new(0.8, Enum.EasingStyle.Exponential), { ImageTransparency = 0.95 }):Play()
					end)
				elseif ButtonData.Type == 'Hold' then
					local HoldTime = ButtonData.HoldTime
					local Holding = false
					local TimeLeft = HoldTime
					local Complete = false

					button.ImageLabel.Image = 'rbxassetid://127075195365098'
					button.ImageLabel.Rotation = 0
					button.ImageLabel.Size = UDim2.new(0, 16,0, 16)
					button.ImageLabel.Position = UDim2.new(1, -41,0.5, 0)

					local function CancelOperation()
						Holding = false
						TweenService:Create(button.ImageLabel, TweenInfo.new(0.8, Enum.EasingStyle.Exponential), { ImageTransparency = 0.95 }):Play()
						TweenService:Create(button.Title.Timer, TweenInfo.new(0.8, Enum.EasingStyle.Exponential), { TextTransparency = 1 }):Play()
						if not Complete then
							TweenService:Create(button.UIStroke, TweenInfo.new(1, Enum.EasingStyle.Exponential), { Transparency = 1 }):Play()
							TweenService:Create(button.UIStroke.UIGradient, TweenInfo.new(1, Enum.EasingStyle.Linear), { Offset = Vector2.new(-1, 0) }):Play()
							TweenService:Create(button, TweenInfo.new(0.8, Enum.EasingStyle.Exponential), { Position = UDim2.new(0 ,-15 ,0 ,button.Position.Y.Offset) }):Play()
							task.wait(0.15)
							TweenService:Create(button, TweenInfo.new(0.8, Enum.EasingStyle.Exponential), { Position = UDim2.new(0 ,30 ,0 ,button.Position.Y.Offset) }):Play()
							task.wait(0.15)
							TweenService:Create(button, TweenInfo.new(0.8, Enum.EasingStyle.Exponential), { Position = UDim2.new(0 ,0 ,0 ,button.Position.Y.Offset) }):Play()
							task.wait(1)
							TweenService:Create(button.UIStroke, TweenInfo.new(1, Enum.EasingStyle.Exponential), { Transparency = 0 }):Play()
						end

						-- did not complete 

						--	button.UIStroke.UIGradient.Offset = Vector2.new(-1, 0)
						--	TweenService:Create(button.UIStroke, TweenInfo.new(HoldTime, Enum.EasingStyle.Linear), { Offset = Vector2.new(-1, 0) }):Play()

						-- Restore the timer value
						TimeLeft = HoldTime
						button.Title.Timer.Text = tostring(HoldTime)
						task.wait(0.1)
						Complete = false
					end

					button.interact.MouseButton1Down:Connect(function()

						Holding = true
						TimeLeft = HoldTime
						button.Title.Timer.Text = tostring(TimeLeft)
						TweenService:Create(button.ImageLabel, TweenInfo.new(0.8, Enum.EasingStyle.Exponential), { ImageTransparency = 1 }):Play()
						TweenService:Create(button.Title.Timer, TweenInfo.new(0.8, Enum.EasingStyle.Exponential), { TextTransparency = 0 }):Play()
						TweenService:Create(button.UIStroke.UIGradient, TweenInfo.new(HoldTime, Enum.EasingStyle.Linear), { Offset = Vector2.new(0.7, 0) }):Play()
						TweenService:Create(button.UIStroke, TweenInfo.new(1, Enum.EasingStyle.Exponential), { Transparency = 0}):Play()

						-- Countdown loop
						while Holding and TimeLeft > 0 do
							TimeLeft = math.max(0, TimeLeft - RunService.Heartbeat:Wait()) -- Ensures it doesn't go below 0
							button.Title.Timer.Text = string.format("%.1f", TimeLeft) -- Always shows at least 0.0

						end

						if TimeLeft <= 0 then
							Complete = true
							if ButtonData.CallBack then
								local success, errorMsg = pcall(ButtonData.CallBack)
								if not success then
								end
							else
							end
							TweenService:Create(button, TweenInfo.new(0.34, Enum.EasingStyle.Exponential), { BackgroundColor3 = Color3.fromRGB(24, 24, 24) }):Play()
							TweenService:Create(button.UIStroke.UIGradient, TweenInfo.new(0.1, Enum.EasingStyle.Linear), { Offset = Vector2.new(-1, 0) }):Play()
							task.wait(0.34)
							TweenService:Create(button, TweenInfo.new(0.34, Enum.EasingStyle.Exponential), { BackgroundColor3 = Color3.fromRGB(17, 17, 17) }):Play()
						end
					end)

					button.interact.MouseButton1Up:Connect(function()
						CancelOperation()
					end)

					button.interact.MouseLeave:Connect(function()
						if Holding then
							CancelOperation()
						end
					end)
				end

				--[DESC]
				local descLabel = button:FindFirstChild("Desc")

				if descLabel then
					if ButtonData.Desc and ButtonData.Desc ~= "" then
						descLabel.Text = ButtonData.Desc
						descLabel.Visible = true
						descLabel.TextWrapped = true

						local function updateSize()
							local textSize = TextService:GetTextSize(
								descLabel.Text,
								descLabel.TextSize,
								descLabel.Font,
								Vector2.new(descLabel.AbsoluteSize.X, math.huge) -- Allows vertical expansion
							)

							local newDescSize = UDim2.new(1, -150, 0, textSize.Y)
							local newButtonSize = UDim2.new(button.Size.X.Scale, button.Size.X.Offset, 0, button.Title.Size.Y.Offset + textSize.Y + 5) -- Adding extra padding

							local descTween = TweenService:Create(descLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = newDescSize })
							descTween:Play()

							local buttonTween = TweenService:Create(button, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = newButtonSize })
							buttonTween:Play()
						end

						updateSize()

						descLabel:GetPropertyChangedSignal("TextBounds"):Connect(updateSize)
					else
						descLabel.Visible = false
					end
				end


			end

			---

			function element:TextInput(TextInput, Parent)
				local TextInputData = {
					Title = TextInput.Title or "Text Input",
					PlaceHolder = TextInput.PlaceHolder or "Enter text...",
					NumbersOnly = TextInput.NumberOnly or false,
					ClearOnLost = TextInput.ClearOnLost == nil and true or TextInput.ClearOnLost,
					MaxSize = TextInput.MaxSize or 100,
					CallBack = TextInput.CallBack,
				}

				local textinput = Library.Settings.Input:Clone()
				textinput.Visible = true
				textinput.Parent = Parent
				textinput.Name = TextInputData.Title
				textinput.Title.Text = TextInputData.Title
				textinput.TextFrame.TextBox.PlaceholderText = TextInputData.PlaceHolder

				local textBox = textinput.TextFrame.TextBox
				local defaultHeight = 32
				local maxHeight = TextInputData.MaxSize

				textinput.TextFrame.Enter.MouseEnter:Connect(function()
					TweenService:Create(textinput.TextFrame.Enter, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
				end)

				textinput.TextFrame.Enter.MouseLeave:Connect(function()
					TweenService:Create(textinput.TextFrame.Enter, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextColor3 = Color3.fromRGB(40, 40, 40)}):Play()
				end)

				textBox:GetPropertyChangedSignal("Text"):Connect(function()
					if TextInputData.NumbersOnly then
						textBox.Text = textBox.Text:gsub("%D", "")
					end

					textBox.Size = UDim2.new(1, -60, 0, defaultHeight + 40)

					local textSize = game:GetService("TextService"):GetTextSize(
						textBox.Text, textBox.TextSize, textBox.Font, Vector2.new(textBox.AbsoluteSize.X, math.huge)
					)

					if textBox.Text == "" then
						textBox.Size = UDim2.new(1, -60, 0, math.max(defaultHeight))
					else
						local newHeight = math.min(textSize.Y + 18, maxHeight + 50)
						textBox.Size = UDim2.new(1, -60, 0, newHeight)
					end

				end)

				textinput.TextFrame:GetPropertyChangedSignal("Size"):Connect(function()
					local newHeight = textinput.TextFrame.Size.Y.Offset
					local extraHeight = 32

					TweenService:Create(
						textinput,
						TweenInfo.new(0.7, Enum.EasingStyle.Quint),
						{ Size = UDim2.new(1, -15, 0, newHeight + extraHeight + 25) }
					):Play()

				end)

				textBox:GetPropertyChangedSignal("Size"):Connect(function()
					local newHeight = textBox.Size.Y.Offset
					local totalHeight = math.max(newHeight, defaultHeight)

					TweenService:Create(
						textinput.TextFrame,
						TweenInfo.new(0.7, Enum.EasingStyle.Quint),
						{ Size = UDim2.new(1, -60, 0, totalHeight + 0) }
					):Play()

				end)

				textBox.FocusLost:Connect(function(enterPressed)
					if not enterPressed then return end

					local success, errorMsg = pcall(function()
						TextInputData.CallBack(textBox.Text)
					end)
					if not success then
					end

					if TextInputData.ClearOnLost then
						task.defer(function()
							textBox.Text = ""
							textBox.Size = UDim2.new(1, -60, 0, math.max(defaultHeight))
						end)
					else
						textBox.ClearTextOnFocus = false
					end
				end)

				textinput.TextFrame.Enter.MouseButton1Click:Connect(function()
					local success, errorMsg = pcall(function()
						TextInputData.CallBack(textBox.Text)
					end)
					if not success then
					end

					if TextInputData.ClearOnLost then
						task.defer(function()
							textBox.Text = ""
							textBox.Size = UDim2.new(1, -60, 0, math.max(defaultHeight))
						end)
					else
						textBox.ClearTextOnFocus = false
					end
				end)

			end

			---

			function element:ColorPicker(ColorPicker, Parent)
				local ColorPickerData = {
					Title = ColorPicker.Title;
					Color = ColorPicker.Color;
					Linkable = ColorPicker.Linkable;
					CallBack = ColorPicker.CallBack;
					SFlag = ColorPicker.SFlag;
				}

				ColorPicker.Linkable = ColorPicker.Linkable or true
				ColorPickerData.Type = 'ColorPicker'

				local colorpicker = Library.Settings.ColorPicker:Clone()
				colorpicker.Visible = true
				colorpicker.Parent = Parent
				colorpicker.Title.Text = ColorPickerData.Title
				colorpicker.Name = ColorPickerData.Title

				local isLinkable = Instance.new("BoolValue")
				isLinkable.Name = 'isLinkable'
				isLinkable.Value = ColorPickerData.Linkable
				isLinkable.Parent = colorpicker

				local HueSat = Instance.new("Color3Value")
				HueSat.Name = 'HueSat'
				HueSat.Value = ColorPickerData.Color
				HueSat.Parent = colorpicker

				local Open = false
				local DeBounce = false
				local State = false

				colorpicker.color.Values.Hue.BackgroundTransparency = 1
				colorpicker.color.Values.Hue.Pin.BackgroundTransparency = 1
				colorpicker.color.Values.Hue.Pin.UIStroke.Transparency = 1
				colorpicker.color.Values.Rainbow.ImageTransparency = 1

				colorpicker.color.SVPicker.Pin.BackgroundTransparency = 1
				colorpicker.color.SVPicker.Pin.UIStroke.Transparency = 1
				colorpicker.color.SVPicker.Brightness.BackgroundTransparency = 1
				colorpicker.color.SVPicker.Saturation.BackgroundTransparency = 1

				colorpicker.HueValues.HEX.BackgroundTransparency = 1
				colorpicker.HueValues.HEX.UIStroke.Transparency = 1
				colorpicker.HueValues.HEX.V.HEXBox.TextTransparency = 1
				colorpicker.HueValues.HEX.Link.ImageTransparency = 1
				colorpicker.HueValues.HEX.Copy.ImageTransparency = 1

				colorpicker.HueValues.RGB.BackgroundTransparency = 1
				colorpicker.HueValues.RGB.UIStroke.Transparency = 1
				colorpicker.HueValues.RGB.V.RGBBox.TextTransparency = 1
				colorpicker.HueValues.RGB.Copy.ImageTransparency = 1
				colorpicker.QuickClose.Interactable = false
				TweenService:Create(colorpicker.color, TweenInfo.new( 0.6, Enum.EasingStyle.Exponential ), { BackgroundColor3 = ColorPickerData.Color }):Play()

				local recentContainer = colorpicker.color.Recent
				local spacing = 5
				local frameSize = 12 

				local function updateRecentLayout()
					local children = {} 
					for _, child in pairs(recentContainer:GetChildren()) do
						if child:IsA("Frame") then
							table.insert(children, child)
						end
					end

					table.sort(children, function(a, b)
						return a.LayoutOrder > b.LayoutOrder 
					end)

					-- Calculate total width needed
					local totalWidth = #children * frameSize + math.max(#children - 1, 0) * spacing
					local startX = recentContainer.AbsoluteSize.X - totalWidth 

					for _, frame in ipairs(children) do
						--	frame.Position = UDim2.new(0, startX, 0.5, -frame.Size.Y.Offset / 2)
						TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quart), {Position = UDim2.new(0, startX , 0.8, -frame.Size.Y.Offset / 2) }):Play()
						startX += frameSize + spacing
					end
				end

				recentContainer.ChildAdded:Connect(function(child)
					if child:IsA("Frame") then
						child.LayoutOrder = os.time() 
						updateRecentLayout()
					end
				end)
				recentContainer.ChildRemoved:Connect(updateRecentLayout)
				updateRecentLayout()

				local HSV

				if ColorPickerData.Color then
					HSV = { ColorPickerData.Color:ToHSV() }
				else

					HSV = { 0, 0, 0 }
				end
				local Selected = ColorPickerData.Color
				local HueValue = HSV[1]

				local function TableToColor(Table)
					if type(Table) ~= "table" then return Table end
					return Color3.fromHSV(Table[1],Table[2],Table[3])
				end

				local function FormatColor(Color, format, precision)

					format = format or "RGB"
					precision = precision or 2

					local formattedColor = ""

					if format == "RGB" then
						return	math.round(Color.R * 255) .. "," .. math.round(Color.G * 255) .. "," .. math.round(Color.B * 255)
					elseif format == "Hex" then
						formattedColor = string.format("#%02X%02X%02X",
							math.round(Color.R * 255),
							math.round(Color.G * 255),
							math.round(Color.B * 255)
						)

						return formattedColor
					end
				end

				local SVPicker = colorpicker.color.SVPicker
				local HUESlider = colorpicker.color.Values.Hue

				SVPicker.Pin.BackgroundColor3 = ColorPickerData.Color
				HUESlider.Pin.BackgroundColor3 = ColorPickerData.Color

				local function updatestuff()
					ColorPickerData.Color = TableToColor(HSV)
					colorpicker.color.BackgroundColor3 = ColorPickerData.Color
					colorpicker.color.glow.ImageColor3 = ColorPickerData.Color

					colorpicker.color.BackgroundColor3 = Color3.fromHSV(HSV[1], 1, 1)
					local newColor = Color3.fromHSV(HSV[1], HSV[2], HSV[3])
					local newColor2 = Color3.fromHSV(HSV[1], 1, 1)

					HueSat.Value = ColorPickerData.Color

					TweenService:Create(HUESlider.Pin, TweenInfo.new(0.1, Enum.EasingStyle.Exponential), {BackgroundColor3 = newColor2}):Play()
					TweenService:Create(SVPicker.Pin, TweenInfo.new(0.1, Enum.EasingStyle.Exponential), {BackgroundColor3 = newColor}):Play()


					TweenService:Create(SVPicker.Pin, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Position = UDim2.new(HSV[2], 0, 1 - HSV[3], 0)
					}):Play()

					TweenService:Create(HUESlider.Pin, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Position = UDim2.new(1 - HSV[1], 0, 0.5, 0)
					}):Play()

					local formattedHex = FormatColor(ColorPickerData.Color, 'Hex')
					colorpicker.HueValues.HEX.V.HEXBox.PlaceholderText = formattedHex

					local formattedRGB = FormatColor(ColorPickerData.Color,'RGB', 2)
					colorpicker.HueValues.RGB.V.RGBBox.PlaceholderText = formattedRGB

					if ColorPickerData.CallBack then
						ColorPickerData.CallBack(ColorPickerData.Color)
					end
				end
				updatestuff()

				local newColor = Color3.fromHSV(HSV[1], HSV[2], HSV[3])

				local function OpenPicker()
					Open = true
					DeBounce = true
					colorpicker.color.Values.Visible = true
					colorpicker.color.SVPicker.Visible = true
					colorpicker.HueValues.Visible = true
					colorpicker.color.Recent.Visible = true

					colorpicker.interact.Interactable = false
					colorpicker.QuickClose.Interactable = true

					TweenService:Create(colorpicker.color, TweenInfo.new( 0.95, Enum.EasingStyle.Quart ), { Size = UDim2.new(0, 1,0, 1) }):Play()
					TweenService:Create(colorpicker, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { BackgroundColor3 = Color3.fromRGB(35, 35, 35) }):Play()
					TweenService:Create(colorpicker.color, TweenInfo.new( 1, Enum.EasingStyle.Exponential ), { BackgroundColor3 = Color3.fromHSV(HSV[1], 1, 1) }):Play()
					TweenService:Create(colorpicker.QuickClose, TweenInfo.new( 0.6, Enum.EasingStyle.Exponential ), { BackgroundTransparency = 0 }):Play()
					TweenService:Create(colorpicker.color.glow, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { ImageTransparency = 1}):Play()
					task.wait(0.12)
					TweenService:Create(colorpicker.color, TweenInfo.new( 0.9, Enum.EasingStyle.Quart ), { Size = UDim2.new(1, -200,0, 120) }):Play()
					TweenService:Create(colorpicker, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { BackgroundColor3 = Color3.fromRGB(18, 18, 18) }):Play()
					TweenService:Create(colorpicker, TweenInfo.new( 0.8, Enum.EasingStyle.Quart ), { Size = UDim2.new(1, -15,0, 180) }):Play()
					TweenService:Create(colorpicker.color.Values.Rainbow, TweenInfo.new( 1, Enum.EasingStyle.Exponential ), { ImageTransparency = 0 }):Play()
					task.wait(0.6)

					TweenService:Create(colorpicker.color.SVPicker.Brightness, TweenInfo.new( 2, Enum.EasingStyle.Exponential ), { BackgroundTransparency = 0 }):Play()
					TweenService:Create(colorpicker.color.SVPicker.Saturation, TweenInfo.new( 2, Enum.EasingStyle.Exponential ), { BackgroundTransparency = 0 }):Play()
					TweenService:Create(colorpicker.color.SVPicker.Pin, TweenInfo.new( 2, Enum.EasingStyle.Exponential ), { BackgroundTransparency = 0 }):Play()
					TweenService:Create(colorpicker.color.SVPicker.Pin.UIStroke, TweenInfo.new( 2, Enum.EasingStyle.Exponential ), { Transparency = 0.58 }):Play()

					task.wait(0.5)
					TweenService:Create(colorpicker.color.Values.Hue, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { BackgroundTransparency = 0 }):Play()
					TweenService:Create(colorpicker.color.Values.Hue.Pin, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { BackgroundTransparency = 0 }):Play()
					TweenService:Create(colorpicker.color.Values.Hue.Pin.UIStroke, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { Transparency = 0.58 }):Play()

					TweenService:Create(colorpicker.HueValues.HEX, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { BackgroundTransparency = 0.9 }):Play()
					TweenService:Create(colorpicker.HueValues.HEX.UIStroke, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { Transparency = 0.4 }):Play()
					TweenService:Create(colorpicker.HueValues.HEX.V.HEXBox, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { TextTransparency = 0 }):Play()
					TweenService:Create(colorpicker.HueValues.HEX.Link, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { ImageTransparency = 0 }):Play()
					TweenService:Create(colorpicker.HueValues.HEX.Copy, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { ImageTransparency = 0 }):Play()

					task.wait(0.09)
					TweenService:Create(colorpicker.HueValues.RGB, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { BackgroundTransparency = 0.9 }):Play()
					TweenService:Create(colorpicker.HueValues.RGB.UIStroke, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { Transparency = 0.4 }):Play()
					TweenService:Create(colorpicker.HueValues.RGB.V.RGBBox, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { TextTransparency = 0 }):Play()
					TweenService:Create(colorpicker.HueValues.RGB.Copy, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { ImageTransparency = 0 }):Play()

					for _,v in ipairs(colorpicker.color.Recent:GetChildren()) do
						if v:IsA('Frame') then
							task.wait(0.1)
							TweenService:Create(v, TweenInfo.new( 0.3, Enum.EasingStyle.Exponential ), { BackgroundTransparency = 0 }):Play()
						end
					end

					task.wait(0.7)
					DeBounce = false
				end


				colorpicker.interact.MouseButton1Click:Connect(function()
					if DeBounce then return end
					if not Open then
						Open = true
						OpenPicker()
					end
				end)

				colorpicker.QuickClose.MouseEnter:Connect(function()
					TweenService:Create(colorpicker.QuickClose, TweenInfo.new( 0.8, Enum.EasingStyle.Quint ), { Size = UDim2.new(0, 70,0, 3) }):Play()
					TweenService:Create(colorpicker.QuickClose, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { BackgroundColor3 = Color3.fromRGB(255, 255, 255) }):Play()
				end)

				colorpicker.QuickClose.MouseLeave:Connect(function()
					TweenService:Create(colorpicker.QuickClose, TweenInfo.new( 0.8, Enum.EasingStyle.Quint ), { Size = UDim2.new(0, 60,0, 3) }):Play()
					TweenService:Create(colorpicker.QuickClose, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { BackgroundColor3 = Color3.fromRGB(33, 33, 33) }):Play()
				end)

				local function ClosePicker()
					Open = false
					DeBounce = true
					TweenService:Create(colorpicker, TweenInfo.new( 0.85, Enum.EasingStyle.Quint ), { Size = UDim2.new(1, -40,0, 40) }):Play()
					TweenService:Create(colorpicker.color, TweenInfo.new( 0.85, Enum.EasingStyle.Quint ), { Size = UDim2.new(0, 20,0, 20) }):Play()
					TweenService:Create(colorpicker.color, TweenInfo.new( 0.6, Enum.EasingStyle.Exponential ), { BackgroundColor3 = ColorPickerData.Color }):Play()
					TweenService:Create(colorpicker.QuickClose, TweenInfo.new( 0.6, Enum.EasingStyle.Exponential ), { BackgroundTransparency = 1 }):Play()
					TweenService:Create(colorpicker.color.glow, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { ImageTransparency = 0.73}):Play()
					colorpicker.interact.Interactable = true
					colorpicker.QuickClose.Interactable = false

					--	task.wait(0.6)

					TweenService:Create(colorpicker.color.SVPicker.Brightness, TweenInfo.new( 2, Enum.EasingStyle.Exponential ), { BackgroundTransparency = 1 }):Play()
					TweenService:Create(colorpicker.color.SVPicker.Saturation, TweenInfo.new( 2, Enum.EasingStyle.Exponential ), { BackgroundTransparency = 1 }):Play()
					TweenService:Create(colorpicker.color.SVPicker.Pin, TweenInfo.new( 1, Enum.EasingStyle.Exponential ), { BackgroundTransparency = 1 }):Play()
					TweenService:Create(colorpicker.color.SVPicker.Pin.UIStroke, TweenInfo.new( 0.4, Enum.EasingStyle.Exponential ), { Transparency = 1 }):Play()
					TweenService:Create(colorpicker.color.Values.Hue, TweenInfo.new( 0.5, Enum.EasingStyle.Exponential ), { BackgroundTransparency = 1 }):Play()
					TweenService:Create(colorpicker.color.Values.Hue.Pin, TweenInfo.new( 1, Enum.EasingStyle.Exponential ), { BackgroundTransparency = 1 }):Play()
					TweenService:Create(colorpicker.color.Values.Hue.Pin.UIStroke, TweenInfo.new( 0.5, Enum.EasingStyle.Exponential ), { Transparency = 1 }):Play()
					TweenService:Create(colorpicker.color.Values.Rainbow, TweenInfo.new( 0.5, Enum.EasingStyle.Exponential ), { ImageTransparency = 1 }):Play()

					TweenService:Create(colorpicker.HueValues.RGB, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { BackgroundTransparency = 1 }):Play()
					TweenService:Create(colorpicker.HueValues.RGB.UIStroke, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { Transparency = 1 }):Play()
					TweenService:Create(colorpicker.HueValues.RGB.V.RGBBox, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { TextTransparency = 1 }):Play()
					TweenService:Create(colorpicker.HueValues.RGB.Copy, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { ImageTransparency = 1 }):Play()

					task.wait(0.1)

					TweenService:Create(colorpicker.HueValues.HEX, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { BackgroundTransparency = 1 }):Play()
					TweenService:Create(colorpicker.HueValues.HEX.UIStroke, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { Transparency = 1 }):Play()
					TweenService:Create(colorpicker.HueValues.HEX.V.HEXBox, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { TextTransparency = 1 }):Play()
					TweenService:Create(colorpicker.HueValues.HEX.Link, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { ImageTransparency = 1 }):Play()
					TweenService:Create(colorpicker.HueValues.HEX.Copy, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { ImageTransparency = 1 }):Play()
					for _,v in ipairs(colorpicker.color.Recent:GetChildren()) do
						if v:IsA('Frame') then
							TweenService:Create(v, TweenInfo.new( 0.6, Enum.EasingStyle.Exponential ), { BackgroundTransparency = 1 }):Play()
						end
					end
					task.wait(1)
					colorpicker.color.SVPicker.Visible = false
					colorpicker.color.Recent.Visible = false
					task.wait(0.7)
					DeBounce = false
				end

				colorpicker.QuickClose.MouseButton1Click:Connect(function()
					if DeBounce then return end
					if Open then
						Open = false
						ClosePicker()
					end
				end)

				local function AddRecentColor(newColor)
					local recentFrame = colorpicker.colorPlaceHolder:Clone()
					recentFrame.Visible = true
					recentFrame.Parent = colorpicker.color.Recent
					recentFrame.BackgroundColor3 = newColor

					recentFrame.interact.MouseButton1Click:Connect(function()
				--[[	TweenService:Create(recentFrame, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 5,0, 5) }):Play()
					task.wait(0.09)
					TweenService:Create(recentFrame, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 12,0, 12) }):Play() ]]

						local h, s, v = newColor:ToHSV()
						if s > 0.02 then
							HSV[1] = h
						end
						HSV[2] = s
						HSV[3] = v
						updatestuff()

					end)

					recentFrame.interact.MouseEnter:Connect(function()
						TweenService:Create(recentFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Size = UDim2.new(0, 20,0, 20) }):Play()
					end)

					recentFrame.interact.MouseLeave:Connect(function()
						TweenService:Create(recentFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Size = UDim2.new(0, 12,0, 12) }):Play()
					end)

					local maxRecentColors = 10
					local recentContainer = colorpicker.color.Recent

					local children = recentContainer:GetChildren()
					if #children > maxRecentColors then
						for _, child in ipairs(children) do
							if child:IsA("Frame") then
								child:Destroy()
								break
							end
						end
					end
				end

				local SV, HUE = nil, nil

				syde:AddConnection(SVPicker.InputBegan, function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						SV = RunService.RenderStepped:Connect(function()
							local mouse = game.Players.LocalPlayer:GetMouse()
							local ColorX = math.clamp(mouse.X - SVPicker.AbsolutePosition.X, 0, SVPicker.AbsoluteSize.X) / SVPicker.AbsoluteSize.X
							local ColorY = math.clamp(mouse.Y - SVPicker.AbsolutePosition.Y, 0, SVPicker.AbsoluteSize.Y) / SVPicker.AbsoluteSize.Y

							HSV[2] = ColorX
							HSV[3] = 1 - ColorY

							updatestuff()
						end)
					end
				end)

				syde:AddConnection(SVPicker.InputEnded, function(i)
					if i.UserInputType == Enum.UserInputType.MouseButton1 and SV then
						SV:Disconnect()
						SV = nil
						AddRecentColor(ColorPickerData.Color)
					end
				end)

				syde:AddConnection(HUESlider.InputBegan, function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						HUE = RunService.RenderStepped:Connect(function()
							local mouse = game.Players.LocalPlayer:GetMouse()
							local ColorX = math.clamp(mouse.X - HUESlider.AbsolutePosition.X, 0, HUESlider.AbsoluteSize.X) / HUESlider.AbsoluteSize.X

							HSV[1] = 1 - ColorX

							updatestuff()
						end)
					end
				end)

				syde:AddConnection(HUESlider.InputEnded, function(i)
					if i.UserInputType == Enum.UserInputType.MouseButton1 and HUE then
						HUE:Disconnect()
						HUE = nil
						AddRecentColor(ColorPickerData.Color)
					end
				end)

				colorpicker.HueValues.HEX.V.HEXBox.FocusLost:Connect(function(Enter)
					if not Enter then return end

					local hexInput = colorpicker.HueValues.HEX.V.HEXBox.Text

					local success, result = pcall(function()
						return Color3.fromHex(hexInput)
					end)

					if success then
						local Hue, Saturation, Value = result:ToHSV()
						colorpicker.HueValues.HEX.V.HEXBox.Text = ''
						if Saturation > 0.02 then
							HSV[1] = Hue
						end
						HSV[2] = Saturation
						HSV[3] = Value
						updatestuff()
					else
					end
				end)

				colorpicker.HueValues.RGB.V.RGBBox.FocusLost:Connect(function(Enter)
					if not Enter then return end

					local rgbInput = colorpicker.HueValues.RGB.V.RGBBox.Text

					local r, g, b = rgbInput:match("^(%d+),%s*(%d+),%s*(%d+)$")

					if r and g and b then

						r, g, b = tonumber(r), tonumber(g), tonumber(b)

						if r >= 0 and r <= 255 and g >= 0 and g <= 255 and b >= 0 and b <= 255 then
							local color = Color3.fromRGB(r, g, b)

							local Hue, Saturation, Value = color:ToHSV()
							if Saturation > 0.02 then
								HSV[1] = Hue
							end
							HSV[2] = Saturation
							HSV[3] = Value

							colorpicker.HueValues.RGB.V.RGBBox.Text = ''
							updatestuff()
						else
						end
					else
					end
				end)


				local linkDragging = false
				local originalPosition = UDim2.new(1, -10, 0.5, 0)
				local draggedColorPicker = nil

				local function isMouseOver(guiObject)
					local mouse = game.Players.LocalPlayer:GetMouse()
					local pos = guiObject.AbsolutePosition
					local size = guiObject.AbsoluteSize
					return mouse.X >= pos.X and mouse.X <= pos.X + size.X and mouse.Y >= pos.Y and mouse.Y <= pos.Y + size.Y
				end

				colorpicker.HueValues.HEX.Link.MouseButton1Down:Connect(function()
					linkDragging = true
					draggedColorPicker = colorpicker

					TweenService:Create(colorpicker.HueValues.HEX.Link, TweenInfo.new(0.5, Enum.EasingStyle.Exponential) , {ImageColor3 = Color3.fromRGB(255, 255, 255)}):Play()
					TweenService:Create(colorpicker.HueValues.HEX.Link, TweenInfo.new(0.5, Enum.EasingStyle.Exponential) , {Size = UDim2.new(0, 20,0, 20)}):Play()

					local followMouse
					followMouse = RunService.RenderStepped:Connect(function()
						if not linkDragging then
							followMouse:Disconnect()
							return
						end
						local mouse = game.Players.LocalPlayer:GetMouse()
						colorpicker.HueValues.HEX.Link.Position = UDim2.new(0, mouse.X - colorpicker.AbsolutePosition.X - 10, 0, mouse.Y - colorpicker.AbsolutePosition.Y - 100)

						for _, otherPicker in pairs(Parent:GetChildren()) do
							if otherPicker:IsA("Frame") and otherPicker:FindFirstChild("isLinkable") and otherPicker.isLinkable.Value then
								if isMouseOver(otherPicker) and otherPicker ~= draggedColorPicker then
									TweenService:Create(otherPicker.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
								else
									TweenService:Create(otherPicker.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
								end
							end
						end
					end)
				end)

				UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 and linkDragging then
						linkDragging = false
						local foundTarget = false

						for _, otherPicker in pairs(Parent:GetChildren()) do
							if otherPicker:IsA("Frame") and otherPicker:FindFirstChild("isLinkable") and otherPicker.isLinkable.Value then
								if isMouseOver(otherPicker) and otherPicker ~= draggedColorPicker then
									otherPicker.HueSat.Value = draggedColorPicker.HueSat.Value
									updatestuff() 
									foundTarget = true
									TweenService:Create(
										colorpicker.HueValues.HEX.Link,
										TweenInfo.new(0.3, Enum.EasingStyle.Quint),
										{ Position = originalPosition }
									):Play()

									TweenService:Create(otherPicker.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
									TweenService:Create(colorpicker.HueValues.HEX.Link, TweenInfo.new(0.5, Enum.EasingStyle.Exponential) , {ImageColor3 = Color3.fromRGB(66, 66, 66)}):Play()
									TweenService:Create(colorpicker.HueValues.HEX.Link, TweenInfo.new(0.5, Enum.EasingStyle.Exponential) , {Size = UDim2.new(0, 15,0, 15)}):Play()
									break
								end
							end
						end

						if not foundTarget then
							TweenService:Create(colorpicker.HueValues.HEX.Link, TweenInfo.new(0.5, Enum.EasingStyle.Exponential) , {ImageColor3 = Color3.fromRGB(66, 66, 66)}):Play()
							TweenService:Create(colorpicker.HueValues.HEX.Link, TweenInfo.new(0.5, Enum.EasingStyle.Exponential) , {Size = UDim2.new(0, 15,0, 15)}):Play()
							TweenService:Create(
								colorpicker.HueValues.HEX.Link,
								TweenInfo.new(0.3, Enum.EasingStyle.Quint),
								{ Position = originalPosition }
							):Play()
						end
					end
				end)

				local function updateColorPicker()
					local Hue, Saturation, Value = HueSat.Value:ToHSV()

					if Saturation > 0.02 then
						HSV[1] = Hue
					end
					HSV[2] = Saturation
					HSV[3] = Value

					updatestuff()
				end

				HueSat.Changed:Connect(updateColorPicker)

				local hueIncrement = 0.005 

				local function RainbowEffect()
					HueValue = (HueValue + hueIncrement) % 1
					HSV[1] = HueValue

					updatestuff()
				end

				local isRainbowEnabled = false
				local huerender = nil

				local function ToggleRainbowEffect()
					isRainbowEnabled = not isRainbowEnabled
					if isRainbowEnabled then
						if not huerender then
							huerender = RunService.RenderStepped:Connect(RainbowEffect)
							TweenService:Create(colorpicker.color.Values.Rainbow, TweenInfo.new(0.5, Enum.EasingStyle.Exponential ), {ImageColor3 = Color3.fromRGB(255, 255, 255)}):Play()
						end
					else
						if huerender then
							huerender:Disconnect()
							TweenService:Create(colorpicker.color.Values.Rainbow, TweenInfo.new(0.5, Enum.EasingStyle.Exponential ), {ImageColor3 = Color3.fromRGB(62, 62, 62)}):Play()
							huerender = nil
						end
					end
				end

				function ColorPickerData:Set(RGBColor)

					if typeof(RGBColor) == "table" then
						RGBColor = Color3.fromRGB(RGBColor.R, RGBColor.G, RGBColor.B)
					end

					ColorPickerData.Color = RGBColor

					local h, s, v = RGBColor:ToHSV()
					HSV[1], HSV[2], HSV[3] = h, s, v
					updatestuff()
				end

				if ColorPickerData.SFlag then
					syde.SettingsFlags[ColorPickerData.SFlag] = ColorPickerData
				end

				colorpicker.color.Values.Rainbow.MouseButton1Click:Connect(ToggleRainbowEffect)

				return ColorPickerData

			end

			---

			function element:Section(Title, Parent, Icon)
				local SectionData = {
					Title = Title
				}

				local Section =  Library.Settings.Section:Clone()
				Section.Visible = true
				Section.Title.Text = Title
				Section.Parent = Parent
				Section.Title.Position = UDim2.new(0, 0,0, 0)

				if Icon then
					Section.icon.Image = 'rbxassetid://'..Icon
					Section.Title.Position = UDim2.new(0, 25,0, 0)
				else
					Section.icon.Visible = false
				end
			end

			function element:Paragraph(Paragraph, Parent)
				local ParaData = {
					Title = Paragraph.Title;
					Content = Paragraph.Content;
				}

				local Para = Library.Settings.Paragraph:Clone()
				Para.Visible = true
				Para.Parent = Parent
				Para.Title.Text = ParaData.Title
				Para.Content.Text = ParaData.Content

				Para.Content.Size = UDim2.new(1, -20, 0, Para.Content.TextBounds.Y)
				Para.Size = UDim2.new(1, -15, 0, Para.Content.Size.Y.Offset + 45)

				local function updateSize()
					local textSize = TextService:GetTextSize(
						Para.Content.Text,
						Para.Content.TextSize,
						Para.Content.Font,
						Vector2.new(Para.Content.AbsoluteSize.X, math.huge) -- Allows vertical expansion
					)

					local newDescSize = UDim2.new(1, -20, 0, textSize.Y)
					local newButtonSize = UDim2.new(Para.Size.X.Scale, -40, 0, textSize.Y + 40) -- Adding extra padding

					local descTween = TweenService:Create(Para.Content, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = newDescSize })
					descTween:Play()

					local buttonTween = TweenService:Create(Para, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = newButtonSize })
					buttonTween:Play()
				end

				updateSize()

				Para.Content:GetPropertyChangedSignal("TextBounds"):Connect(updateSize)

				local ParagraphSettings = {}

				function ParagraphSettings:Set(text, title)
					Para.Title.Text = title
					Para.Content.Text = text
				end

				ParagraphSettings.Instance = Para

				return ParagraphSettings

			end

			function element:CreateSlider(Slider, Parent)
				local SliderData = {
					Title = Slider.Title;
					Desc = Slider.Description;
					Sliders = Slider.Sliders
				}

				local slider = Library.Settings.Slider:Clone()
				slider.Visible = true
				slider.Parent = Parent
				slider.Title.Text = SliderData.Title
				slider.Name = SliderData.Title
				slider.slideholder.slider.Visible = false


				--[SLIDERS INITIALIZE]
				for _, Options in ipairs(SliderData.Sliders) do
					local Slider =  Library.Settings.Slider.slideholder.slider:Clone()

					Options = {
						Title = Options.Title or "Slider";
						Increment = Options.Increment or 1;
						Range = Options.Range or {0, 100};
						StarterValue = Options.StarterValue or 16;
						CallBack = Options.CallBack;
						SFlag = Options.SFlag;
						SettingsConfig = true;
					}

					Slider.Name = Options.Title
					Slider.Title.Text = Options.Title

					local dragging = false
					Slider.Visible = true
					Slider.Parent = slider.slideholder

					local SliderPosition
					if Options.StarterValue <= Options.Range[1] then
						SliderPosition = 0
					elseif Options.StarterValue >= Options.Range[2] then
						SliderPosition = 1
					else
						local range = Options.Range[2] - Options.Range[1]
						SliderPosition = (Options.StarterValue - Options.Range[1]) / range
					end

					--Slider.slide.slideframe:TweenSize(UDim2.new(SliderPosition, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quint, 0.5, true)
					TweenService:Create(Slider.slide.slideframe, TweenInfo.new(0.55, Enum.EasingStyle.Quint), {Size = UDim2.new(SliderPosition, 0, 1, 0)}):Play()

					local decimalPlaces = tostring(Options.Increment):match("%.([^0]*)") and #tostring(Options.Increment):match("%.([^0]*)") or 0
					Slider.v.Text = string.format("<font size='14'>%." .. decimalPlaces .. "f</font><font color='#434343'>/%." .. decimalPlaces .. "f</font>", Options.StarterValue, Options.Range[2])


					local function UpdateSlider(x)
						if dragging then
							local sliderStart = Slider.slide.AbsolutePosition.X
							local sliderWidth = Slider.slide.AbsoluteSize.X
							local sliderPosition = (x - sliderStart) / sliderWidth
							sliderPosition = math.clamp(sliderPosition, 0, 1)

							local range = Options.Range[2] - Options.Range[1]
							local newValue = Options.Range[1] + sliderPosition * range
							newValue = math.floor((newValue - Options.Range[1]) / Options.Increment + 0.5) * Options.Increment + Options.Range[1]

							-- Update the slider visual position
							local snapPosition = (newValue - Options.Range[1]) / range
							--	Slider.slide.slideframe:TweenSize(UDim2.new(snapPosition, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quint, 0.55, true)
							TweenService:Create(Slider.slide.slideframe, TweenInfo.new(0.55, Enum.EasingStyle.Quint), {Size = UDim2.new(snapPosition, 0, 1, 0)}):Play()


							-- Update the displayed value
							local decimalPlaces = tostring(Options.Increment):match("%.([^0]*)") and #tostring(Options.Increment):match("%.([^0]*)") or 0
							Slider.v.Text = string.format("<font size='14'>%." .. decimalPlaces .. "f</font><font color='#434343'>/%." .. decimalPlaces .. "f</font>", newValue, Options.Range[2])


							TweenService:Create(Slider.Title, TweenInfo.new(0.55, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()

							local success, errorMsg = pcall(function()
								Options.CallBack(newValue)
							end)
							if not success then
							end


							Options.StarterValue = newValue
						end
					end

					Slider.slide.Interact.MouseButton1Down:Connect(function()
						dragging = true
					end)

					Slider.slide.Interact.MouseButton1Up:Connect(function()
						dragging = false
					end)


					SettingsElements:AddConnection(UserInputService.InputEnded, function(input, processed)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							dragging = false
							if Slider and Slider:FindFirstChild("Title") then
								TweenService:Create(Slider.Title, TweenInfo.new( 0.5, Enum.EasingStyle.Exponential ), { TextTransparency = 0.6 }):Play()
							end
						end
					end)

					SettingsElements:AddConnection(UserInputService.InputChanged, function(input)
						if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
							UpdateSlider(input.Position.X)
						end
					end)

		--[[Slider.slide.slideframe.BackgroundColor3 = syde.theme.HitBox
		Slider.slide.slideframe.shadowHolder.ambientShadow.ImageColor3 = syde.theme.HitBox
		Slider.slide.slideframe.shadowHolder.penumbraShadow.ImageColor3 = syde.theme.HitBox
		Slider.slide.slideframe.shadowHolder.umbraShadow.ImageColor3 = syde.theme.HitBox]]
					slider.slideholder.Size = UDim2.new(1,-30,0,slider.slideholder.UIListLayout.AbsoluteContentSize.Y)
					local ss = slider.slideholder.UIListLayout.AbsoluteContentSize.Y
					slider.Size = UDim2.new(1,-15,0, ss  + 20)

		--[[syde:AddConnection(syde.Comms.Event, function(p, color)
			if p == 'HitBox' then
				Slider.slide.slideframe.BackgroundColor3 = color
				Slider.slide.slideframe.shadowHolder.ambientShadow.ImageColor3 = color
				Slider.slide.slideframe.shadowHolder.penumbraShadow.ImageColor3 = color
				Slider.slide.slideframe.shadowHolder.umbraShadow.ImageColor3 = color
			end
		end)]]

					function Options:Set(NewVal)
						local range = Options.Range[2] - Options.Range[1]
						local sliderPosition = (NewVal - Options.Range[1]) / range

						Slider.slide.slideframe:TweenSize(
							UDim2.new(sliderPosition, 0, 1, 0),
							Enum.EasingDirection.Out,
							Enum.EasingStyle.Quint,
							0.55,
							true
						)

						-- Register load tween
						syde:registerLoadTween(
							Slider.slide.slideframe,
							{Size = UDim2.new(sliderPosition, 0, 1, 0)},
							{Size = UDim2.new(0, 100, 1, 0)},
							TweenInfo.new(0.85, Enum.EasingStyle.Quint)
						) 

						local decimalPlaces = tostring(Options.Increment):match("%.([^0]*)") and #tostring(Options.Increment):match("%.([^0]*)") or 0
						Slider.v.Text = string.format("<font size='14'>%." .. decimalPlaces .. "f</font><font color='#434343'>/%." .. decimalPlaces .. "f</font>", NewVal, Options.Range[2])

						-- Tween title appearance
						TweenService:Create(Slider.Title, TweenInfo.new(0.55, Enum.EasingStyle.Exponential), {
							TextTransparency = 0
						}):Play()

						-- Callback
						local success, result = pcall(function()
							Options.CallBack(NewVal)
						end)
						if not success then
						end

						Options.StarterValue = NewVal
					end

					if Options.SFlag then
						syde.SettingsFlags[Options.SFlag] = Options
					end

				end

				--[DESC]
				local descLabel = slider.slideholder:FindFirstChild("Desc")

				if descLabel then
					if SliderData.Desc and SliderData.Desc ~= "" then
						descLabel.Text = SliderData.Desc
						descLabel.Visible = true
						descLabel.TextWrapped = true

						local function updateSize()
							local textSize = TextService:GetTextSize(
								descLabel.Text,
								descLabel.TextSize,
								descLabel.Font,
								Vector2.new(descLabel.AbsoluteSize.X, math.huge) -- Allows vertical expansion
							)

							local newDescSize = UDim2.new(1, -150, 0, textSize.Y)
							local newButtonSize = UDim2.new(slider.Size.X.Scale, slider.Size.X.Offset, 0,slider.slideholder.AbsoluteSize.Y + slider.Title.Size.Y.Offset + textSize.Y - 5) -- Adding extra padding

							local descTween = TweenService:Create(descLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = newDescSize })
							descTween:Play()

							local ToggleTween = TweenService:Create(slider, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = newButtonSize })
							ToggleTween:Play()
						end

						updateSize()

						descLabel:GetPropertyChangedSignal("TextBounds"):Connect(updateSize)
					else
						descLabel.Visible = false
					end
				end


			end

              function element:Keybind(Keybind, Parent)
				local KeybindData = {
					Title = Keybind.Title;
					Key = Keybind.Key;
					Desc = Keybind.Description or "";
					CallBack = Keybind.CallBack;
					WaitingForKey = false;
					Hold = false;
					Holding = false
				}

				local KeyBind = Library.Settings.KeyBind:Clone()
				KeyBind.Visible = true
				KeyBind.Parent = Parent
				KeyBind.Title.Text = KeybindData.Title
				KeyBind.Name = KeybindData.Title

				KeyBind.Bind.v.Text = KeybindData.Key and KeybindData.Key.Name or "NONE"
				TweenService:Create(KeyBind.Bind, TweenInfo.new(0.55, Enum.EasingStyle.Quint ), {Size = UDim2.new(0, KeyBind.Bind.v.TextBounds.X + 15, 0, KeyBind.Bind.Size.Y.Offset)}):Play()

				KeyBind.interact.MouseButton1Click:Connect(function()
					KeyBind.Bind.v.Text = '...'
					KeybindData.WaitingForKey = true
				end)

				KeyBind.Bind.v:GetPropertyChangedSignal('TextBounds'):Connect(function()
					TweenService:Create(KeyBind.Bind, TweenInfo.new(0.55, Enum.EasingStyle.Quint ), {Size = UDim2.new(0, KeyBind.Bind.v.TextBounds.X + 15, 0, KeyBind.Bind.Size.Y.Offset)}):Play()
				end)

				local function SetKeybind(keyCode)
					if keyCode and keyCode ~= Enum.KeyCode.Unknown then
						KeybindData.Key = keyCode
						KeyBind.Bind.v.Text = keyCode.Name

						if typeof(Keybind.OnKeyChanged) == "function" then
							pcall(Keybind.OnKeyChanged, keyCode)
						end
					else
						KeybindData.Key = nil
						KeyBind.Bind.v.Text = "NONE"
					end
				end

				SettingsElements:AddConnection(UserInputService.InputBegan, function(input, gameProcessed)
					if gameProcessed then return end
					if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

					if KeybindData.WaitingForKey then
						KeybindData.WaitingForKey = false
						SetKeybind(input.KeyCode)
						return
					end

					if input.KeyCode == KeybindData.Key then
						KeybindData.Hold = true

						local holdConnection
						holdConnection = input.Changed:Connect(function(prop)
							if prop == "UserInputState" then
								local state = input.UserInputState
								KeybindData.Hold = (state == Enum.UserInputState.Begin)
								if state == Enum.UserInputState.End and holdConnection then
									holdConnection:Disconnect()
								end
							end
						end)

						local success, result = pcall(KeybindData.CallBack, KeybindData.Key)
						if not KeybindData.Holding then
							if not success then
							end
						else
							if KeybindData.Hold then
								local holdLoop
								holdLoop = RunService.RenderStepped:Connect(function()
									if not KeybindData.Hold then
										KeybindData.CallBack(false)
										holdLoop:Disconnect()
									else
										KeybindData.CallBack(false)
									end
								end)
							end
						end
					end
				end)

			end

			function element:Toggle(Toggle, Parent)
				local ToggleData = {
					Title = Toggle.Title or "Temp Toggle";
					Desc = Toggle.Description or "";
					Value = Toggle.Value or false;
					Config = Toggle.Config or false;
					CallBack = Toggle.CallBack;
					SFlag = Toggle.SFlag;
					SettingsConfig = true;
				}

				local toggle = Library.Settings.Toggle:Clone()
				toggle.Visible = true
				toggle.Parent = Parent
				toggle.Title.Text = ToggleData.Title
				toggle.Name = ToggleData.Title

				local toggleConfiguration = UI.Render.ToggleConfiguration:Clone()
				toggleConfiguration.Parent = UI.Render
				toggleConfiguration.Visible = false

				toggleConfiguration.Container.KeyBind.Bind.v.Text = 'None'
				TweenService:Create(toggleConfiguration.Container.KeyBind.Bind, TweenInfo.new(0.5, Enum.EasingStyle.Quint), { Size = UDim2.new(0, toggleConfiguration.Container.KeyBind.Bind.v.TextBounds.X + 20,0, 28) }):Play()

				toggleConfiguration.BackgroundTransparency = 1
				toggleConfiguration.Container.KeyBind.Title.TextTransparency = 1
				toggleConfiguration.Container.KeyBind.Bind.BackgroundTransparency = 1
				toggleConfiguration.Container.KeyBind.Bind.v.TextTransparency = 1
				toggleConfiguration.Container.Clear.Title.TextTransparency = 1
				toggleConfiguration.Container.Clear.clear.ImageLabel.ImageTransparency = 1
				toggleConfiguration.Size = UDim2.new(0, 75,0, 53)

				if not ToggleData.Config then
					toggle.Configure:Destroy()
				end

				local toggleTween = TweenInfo.new(0.7, Enum.EasingStyle.Exponential)
				local fadeTween = TweenInfo.new(0.57, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

				local function UpdateToggleUI(state)
					local targetColor = state and syde.theme.HitBox or Color3.fromRGB(20, 20, 20)
					local strokeTransparency = state and 1 or 0
					local checkTransparency = state and 0 or 1
					local gradientTransparency = state and 0 or 1

					TweenService:Create(toggle.tog, toggleTween, { BackgroundColor3 = targetColor }):Play()
					TweenService:Create(toggle.tog.UIStroke, toggleTween, { Transparency = strokeTransparency }):Play()
					TweenService:Create(toggle.tog.check, toggleTween, { ImageTransparency = checkTransparency }):Play()
					TweenService:Create(toggle.tog.gradfr, fadeTween, { BackgroundTransparency = gradientTransparency }):Play()
				end

				UpdateToggleUI(ToggleData.Value)

				toggle.interact.MouseButton1Click:Connect(function()
					ToggleData.Value = not ToggleData.Value
					UpdateToggleUI(ToggleData.Value)

					local success, errorMsg = pcall(function()
						if ToggleData.CallBack then
							ToggleData.CallBack(ToggleData.Value)
						end
					end)

					if not success then
					end

				end)

				--[DESC]
				local descLabel = toggle:FindFirstChild("Desc")

				if descLabel then
					if ToggleData.Desc and ToggleData.Desc ~= "" then
						descLabel.Text = ToggleData.Desc
						descLabel.Visible = true
						descLabel.TextWrapped = true

						local function updateSize()
							local textSize = TextService:GetTextSize(
								descLabel.Text,
								descLabel.TextSize,
								descLabel.Font,
								Vector2.new(descLabel.AbsoluteSize.X, math.huge)
							)

							local newDescSize = UDim2.new(1, -150, 0, textSize.Y)
							local newButtonSize = UDim2.new(toggle.Size.X.Scale, toggle.Size.X.Offset, 0, toggle.Title.Size.Y.Offset + textSize.Y + 5) -- Adding extra padding

							local descTween = TweenService:Create(descLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = newDescSize })
							descTween:Play()

							local ToggleTween = TweenService:Create(toggle, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = newButtonSize })
							ToggleTween:Play()
						end

						updateSize()

						descLabel:GetPropertyChangedSignal("TextBounds"):Connect(updateSize)
					else
						descLabel.Visible = false
					end
				end


				-- [CONFIGURATIPON]
				if ToggleData.Config then

					local State = false

					local enterTween = TweenInfo.new(0.5, Enum.EasingStyle.Exponential)
					local leaveTween = TweenInfo.new(0.5, Enum.EasingStyle.Exponential)

					toggle.Configure.MouseEnter:Connect(function()
						TweenService:Create(toggle.Configure, enterTween, { ImageColor3 = Color3.fromRGB(255, 255, 255) }):Play()
					end)

					toggle.Configure.MouseLeave:Connect(function()
						TweenService:Create(toggle.Configure, leaveTween, { ImageColor3 = Color3.fromRGB(104, 104, 104) }):Play()
					end)

					local function ToggleConfigOpen()
						toggleConfiguration.Visible = true
						State = true

						TweenService:Create(toggleConfiguration, enterTween, { BackgroundTransparency = 0 }):Play()
						TweenService:Create(toggleConfiguration.Container.KeyBind.Title, enterTween, { TextTransparency = 0 }):Play()
						TweenService:Create(toggleConfiguration.Container.KeyBind.Bind, enterTween, { BackgroundTransparency = 0 }):Play()
						TweenService:Create(toggleConfiguration.Container.KeyBind.Bind.v, enterTween, { TextTransparency = 0 }):Play()
						TweenService:Create(toggleConfiguration.Container.Clear.clear.ImageLabel, enterTween, { ImageTransparency = 0 }):Play()
						TweenService:Create(toggleConfiguration.Container.Clear.Title, enterTween, { TextTransparency = 0 }):Play()
						TweenService:Create(toggleConfiguration, TweenInfo.new(0.7, Enum.EasingStyle.Quint), { Size = UDim2.new(0, 186,0, 85) }):Play()

					end

					local function ToggleConfigClose()
						State = false

						TweenService:Create(toggleConfiguration, enterTween, { BackgroundTransparency = 1 }):Play()
						TweenService:Create(toggleConfiguration.Container.KeyBind.Title, enterTween, { TextTransparency = 1 }):Play()
						TweenService:Create(toggleConfiguration.Container.KeyBind.Bind, enterTween, { BackgroundTransparency = 1 }):Play()
						TweenService:Create(toggleConfiguration.Container.KeyBind.Bind.v, enterTween, { TextTransparency = 1 }):Play()
						TweenService:Create(toggleConfiguration.Container.Clear.clear.ImageLabel, enterTween, { ImageTransparency = 1 }):Play()
						TweenService:Create(toggleConfiguration.Container.Clear.Title, enterTween, { TextTransparency = 1 }):Play()
						TweenService:Create(toggleConfiguration, TweenInfo.new(0.7, Enum.EasingStyle.Quint), { Size = UDim2.new(0, 75,0, 53) }):Play()

						task.wait(0.5)

						toggleConfiguration.Visible = false

					end

					local TogService
					local heldKeys = {} 
					local debounce1 = false

					local function ToggleConfig()
						if debounce1 then return end
						debounce1 = true

						if not toggleConfiguration.Visible then
							TogService = RunService.RenderStepped:Connect(function()
								toggleConfiguration:TweenPosition(UDim2.new(0,toggle.Configure.AbsolutePosition.X - 190,0,toggle.Configure.AbsolutePosition.Y + toggle.Configure.AbsoluteSize.Y + 65), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.1, true)
								if not toggleConfiguration.Visible then
									TogService:Disconnect()
								end
							end)
							ToggleConfigOpen()
						else
							if TogService then TogService:Disconnect() end
							ToggleConfigClose()
						end

						task.delay(0.4, function()
							debounce1 = false
						end)
					end

					toggle.Configure.MouseButton1Click:Connect(function()
						ToggleConfig()
					end)

					local function ResizeBindFrame()
						TweenService:Create(toggleConfiguration.Container.KeyBind.Bind, TweenInfo.new(0.5, Enum.EasingStyle.Quint), { Size = UDim2.new(0, toggleConfiguration.Container.KeyBind.Bind.v.TextBounds.X + 20,0, 28) }):Play()
					end

					local function setKeybind(key)
						if not key then
							toggleConfiguration.Container.KeyBind.Bind.v.Text = 'None'
							ResizeBindFrame()
							ToggleData.Keybind = nil
						else
							ToggleData.Keybind = key
							ToggleData.KeybindReady = false

							TweenService:Create(toggleConfiguration.Container.KeyBind.Bind.v, TweenInfo.new(0.25, Enum.EasingStyle.Exponential), { TextTransparency = 1 }):Play()
							toggleConfiguration.Container.KeyBind.Bind.v.Text = key.Name
							TweenService:Create(toggleConfiguration.Container.KeyBind.Bind.v, TweenInfo.new(1, Enum.EasingStyle.Exponential), { TextTransparency = 0 }):Play()
							ResizeBindFrame()

							task.delay(0.5, function()
								ToggleData.KeybindReady = true
							end)
						end
					end

					toggleConfiguration.Container.KeyBind.Interact.MouseButton1Click:Connect(function()
						TweenService:Create(toggleConfiguration.Container.KeyBind.Bind.v, TweenInfo.new(0.25, Enum.EasingStyle.Exponential), { TextTransparency = 1 }):Play()
						task.wait(0.2)
						toggleConfiguration.Container.KeyBind.Bind.v.Text = "..."
						TweenService:Create(toggleConfiguration.Container.KeyBind.Bind.v, TweenInfo.new(0.25, Enum.EasingStyle.Exponential), { TextTransparency = 0 }):Play()
						ResizeBindFrame()


						local connection
						connection = UserInputService.InputBegan:Connect(function(input, processed)
							if not processed and input.UserInputType == Enum.UserInputType.Keyboard then
								setKeybind(input.KeyCode)
								connection:Disconnect()
							end
						end)
					end)

					UserInputService.InputBegan:Connect(function(input, processed)
						if not processed and ToggleData.Keybind and ToggleData.KeybindReady and input.KeyCode == ToggleData.Keybind then
							ToggleData.Value = not ToggleData.Value
							UpdateToggleUI(ToggleData.Value)

							if ToggleData.CallBack then
								local success, errorMsg = pcall(function()
									ToggleData.CallBack(ToggleData.Value)
								end)
								if not success then
								end
							end
						end
					end)

					local debounce2 = false

					toggleConfiguration.Container.Clear.Interact.MouseButton1Click:Connect(function()
						if debounce2 then return end
						debounce2 = true

						setKeybind(nil)

						local function blink()
							TweenService:Create(toggleConfiguration.Container.Clear.clear.ImageLabel, TweenInfo.new(0.25, Enum.EasingStyle.Quint), { Rotation = 13 }):Play()
							task.wait(0.2)
							TweenService:Create(toggleConfiguration.Container.Clear.clear.ImageLabel, TweenInfo.new(0.25, Enum.EasingStyle.Quint), { Rotation = -13 }):Play()
							task.wait(0.2)
							TweenService:Create(toggleConfiguration.Container.Clear.clear.ImageLabel, TweenInfo.new(0.25, Enum.EasingStyle.Quint), { Rotation = 0 }):Play()
						end

						blink()

						task.delay(2, function()
							debounce2 = false
						end)
					end)

					toggleConfiguration.Container.Clear.MouseEnter:Connect(function()
						TweenService:Create(toggleConfiguration.Container.Clear.clear, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), { BackgroundTransparency = 0.9 }):Play()
					end)

					toggleConfiguration.Container.Clear.MouseLeave:Connect(function()
						TweenService:Create(toggleConfiguration.Container.Clear.clear, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), { BackgroundTransparency = 1 }):Play()
					end)

				end

				function ToggleData:Set(NewValue)

					ToggleData.Value = NewValue
					UpdateToggleUI(NewValue)

					local success, errorMsg = pcall(function()
						if ToggleData.CallBack then
							ToggleData.CallBack(NewValue)
						end
					end)

					if not success then
					end

				end

				if ToggleData.SFlag then
					syde.SettingsFlags[ToggleData.SFlag] = ToggleData
				end

			end

			return element

		end

		local element = SettingsElements:GetSettingsElements()

		element:Section('Other', WINDOW.Settings.Pages.Theme.Container, '0')

		element:Keybind({
			Title = 'Toggle UI',
			Key = UIToggle,
			OnKeyChanged = function(newKey)
				UIToggle = newKey
			end,
			CallBack = function()
				ToggleUI()
			end,
		}, WINDOW.Settings.Pages.Theme.Container)

element:Toggle({
    Title = 'Nexus Timer',
    Description = 'A 0-60 GUI timer for Vehicles.',
    Value = false,
    CallBack = (function()
        local player = Players.LocalPlayer

        local screenGui
        local velocityConnection
        local buttonConnection1
        local buttonConnection2
        local _060timer
        local Timer
        local ReadyReset
        local Bot
        local Started = false
        local TReady = false
        local StartTime = nil

        local function getVehicleVelocity()
            if Players.Character and Players.Character:FindFirstChild('Humanoid') then
                local humanoid = Players.Character.Humanoid
                if humanoid.SeatPart then
                    local vehicle = humanoid.SeatPart.Parent
                    if vehicle and vehicle:FindFirstChild('VehicleSeat') then
                        return vehicle.VehicleSeat.Velocity
                    elseif vehicle.PrimaryPart then
                        return vehicle.PrimaryPart.Velocity
                    end
                end
                return Players.Character.HumanoidRootPart.Velocity
            end
            return Vector3.new(0,0,0)
        end

        local function velocityToMph(velocity)
            return velocity.Magnitude * (10 / 12) * (60 / 88)
        end

        local function updateTimer()
            if Timer then
                Timer.Text = string.format('%.3f', os.clock() - StartTime)
            end
            local velocity = getVehicleVelocity()
            local mph = velocityToMph(velocity)
            if mph >= 60 then
                RunService:UnbindFromRenderStep('60Timer')
                if ReadyReset then ReadyReset.Text = 'RESET' end
                if Bot then Bot.ImageColor3 = Color3.fromRGB(100,100,0) end
            end
        end

        local function startTimer()
            local velocity = getVehicleVelocity()
            local mph = velocityToMph(velocity)
            if not Started and TReady and mph > 1 then
                Started = true
                StartTime = os.clock()
                RunService:BindToRenderStep('60Timer', 100, updateTimer)
            end
        end

        local function removeUI()
            if velocityConnection then velocityConnection:Disconnect() velocityConnection = nil end
            if buttonConnection1 then buttonConnection1:Disconnect() buttonConnection1 = nil end
            if buttonConnection2 then buttonConnection2:Disconnect() buttonConnection2 = nil end
            RunService:UnbindFromRenderStep('60Timer')
            if screenGui then screenGui:Destroy() screenGui = nil end
            _060timer, Timer, ReadyReset, Bot = nil, nil, nil, nil
            Started, TReady, StartTime = false, false, nil
        end

        local function createUI()
            screenGui = CoreGui:FindFirstChild('OISDBNGIOASDHGNEXUS')
            if screenGui then removeUI() end

            screenGui = Instance.new('ScreenGui')
            screenGui.Name = 'OISDBNGIOASDHGNEXUS'
            screenGui.Parent = CoreGui

            _060timer = Instance.new('Frame')
            Timer = Instance.new('TextLabel')
            ReadyReset = Instance.new('TextButton')
            local Top = Instance.new('ImageLabel')
            local Mid = Instance.new('ImageLabel')
            local Logo = Instance.new('ImageLabel')
            local UIAspectRatioConstraint = Instance.new('UIAspectRatioConstraint')
            local TextLabel = Instance.new('TextLabel')
            Bot = Instance.new('ImageLabel')

            _060timer.Name = 'NEXUS-TIMER'
            _060timer.Parent = screenGui
            _060timer.BackgroundTransparency = 1
            _060timer.Position = UDim2.new(0,50,0.3,0)
            _060timer.Size = UDim2.new(0,225,0,175)
            _060timer.Active = true
            _060timer.Draggable = true

            Timer.Name = 'Timer'
            Timer.Parent = _060timer
            Timer.BackgroundTransparency = 1
            Timer.Position = UDim2.new(0.138,0,0.275,0)
            Timer.Size = UDim2.new(0.724,0,0.36,0)
            Timer.Font = Enum.Font.Michroma
            Timer.Text = '0.000'
            Timer.TextColor3 = Color3.new(1,1,1)
            Timer.TextScaled = true

            ReadyReset.Name = 'ReadyReset'
            ReadyReset.Parent = _060timer
            ReadyReset.BackgroundTransparency = 1
            ReadyReset.Position = UDim2.new(0.088,0,0.754,0)
            ReadyReset.Size = UDim2.new(0.648,0,0.195,0)
            ReadyReset.Font = Enum.Font.Michroma
            ReadyReset.Text = 'READY'
            ReadyReset.TextColor3 = Color3.new(1,1,1)
            ReadyReset.TextScaled = true

            Top.Parent = _060timer
            Top.AnchorPoint = Vector2.new(0.5,0.5)
            Top.BackgroundTransparency = 1
            Top.Position = UDim2.new(0.5,0,0.5,0)
            Top.Size = UDim2.new(1.5,0,1.5,0)
            Top.ZIndex = 0
            Top.Image = 'rbxassetid://7082214065'
            Top.ImageColor3 = Color3.new(0,0,0)
            Top.ImageTransparency = 0.2

            Mid.Parent = _060timer
            Mid.AnchorPoint = Vector2.new(0.5,0.5)
            Mid.BackgroundTransparency = 1
            Mid.Position = UDim2.new(0.5,0,0.5,0)
            Mid.Size = UDim2.new(1.5,0,1.5,0)
            Mid.ZIndex = 0
            Mid.Image = 'rbxassetid://7056625228'
            Mid.ImageColor3 = Color3.new(0,0,0)
            Mid.ImageTransparency = 0.75

            Logo.Parent = Mid
            Logo.AnchorPoint = Vector2.new(0.5,0.5)
            Logo.BackgroundTransparency = 1
            Logo.Position = UDim2.new(0.5,0,0.49,0)
            Logo.Size = UDim2.new(0.7,0,0.5,0)
            Logo.ZIndex = 0
            Logo.Image = 'rbxassetid://70516345595834'
            Logo.ImageTransparency = 0.4

            UIAspectRatioConstraint.Parent = Logo
            UIAspectRatioConstraint.AspectRatio = 1.8

            TextLabel.Parent = _060timer
            TextLabel.BackgroundTransparency = 1
            TextLabel.Position = UDim2.new(0.274,0,0.045,0)
            TextLabel.Size = UDim2.new(0.708,0,0.15,0)
            TextLabel.Font = Enum.Font.Michroma
            TextLabel.Text = 'NEXUS-TIMER'
            TextLabel.TextColor3 = Color3.new(1,1,1)
            TextLabel.TextScaled = true

            Bot.Parent = _060timer
            Bot.AnchorPoint = Vector2.new(0.5,0.5)
            Bot.BackgroundTransparency = 1
            Bot.Position = UDim2.new(0.5,0,0.5,0)
            Bot.Size = UDim2.new(1.5,0,1.5,0)
            Bot.ZIndex = 0
            Bot.Image = 'rbxassetid://7056626991'
            Bot.ImageColor3 = Color3.fromRGB(129,31,255)

            velocityConnection = RunService.Heartbeat:Connect(startTimer)

            buttonConnection1 = ReadyReset.MouseButton1Click:Connect(function()
                local velocity = getVehicleVelocity()
                local mph = velocityToMph(velocity)
                if ReadyReset.Text == 'RESET' then
                    RunService:UnbindFromRenderStep('60Timer')
                    ReadyReset.Text = 'READY'
                    Bot.ImageColor3 = Color3.fromRGB(129,31,255)
                    Started = false
                    TReady = false
                    Timer.Text = '0.000'
                elseif ReadyReset.Text == 'READY' then
                    if mph < 1 then
                        ReadyReset.Text = 'CANCEL'
                        Bot.ImageColor3 = Color3.fromRGB(100,0,0)
                        TReady = true
                    else
                        ReadyReset.Text = 'SLOW DOWN'
                        Bot.ImageColor3 = Color3.fromRGB(150,50,0)
                        task.spawn(function()
                            repeat task.wait(0.1)
                                velocity = getVehicleVelocity()
                                mph = velocityToMph(velocity)
                            until mph < 1
                            if ReadyReset.Text == 'SLOW DOWN' then
                                ReadyReset.Text = 'READY'
                                Bot.ImageColor3 = Color3.fromRGB(129,31,255)
                            end
                        end)
                    end
                elseif ReadyReset.Text == 'CANCEL' then
                    ReadyReset.Text = 'READY'
                    Bot.ImageColor3 = Color3.fromRGB(129,31,255)
                    TReady = false
                    Started = false
                    Timer.Text = '0.000'
                end
            end)

            buttonConnection2 = ReadyReset.MouseButton1Click:Connect(function()
                if Started then
                    RunService:UnbindFromRenderStep('60Timer')
                    Started = false
                    Timer.Text = '0.000'
                end
            end)
        end

        return function(enabled)
            screenGui = CoreGui:FindFirstChild('OISDBNGIOASDHGNEXUS')
            if enabled then
                createUI()
            else
                removeUI()
            end
        end
    end)(),
    SFlag = 'NexusTimerToggle',
}, WINDOW.Settings.Pages.Theme.Container)

task.spawn(function()
    while true do
        task.wait(0.5)
        local gui = game:GetService('CoreGui'):FindFirstChild('OISDBNGIOASDHGNEXUS')
        if gui and not gui.Parent then
            gui = nil
        end
    end
end)



		element:CreateSlider({
			Title = 'Modifiers',
			Sliders = {
				{
					Title = 'Glow Density',
					Range = {0, 1},
					Increment = 0.1,
					StarterValue = WINDOW.Shadow.ImageLabel.ImageTransparency,
					CallBack = function(v)
						TweenService:Create(WINDOW.Shadow.ImageLabel, TweenInfo.new(0.65, Enum.EasingStyle.Exponential), {ImageTransparency = v}):Play()
					end,
					SFlag = 'GDensity',
					SettingConfig = true,
				},
				{
					Title = 'Drag Smoothness',
					Range = {0, 1},
					Increment = 0.1,
					StarterValue = dragSpeed,
					CallBack = function(v)
						dragSpeed = v
					end,
					SFlag = 'DSmoothness',
					SettingConfig = true,
				},
			}
		}, WINDOW.Settings.Pages.Theme.Container)

		element:Toggle({
			Title = 'LockToScreen',
			Description = 'Prevents UI from moving off screen.',
			Value = LockToScreen,
			CallBack = function (v)
				LockToScreen = v
			end,
			SFlag = 'LTS',
			SettingConfig = true,
		}, WINDOW.Settings.Pages.Theme.Container)


		function syde:SaveSettingsConfig()
			local Data = {}


			for flag, v in pairs(syde.SettingsFlags or {}) do

				if v.Type == "ColorPicker" and v.Color then
					Data[flag] = syde:ColorPack(v.Color)
				elseif v.Value ~= nil then
					Data[flag] = v.Value
				elseif v.StarterValue ~= nil then
					Data[flag] = v.StarterValue
				else
				end
			end


			local path = string.format("%s/NexusConfig.lua", syde.ConfigFolder)
			local encoded = HttpService:JSONEncode(Data)

			writefile(path, encoded)


		end

		function syde:LoadSettingsConfig()
			local path = string.format("%s/NexusConfig.lua", syde.ConfigFolder)

			if not isfile(path) then

				return
			end

			local success, data = pcall(function()
				return HttpService:JSONDecode(readfile(path))
			end)

			if not success or typeof(data) ~= "table" then
				return
			end

			for flag, val in pairs(data) do
				local setting = syde.SettingsFlags and syde.SettingsFlags[flag]
				if setting then
					if setting.Set then
						setting:Set(val)
					elseif setting.Type == "ColorPicker" and setting.Color then
						setting.Color = syde:ColorUnpack(val)
					elseif setting.Value ~= nil then
						setting.Value = val
					end
				else
				end
			end


		end

		element:CreateButton({
			Title = 'Save',
			Description = "Saves Setting Configuration",
			CallBack = function(v)
				syde:SaveSettingsConfig()
			end,
		},  WINDOW.Settings.Pages.Theme.Container)

		element:CreateButton({
			Title = 'Load',
			Description = "Loads Setting Configuration",
			CallBack = function()
				syde:LoadSettingsConfig()
			end,
		}, WINDOW.Settings.Pages.Theme.Container)

		element:Paragraph({
			Title = 'Status',
			Content = 'You are Up To Date!'
		}, WINDOW.Settings.Pages.Info.Container)




		element:Paragraph({
			Title = 'Coming Soon',
			Content = 'More options coming soon...'
		}, WINDOW.Settings.Pages.Privacy.Container)



        element:Toggle({
    Title = 'Quick Load',
    Description = 'Enables fast loader animation on next script execution.',
    Value = getgenv().NexusLoaderSettings
        and getgenv().NexusLoaderSettings.QuickLoad
        or false,
    CallBack = (function()
        local firstRun = true
        return function(enabled)
            if not getgenv().NexusLoaderSettings then
                getgenv().NexusLoaderSettings = {}
            end
            getgenv().NexusLoaderSettings.QuickLoad = enabled

            local settingsFolder = 'Nexus'
            local settingsFile = 'Settings.json'

            if not isfolder(settingsFolder) then
                makefolder(settingsFolder)
            end

            local path = settingsFolder .. '/' .. settingsFile
            local currentSettings = {}

            if isfile(path) then
                pcall(function()
                    currentSettings = game:GetService('HttpService'):JSONDecode(readfile(path))
                end)
            end

            currentSettings.QuickLoad = enabled

            pcall(function()
                writefile(path, game:GetService('HttpService'):JSONEncode(currentSettings))
            end)

            if firstRun then
                firstRun = false
                return
            end

            if getgenv().notifaction and getgenv().notifaction.notify then
                local privacyEnabled = getgenv().notifaction.GetPrivacyMode
                    and getgenv().notifaction.GetPrivacyMode()
                    or false
                if not privacyEnabled then

                end
            end
        end
    end)(),
    SFlag = 'QuickLoadToggle',
}, WINDOW.Settings.Pages.Privacy.Container)



        element:Toggle({
    Title = 'Privacy Mode',
    Description = 'Keeps you private and mutes notifications.',
    Value = getgenv().notifaction
        and getgenv().notifaction.GetPrivacyMode
        and getgenv().notifaction.GetPrivacyMode() 
        or false,
    CallBack = (function()
        local firstRun = true
        return function(enabled)
            if getgenv().notifaction and getgenv().notifaction.SetPrivacyMode then
                getgenv().notifaction.SetPrivacyMode(enabled)

                if firstRun then
                    firstRun = false
                    return
                end

                if enabled then

                else

                end
            end
        end
    end)(),
    SFlag = 'PrivacyModeToggle',
}, WINDOW.Settings.Pages.Privacy.Container)

		element:Toggle({
			Title = 'Anonymous',
			Description = 'Hides your info in User Info.',
			Value = UserInfoDisabled,
			CallBack = function (v)
				if v then
					UserInfoDisabled = true
					TweenService:Create(WINDOW.UserInfo.ImageLabel.text.Username, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 0 }):Play()
					TweenService:Create(WINDOW.UserInfo.ImageLabel.text.Display, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 0 }):Play()
					TweenService:Create(WINDOW.UserInfo.ImageLabel.UIStroke, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Transparency = 0 }):Play()
					TweenService:Create(WINDOW.Tab, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 200,1, -50) }):Play()
					WINDOW.UserInfo.ImageLabel.Image = "rbxthumb://type=AvatarHeadShot&id=7380657564&w=420&h=420"
					WINDOW.UserInfo.ImageLabel.text.Username.Text = 'Nexus User'
					WINDOW.UserInfo.ImageLabel.text.Display.Text = '@nexus'
				else
					UserInfoDisabled = false
					TweenService:Create(WINDOW.UserInfo.ImageLabel.text.Username, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 0 }):Play()
					TweenService:Create(WINDOW.UserInfo.ImageLabel.text.Display, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 0 }):Play()
					TweenService:Create(WINDOW.UserInfo.ImageLabel.UIStroke, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Transparency = 0 }):Play()
					TweenService:Create(WINDOW.Tab, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 200,1, -150) }):Play()
					SetUserInfo()
				end
			end,
			SFlag = 'Anon'
		}, WINDOW.Settings.Pages.Privacy.Container)



		--local startTime = tick()

		-- breaks ui may add later
--[[	local uptimeParagraph = element:Paragraph({
		Title = 'Session UpTime',
		Content = 'Calculating...'
	}, WINDOW.Settings.Pages.Info.Container)

	local function formatTime(seconds)
		local days = math.floor(seconds / 86400)
		seconds = seconds % 86400
		local hours = math.floor(seconds / 3600)
		seconds = seconds % 3600
		local minutes = math.floor(seconds / 60)
		seconds = math.floor(seconds % 60)

		return string.format("%02d:%02d:%02d:%02d", days, hours, minutes, seconds)
	end

	local startTime = tick()
	
	local heartbeatConnection
	heartbeatConnection = RunService.Heartbeat
	
	SettingsElements:AddConnection(heartbeatConnection, function()
		if uptimeParagraph then
			local uptime = tick() - startTime
			local formatted = formatTime(uptime)
			uptimeParagraph:Set("Server Uptime: " .. formatted)
		else
			heartbeatConnection:Disconnect()
		end
	end)]]


	end


	-------------------------------

	local ldata = {
		first = false,
		selected = false
	}

	--[TAB INITIALIZATION]
	function ldata:InitTab(tab)
		local isFirstTab = not ldata.first 
		
		local TabData = {
			Title = tab.Title;
			Locked = tab.Locked or false;
			Key = tab.Key;
		}
		
		local LockedFrames = {}
		--[Tab Setup]
		local Tab = TABS.Tb:Clone()
		Tab.Visible = true
		Tab.Parent = TABS
		Tab.Title.Text = TabData.Title
		Tab.Name = TabData.Title

		Tab.Title.TextTransparency = 1
		Tab.indicator.BackgroundTransparency = 1

		for _, temp in ipairs(PAGES.Page:GetChildren()) do
			if temp:IsA("Frame") then
				temp.Visible = false
			end
		end

		--[Page Setup]
		local Page = PAGES.Page:Clone()
		Page.Visible = false
		Page.Parent = PAGES
		Page.Name = TabData.Title

		local defaultParent = Page 

		local function setInternalParent(newParent)
			defaultParent = newParent
		end


		Page.ChildAdded:Connect(function(child)
			child:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				syde:updateLayout(Page, 7) 
			end)
			child:GetPropertyChangedSignal("Visible"):Connect(function()
				syde:updateLayout(Page, 7)
			end)
			syde:updateLayout(Page, 7)
		end)

		Page.ChildRemoved:Connect(function()
			syde:updateLayout(Page, 7)
		end)

		Page:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			syde:updateLayout(Page, 7)
		end)

		syde:updateLayout(Page, 7)

		local function ChangeName(Name)
			TweenService:Create(PAGES.Clipframe.TBName, TweenInfo.new(0), { TextTransparency = PAGES.Clipframe.TBName.TextTransparency }):Play()
			TweenService:Create(PAGES.Clipframe.TBName, TweenInfo.new(0), { Position = PAGES.Clipframe.TBName.Position }):Play()

			local fadeOut = TweenService:Create(PAGES.Clipframe.TBName, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), { TextTransparency = 1 })
			local moveUp = TweenService:Create(PAGES.Clipframe.TBName, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), { Position = UDim2.new(0, 5,0.5, -25) })

			fadeOut:Play()
			moveUp:Play()
			task.wait(0.2)

			PAGES.Clipframe.TBName.Position = UDim2.new(0, 5,0.5, 25)

			PAGES.Clipframe.TBName.Text = Name

			local moveDown = TweenService:Create(PAGES.Clipframe.TBName, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), { Position = UDim2.new(0, 5,0.5, 0) })
			local fadeIn = TweenService:Create(PAGES.Clipframe.TBName, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), { TextTransparency = 0 })

			moveDown:Play()
			fadeIn:Play()
		end


		if isFirstTab then
			ChangeName(TabData.Title)
			Page.Visible = true
			ldata.first = TabData.Title
		end


		if ldata.first then
			TweenService:Create(Tab.Title, TweenInfo.new(2, Enum.EasingStyle.Quint), { Size = UDim2.new(1, -8, 1, 0) }):Play()
			TweenService:Create(Tab.Title, TweenInfo.new(2, Enum.EasingStyle.Quint), { TextColor3 = Color3.fromRGB(52, 52, 52) }):Play()
			TweenService:Create(Tab.indicator, TweenInfo.new(2, Enum.EasingStyle.Quint), { Size = UDim2.new(0, 2, 0, 10) }):Play()
			TweenService:Create(Tab.Title, TweenInfo.new(2, Enum.EasingStyle.Exponential), { TextTransparency = 0 }):Play()
			TweenService:Create(Tab.indicator, TweenInfo.new(1, Enum.EasingStyle.Exponential), { BackgroundTransparency = 0.9 }):Play()
			TweenService:Create(Tab.indicator.ImageLabel, TweenInfo.new(1, Enum.EasingStyle.Exponential), { ImageTransparency = 1 }):Play()
		else
			ldata.first = TabData.Title
			TweenService:Create(Tab.Title, TweenInfo.new(2, Enum.EasingStyle.Quint), { Size = UDim2.new(1, -10, 1, 0) }):Play()
			TweenService:Create(Tab.Title, TweenInfo.new(2, Enum.EasingStyle.Exponential), { TextTransparency = 0 }):Play()
			TweenService:Create(Tab.indicator, TweenInfo.new(2, Enum.EasingStyle.Exponential), { BackgroundColor3 = syde.theme.Accent }):Play()
			TweenService:Create(Tab.indicator, TweenInfo.new(2, Enum.EasingStyle.Quint), { Size = UDim2.new(0, 2, 0, 2) }):Play()
			TweenService:Create(Tab.indicator.ImageLabel, TweenInfo.new(1, Enum.EasingStyle.Exponential), { ImageTransparency = 0.6 }):Play()
		end

		local positionTweenInfo = TweenInfo.new(0.75, Enum.EasingStyle.Quint)
		local colorTweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quart)

		local function ApplyTabStyle(tabButton, isSelected)
			local targetSize = isSelected and UDim2.new(1, -12, 1, 0) or UDim2.new(1, -12, 1, 0)
			local targetTextColor = isSelected and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(52, 52, 52)
			local targetTransparency = isSelected and 0 or 1
			local targetColor = isSelected and syde.theme.Accent or Color3.fromRGB(29, 29, 29)
			local indicatorSize = isSelected and UDim2.new(0, 2, 0, 10) or UDim2.new(0, 2, 0, 5)

			TweenService:Create(tabButton.Title, positionTweenInfo, { Size = targetSize, TextColor3 = targetTextColor }):Play()
			TweenService:Create(tabButton.indicator, colorTweenInfo, { BackgroundTransparency = targetTransparency, BackgroundColor3 = targetColor, Size = indicatorSize }):Play()
			TweenService:Create(tabButton.indicator.ImageLabel, colorTweenInfo, { ImageColor3 = targetColor }):Play()
			TweenService:Create(tabButton.indicator.ImageLabel, colorTweenInfo, { ImageTransparency = isSelected and 0.6 or 1 }):Play()
		end

		ApplyTabStyle(Tab, isFirstTab)

		local function OpenSettings()

			WINDOW.Settings.Visible = true
			WINDOW.dim.Visible = true

			TweenService:Create(WINDOW.Settings, TweenInfo.new(0.65, Enum.EasingStyle.Quint), { Position = UDim2.new(0.5, 0,0.5, 0) }):Play()
			TweenService:Create(WINDOW.Settings, TweenInfo.new(0.35, Enum.EasingStyle.Quint), { Size = UDim2.new(0, 500,0, 375) }):Play()
			TweenService:Create(WINDOW.dim, TweenInfo.new(0.73, Enum.EasingStyle.Exponential), { BackgroundTransparency = 0.3 }):Play()
			TweenService:Create(WINDOW.Settings.Close, TweenInfo.new(0.73, Enum.EasingStyle.Exponential), { ImageTransparency = 0 }):Play()

			TweenService:Create(WINDOW.Settings.void, TweenInfo.new(0.73, Enum.EasingStyle.Exponential), {  BackgroundTransparency = 0 }):Play()
			TweenService:Create(WINDOW.Settings.void2, TweenInfo.new(0.73, Enum.EasingStyle.Exponential), { BackgroundTransparency = 0 }):Play()

			TweenService:Create(WINDOW.Settings, TweenInfo.new(0.73, Enum.EasingStyle.Exponential), { BackgroundTransparency = 0 }):Play()
			TweenService:Create(WINDOW.Settings.TabBlock.UIStroke, TweenInfo.new(0.73, Enum.EasingStyle.Exponential), { Transparency = 0 }):Play()
			TweenService:Create(WINDOW.Settings.Shadow.ImageLabel, TweenInfo.new(0.73, Enum.EasingStyle.Exponential), { ImageTransparency = 0.86 }):Play()

			TweenService:Create(WINDOW.Settings.TabBlock.Theme, TweenInfo.new(0.73, Enum.EasingStyle.Exponential), { BackgroundTransparency = 0 }):Play()
			TweenService:Create(WINDOW.Settings.TabBlock.Theme, TweenInfo.new(0.73, Enum.EasingStyle.Exponential), { TextTransparency = 0 }):Play()
			TweenService:Create(WINDOW.Settings.TabBlock.Theme.d, TweenInfo.new(0.73, Enum.EasingStyle.Exponential), { BackgroundTransparency = 0 }):Play()
			TweenService:Create(WINDOW.Settings.TabBlock.Theme.Frame, TweenInfo.new(0.73, Enum.EasingStyle.Exponential), { BackgroundTransparency = 0 }):Play()

			TweenService:Create(WINDOW.Settings.TabBlock.Info, TweenInfo.new(0.73, Enum.EasingStyle.Exponential), { BackgroundTransparency = 0 }):Play()
			TweenService:Create(WINDOW.Settings.TabBlock.Info, TweenInfo.new(0.73, Enum.EasingStyle.Exponential), { TextTransparency = 0 }):Play()
			TweenService:Create(WINDOW.Settings.TabBlock.Info.d, TweenInfo.new(0.73, Enum.EasingStyle.Exponential), { BackgroundTransparency = 0 }):Play()
			TweenService:Create(WINDOW.Settings.TabBlock.Info.Frame, TweenInfo.new(0.73, Enum.EasingStyle.Exponential), { BackgroundTransparency = 0 }):Play()

			TweenService:Create(WINDOW.Settings.TabBlock.Privacy, TweenInfo.new(0.73, Enum.EasingStyle.Exponential), { BackgroundTransparency = 0 }):Play()
			TweenService:Create(WINDOW.Settings.TabBlock.Privacy, TweenInfo.new(0.73, Enum.EasingStyle.Exponential), { TextTransparency = 0 }):Play()
		end

		local function CloseSettings()

			TweenService:Create(WINDOW.Settings, TweenInfo.new(0.65, Enum.EasingStyle.Quint), { Position = UDim2.new(0.5, 176,0.5, -200) }):Play()
			TweenService:Create(WINDOW.Settings, TweenInfo.new(0.35, Enum.EasingStyle.Quint), { Size = UDim2.new(0, 200,0, 110) }):Play()
			TweenService:Create(WINDOW.dim, TweenInfo.new(0.73, Enum.EasingStyle.Exponential), { BackgroundTransparency = 1 }):Play()
			TweenService:Create(WINDOW.Settings.Close, TweenInfo.new(0.73, Enum.EasingStyle.Exponential), { ImageTransparency = 1 }):Play()

			TweenService:Create(WINDOW.Settings.void, TweenInfo.new(0.73, Enum.EasingStyle.Exponential), { BackgroundTransparency = 1 }):Play()
			TweenService:Create(WINDOW.Settings.void2, TweenInfo.new(0.73, Enum.EasingStyle.Exponential), { BackgroundTransparency = 1 }):Play()

			TweenService:Create(WINDOW.Settings, TweenInfo.new(0.73, Enum.EasingStyle.Exponential), { BackgroundTransparency = 1 }):Play()
			TweenService:Create(WINDOW.Settings.TabBlock.UIStroke, TweenInfo.new(0.73, Enum.EasingStyle.Exponential), { Transparency = 1 }):Play()
			TweenService:Create(WINDOW.Settings.Shadow.ImageLabel, TweenInfo.new(0.73, Enum.EasingStyle.Exponential), { ImageTransparency = 1 }):Play()

			TweenService:Create(WINDOW.Settings.TabBlock.Theme, TweenInfo.new(0.73, Enum.EasingStyle.Exponential), { BackgroundTransparency = 1 }):Play()
			TweenService:Create(WINDOW.Settings.TabBlock.Theme, TweenInfo.new(0.73, Enum.EasingStyle.Exponential), { TextTransparency = 1 }):Play()
			TweenService:Create(WINDOW.Settings.TabBlock.Theme.d, TweenInfo.new(0.73, Enum.EasingStyle.Exponential), { BackgroundTransparency = 1 }):Play()
			TweenService:Create(WINDOW.Settings.TabBlock.Theme.Frame, TweenInfo.new(0.73, Enum.EasingStyle.Exponential), { BackgroundTransparency = 1 }):Play()

			TweenService:Create(WINDOW.Settings.TabBlock.Info, TweenInfo.new(0.73, Enum.EasingStyle.Exponential), { BackgroundTransparency = 1 }):Play()
			TweenService:Create(WINDOW.Settings.TabBlock.Info, TweenInfo.new(0.73, Enum.EasingStyle.Exponential), { TextTransparency = 1 }):Play()
			TweenService:Create(WINDOW.Settings.TabBlock.Info.d, TweenInfo.new(0.73, Enum.EasingStyle.Exponential), { BackgroundTransparency = 1 }):Play()
			TweenService:Create(WINDOW.Settings.TabBlock.Info.Frame, TweenInfo.new(0.73, Enum.EasingStyle.Exponential), { BackgroundTransparency = 1 }):Play()

			TweenService:Create(WINDOW.Settings.TabBlock.Privacy, TweenInfo.new(0.73, Enum.EasingStyle.Exponential), { BackgroundTransparency = 1 }):Play()
			TweenService:Create(WINDOW.Settings.TabBlock.Privacy, TweenInfo.new(0.73, Enum.EasingStyle.Exponential), { TextTransparency = 1 }):Play()

			task.wait(0.4)
			WINDOW.dim.Visible = false
		end
		
		local currentLockedTabData = nil
		local lockedframe

		if TabData.Locked then
			lockedframe =  WINDOW.Pages.locked:Clone()
			lockedframe.Visible = false
			lockedframe.Parent = WINDOW.Pages.lockedpages
			lockedframe.Name = TabData.Title
		end


		Tab.interact.MouseButton1Click:Connect(function()
			if ldata.first == TabData.Title then return end 


			ChangeName(TabData.Title)
			for _, otherPage in ipairs(PAGES:GetChildren()) do
				if otherPage:IsA("ScrollingFrame") then
					otherPage.Visible = false
				end
			end


			Page.Visible = true
			ldata.first = TabData.Title
			
			if TabData.Locked == true then
				if lockedframe and lockedframe.Name == TabData.Title then
					lockedframe.Visible = true
					for _, v in pairs(WINDOW.Pages.lockedpages:GetChildren()) do
						if v.Name ~= TabData.Title then
							v.Visible = false
						end
					end
				end
				currentLockedTabData = TabData
			else
				for _, v in pairs(WINDOW.Pages.lockedpages:GetChildren()) do
					if v then
						v.Visible = false
					end
				end
			end

			syde:replayLoadTweens()

			for _, otherTab in ipairs(TABS:GetChildren()) do
				if otherTab:IsA("Frame") then
					ApplyTabStyle(otherTab, otherTab == Tab)
				end
			end
		end)
		
		if lockedframe  then
			local keyInputBox = lockedframe.lockedframe.keyframe.key.TextBox
			keyInputBox.FocusLost:Connect(function(enterPressed)
				if not enterPressed or not currentLockedTabData then return end

				local enteredKey = keyInputBox.Text
				local correctKey = enteredKey == currentLockedTabData.Key

				if correctKey and currentLockedTabData.Locked then
					local keyFrame = lockedframe.lockedframe.keyframe.key
					local enterIcon = keyFrame.enter

					TweenService:Create(enterIcon, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), { ImageTransparency = 1 }):Play()
					task.wait(0.5)

					enterIcon.Image = 'rbxassetid://10709790644'
					TweenService:Create(enterIcon, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), { ImageTransparency = 0 }):Play()
					TweenService:Create(enterIcon, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), { ImageColor3 = Color3.fromRGB(173, 255, 135) }):Play()

					TweenService:Create( lockedframe.lockedframe.keyframe.ImageLabel, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), { ImageTransparency = 1 }):Play()
					task.wait(0.4)
					TweenService:Create( lockedframe.lockedframe.keyframe.ImageLabel, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), { ImageTransparency = 0 }):Play()
					TweenService:Create( lockedframe.lockedframe.keyframe.ImageLabel, TweenInfo.new(0.2, Enum.EasingStyle.Sine), { Rotation = -26 }):Play()
					TweenService:Create( lockedframe.lockedframe.keyframe.ImageLabel, TweenInfo.new(0.2, Enum.EasingStyle.Sine), { Rotation = -26 }):Play()
					lockedframe.lockedframe.keyframe.ImageLabel.Image = 'rbxassetid://10747366027'
					task.wait(2)
					TweenService:Create( lockedframe.lockedframe.keyframe.UIScale, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), { Scale = 0.8 }):Play()
					TweenService:Create( lockedframe.lockedframe.keyframe, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), { BackgroundTransparency = 1 }):Play()
					TweenService:Create( lockedframe.lockedframe.keyframe.ImageLabel, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), { ImageTransparency = 1 }):Play()
					TweenService:Create( lockedframe.lockedframe.keyframe.Title, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), { TextTransparency = 1 }):Play()
					TweenService:Create( lockedframe.lockedframe.keyframe.Description, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), {TextTransparency = 1 }):Play()


					TweenService:Create( lockedframe.lockedframe.keyframe.key, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), { BackgroundTransparency = 1 }):Play()
					TweenService:Create( lockedframe.lockedframe.keyframe.key.UIStroke, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), { Transparency = 1 }):Play()
					TweenService:Create( lockedframe.lockedframe.keyframe.key.getkey, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), {TextTransparency = 1 }):Play()
					TweenService:Create( lockedframe.lockedframe.keyframe.key.enter, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), { ImageTransparency = 1 }):Play()
					TweenService:Create( lockedframe.lockedframe.keyframe.key.TextBox, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), { TextTransparency = 1 }):Play()
					TweenService:Create( lockedframe.lockedframe.keyframe.key.Frame, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), { BackgroundTransparency = 1 }):Play()
					--	task.wait(0.3)
					TweenService:Create( lockedframe.lockedframe, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), { BackgroundTransparency = 1 }):Play()
					TweenService:Create( lockedframe.lockedframe.void, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), { BackgroundTransparency = 1 }):Play()
					TweenService:Create( lockedframe.lockedframe, TweenInfo.new(0.5, Enum.EasingStyle.Quint), { Size = UDim2.new(0.069, -25,1, 0) }):Play()

					task.wait(1)

					lockedframe:Destroy()
					TabData.Locked = false
				else
					-- Wrong key wiggle
					local key = lockedframe.lockedframe.keyframe.key
					TweenService:Create(key, TweenInfo.new(0.3, Enum.EasingStyle.Quint), { Position = UDim2.new(0.5, 10, 0, 100) }):Play()
					task.wait(0.1)
					TweenService:Create(key, TweenInfo.new(0.3, Enum.EasingStyle.Quint), { Position = UDim2.new(0.5, -10, 0, 100) }):Play()
					task.wait(0.1)
					TweenService:Create(key, TweenInfo.new(0.3, Enum.EasingStyle.Quint), { Position = UDim2.new(0.5, 0, 0, 100) }):Play()
				end
			end)
		end

		WINDOW.Top.UHolder.Util.Settings.interact.MouseButton1Click:Connect(function()
			if ldata.first == "Settings" then return end
			ldata.previousTab = ldata.first 
			ldata.first = "Settings"
			ChangeName('Settings')

			if not settingsOpen then
				settingsOpen = true
				OpenSettings()
			end

			TweenService:Create(WINDOW.Top.UHolder.Util.Settings.interact, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageTransparency = 0}):Play()

		--[[	for _, otherPage in ipairs(PAGES:GetChildren()) do
				if otherPage:IsA("ScrollingFrame") then
					otherPage.Visible = false
				end
			end  ]]

			-- Make all tab buttons appear disabled
			for _, otherTab in ipairs(TABS:GetChildren()) do
				if otherTab:IsA("Frame") then
					ApplyTabStyle(otherTab, false) 
					otherTab.interact.Active = false 
					--	TweenService:Create(otherTab, TweenInfo.new(0.5), { BackgroundTransparency = 0.7 }):Play() 
				end
			end
		end)


		WINDOW.Settings.Close.MouseButton1Click:Connect(function()
			if not ldata.previousTab then return end
			ldata.first = ldata.previousTab
			ChangeName(ldata.previousTab)

			-- Restore all normal pages
			for _, otherPage in ipairs(PAGES:GetChildren()) do
				if otherPage:IsA("ScrollingFrame") then
					otherPage.Visible = (otherPage.Name == ldata.previousTab)
				end
			end

			for _, otherTab in ipairs(TABS:GetChildren()) do
				if otherTab:IsA("Frame") then
					ApplyTabStyle(otherTab, otherTab.Name == ldata.previousTab) 
					otherTab.interact.Active = true 
				end
			end

			if settingsOpen then
				settingsOpen = false
				TweenService:Create(WINDOW.Top.UHolder.Util.Settings.interact, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageTransparency = 0.7}):Play()
				CloseSettings()
			end
		end)

		local InitElement = {}

		function InitElement:Section(Title, Icon)
			local SectionData = {
				Title = Title
			}

			local Section = PAGES.Page.Section:Clone()
			Section.Visible = true
			Section.Title.Text = Title
			Section.Parent = Page
			Section.Title.Position = UDim2.new(0, 0,0, 0)

			if Icon then
				Section.icon.Image = 'rbxassetid://'..Icon
				Section.Title.Position = UDim2.new(0, 25,0, 0)
			else
				Section.icon.Visible = false
			end
		end


function InitElement:Button(Button)
	local ButtonData = {
		Title = Button.Title or "Temp Button";
		CallBack = Button.CallBack;
		Desc = Button.Description or "";
		Type = Button.Type or 'Default';
		HoldTime = Button.HoldTime or 3;
	}

	local button = PAGES.Page.Button:Clone()
	button.Visible = true
	button.Parent = Page
	button.Title.Text = ButtonData.Title
	button.Name = ButtonData.Title
	button.Title.Size = UDim2.new(0, button.Title.TextBounds.X + 15,0, 35)

	local fOTween = TweenInfo.new(0.7, Enum.EasingStyle.Exponential)
	local fITween = TweenInfo.new(0.7, Enum.EasingStyle.Exponential)

	if ButtonData.Type == 'Default' then
		button.interact.MouseButton1Down:Connect(function()
			TweenService:Create(button.UIStroke, fOTween, { Transparency = 1 }):Play()
			TweenService:Create(button.ImageLabel, fOTween, { ImageTransparency = 1 }):Play()
			TweenService:Create(button.ImageLabel, TweenInfo.new(0.8, Enum.EasingStyle.Exponential), { ImageTransparency = 1 }):Play()
		end)

		button.interact.MouseButton1Up:Connect(function()
			TweenService:Create(button.UIStroke, fITween, { Transparency = 0 }):Play()
			TweenService:Create(button.ImageLabel, TweenInfo.new(0.8, Enum.EasingStyle.Exponential), { ImageTransparency = 0.95 }):Play()
		end)

		button.interact.MouseButton1Click:Connect(function()
			if TabData.Locked == false and ButtonData.CallBack then
				pcall(ButtonData.CallBack)
			end
		end)

		button.interact.MouseLeave:Connect(function()
			TweenService:Create(button.UIStroke, fITween, { Transparency = 0 }):Play()
			TweenService:Create(button.ImageLabel, TweenInfo.new(0.8, Enum.EasingStyle.Exponential), { ImageTransparency = 0.95 }):Play()
		end)
	elseif ButtonData.Type == 'Hold' then
		local HoldTime = ButtonData.HoldTime
		local Holding = false
		local TimeLeft = HoldTime
		local Complete = false

		button.ImageLabel.Image = 'rbxassetid://127075195365098'
		button.ImageLabel.Rotation = 0
		button.ImageLabel.Size = UDim2.new(0, 16,0, 16)
		button.ImageLabel.Position = UDim2.new(1, -41,0.5, 0)

		local function CancelOperation()
			Holding = false
			TweenService:Create(button.ImageLabel, TweenInfo.new(0.8, Enum.EasingStyle.Exponential), { ImageTransparency = 0.95 }):Play()
			TweenService:Create(button.Title.Timer, TweenInfo.new(0.8, Enum.EasingStyle.Exponential), { TextTransparency = 1 }):Play()
			if not Complete then
				TweenService:Create(button.UIStroke, TweenInfo.new(1, Enum.EasingStyle.Exponential), { Transparency = 1 }):Play()
				TweenService:Create(button.UIStroke.UIGradient, TweenInfo.new(1, Enum.EasingStyle.Linear), { Offset = Vector2.new(-1, 0) }):Play()
				TweenService:Create(button, TweenInfo.new(0.8, Enum.EasingStyle.Exponential), { Position = UDim2.new(0 ,-15 ,0 ,button.Position.Y.Offset) }):Play()
				task.wait(0.15)
				TweenService:Create(button, TweenInfo.new(0.8, Enum.EasingStyle.Exponential), { Position = UDim2.new(0 ,30 ,0 ,button.Position.Y.Offset) }):Play()
				task.wait(0.15)
				TweenService:Create(button, TweenInfo.new(0.8, Enum.EasingStyle.Exponential), { Position = UDim2.new(0 ,0 ,0 ,button.Position.Y.Offset) }):Play()
				task.wait(1)
				TweenService:Create(button.UIStroke, TweenInfo.new(1, Enum.EasingStyle.Exponential), { Transparency = 0 }):Play()
			end
			TimeLeft = HoldTime
			button.Title.Timer.Text = tostring(HoldTime)
			task.wait(0.1)
			Complete = false
		end

		button.interact.MouseButton1Down:Connect(function()
			Holding = true
			TimeLeft = HoldTime
			button.Title.Timer.Text = tostring(TimeLeft)
			TweenService:Create(button.ImageLabel, TweenInfo.new(0.8, Enum.EasingStyle.Exponential), { ImageTransparency = 1 }):Play()
			TweenService:Create(button.Title.Timer, TweenInfo.new(0.8, Enum.EasingStyle.Exponential), { TextTransparency = 0 }):Play()
			TweenService:Create(button.UIStroke.UIGradient, TweenInfo.new(HoldTime, Enum.EasingStyle.Linear), { Offset = Vector2.new(0.7, 0) }):Play()
			TweenService:Create(button.UIStroke, TweenInfo.new(1, Enum.EasingStyle.Exponential), { Transparency = 0}):Play()

			while Holding and TimeLeft > 0 do
				TimeLeft = math.max(0, TimeLeft - RunService.Heartbeat:Wait())
				button.Title.Timer.Text = string.format("%.1f", TimeLeft)
			end

			if TimeLeft <= 0 then
				Complete = true
				if TabData.Locked == false and ButtonData.CallBack then
					pcall(ButtonData.CallBack)
				end
				TweenService:Create(button, TweenInfo.new(0.34, Enum.EasingStyle.Exponential), { BackgroundColor3 = Color3.fromRGB(24, 24, 24) }):Play()
				TweenService:Create(button.UIStroke.UIGradient, TweenInfo.new(0.1, Enum.EasingStyle.Linear), { Offset = Vector2.new(-1, 0) }):Play()
				task.wait(0.34)
				TweenService:Create(button, TweenInfo.new(0.34, Enum.EasingStyle.Exponential), { BackgroundColor3 = Color3.fromRGB(17, 17, 17) }):Play()
			end
		end)

		button.interact.MouseButton1Up:Connect(function()
			CancelOperation()
		end)

		button.interact.MouseLeave:Connect(function()
			if Holding then
				CancelOperation()
			end
		end)
	end

	local descLabel = button:FindFirstChild("Desc")

	if descLabel then
		if ButtonData.Desc and ButtonData.Desc ~= "" then
			descLabel.Text = ButtonData.Desc
			descLabel.Visible = true
			descLabel.TextWrapped = true

			local function updateSize()
				local textSize = TextService:GetTextSize(
					descLabel.Text,
					descLabel.TextSize,
					descLabel.Font,
					Vector2.new(descLabel.AbsoluteSize.X, math.huge)
				)

				local newDescSize = UDim2.new(1, -150, 0, textSize.Y)
				local newButtonSize = UDim2.new(button.Size.X.Scale, button.Size.X.Offset, 0, button.Title.Size.Y.Offset + textSize.Y + 5)

				TweenService:Create(descLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = newDescSize }):Play()
				TweenService:Create(button, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = newButtonSize }):Play()
			end

			updateSize()
			descLabel:GetPropertyChangedSignal("TextBounds"):Connect(updateSize)
		else
			descLabel.Visible = false
		end
	end

	return button
end



		function InitElement:Toggle(Toggle)
			local ToggleData = {
				Title = Toggle.Title or "Temp Toggle";
				Desc = Toggle.Description or "";
				Value = Toggle.Value or false;
				Config = Toggle.Config or false;
				CallBack = Toggle.CallBack;
				Flag = Toggle.Flag;
			}

			local toggle = PAGES.Page.Toggle:Clone()
			toggle.Visible = true
			toggle.Parent = Page
			toggle.Title.Text = ToggleData.Title
			toggle.Name = ToggleData.Title

			local toggleConfiguration = UI.Render.ToggleConfiguration:Clone()
			toggleConfiguration.Parent = UI.Render
			toggleConfiguration.Visible = false

			toggleConfiguration.Container.KeyBind.Bind.v.Text = 'None'
			TweenService:Create(toggleConfiguration.Container.KeyBind.Bind, TweenInfo.new(0.5, Enum.EasingStyle.Quint), { Size = UDim2.new(0, toggleConfiguration.Container.KeyBind.Bind.v.TextBounds.X + 20,0, 28) }):Play()

			toggleConfiguration.BackgroundTransparency = 1
			toggleConfiguration.Container.KeyBind.Title.TextTransparency = 1
			toggleConfiguration.Container.KeyBind.Bind.BackgroundTransparency = 1
			toggleConfiguration.Container.KeyBind.Bind.v.TextTransparency = 1
			toggleConfiguration.Container.Clear.Title.TextTransparency = 1
			toggleConfiguration.Container.Clear.clear.ImageLabel.ImageTransparency = 1
			toggleConfiguration.Size = UDim2.new(0, 75,0, 53)

			if not ToggleData.Config then
				toggle.Configure:Destroy()
			end

			local toggleTween = TweenInfo.new(0.7, Enum.EasingStyle.Exponential)
			local fadeTween = TweenInfo.new(0.57, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

			local function UpdateToggleUI(state)
				local targetColor = state and syde.theme.HitBox or Color3.fromRGB(28, 28, 28)
				local strokeTransparency = state and 1 or 0
				local checkTransparency = state and 0 or 1
				local gradientTransparency = state and 0 or 1

				TweenService:Create(toggle.tog, toggleTween, { BackgroundColor3 = targetColor }):Play()
				TweenService:Create(toggle.tog.UIStroke, toggleTween, { Transparency = strokeTransparency }):Play()
				TweenService:Create(toggle.tog.check, toggleTween, { ImageTransparency = checkTransparency }):Play()
				TweenService:Create(toggle.tog.gradfr, fadeTween, { BackgroundTransparency = gradientTransparency }):Play()
			end

			UpdateToggleUI(ToggleData.Value)

			toggle.interact.MouseButton1Click:Connect(function()
				if TabData.Locked == false then
					ToggleData.Value = not ToggleData.Value
					UpdateToggleUI(ToggleData.Value)

					local success, errorMsg = pcall(function()
						if ToggleData.CallBack then
							ToggleData.CallBack(ToggleData.Value)
						end
					end)

					if not success then
					end

					SaveConfig()
				end
			end)

			--[DESC]
			local descLabel = toggle:FindFirstChild("Desc")

			if descLabel then
				if ToggleData.Desc and ToggleData.Desc ~= "" then
					descLabel.Text = ToggleData.Desc
					descLabel.Visible = true
					descLabel.TextWrapped = true

					local function updateSize()
						local textSize = TextService:GetTextSize(
							descLabel.Text,
							descLabel.TextSize,
							descLabel.Font,
							Vector2.new(descLabel.AbsoluteSize.X, math.huge)
						)

						local newDescSize = UDim2.new(1, -150, 0, textSize.Y)
						local newButtonSize = UDim2.new(toggle.Size.X.Scale, toggle.Size.X.Offset, 0, toggle.Title.Size.Y.Offset + textSize.Y + 5) -- Adding extra padding

						local descTween = TweenService:Create(descLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = newDescSize })
						descTween:Play()

						local ToggleTween = TweenService:Create(toggle, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = newButtonSize })
						ToggleTween:Play()
					end

					updateSize()

					descLabel:GetPropertyChangedSignal("TextBounds"):Connect(updateSize)
				else
					descLabel.Visible = false
				end
			end


			-- [CONFIGURATIPON]
			if ToggleData.Config then

				local State = false

				local enterTween = TweenInfo.new(0.5, Enum.EasingStyle.Exponential)
				local leaveTween = TweenInfo.new(0.5, Enum.EasingStyle.Exponential)

				toggle.Configure.MouseEnter:Connect(function()
					TweenService:Create(toggle.Configure, enterTween, { ImageColor3 = Color3.fromRGB(255, 255, 255) }):Play()
				end)

				toggle.Configure.MouseLeave:Connect(function()
					TweenService:Create(toggle.Configure, leaveTween, { ImageColor3 = Color3.fromRGB(104, 104, 104) }):Play()
				end)

				local function ToggleConfigOpen()
					toggleConfiguration.Visible = true
					State = true

					TweenService:Create(toggleConfiguration, enterTween, { BackgroundTransparency = 0 }):Play()
					TweenService:Create(toggleConfiguration.Container.KeyBind.Title, enterTween, { TextTransparency = 0 }):Play()
					TweenService:Create(toggleConfiguration.Container.KeyBind.Bind, enterTween, { BackgroundTransparency = 0 }):Play()
					TweenService:Create(toggleConfiguration.Container.KeyBind.Bind.v, enterTween, { TextTransparency = 0 }):Play()
					TweenService:Create(toggleConfiguration.Container.Clear.clear.ImageLabel, enterTween, { ImageTransparency = 0 }):Play()
					TweenService:Create(toggleConfiguration.Container.Clear.Title, enterTween, { TextTransparency = 0 }):Play()
					TweenService:Create(toggleConfiguration, TweenInfo.new(0.7, Enum.EasingStyle.Quint), { Size = UDim2.new(0, 186,0, 85) }):Play()

				end

				local function ToggleConfigClose()
					State = false

					TweenService:Create(toggleConfiguration, enterTween, { BackgroundTransparency = 1 }):Play()
					TweenService:Create(toggleConfiguration.Container.KeyBind.Title, enterTween, { TextTransparency = 1 }):Play()
					TweenService:Create(toggleConfiguration.Container.KeyBind.Bind, enterTween, { BackgroundTransparency = 1 }):Play()
					TweenService:Create(toggleConfiguration.Container.KeyBind.Bind.v, enterTween, { TextTransparency = 1 }):Play()
					TweenService:Create(toggleConfiguration.Container.Clear.clear.ImageLabel, enterTween, { ImageTransparency = 1 }):Play()
					TweenService:Create(toggleConfiguration.Container.Clear.Title, enterTween, { TextTransparency = 1 }):Play()
					TweenService:Create(toggleConfiguration, TweenInfo.new(0.7, Enum.EasingStyle.Quint), { Size = UDim2.new(0, 75,0, 53) }):Play()

					task.wait(0.5)

					toggleConfiguration.Visible = false

				end

				local TogService
				local heldKeys = {} 
				local debounce1 = false

				local function ToggleConfig()
					if debounce1 then return end
					debounce1 = true

					if not toggleConfiguration.Visible then
						TogService = RunService.RenderStepped:Connect(function()
							toggleConfiguration:TweenPosition(UDim2.new(0,toggle.Configure.AbsolutePosition.X - 190,0,toggle.Configure.AbsolutePosition.Y + toggle.Configure.AbsoluteSize.Y + 65), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.1, true)
							if not toggleConfiguration.Visible then
								TogService:Disconnect()
							end
						end)
						ToggleConfigOpen()
					else
						if TogService then TogService:Disconnect() end
						ToggleConfigClose()
					end

					task.delay(0.4, function()
						debounce1 = false
					end)
				end

				toggle.Configure.MouseButton1Click:Connect(function()
					ToggleConfig()
				end)

				local function ResizeBindFrame()
					TweenService:Create(toggleConfiguration.Container.KeyBind.Bind, TweenInfo.new(0.5, Enum.EasingStyle.Quint), { Size = UDim2.new(0, toggleConfiguration.Container.KeyBind.Bind.v.TextBounds.X + 20,0, 28) }):Play()
				end

				local function setKeybind(key)
					if not key then
						toggleConfiguration.Container.KeyBind.Bind.v.Text = 'None'
						ResizeBindFrame()
						ToggleData.Keybind = nil
					else
						ToggleData.Keybind = key
						ToggleData.KeybindReady = false

						TweenService:Create(toggleConfiguration.Container.KeyBind.Bind.v, TweenInfo.new(0.25, Enum.EasingStyle.Exponential), { TextTransparency = 1 }):Play()
						toggleConfiguration.Container.KeyBind.Bind.v.Text = key.Name
						TweenService:Create(toggleConfiguration.Container.KeyBind.Bind.v, TweenInfo.new(1, Enum.EasingStyle.Exponential), { TextTransparency = 0 }):Play()
						ResizeBindFrame()

						task.delay(0.5, function()
							ToggleData.KeybindReady = true
						end)
					end
				end

				toggleConfiguration.Container.KeyBind.Interact.MouseButton1Click:Connect(function()
					TweenService:Create(toggleConfiguration.Container.KeyBind.Bind.v, TweenInfo.new(0.25, Enum.EasingStyle.Exponential), { TextTransparency = 1 }):Play()
					task.wait(0.2)
					toggleConfiguration.Container.KeyBind.Bind.v.Text = "..."
					TweenService:Create(toggleConfiguration.Container.KeyBind.Bind.v, TweenInfo.new(0.25, Enum.EasingStyle.Exponential), { TextTransparency = 0 }):Play()
					ResizeBindFrame()


					local connection
					connection = UserInputService.InputBegan:Connect(function(input, processed)
						if not processed and input.UserInputType == Enum.UserInputType.Keyboard then
							setKeybind(input.KeyCode)
							connection:Disconnect()
						end
					end)
				end)

				UserInputService.InputBegan:Connect(function(input, processed)
					if not processed and ToggleData.Keybind and ToggleData.KeybindReady and input.KeyCode == ToggleData.Keybind then
						if TabData.Locked == false then
							ToggleData.Value = not ToggleData.Value
							UpdateToggleUI(ToggleData.Value)

							if ToggleData.CallBack then
								local success, errorMsg = pcall(function()
									ToggleData.CallBack(ToggleData.Value)
								end)
								if not success then
								end

								SaveConfig()
							end
						end
					end
				end)

				local debounce2 = false

				toggleConfiguration.Container.Clear.Interact.MouseButton1Click:Connect(function()
					if debounce2 then return end
					debounce2 = true

					setKeybind(nil)

					local function blink()
						TweenService:Create(toggleConfiguration.Container.Clear.clear.ImageLabel, TweenInfo.new(0.25, Enum.EasingStyle.Quint), { Rotation = 13 }):Play()
						task.wait(0.2)
						TweenService:Create(toggleConfiguration.Container.Clear.clear.ImageLabel, TweenInfo.new(0.25, Enum.EasingStyle.Quint), { Rotation = -13 }):Play()
						task.wait(0.2)
						TweenService:Create(toggleConfiguration.Container.Clear.clear.ImageLabel, TweenInfo.new(0.25, Enum.EasingStyle.Quint), { Rotation = 0 }):Play()
					end

					blink()

					task.delay(2, function()
						debounce2 = false
					end)
				end)

				toggleConfiguration.Container.Clear.MouseEnter:Connect(function()
					TweenService:Create(toggleConfiguration.Container.Clear.clear, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), { BackgroundTransparency = 0.9 }):Play()
				end)

				toggleConfiguration.Container.Clear.MouseLeave:Connect(function()
					TweenService:Create(toggleConfiguration.Container.Clear.clear, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), { BackgroundTransparency = 1 }):Play()
				end)

			end

			function ToggleData:Set(NewValue)

				ToggleData.Value = NewValue
				UpdateToggleUI(NewValue)

				local success, errorMsg = pcall(function()
					if ToggleData.CallBack then
						ToggleData.CallBack(NewValue)
					end
				end)

				if not success then
				end

				SaveConfig()
			end

			if syde.ConfigEnabled then
				if ToggleData.Flag then
					syde.Flags[ToggleData.Flag] = ToggleData
				end
			end


			syde:AddConnection(syde.Comms.Event, function(p, color)
				if p == 'HitBox' then
					if ToggleData.Value then
						toggle.tog.BackgroundColor3 = color
					end
				end
			end)

			return ToggleData

		end

function InitElement:CreateSlider(Slider)
    local SliderData = {
        Title = Slider.Title;
        Desc = Slider.Description;
        Sliders = Slider.Sliders
    }

    local sliderContainer = PAGES.Page.Slider:Clone()
    sliderContainer.Visible = true
    sliderContainer.Parent = Page
    sliderContainer.Title.Text = SliderData.Title
    sliderContainer.Name = SliderData.Title
    sliderContainer.slideholder.slider.Visible = false

    local sliderObjects = {} 

    for index, Options in ipairs(SliderData.Sliders) do
        local SliderFrame = PAGES.Page.Slider.slideholder.slider:Clone()

        Options = {
            Title = Options.Title or "Slider";
            Increment = Options.Increment or 1;
            Range = Options.Range or {0, 100};
            StarterValue = Options.StarterValue or 16;
            CallBack = Options.CallBack;
            Flag = Options.Flag;
        }

        SliderFrame.Name = Options.Title
        SliderFrame.Title.Text = Options.Title

        local dragging = false
        SliderFrame.Visible = true
        SliderFrame.Parent = sliderContainer.slideholder

        local SliderPosition
        if Options.StarterValue <= Options.Range[1] then
            SliderPosition = 0
        elseif Options.StarterValue >= Options.Range[2] then
            SliderPosition = 1
        else
            local range = Options.Range[2] - Options.Range[1]
            SliderPosition = (Options.StarterValue - Options.Range[1]) / range
        end

        SliderFrame.slide.slideframe.Size = UDim2.new(SliderPosition, 0, 1, 0)

        local decimalPlaces = tostring(Options.Increment):match("%.([^0]*)") and #tostring(Options.Increment):match("%.([^0]*)") or 0
        SliderFrame.v.Text = string.format("<font size='14'>%." .. decimalPlaces .. "f</font><font color='#434343'>/%." .. decimalPlaces .. "f</font>", Options.StarterValue, Options.Range[2])

        local function UpdateSlider(x)
            if dragging then
                local sliderStart = SliderFrame.slide.AbsolutePosition.X
                local sliderWidth = SliderFrame.slide.AbsoluteSize.X
                local sliderPosition = (x - sliderStart) / sliderWidth
                sliderPosition = math.clamp(sliderPosition, 0, 1)

                local range = Options.Range[2] - Options.Range[1]
                local newValue = Options.Range[1] + sliderPosition * range
                newValue = math.floor((newValue - Options.Range[1]) / Options.Increment + 0.5) * Options.Increment + Options.Range[1]

                local snapPosition = (newValue - Options.Range[1]) / range
                TweenService:Create(SliderFrame.slide.slideframe, TweenInfo.new(0.55, Enum.EasingStyle.Quint), {
                    Size = UDim2.new(snapPosition, 0, 1, 0)
                }):Play()

                local decimalPlaces = tostring(Options.Increment):match("%.([^0]*)") and #tostring(Options.Increment):match("%.([^0]*)") or 0
                SliderFrame.v.Text = string.format("<font size='14'>%." .. decimalPlaces .. "f</font><font color='#434343'>/%." .. decimalPlaces .. "f</font>", newValue, Options.Range[2])

                TweenService:Create(SliderFrame.Title, TweenInfo.new(0.55, Enum.EasingStyle.Exponential), {
                    TextTransparency = 0
                }):Play()

                if TabData.Locked == false then
                    local success, errorMsg = pcall(function()
                        Options.CallBack(newValue)
                    end)
                    if not success then
                        -- Handle error
                    end

                    Options.StarterValue = newValue
                    SaveConfig()
                end
            end
        end

        SliderFrame.slide.Interact.MouseButton1Down:Connect(function()
            dragging = true
        end)

        SliderFrame.slide.Interact.MouseButton1Up:Connect(function()
            dragging = false
        end)

        syde:AddConnection(UserInputService.InputEnded, function(input, processed)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
                if SliderFrame and SliderFrame:FindFirstChild("Title") then
                    TweenService:Create(SliderFrame.Title, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {
                        TextTransparency = 0.6
                    }):Play()
                end
            end
        end)

        syde:AddConnection(UserInputService.InputChanged, function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                UpdateSlider(input.Position.X)
            end
        end)

        SliderFrame.slide.slideframe.BackgroundColor3 = syde.theme.HitBox
        SliderFrame.slide.slideframe.shadowHolder.ambientShadow.ImageColor3 = syde.theme.HitBox
        SliderFrame.slide.slideframe.shadowHolder.penumbraShadow.ImageColor3 = syde.theme.HitBox
        SliderFrame.slide.slideframe.shadowHolder.umbraShadow.ImageColor3 = syde.theme.HitBox
        
        sliderContainer.slideholder.Size = UDim2.new(1, -30, 0, sliderContainer.slideholder.UIListLayout.AbsoluteContentSize.Y)
        local ss = sliderContainer.slideholder.UIListLayout.AbsoluteContentSize.Y
        sliderContainer.Size = UDim2.new(1, -15, 0, ss + 20)

        syde:AddConnection(syde.Comms.Event, function(p, color)
            if p == 'HitBox' then
                SliderFrame.slide.slideframe.BackgroundColor3 = color
                SliderFrame.slide.slideframe.shadowHolder.ambientShadow.ImageColor3 = color
                SliderFrame.slide.slideframe.shadowHolder.penumbraShadow.ImageColor3 = color
                SliderFrame.slide.slideframe.shadowHolder.umbraShadow.ImageColor3 = color
            end
        end)

        function Options:Set(NewVal, noCallback)
            NewVal = math.clamp(NewVal, Options.Range[1], Options.Range[2])
            
            local range = Options.Range[2] - Options.Range[1]
            local sliderPosition = (NewVal - Options.Range[1]) / range

            TweenService:Create(SliderFrame.slide.slideframe, TweenInfo.new(0.55, Enum.EasingStyle.Quint), {
                Size = UDim2.new(sliderPosition, 0, 1, 0)
            }):Play()

            local decimalPlaces = tostring(Options.Increment):match("%.([^0]*)") and #tostring(Options.Increment):match("%.([^0]*)") or 0
            SliderFrame.v.Text = string.format("<font size='14'>%." .. decimalPlaces .. "f</font><font color='#434343'>/%." .. decimalPlaces .. "f</font>", NewVal, Options.Range[2])

            if not noCallback and TabData.Locked == false then
                local success, errorMsg = pcall(function()
                    Options.CallBack(NewVal)
                end)
                if not success then
                    -- Handle error
                end
            end

            Options.StarterValue = NewVal
        end

        sliderObjects[index] = Options

        if syde.ConfigEnabled then
            if Options.Flag then
                syde.Flags[Options.Flag] = Options
            end
        end
    end

    local descLabel = sliderContainer.slideholder:FindFirstChild("Desc")

    if descLabel then
        if SliderData.Desc and SliderData.Desc ~= "" then
            descLabel.Text = SliderData.Desc
            descLabel.Visible = true
            descLabel.TextWrapped = true

            local function updateSize()
                local textSize = TextService:GetTextSize(
                    descLabel.Text,
                    descLabel.TextSize,
                    descLabel.Font,
                    Vector2.new(descLabel.AbsoluteSize.X, math.huge)
                )

                local newDescSize = UDim2.new(1, -150, 0, textSize.Y)
                local newButtonSize = UDim2.new(sliderContainer.Size.X.Scale, sliderContainer.Size.X.Offset, 0, sliderContainer.slideholder.AbsoluteSize.Y + sliderContainer.Title.Size.Y.Offset + textSize.Y - 5)

                local descTween = TweenService:Create(descLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Size = newDescSize
                }):Play()

                local ToggleTween = TweenService:Create(sliderContainer, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Size = newButtonSize
                }):Play()
            end

            updateSize()
            descLabel:GetPropertyChangedSignal("TextBounds"):Connect(updateSize)
        else
            descLabel.Visible = false
        end
    end

    return sliderObjects[1]
end

function InitElement:Dropdown(Dropdown)
	local DropdownData = {
		Title = Dropdown.Title or "Temp Dropdown";
		Options = Dropdown.Options or {};
		StarterOption = Dropdown.StarterOption;
		PlaceHolder = Dropdown.PlaceHolder or "Select Option...";
		Multi = Dropdown.Multi or false;
		CallBack = Dropdown.CallBack;
	}

	local dropdown = PAGES.Page.Dropdown:Clone()
	dropdown.Visible = true
	dropdown.Parent = Page
	dropdown.Title.Text = DropdownData.Title
	dropdown.Name = DropdownData.Title
	dropdown.dropHolder.drop.Container.Option.Visible = false
	dropdown.dropHolder.drop.Container.Visible = false
	TweenService:Create(dropdown.dropHolder.drop.Container, TweenInfo.new(1, Enum.EasingStyle.Quint), { Size = UDim2.new(0.33, -20,0.576, -75) }):Play()
	dropdown.dropHolder.drop.Selected.Text = DropdownData.PlaceHolder 

	local DropOpen = false
	local DeBounce = false
	local OptionButton = dropdown.dropHolder.drop.Container.Option
	local SelectedOptions = {}
	local SelectedOrder = {}
	local searchDebounce = false

	local function UpdateCustomLayout()
		local yOffset = 0
		for _, option in ipairs(dropdown.dropHolder.drop.Container:GetChildren()) do
			if option:IsA("Frame") and option.Name ~= "Option" and option.Visible then
				option.Position = UDim2.new(0, 0, 0, yOffset)
				yOffset = yOffset + option.Size.Y.Offset + 7
			end
		end
	end

	local function OpenDrop()
		DropOpen = true
		dropdown.dropHolder.drop.Container.Visible = true
		dropdown.dropHolder.drop.Search.Visible = true

		TweenService:Create(dropdown, TweenInfo.new(1.34, Enum.EasingStyle.Quint), { Size = UDim2.new(1, -15, 0, 300) }):Play()
		TweenService:Create(dropdown.dropHolder.drop.Container, TweenInfo.new(1, Enum.EasingStyle.Quint), { Size = UDim2.new(1, -20, 1, -75) }):Play()
		TweenService:Create(dropdown.dropHolder.drop.void, TweenInfo.new(1.34, Enum.EasingStyle.Exponential), { BackgroundTransparency = 0 }):Play()
		TweenService:Create(dropdown.dropHolder.drop.down, TweenInfo.new(0.35, Enum.EasingStyle.Quint), { Rotation = 180 }):Play()

		TweenService:Create(dropdown.dropHolder.drop.Search, TweenInfo.new(1, Enum.EasingStyle.Exponential), { BackgroundTransparency = 0.65 }):Play()
		TweenService:Create(dropdown.dropHolder.drop.Search.UIStroke, TweenInfo.new(1, Enum.EasingStyle.Exponential), { Transparency = 0.4 }):Play()
		TweenService:Create(dropdown.dropHolder.drop.Search.TextBox, TweenInfo.new(1, Enum.EasingStyle.Exponential), { TextTransparency = 0 }):Play()
		TweenService:Create(dropdown.dropHolder.drop.Search.ImageLabel, TweenInfo.new(1, Enum.EasingStyle.Exponential), { ImageTransparency = 0.9 }):Play()
		TweenService:Create(dropdown.dropHolder.drop.Search.icon, TweenInfo.new(1, Enum.EasingStyle.Exponential), { ImageTransparency = 0.85 }):Play()
	end

	local function CloseDrop()
		DropOpen = false
		dropdown.dropHolder.drop.Search.TextBox.Text = ""
		
		TweenService:Create(dropdown, TweenInfo.new(1, Enum.EasingStyle.Quint), { Size = UDim2.new(1, -15, 0, 89) }):Play()
		TweenService:Create(dropdown.dropHolder.drop.Container, TweenInfo.new(1, Enum.EasingStyle.Quint), { Size = UDim2.new(0.33, -20, 0.576, -75) }):Play()
		TweenService:Create(dropdown.dropHolder.drop.void, TweenInfo.new(1.34, Enum.EasingStyle.Exponential), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(dropdown.dropHolder.drop.down, TweenInfo.new(0.35, Enum.EasingStyle.Quint), { Rotation = 0 }):Play()

		TweenService:Create(dropdown.dropHolder.drop.Search, TweenInfo.new(1, Enum.EasingStyle.Exponential), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(dropdown.dropHolder.drop.Search.UIStroke, TweenInfo.new(1, Enum.EasingStyle.Exponential), { Transparency = 1 }):Play()
		TweenService:Create(dropdown.dropHolder.drop.Search.TextBox, TweenInfo.new(1, Enum.EasingStyle.Exponential), { TextTransparency = 1 }):Play()
		TweenService:Create(dropdown.dropHolder.drop.Search.ImageLabel, TweenInfo.new(1, Enum.EasingStyle.Exponential), { ImageTransparency = 1 }):Play()
		TweenService:Create(dropdown.dropHolder.drop.Search.icon, TweenInfo.new(1, Enum.EasingStyle.Exponential), { ImageTransparency = 1 }):Play()

		task.wait(0.6)
		dropdown.dropHolder.drop.Container.Visible = false
		dropdown.dropHolder.drop.Search.Visible = false
	end

	dropdown.dropHolder.drop.down.MouseButton1Click:Connect(function()
		if DeBounce then return end
		DeBounce = true

		if DropOpen then
			CloseDrop()
		else
			OpenDrop()
		end

		task.delay(1.2, function()
			DeBounce = false
		end)
	end)

	local function UpdateSelectedText()
		if #SelectedOrder > 0 then
			dropdown.dropHolder.drop.Selected.Text = table.concat(SelectedOrder, ", ")
		else
			dropdown.dropHolder.drop.Selected.Text = DropdownData.PlaceHolder
		end
	end

	local function AddToSelected(option)
		if not SelectedOptions[option] then
			SelectedOptions[option] = true

			local originalIndex
			for i, opt in ipairs(DropdownData.Options) do
				if opt == option then
					originalIndex = i
					break
				end
			end

			local insertIndex = 1
			for i, selected in ipairs(SelectedOrder) do
				local selectedIndex = table.find(DropdownData.Options, selected)
				if selectedIndex and selectedIndex < originalIndex then
					insertIndex = i + 1
				else
					break
				end
			end
			table.insert(SelectedOrder, insertIndex, option)
		end
	end

	local function RemoveFromSelected(option)
		if SelectedOptions[option] then
			SelectedOptions[option] = nil
			for i = #SelectedOrder, 1, -1 do
				if SelectedOrder[i] == option then
					table.remove(SelectedOrder, i)
					break
				end
			end
		end
	end

	local function UpdateSearch()
		if searchDebounce then return end
		searchDebounce = true

		local searchText = dropdown.dropHolder.drop.Search.TextBox.Text:lower()

		for _, option in ipairs(dropdown.dropHolder.drop.Container:GetChildren()) do
			if option:IsA("Frame") and option.Name ~= "Option" and option:FindFirstChild("Title") then
				local optionText = option.Title.Text:lower()
				local shouldShow = searchText == "" or optionText:find(searchText, 1, true)

				if shouldShow then
					option.Visible = true
					if SelectedOptions[option.Title.Text] then
						option.BackgroundTransparency = 0
						option.BackgroundColor3 = Color3.fromRGB(39, 39, 39)
						option.Title.TextTransparency = 0
						if option:FindFirstChild("UIStroke") then
							option.UIStroke.Transparency = 1
						end
						if option:FindFirstChild("ImageLabel") then
							option.ImageLabel.ImageTransparency = 0
						end
					else
						option.BackgroundTransparency = 0
						option.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
						option.Title.TextTransparency = 0
						if option:FindFirstChild("UIStroke") then
							option.UIStroke.Transparency = 0.5
						end
						if option:FindFirstChild("ImageLabel") then
							option.ImageLabel.ImageTransparency = 0.9
						end
					end
				else
					option.Visible = false
				end
			end
		end

		UpdateCustomLayout()
		
		task.wait(0.05)
		searchDebounce = false
	end

	dropdown.dropHolder.drop.Search.TextBox:GetPropertyChangedSignal("Text"):Connect(UpdateSearch)

	local function SetDropdownOptions()
		local starterSet = false
		for _, OptionText in ipairs(DropdownData.Options) do
			local option = OptionButton:Clone()
			option.Title.Text = OptionText
			option.Parent = dropdown.dropHolder.drop.Container
			option.Visible = true
			option.Name = OptionText

			if OptionText == DropdownData.StarterOption and not starterSet then
				starterSet = true
				dropdown.dropHolder.drop.Selected.Text = OptionText
				SelectedOptions = {[OptionText] = true}
				SelectedOrder = {OptionText}

				option.BackgroundColor3 = Color3.fromRGB(39, 39, 39)
				if option:FindFirstChild("ImageLabel") then
					option.ImageLabel.ImageTransparency = 0
				end
			end

			option.Interact.MouseButton1Click:Connect(function()
				if DropdownData.Multi then
					if SelectedOptions[OptionText] then
						RemoveFromSelected(OptionText)
						TweenService:Create(option, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(33, 33, 33)}):Play()
						if option:FindFirstChild("ImageLabel") then
							TweenService:Create(option.ImageLabel, TweenInfo.new(0.3), {ImageTransparency = 0.9}):Play()
						end
					else
						AddToSelected(OptionText)
						TweenService:Create(option, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(39, 39, 39)}):Play()
						if option:FindFirstChild("ImageLabel") then
							TweenService:Create(option.ImageLabel, TweenInfo.new(0.3), {ImageTransparency = 0}):Play()
						end
					end

					UpdateSelectedText()

					if TabData.Locked == false then
						if DropdownData.CallBack then
							DropdownData.CallBack(SelectedOrder)
						end
					end
				else
					dropdown.dropHolder.drop.Selected.Text = OptionText

					SelectedOptions = {[OptionText] = true}
					SelectedOrder = {OptionText}

					for _, opt in ipairs(dropdown.dropHolder.drop.Container:GetChildren()) do
						if opt:IsA("Frame") and opt.Name ~= "Option" then
							TweenService:Create(opt, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(33, 33, 33)}):Play()
							if opt:FindFirstChild("ImageLabel") then
								TweenService:Create(opt.ImageLabel, TweenInfo.new(0.3), {ImageTransparency = 0.9}):Play()
							end
						end
					end

					TweenService:Create(option, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(39, 39, 39)}):Play()
					if option:FindFirstChild("ImageLabel") then
						TweenService:Create(option.ImageLabel, TweenInfo.new(0.3), {ImageTransparency = 0}):Play()
					end
					
					if TabData.Locked == false then
						if DropdownData.CallBack then
							DropdownData.CallBack(OptionText)
						end
					end
			
					CloseDrop()
				end
			end)
		end

		if not starterSet then
			dropdown.dropHolder.drop.Selected.Text = DropdownData.PlaceHolder
		end

		UpdateCustomLayout()
	end

	SetDropdownOptions()

	function DropdownData:Set(NewValue)
		if DropdownData.Multi then
			return
		end

		local foundOption = false
		for _, OptionText in ipairs(DropdownData.Options) do
			if OptionText == NewValue then
				foundOption = true
				break
			end
		end

		if not foundOption then
			return
		end

		dropdown.dropHolder.drop.Selected.Text = NewValue
		SelectedOptions = {[NewValue] = true}
		SelectedOrder = {NewValue}

		for _, opt in ipairs(dropdown.dropHolder.drop.Container:GetChildren()) do
			if opt:IsA("Frame") and opt.Name ~= "Option" then
				if opt.Title.Text == NewValue then
					TweenService:Create(opt, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(39, 39, 39)}):Play()
					if opt:FindFirstChild("ImageLabel") then
						TweenService:Create(opt.ImageLabel, TweenInfo.new(0.3), {ImageTransparency = 0}):Play()
					end
				else
					TweenService:Create(opt, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(33, 33, 33)}):Play()
					if opt:FindFirstChild("ImageLabel") then
						TweenService:Create(opt.ImageLabel, TweenInfo.new(0.3), {ImageTransparency = 0.9}):Play()
					end
				end
			end
		end

		if TabData.Locked == false then
			if DropdownData.CallBack then
				DropdownData.CallBack(NewValue)
			end
		end
	end

	return DropdownData
end


		function InitElement:TextInput(TextInput)
			local TextInputData = {
				Title = TextInput.Title or "Text Input",
				PlaceHolder = TextInput.PlaceHolder or "Enter text...",
				NumbersOnly = TextInput.NumberOnly or false,
				ClearOnLost = TextInput.ClearOnLost == nil and true or TextInput.ClearOnLost,
				MaxSize = TextInput.MaxSize or 100,
				CallBack = TextInput.CallBack,
			}

			local textinput = PAGES.Page.Input:Clone()
			textinput.Visible = true
			textinput.Parent = Page
			textinput.Name = TextInputData.Title
			textinput.Title.Text = TextInputData.Title
			textinput.TextFrame.TextBox.PlaceholderText = TextInputData.PlaceHolder

			local textBox = textinput.TextFrame.TextBox
			local defaultHeight = 32
			local maxHeight = TextInputData.MaxSize

			textinput.TextFrame.Enter.MouseEnter:Connect(function()
				TweenService:Create(textinput.TextFrame.Enter, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
			end)

			textinput.TextFrame.Enter.MouseLeave:Connect(function()
				TweenService:Create(textinput.TextFrame.Enter, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextColor3 = Color3.fromRGB(40, 40, 40)}):Play()
			end)

			textBox:GetPropertyChangedSignal("Text"):Connect(function()
				if TextInputData.NumbersOnly then
					textBox.Text = textBox.Text:gsub("%D", "")
				end

				textBox.Size = UDim2.new(1, -60, 0, defaultHeight + 40)

				local textSize = game:GetService("TextService"):GetTextSize(
					textBox.Text, textBox.TextSize, textBox.Font, Vector2.new(textBox.AbsoluteSize.X, math.huge)
				)

				if textBox.Text == "" then
					textBox.Size = UDim2.new(1, -60, 0, math.max(defaultHeight))
				else
					local newHeight = math.min(textSize.Y + 18, maxHeight + 50)
					textBox.Size = UDim2.new(1, -60, 0, newHeight)
				end

			end)

			textinput.TextFrame:GetPropertyChangedSignal("Size"):Connect(function()
				local newHeight = textinput.TextFrame.Size.Y.Offset
				local extraHeight = 32

				TweenService:Create(
					textinput,
					TweenInfo.new(0.7, Enum.EasingStyle.Quint),
					{ Size = UDim2.new(1, -15, 0, newHeight + extraHeight + 25) }
				):Play()

			end)

			textBox:GetPropertyChangedSignal("Size"):Connect(function()
				local newHeight = textBox.Size.Y.Offset
				local totalHeight = math.max(newHeight, defaultHeight)

				TweenService:Create(
					textinput.TextFrame,
					TweenInfo.new(0.7, Enum.EasingStyle.Quint),
					{ Size = UDim2.new(1, -60, 0, totalHeight + 0) }
				):Play()

			end)

			textBox.FocusLost:Connect(function(enterPressed)
				if not enterPressed then return end

				local success, errorMsg = pcall(function()
					TextInputData.CallBack(textBox.Text)
				end)
				if not success then
				end

				if TextInputData.ClearOnLost then
					task.defer(function()
						textBox.Text = ""
						textBox.Size = UDim2.new(1, -60, 0, math.max(defaultHeight))
					end)
				else
					textBox.ClearTextOnFocus = false
				end
			end)

			textinput.TextFrame.Enter.MouseButton1Click:Connect(function()
				local success, errorMsg = pcall(function()
					TextInputData.CallBack(textBox.Text)
				end)
				if not success then
				end

				if TextInputData.ClearOnLost then
					task.defer(function()
						textBox.Text = ""
						textBox.Size = UDim2.new(1, -60, 0, math.max(defaultHeight))
					end)
				else
					textBox.ClearTextOnFocus = false
				end
			end)
		end

		function InitElement:ColorPicker(ColorPicker)
			local ColorPickerData = {
				Title = ColorPicker.Title;
				Color = ColorPicker.Color or Color3.fromRGB(255, 255, 255);
				Linkable = ColorPicker.Linkable;
				CallBack = ColorPicker.CallBack;
				Flag = ColorPicker.Flag;
			}

			ColorPicker.Linkable = ColorPicker.Linkable or true
			ColorPickerData.Type = 'ColorPicker'

			local colorpicker = PAGES.Page.ColorPicker:Clone()
			colorpicker.Visible = true
			colorpicker.Parent = Page
			colorpicker.Title.Text = ColorPickerData.Title
			colorpicker.Name = ColorPickerData.Title

			local isLinkable = Instance.new("BoolValue")
			isLinkable.Name = 'isLinkable'
			isLinkable.Value = ColorPickerData.Linkable
			isLinkable.Parent = colorpicker

			local HueSat = Instance.new("Color3Value")
			HueSat.Name = 'HueSat'
			HueSat.Value = ColorPickerData.Color
			HueSat.Parent = colorpicker

			local Open = false
			local DeBounce = false
			local State = false

			colorpicker.color.Values.Hue.BackgroundTransparency = 1
			colorpicker.color.Values.Hue.Pin.BackgroundTransparency = 1
			colorpicker.color.Values.Hue.Pin.UIStroke.Transparency = 1
			colorpicker.color.Values.Rainbow.ImageTransparency = 1

			colorpicker.color.SVPicker.Pin.BackgroundTransparency = 1
			colorpicker.color.SVPicker.Pin.UIStroke.Transparency = 1
			colorpicker.color.SVPicker.Brightness.BackgroundTransparency = 1
			colorpicker.color.SVPicker.Saturation.BackgroundTransparency = 1

			colorpicker.HueValues.HEX.BackgroundTransparency = 1
			colorpicker.HueValues.HEX.UIStroke.Transparency = 1
			colorpicker.HueValues.HEX.V.HEXBox.TextTransparency = 1
			colorpicker.HueValues.HEX.Link.ImageTransparency = 1
			colorpicker.HueValues.HEX.Copy.ImageTransparency = 1

			colorpicker.HueValues.RGB.BackgroundTransparency = 1
			colorpicker.HueValues.RGB.UIStroke.Transparency = 1
			colorpicker.HueValues.RGB.V.RGBBox.TextTransparency = 1
			colorpicker.HueValues.RGB.Copy.ImageTransparency = 1
			colorpicker.QuickClose.Interactable = false

			local recentContainer = colorpicker.color.Recent
			local spacing = 5
			local frameSize = 12 

			local function updateRecentLayout()
				local children = {} 
				for _, child in pairs(recentContainer:GetChildren()) do
					if child:IsA("Frame") then
						table.insert(children, child)
					end
				end

				table.sort(children, function(a, b)
					return a.LayoutOrder > b.LayoutOrder 
				end)

				-- Calculate total width needed
				local totalWidth = #children * frameSize + math.max(#children - 1, 0) * spacing
				local startX = recentContainer.AbsoluteSize.X - totalWidth 

				for _, frame in ipairs(children) do
					--	frame.Position = UDim2.new(0, startX, 0.5, -frame.Size.Y.Offset / 2)
					TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quart), {Position = UDim2.new(0, startX , 0.8, -frame.Size.Y.Offset / 2) }):Play()
					startX += frameSize + spacing
				end
			end

			recentContainer.ChildAdded:Connect(function(child)
				if child:IsA("Frame") then
					child.LayoutOrder = os.time() 
					updateRecentLayout()
				end
			end)
			recentContainer.ChildRemoved:Connect(updateRecentLayout)
			updateRecentLayout()

			local HSV

			if ColorPickerData.Color then
				HSV = { ColorPickerData.Color:ToHSV() }
			else

				HSV = { 0, 0, 0 }
			end
			local Selected = ColorPickerData.Color
			local HueValue = HSV[1]

			local function TableToColor(Table)
				if type(Table) ~= "table" then return Table end
				return Color3.fromHSV(Table[1],Table[2],Table[3])
			end

			local function FormatColor(Color, format, precision)

				format = format or "RGB"
				precision = precision or 2

				local formattedColor = ""

				if format == "RGB" then
					return	math.round(Color.R * 255) .. "," .. math.round(Color.G * 255) .. "," .. math.round(Color.B * 255)
				elseif format == "Hex" then
					formattedColor = string.format("#%02X%02X%02X",
						math.round(Color.R * 255),
						math.round(Color.G * 255),
						math.round(Color.B * 255)
					)

					return formattedColor
				end
			end

			local SVPicker = colorpicker.color.SVPicker
			local HUESlider = colorpicker.color.Values.Hue

			SVPicker.Pin.BackgroundColor3 = ColorPickerData.Color
			HUESlider.Pin.BackgroundColor3 = ColorPickerData.Color

			local function updatestuff()
				ColorPickerData.Color = TableToColor(HSV)
				colorpicker.color.BackgroundColor3 = ColorPickerData.Color
				colorpicker.color.glow.ImageColor3 = ColorPickerData.Color

				colorpicker.color.BackgroundColor3 = Color3.fromHSV(HSV[1], 1, 1)
				local newColor = Color3.fromHSV(HSV[1], HSV[2], HSV[3])
				local newColor2 = Color3.fromHSV(HSV[1], 1, 1)

				HueSat.Value = ColorPickerData.Color

				TweenService:Create(HUESlider.Pin, TweenInfo.new(0.1, Enum.EasingStyle.Exponential), {BackgroundColor3 = newColor2}):Play()
				TweenService:Create(SVPicker.Pin, TweenInfo.new(0.1, Enum.EasingStyle.Exponential), {BackgroundColor3 = newColor}):Play()


				TweenService:Create(SVPicker.Pin, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Position = UDim2.new(HSV[2], 0, 1 - HSV[3], 0)
				}):Play()

				TweenService:Create(HUESlider.Pin, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Position = UDim2.new(1 - HSV[1], 0, 0.5, 0)
				}):Play()

				local formattedHex = FormatColor(ColorPickerData.Color, 'Hex')
				colorpicker.HueValues.HEX.V.HEXBox.PlaceholderText = formattedHex

				local formattedRGB = FormatColor(ColorPickerData.Color,'RGB', 2)
				colorpicker.HueValues.RGB.V.RGBBox.PlaceholderText = formattedRGB

				if ColorPickerData.CallBack then
					ColorPickerData.CallBack(ColorPickerData.Color)
				end

				ColorPickerData.Color = ColorPickerData.Color
			end
			updatestuff()

			local newColor = Color3.fromHSV(HSV[1], HSV[2], HSV[3])

			local function OpenPicker()
				Open = true
				DeBounce = true
				colorpicker.color.Values.Visible = true
				colorpicker.color.SVPicker.Visible = true
				colorpicker.HueValues.Visible = true
				colorpicker.color.Recent.Visible = true

				colorpicker.interact.Interactable = false
				colorpicker.QuickClose.Interactable = true

				TweenService:Create(colorpicker.color, TweenInfo.new( 0.95, Enum.EasingStyle.Quart ), { Size = UDim2.new(0, 1,0, 1) }):Play()
				TweenService:Create(colorpicker, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { BackgroundColor3 = Color3.fromRGB(35, 35, 35) }):Play()
				TweenService:Create(colorpicker.color, TweenInfo.new( 1, Enum.EasingStyle.Exponential ), { BackgroundColor3 = Color3.fromHSV(HSV[1], 1, 1) }):Play()
				TweenService:Create(colorpicker.QuickClose, TweenInfo.new( 0.6, Enum.EasingStyle.Exponential ), { BackgroundTransparency = 0 }):Play()
				TweenService:Create(colorpicker.color.glow, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { ImageTransparency = 1}):Play()
				task.wait(0.12)
				TweenService:Create(colorpicker.color, TweenInfo.new( 0.9, Enum.EasingStyle.Quart ), { Size = UDim2.new(1, -200,0, 120) }):Play()
				TweenService:Create(colorpicker, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { BackgroundColor3 = Color3.fromRGB(18, 18, 18) }):Play()
				TweenService:Create(colorpicker, TweenInfo.new( 0.8, Enum.EasingStyle.Quart ), { Size = UDim2.new(1, -15,0, 180) }):Play()
				TweenService:Create(colorpicker.color.Values.Rainbow, TweenInfo.new( 1, Enum.EasingStyle.Exponential ), { ImageTransparency = 0 }):Play()
				task.wait(0.6)

				TweenService:Create(colorpicker.color.SVPicker.Brightness, TweenInfo.new( 2, Enum.EasingStyle.Exponential ), { BackgroundTransparency = 0 }):Play()
				TweenService:Create(colorpicker.color.SVPicker.Saturation, TweenInfo.new( 2, Enum.EasingStyle.Exponential ), { BackgroundTransparency = 0 }):Play()
				TweenService:Create(colorpicker.color.SVPicker.Pin, TweenInfo.new( 2, Enum.EasingStyle.Exponential ), { BackgroundTransparency = 0 }):Play()
				TweenService:Create(colorpicker.color.SVPicker.Pin.UIStroke, TweenInfo.new( 2, Enum.EasingStyle.Exponential ), { Transparency = 0.58 }):Play()

				task.wait(0.5)
				TweenService:Create(colorpicker.color.Values.Hue, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { BackgroundTransparency = 0 }):Play()
				TweenService:Create(colorpicker.color.Values.Hue.Pin, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { BackgroundTransparency = 0 }):Play()
				TweenService:Create(colorpicker.color.Values.Hue.Pin.UIStroke, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { Transparency = 0.58 }):Play()

				TweenService:Create(colorpicker.HueValues.HEX, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { BackgroundTransparency = 0.9 }):Play()
				TweenService:Create(colorpicker.HueValues.HEX.UIStroke, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { Transparency = 0.4 }):Play()
				TweenService:Create(colorpicker.HueValues.HEX.V.HEXBox, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { TextTransparency = 0 }):Play()
				TweenService:Create(colorpicker.HueValues.HEX.Link, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { ImageTransparency = 0 }):Play()
				TweenService:Create(colorpicker.HueValues.HEX.Copy, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { ImageTransparency = 0 }):Play()

				task.wait(0.09)
				TweenService:Create(colorpicker.HueValues.RGB, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { BackgroundTransparency = 0.9 }):Play()
				TweenService:Create(colorpicker.HueValues.RGB.UIStroke, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { Transparency = 0.4 }):Play()
				TweenService:Create(colorpicker.HueValues.RGB.V.RGBBox, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { TextTransparency = 0 }):Play()
				TweenService:Create(colorpicker.HueValues.RGB.Copy, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { ImageTransparency = 0 }):Play()

				for _,v in ipairs(colorpicker.color.Recent:GetChildren()) do
					if v:IsA('Frame') then
						task.wait(0.1)
						TweenService:Create(v, TweenInfo.new( 0.3, Enum.EasingStyle.Exponential ), { BackgroundTransparency = 0 }):Play()
					end
				end

				task.wait(0.7)
				DeBounce = false
			end


			colorpicker.interact.MouseButton1Click:Connect(function()
				if DeBounce then return end
				if not Open then
					Open = true
					OpenPicker()
				end
			end)

			colorpicker.QuickClose.MouseEnter:Connect(function()
				TweenService:Create(colorpicker.QuickClose, TweenInfo.new( 0.8, Enum.EasingStyle.Quint ), { Size = UDim2.new(0, 70,0, 3) }):Play()
				TweenService:Create(colorpicker.QuickClose, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { BackgroundColor3 = Color3.fromRGB(255, 255, 255) }):Play()
			end)

			colorpicker.QuickClose.MouseLeave:Connect(function()
				TweenService:Create(colorpicker.QuickClose, TweenInfo.new( 0.8, Enum.EasingStyle.Quint ), { Size = UDim2.new(0, 60,0, 3) }):Play()
				TweenService:Create(colorpicker.QuickClose, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { BackgroundColor3 = Color3.fromRGB(33, 33, 33) }):Play()
			end)

			local function ClosePicker()
				Open = false
				DeBounce = true
				TweenService:Create(colorpicker, TweenInfo.new( 0.85, Enum.EasingStyle.Quint ), { Size = UDim2.new(1, -15,0, 40) }):Play()
				TweenService:Create(colorpicker.color, TweenInfo.new( 0.85, Enum.EasingStyle.Quint ), { Size = UDim2.new(0, 20,0, 20) }):Play()
				TweenService:Create(colorpicker.color, TweenInfo.new( 0.6, Enum.EasingStyle.Exponential ), { BackgroundColor3 = ColorPickerData.Color }):Play()
				TweenService:Create(colorpicker.QuickClose, TweenInfo.new( 0.6, Enum.EasingStyle.Exponential ), { BackgroundTransparency = 1 }):Play()
				TweenService:Create(colorpicker.color.glow, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { ImageTransparency = 0.73}):Play()
				colorpicker.interact.Interactable = true
				colorpicker.QuickClose.Interactable = false

				--	task.wait(0.6)

				TweenService:Create(colorpicker.color.SVPicker.Brightness, TweenInfo.new( 2, Enum.EasingStyle.Exponential ), { BackgroundTransparency = 1 }):Play()
				TweenService:Create(colorpicker.color.SVPicker.Saturation, TweenInfo.new( 2, Enum.EasingStyle.Exponential ), { BackgroundTransparency = 1 }):Play()
				TweenService:Create(colorpicker.color.SVPicker.Pin, TweenInfo.new( 1, Enum.EasingStyle.Exponential ), { BackgroundTransparency = 1 }):Play()
				TweenService:Create(colorpicker.color.SVPicker.Pin.UIStroke, TweenInfo.new( 0.4, Enum.EasingStyle.Exponential ), { Transparency = 1 }):Play()
				TweenService:Create(colorpicker.color.Values.Hue, TweenInfo.new( 0.5, Enum.EasingStyle.Exponential ), { BackgroundTransparency = 1 }):Play()
				TweenService:Create(colorpicker.color.Values.Hue.Pin, TweenInfo.new( 1, Enum.EasingStyle.Exponential ), { BackgroundTransparency = 1 }):Play()
				TweenService:Create(colorpicker.color.Values.Hue.Pin.UIStroke, TweenInfo.new( 0.5, Enum.EasingStyle.Exponential ), { Transparency = 1 }):Play()
				TweenService:Create(colorpicker.color.Values.Rainbow, TweenInfo.new( 0.5, Enum.EasingStyle.Exponential ), { ImageTransparency = 1 }):Play()

				TweenService:Create(colorpicker.HueValues.RGB, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { BackgroundTransparency = 1 }):Play()
				TweenService:Create(colorpicker.HueValues.RGB.UIStroke, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { Transparency = 1 }):Play()
				TweenService:Create(colorpicker.HueValues.RGB.V.RGBBox, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { TextTransparency = 1 }):Play()
				TweenService:Create(colorpicker.HueValues.RGB.Copy, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { ImageTransparency = 1 }):Play()

				task.wait(0.1)

				TweenService:Create(colorpicker.HueValues.HEX, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { BackgroundTransparency = 1 }):Play()
				TweenService:Create(colorpicker.HueValues.HEX.UIStroke, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { Transparency = 1 }):Play()
				TweenService:Create(colorpicker.HueValues.HEX.V.HEXBox, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { TextTransparency = 1 }):Play()
				TweenService:Create(colorpicker.HueValues.HEX.Link, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { ImageTransparency = 1 }):Play()
				TweenService:Create(colorpicker.HueValues.HEX.Copy, TweenInfo.new( 0.8, Enum.EasingStyle.Exponential ), { ImageTransparency = 1 }):Play()
				for _,v in ipairs(colorpicker.color.Recent:GetChildren()) do
					if v:IsA('Frame') then
						TweenService:Create(v, TweenInfo.new( 0.6, Enum.EasingStyle.Exponential ), { BackgroundTransparency = 1 }):Play()
					end
				end
				task.wait(1)
				colorpicker.color.SVPicker.Visible = false
				colorpicker.color.Recent.Visible = false
				task.wait(0.7)
				DeBounce = false
			end

			colorpicker.QuickClose.MouseButton1Click:Connect(function()
				if DeBounce then return end
				if Open then
					Open = false
					ClosePicker()
				end
			end)

			local function AddRecentColor(newColor)
				local recentFrame = colorpicker.colorPlaceHolder:Clone()
				recentFrame.Visible = true
				recentFrame.Parent = colorpicker.color.Recent
				recentFrame.BackgroundColor3 = newColor

				recentFrame.interact.MouseButton1Click:Connect(function()
				--[[	TweenService:Create(recentFrame, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 5,0, 5) }):Play()
					task.wait(0.09)
					TweenService:Create(recentFrame, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 12,0, 12) }):Play() ]]

					local h, s, v = newColor:ToHSV()
					if s > 0.02 then
						HSV[1] = h
					end
					HSV[2] = s
					HSV[3] = v
					updatestuff()

				end)

				recentFrame.interact.MouseEnter:Connect(function()
					TweenService:Create(recentFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Size = UDim2.new(0, 20,0, 20) }):Play()
				end)

				recentFrame.interact.MouseLeave:Connect(function()
					TweenService:Create(recentFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Size = UDim2.new(0, 12,0, 12) }):Play()
				end)

				local maxRecentColors = 10
				local recentContainer = colorpicker.color.Recent

				local children = recentContainer:GetChildren()
				if #children > maxRecentColors then
					for _, child in ipairs(children) do
						if child:IsA("Frame") then
							child:Destroy()
							break
						end
					end
				end
			end

			local SV, HUE = nil, nil

			syde:AddConnection(SVPicker.InputBegan, function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					SV = RunService.RenderStepped:Connect(function()
						local mouse = game.Players.LocalPlayer:GetMouse()
						local ColorX = math.clamp(mouse.X - SVPicker.AbsolutePosition.X, 0, SVPicker.AbsoluteSize.X) / SVPicker.AbsoluteSize.X
						local ColorY = math.clamp(mouse.Y - SVPicker.AbsolutePosition.Y, 0, SVPicker.AbsoluteSize.Y) / SVPicker.AbsoluteSize.Y

						HSV[2] = ColorX
						HSV[3] = 1 - ColorY

						updatestuff()
					end)
				end
			end)

			syde:AddConnection(SVPicker.InputEnded, function(i)
				if i.UserInputType == Enum.UserInputType.MouseButton1 and SV then
					SV:Disconnect()
					SV = nil
					AddRecentColor(ColorPickerData.Color)
					SaveConfig()
				end
			end)

			syde:AddConnection(HUESlider.InputBegan, function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					HUE = RunService.RenderStepped:Connect(function()
						local mouse = game.Players.LocalPlayer:GetMouse()
						local ColorX = math.clamp(mouse.X - HUESlider.AbsolutePosition.X, 0, HUESlider.AbsoluteSize.X) / HUESlider.AbsoluteSize.X

						HSV[1] = 1 - ColorX

						updatestuff()
					end)
				end
			end)

			syde:AddConnection(HUESlider.InputEnded, function(i)
				if i.UserInputType == Enum.UserInputType.MouseButton1 and HUE then
					HUE:Disconnect()
					HUE = nil
					AddRecentColor(ColorPickerData.Color)
					SaveConfig()
				end
			end)

			colorpicker.HueValues.HEX.V.HEXBox.FocusLost:Connect(function(Enter)
				if not Enter then return end

				local hexInput = colorpicker.HueValues.HEX.V.HEXBox.Text

				local success, result = pcall(function()
					return Color3.fromHex(hexInput)
				end)

				if success then
					local Hue, Saturation, Value = result:ToHSV()
					colorpicker.HueValues.HEX.V.HEXBox.Text = ''
					if Saturation > 0.02 then
						HSV[1] = Hue
					end
					HSV[2] = Saturation
					HSV[3] = Value
					updatestuff()
				else
				end
			end)

			colorpicker.HueValues.RGB.V.RGBBox.FocusLost:Connect(function(Enter)
				if not Enter then return end

				local rgbInput = colorpicker.HueValues.RGB.V.RGBBox.Text

				local r, g, b = rgbInput:match("^(%d+),%s*(%d+),%s*(%d+)$")

				if r and g and b then

					r, g, b = tonumber(r), tonumber(g), tonumber(b)

					if r >= 0 and r <= 255 and g >= 0 and g <= 255 and b >= 0 and b <= 255 then
						local color = Color3.fromRGB(r, g, b)

						local Hue, Saturation, Value = color:ToHSV()
						if Saturation > 0.02 then
							HSV[1] = Hue
						end
						HSV[2] = Saturation
						HSV[3] = Value

						colorpicker.HueValues.RGB.V.RGBBox.Text = ''
						updatestuff()
					else
					end
				else
				end
			end)


			local linkDragging = false
			local originalPosition = UDim2.new(1, -10, 0.5, 0)
			local draggedColorPicker = nil

			local function isMouseOver(guiObject)
				local mouse = game.Players.LocalPlayer:GetMouse()
				local pos = guiObject.AbsolutePosition
				local size = guiObject.AbsoluteSize
				return mouse.X >= pos.X and mouse.X <= pos.X + size.X and mouse.Y >= pos.Y and mouse.Y <= pos.Y + size.Y
			end

			colorpicker.HueValues.HEX.Link.MouseButton1Down:Connect(function()
				linkDragging = true
				draggedColorPicker = colorpicker

				TweenService:Create(colorpicker.HueValues.HEX.Link, TweenInfo.new(0.5, Enum.EasingStyle.Exponential) , {ImageColor3 = Color3.fromRGB(255, 255, 255)}):Play()
				TweenService:Create(colorpicker.HueValues.HEX.Link, TweenInfo.new(0.5, Enum.EasingStyle.Exponential) , {Size = UDim2.new(0, 20,0, 20)}):Play()

				local followMouse
				followMouse = RunService.RenderStepped:Connect(function()
					if not linkDragging then
						followMouse:Disconnect()
						return
					end
					local mouse = game.Players.LocalPlayer:GetMouse()
					colorpicker.HueValues.HEX.Link.Position = UDim2.new(0, mouse.X - colorpicker.AbsolutePosition.X - 10, 0, mouse.Y - colorpicker.AbsolutePosition.Y - 100)

					for _, otherPicker in pairs(Page:GetChildren()) do
						if otherPicker:IsA("Frame") and otherPicker:FindFirstChild("isLinkable") and otherPicker.isLinkable.Value then
							if isMouseOver(otherPicker) and otherPicker ~= draggedColorPicker then
								TweenService:Create(otherPicker.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
							else
								TweenService:Create(otherPicker.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
							end
						end
					end
				end)
			end)

			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 and linkDragging then
					linkDragging = false
					local foundTarget = false

					for _, otherPicker in pairs(Page:GetChildren()) do
						if otherPicker:IsA("Frame") and otherPicker:FindFirstChild("isLinkable") and otherPicker.isLinkable.Value then
							if isMouseOver(otherPicker) and otherPicker ~= draggedColorPicker then
								otherPicker.HueSat.Value = draggedColorPicker.HueSat.Value
								updatestuff() 
								foundTarget = true
								TweenService:Create(
									colorpicker.HueValues.HEX.Link,
									TweenInfo.new(0.3, Enum.EasingStyle.Quint),
									{ Position = originalPosition }
								):Play()

								TweenService:Create(otherPicker.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
								TweenService:Create(colorpicker.HueValues.HEX.Link, TweenInfo.new(0.5, Enum.EasingStyle.Exponential) , {ImageColor3 = Color3.fromRGB(66, 66, 66)}):Play()
								TweenService:Create(colorpicker.HueValues.HEX.Link, TweenInfo.new(0.5, Enum.EasingStyle.Exponential) , {Size = UDim2.new(0, 15,0, 15)}):Play()
								break
							end
						end
					end

					if not foundTarget then
						TweenService:Create(colorpicker.HueValues.HEX.Link, TweenInfo.new(0.5, Enum.EasingStyle.Exponential) , {ImageColor3 = Color3.fromRGB(66, 66, 66)}):Play()
						TweenService:Create(colorpicker.HueValues.HEX.Link, TweenInfo.new(0.5, Enum.EasingStyle.Exponential) , {Size = UDim2.new(0, 15,0, 15)}):Play()
						TweenService:Create(
							colorpicker.HueValues.HEX.Link,
							TweenInfo.new(0.3, Enum.EasingStyle.Quint),
							{ Position = originalPosition }
						):Play()
					end
				end
			end)

			local function updateColorPicker()
				local Hue, Saturation, Value = HueSat.Value:ToHSV()

				if Saturation > 0.02 then
					HSV[1] = Hue
				end
				HSV[2] = Saturation
				HSV[3] = Value

				updatestuff()
			end

			HueSat.Changed:Connect(updateColorPicker)

			local hueIncrement = 0.005 

			local function RainbowEffect()
				HueValue = (HueValue + hueIncrement) % 1
				HSV[1] = HueValue

				updatestuff()
			end

			local isRainbowEnabled = false
			local huerender = nil

			local function ToggleRainbowEffect()
				isRainbowEnabled = not isRainbowEnabled
				if isRainbowEnabled then
					if not huerender then
						huerender = RunService.RenderStepped:Connect(RainbowEffect)
						TweenService:Create(colorpicker.color.Values.Rainbow, TweenInfo.new(0.5, Enum.EasingStyle.Exponential ), {ImageColor3 = Color3.fromRGB(255, 255, 255)}):Play()
					end
				else
					if huerender then
						huerender:Disconnect()
						TweenService:Create(colorpicker.color.Values.Rainbow, TweenInfo.new(0.5, Enum.EasingStyle.Exponential ), {ImageColor3 = Color3.fromRGB(62, 62, 62)}):Play()
						huerender = nil
					end
				end
			end

			function ColorPickerData:Set(RGBColor)
				ColorPickerData.Color = RGBColor
				local h, s, v = RGBColor:ToHSV()
				HSV[1], HSV[2], HSV[3] = h, s, v
				updatestuff()
				SaveConfig()
			end

			if syde.ConfigEnabled then
				if ColorPickerData.Flag then
					syde.Flags[ColorPickerData.Flag] = ColorPickerData
				end
			end

			colorpicker.color.Values.Rainbow.MouseButton1Click:Connect(ToggleRainbowEffect)

			return ColorPickerData

		end

		function InitElement:Keybind(Keybind)
			local KeybindData = {
				Title = Keybind.Title;
				Key = Keybind.Key;
				Desc = Keybind.Description or "";
				CallBack = Keybind.CallBack;
				WaitingForKey = false;
				Hold = false;
				Holding = false
			}

			local KeyBind = PAGES.Page.KeyBind:Clone()
			KeyBind.Visible = true
			KeyBind.Parent = Page
			KeyBind.Title.Text = KeybindData.Title
			KeyBind.Name = KeybindData.Title

			KeyBind.Bind.v.Text = KeybindData.Key and KeybindData.Key.Name or "NONE"
			TweenService:Create(KeyBind.Bind, TweenInfo.new(0.55, Enum.EasingStyle.Quint ), {Size = UDim2.new(0, KeyBind.Bind.v.TextBounds.X + 15, 0, KeyBind.Bind.Size.Y.Offset)}):Play()

			KeyBind.interact.MouseButton1Click:Connect(function()
				KeyBind.Bind.v.Text = '...'
				KeybindData.WaitingForKey = true
			end)

			KeyBind.Bind.v:GetPropertyChangedSignal('TextBounds'):Connect(function()
				TweenService:Create(KeyBind.Bind, TweenInfo.new(0.55, Enum.EasingStyle.Quint ), {Size = UDim2.new(0, KeyBind.Bind.v.TextBounds.X + 15, 0, KeyBind.Bind.Size.Y.Offset)}):Play()
			end)

			local function SetKeybind(keyCode)
				if keyCode and keyCode ~= Enum.KeyCode.Unknown then
					KeybindData.Key = keyCode
					KeyBind.Bind.v.Text = keyCode.Name
				else
					KeybindData.Key = nil
					KeyBind.Bind.v.Text = "NONE"
				end
			end

			-- Main input handler
			syde:AddConnection(UserInputService.InputBegan, function(input)
				if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

				if KeybindData.WaitingForKey then
					KeybindData.WaitingForKey = false
					SetKeybind(input.KeyCode)
					return
				end

				if input.KeyCode == KeybindData.Key then
					KeybindData.Hold = true

					local holdConnection
					holdConnection = input.Changed:Connect(function(prop)
						if prop == "UserInputState" then
							local state = input.UserInputState
							KeybindData.Hold = (state == Enum.UserInputState.Begin)
							if state == Enum.UserInputState.End and holdConnection then
								holdConnection:Disconnect()
							end
						end
					end)

					local success, result = pcall(KeybindData.CallBack)
					if not KeybindData.Holding then
						if not success then
						end
					else
						if KeybindData.Hold then
							local holdLoop
							holdLoop = RunService.RenderStepped:Connect(function()
								if not KeybindData.Hold then
									KeybindData.CallBack(false)
									holdLoop:Disconnect()
								else
									KeybindData.CallBack(false)
								end
							end)
						end
					end
				end
			end)

		end

		function InitElement:Img(Img)
			local imgData = {
				img = Img.Image
			}

			local ImageBlock = PAGES.Page.img:Clone()
			ImageBlock.Visible = true
			ImageBlock.Parent = Page
			ImageBlock.ImageLabel.Image = 'rbxassetid://'..imgData.img

		end

		function InitElement:Label(Text, Alignment)

			local Label = PAGES.Page.Label:Clone()
			Label.Visible = true
			Label.Parent = Page
			Label.Text.Text = Text

			if Alignment == 'Center' then
				Label.Text.TextXAlignment = Enum.TextXAlignment.Center
			elseif Alignment == 'Right' then
				Label.Text.TextXAlignment = Enum.TextXAlignment.Right
			end
			
			local labelSettings = {}
			
			function labelSettings:Set(text)
				Label.Text.Text = text
			end
			
			return labelSettings
			
		end

		function InitElement:Paragraph(Paragraph)
			local ParaData = {
				Title = Paragraph.Title;
				Content = Paragraph.Content;
			}

			local Para = PAGES.Page.Paragraph:Clone()
			Para.Visible = true
			Para.Parent = Page
			Para.Title.Text = ParaData.Title
			Para.Content.Text = ParaData.Content

			Para.Content.Size = UDim2.new(1, -20, 0, Para.Content.TextBounds.Y)
			Para.Size = UDim2.new(1, -15, 0, Para.Content.Size.Y.Offset + 45)

			local function updateSize()
				local textSize = TextService:GetTextSize(
					Para.Content.Text,
					Para.Content.TextSize,
					Para.Content.Font,
					Vector2.new(Para.Content.AbsoluteSize.X, math.huge) -- Allows vertical expansion
				)

				local newDescSize = UDim2.new(1, -20, 0, textSize.Y)
				local newButtonSize = UDim2.new(Para.Size.X.Scale, Para.Size.X.Offset, 0, textSize.Y + 40) -- Adding extra padding

				local descTween = TweenService:Create(Para.Content, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = newDescSize })
				descTween:Play()

				local buttonTween = TweenService:Create(Para, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = newButtonSize })
				buttonTween:Play()
			end

			updateSize()

			Para.Content:GetPropertyChangedSignal("TextBounds"):Connect(updateSize)
			
			local ParagraphSettings = {}

			function ParagraphSettings:Set(title, text)
				Para.Title.Text = title
				Para.Content.Text = text
			end

			ParagraphSettings.Instance = Para

			return ParagraphSettings
		end
		

		function InitElement:EnchancedView(View)
			local Viewdata = {
				Title = View.Title or "3D View",
				Object = View.Object,
				UserRotate = View.UserRotate or false,
				AutoRotate = View.AutoRotate ~= false -- default true
			}

			local EnchancedView = PAGES.Page["3DView"]:Clone()
			EnchancedView.Visible = true
			EnchancedView.Parent = Page
			EnchancedView.Title.Text = Viewdata.Title

			local Viewport = EnchancedView.ViewFrame.ViewportFrame
			local Camera = Instance.new("Camera")
			Camera.Parent = Viewport
			Viewport.CurrentCamera = Camera

			-- Clone the object
			local ObjectClone = Viewdata.Object:Clone()
			ObjectClone.Parent = Viewport

			-- Center object
			-- Center object properly so pivot is in the middle from the start
			if ObjectClone:IsA("Model") then
				ObjectClone:PivotTo(CFrame.new(0, 0, 0))
			else
				ObjectClone.CFrame = CFrame.new(0, 0, 0)
			end

			-- Anchor parts
			if ObjectClone:IsA("BasePart") then
				ObjectClone.Anchored = true
			elseif ObjectClone:IsA("Model") then
				for _, part in ipairs(ObjectClone:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Anchored = true
					end
				end
			end

			if Viewdata.UserRotate == false then
				TweenService:Create(EnchancedView.ViewFrame.ImageLabel, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {
					ImageTransparency = 1
				}):Play()
			end

			-- Determine center & size
			local primaryPart
			local size
			local center

			if ObjectClone:IsA("BasePart") then
				size = ObjectClone.Size
				ObjectClone.CFrame = CFrame.new(0, 0, 0)

			elseif ObjectClone:IsA("Model") then
				-- Get bounding box center and size
				local cf, boundsSize = ObjectClone:GetBoundingBox()
				size = boundsSize

				-- Move model so its center is at (0,0,0)
				ObjectClone:PivotTo(CFrame.new(0, 0, 0))

				-- Ensure Roblox finishes recalculating bounds after clone
				task.defer(function()
					ObjectClone:PivotTo(CFrame.new(0, 0, 0))
				end)
			end


			-- Camera distance based on size
			local maxDimension = math.max(size.X, size.Y, size.Z)
			local distance = maxDimension * 2
			Camera.CFrame = CFrame.new(Vector3.new(0, 0, distance), Vector3.new(0, 0, 0))

			-- Icon Rotation state
			local icon = EnchancedView.ViewFrame.ImageLabel


			-- Rotation state
			local targetRotationX, targetRotationY = 0, 0
			local currentRotationX, currentRotationY = 0, 0

			local dragging = false
			local dragStartPos
			local lastPos

			task.spawn(function()
				while EnchancedView.Parent do
					currentRotationX += (targetRotationX - currentRotationX) * 0.15
					currentRotationY += (targetRotationY - currentRotationY) * 0.15

					local rotationCFrame = CFrame.Angles(currentRotationX, currentRotationY, 0)
					if ObjectClone:IsA("Model") then
						ObjectClone:PivotTo(rotationCFrame)
					else
						ObjectClone.CFrame = rotationCFrame
					end
					task.wait(0.016)
				end
			end)

			-- Auto rotate (horizontal only so it looks natural)
			if Viewdata.AutoRotate then
				task.spawn(function()
					while EnchancedView.Parent do
						if not Viewdata.UserRotate or not dragging then
							targetRotationY = targetRotationY + math.rad(0.5)

						end
						task.wait(0.01)
					end
				end)
			end


			if Viewdata.UserRotate == true then
				Viewport.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						dragging = true
						lastPos = input.Position
						dragStartPos = input.Position -- store where drag started

						TweenService:Create(icon, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {
							ImageColor3 = Color3.fromRGB(255, 255, 255)
						}):Play()
					end
				end)

				Viewport.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						dragging = false
						TweenService:Create(icon, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {
							ImageColor3 = Color3.fromRGB(30, 30, 30)
						}):Play()
					end
				end)

				Viewport.InputChanged:Connect(function(input)
					if dragging and input.UserInputType == Enum.UserInputType.MouseMovement  then
						local delta = input.Position - lastPos

						-- Apply rotation
						targetRotationY = targetRotationY + delta.X * 0.005
						targetRotationX = math.clamp(targetRotationX - delta.Y * 0.005, -math.pi/2, math.pi/2)


						lastPos = input.Position
					end
				end)
			end


			-- === Zoom + Elastic Scroll (virtual vs visual) ===
			local ZoomFrame   = EnchancedView.ViewFrame.Zoom
			local ClipFrame   = ZoomFrame.clipframe
			local ScrollFrame = ClipFrame.scroll
			local ZoomAmountLabel = ZoomFrame.Frame.ZoomAmount -- << change to your label path

			-- Zoom range (studs)
			local minZoomDistance = maxDimension * 0.5
			local maxZoomDistance = maxDimension * 10

			-- Elastic settings
			local elasticity   = 0.4      -- visual resistance (0..1)
			local maxOverdrag  = 50       -- px visual overdrag cap
			local tweenInfo    = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

			-- Limits (top is 0, bottom is negative if scroll is taller than clip)
			local function getScrollLimits()
				local minY = 0
				local diff = ScrollFrame.AbsoluteSize.Y - ClipFrame.AbsoluteSize.Y
				local maxY = diff > 0 and -diff or 0
				return minY, maxY
			end

			-- Map Y -> zoom (defensive if no range)
			local function yToZoom(y)
				local minY, maxY = getScrollLimits()
				if minY == maxY then
					return minZoomDistance
				end
				local t = (y - minY) / (maxY - minY) -- 0..1
				return minZoomDistance + (maxZoomDistance - minZoomDistance) * t
			end

			local function updateZoom(distance)
				distance = math.clamp(distance, minZoomDistance, maxZoomDistance)
				Camera.CFrame = CFrame.new(Vector3.new(0, 0, distance), Vector3.new(0, 0, 0))
				if ZoomAmountLabel then
					TweenService:Create(ZoomAmountLabel, TweenInfo.new(0.8, Enum.EasingStyle.Elastic), {Position = UDim2.new(1, 0,0.5, -20)}):Play()
					task.wait(0.045)
					ZoomAmountLabel.Text = 'x'..string.format("%.2f", distance)
					ZoomAmountLabel.Position = UDim2.new(1, 0,0.5, 20)
					TweenService:Create(ZoomAmountLabel, TweenInfo.new(0.8, Enum.EasingStyle.Elastic), {Position = UDim2.new(1, 0,0.5, 0)}):Play()
				end
			end



			local function visualYFromVirtualY(vy)
				local minY, maxY = getScrollLimits()
				if vy > minY then
					local over = vy - minY
					return math.min(minY + over * elasticity, minY + maxOverdrag)
				elseif vy < maxY then
					local over = vy - maxY -- negative
					return math.max(maxY + over * elasticity, maxY - maxOverdrag)
				else
					return vy
				end
			end

			-- State
			local dragging   = false
			local lastPos
			local virtualY   = 0 

			-- Initialize virtual to current
			virtualY = ScrollFrame.Position.Y.Offset

			local initialZoom = 20
			updateZoom(initialZoom)

			-- Sync scroll position with initial zoom
			local minY, maxY = getScrollLimits()
			local t = (initialZoom - minZoomDistance) / (maxZoomDistance - minZoomDistance)
			local startY = minY + (maxY - minY) * t
			virtualY = startY
			ScrollFrame.Position = UDim2.new(ScrollFrame.Position.X.Scale, ScrollFrame.Position.X.Offset, 0, startY)

			if ZoomAmountLabel then
				ZoomAmountLabel.Text = string.format("%.2f", distance)
			end

			ZoomFrame.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					dragging = true
					lastPos = input.Position
				end
			end)

			ZoomFrame.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					dragging = false

					-- Clamp virtual to limits and snap visually
					local minY, maxY = getScrollLimits()
					virtualY = math.clamp(virtualY, maxY, minY)

					game:GetService("TweenService"):Create(
						ScrollFrame,
						tweenInfo,
						{ Position = UDim2.new(ScrollFrame.Position.X.Scale, ScrollFrame.Position.X.Offset, 0, virtualY) }
					):Play()

					-- Keep zoom in sync with the snapped position
					local distance = yToZoom(virtualY)
					updateZoom(distance)
				end
			end)

			ZoomFrame.InputChanged:Connect(function(input)
				if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
					local deltaY = input.Position.Y - lastPos.Y
					lastPos = input.Position

					-- 1) Update virtual Y with full delta (no elasticity here)
					virtualY = virtualY + deltaY

					-- 2) Visual Y with elasticity (so it rubber-bands)
					local visualY = visualYFromVirtualY(virtualY)
					ScrollFrame.Position = UDim2.new(ScrollFrame.Position.X.Scale, ScrollFrame.Position.X.Offset, 0, visualY)

					-- 3) Zoom uses CLAMPED virtual Y (so overdrag doesn't affect zoom)
					local minY, maxY = getScrollLimits()
					local clampedY = math.clamp(virtualY, maxY, minY)
					local distance = yToZoom(clampedY)
					updateZoom(distance)
				end
			end)

		end

		function InitElement:Rate(Rate)
			local RateData = {
				Title = Rate.Title;
				WebHook = Rate.WebHook;
			}

			local RateBlock = PAGES.Page.Rate:Clone()
			RateBlock.Visible = true
			RateBlock.Parent = Page
			RateBlock.Title.Text = RateData.Title

			local starsFrame = RateBlock.stars
			local stars = {}

			for i = 1, 5 do
				table.insert(stars, starsFrame:FindFirstChild(i))
			end

			local function highlightStars(hoveredIndex, litCount)
				for i, star in ipairs(stars) do
					if i <= litCount then
						TweenService:Create(star, TweenInfo.new(0.43, Enum.EasingStyle.Exponential), {ImageColor3 = Color3.fromRGB(255, 255, 0)}):Play()
						TweenService:Create(star.glow, TweenInfo.new(0.43, Enum.EasingStyle.Exponential), {ImageTransparency = 0.7}):Play()
					else
						TweenService:Create(star, TweenInfo.new(0.43, Enum.EasingStyle.Exponential), {ImageColor3 = Color3.fromRGB(25, 25, 25)}):Play()
						TweenService:Create(star.glow, TweenInfo.new(0.43, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
					end

					-- Scale only the hovered star
					if i == hoveredIndex then
						TweenService:Create(star.UIScale, TweenInfo.new(0.43, Enum.EasingStyle.Exponential), {Scale = 1.2}):Play()
					else
						TweenService:Create(star.UIScale, TweenInfo.new(0.43, Enum.EasingStyle.Exponential), {Scale = 1}):Play()
					end
				end
			end

			local selected = 0

			for i, star in ipairs(stars) do
				star.MouseEnter:Connect(function()
					highlightStars(i, i)
				end)

				star.MouseLeave:Connect(function()
					highlightStars(0, selected ~= 0 and selected or 0)
				end)

				star.MouseButton1Click:Connect(function()
					selected = i
					TweenService:Create(star.glow.UIScale, TweenInfo.new(0.55, Enum.EasingStyle.Exponential), {Scale = 1.3}):Play()
					task.wait(0.35)
					TweenService:Create(star.glow.UIScale, TweenInfo.new(0.55, Enum.EasingStyle.Exponential), {Scale = 1}):Play()
				end)
			end

		end

		function syde:LoadSaveConfig()
			local notified = false
			local loaded = false

			if syde.ConfigEnabled then
				local success, result = pcall(function()
					local filePath = string.format("%s/%s.lua", syde.ConfigFolder, syde.ConfigFile)
					if isfile and isfile(filePath) then
						loaded = LoadConfig(readfile(filePath))
					end
				end)

				if success then

				elseif not success then
				end
			end
		end

		return InitElement

	end

	return ldata

end


--═══════════════════════════════════════════════════════════════
--	LOADING CIRCLE USAGE / API

-- to use its like getgenv().ShowWheel(true) false or a number like how much it stay
-- or use ShowWheel. idk lol.

-- to use:
-- getgenv().ShowWheel(true)
-- getgenv().ShowWheel(false)
-- getgenv().ShowWheel(1) -- duration in seconds

--═══════════════════════════════════════════════════════════════

do
local Config = {
    Wheel = {
        Size = UDim2.new(0.08, 0, 0.08, 0),
        Color = Color3.fromRGB(255, 255, 255),
        RotationSpeed = 350,
        Image = "http://www.roblox.com/asset/?id=5689992454"
    },
    Animation = {
        ShowDuration = 0.5,
        ShowEasing = Enum.EasingStyle.Back,
        HideDuration = 0.4,
        HideEasing = Enum.EasingStyle.Back,
        TransparencyDuration = 0.4
    },
    Overlay = {
        Enabled = true,
        Color = Color3.fromRGB(0, 0, 0),
        Transparency = 0.8
    }
}

if getgenv().WheelAPI and getgenv().WheelAPI.Destroy then
    pcall(getgenv().WheelAPI.Destroy)
end
if shared.WheelAPI and shared.WheelAPI.Destroy then
    pcall(shared.WheelAPI.Destroy)
end

for _, v in pairs(CoreGuiF:GetChildren()) do
    if v:IsA("ScreenGui") and v:FindFirstChild("LoadingWheel") then
        pcall(v.Destroy, v)
    end
end

local gui = Instance.new("ScreenGui")
gui.Name = "LoadingWheel"
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
gui.ResetOnSpawn = false
gui.DisplayOrder = math.huge
gui.IgnoreGuiInset = true

if syn and syn.protect_gui then
    syn.protect_gui(gui)
elseif protectgui then
    protectgui(gui)
end
gui.Parent = CoreGuiF

local overlay = Instance.new("Frame")
overlay.Name = "LoadingWheel"
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Config.Overlay.Color
overlay.BackgroundTransparency = 1
overlay.BorderSizePixel = 0
overlay.ZIndex = math.huge
overlay.Parent = gui

local wheel = Instance.new("ImageLabel")
wheel.Name = "LoadingWheel"
wheel.Size = UDim2.new(0, 0, 0, 0)
wheel.Position = UDim2.new(0.5, 0, 0.5, 0)
wheel.AnchorPoint = Vector2.new(0.5, 0.5)
wheel.BackgroundTransparency = 1
wheel.BorderSizePixel = 0
wheel.Image = Config.Wheel.Image
wheel.ImageColor3 = Config.Wheel.Color
wheel.ImageTransparency = 1
wheel.ScaleType = Enum.ScaleType.Stretch
wheel.ZIndex = 2
wheel.Parent = gui

local ratio = Instance.new("UIAspectRatioConstraint")
ratio.AspectRatio = 1
ratio.Parent = wheel

local state = {
    active = true,
    showing = false,
    queued = nil,
    tweens = {}
}

local conn = RunService.RenderStepped:Connect(function(dt)
    if state.active then
        wheel.Rotation = wheel.Rotation + (Config.Wheel.RotationSpeed * dt)
    end
end)

local function clear()
    for _, t in pairs(state.tweens) do
        if t and t.PlaybackState == Enum.PlaybackState.Playing then
            pcall(t.Cancel, t)
        end
    end
    state.tweens = {}
end

local function show()
    if state.showing then return end
    state.showing = true
    state.queued = nil
    clear()
    
    if Config.Overlay.Enabled then
        local t = TweenService:Create(overlay, TweenInfo.new(Config.Animation.TransparencyDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {BackgroundTransparency = Config.Overlay.Transparency})
        table.insert(state.tweens, t)
        t:Play()
    end
    
    local t1 = TweenService:Create(wheel, TweenInfo.new(Config.Animation.ShowDuration, Config.Animation.ShowEasing, Enum.EasingDirection.Out), {Size = Config.Wheel.Size})
    local t2 = TweenService:Create(wheel, TweenInfo.new(Config.Animation.TransparencyDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {ImageTransparency = 0})
    
    table.insert(state.tweens, t1)
    table.insert(state.tweens, t2)
    t1:Play()
    t2:Play()
end

local function hide(cb)
    if not state.showing then 
        if cb then cb() end
        return 
    end
    state.showing = false
    state.queued = nil
    clear()
    
    if Config.Overlay.Enabled then
        local t = TweenService:Create(overlay, TweenInfo.new(Config.Animation.TransparencyDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {BackgroundTransparency = 1})
        table.insert(state.tweens, t)
        t:Play()
    end
    
    local t1 = TweenService:Create(wheel, TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {ImageTransparency = 1})
    local t2 = TweenService:Create(wheel, TweenInfo.new(Config.Animation.HideDuration, Config.Animation.HideEasing, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)})
    
    table.insert(state.tweens, t1)
    table.insert(state.tweens, t2)
    t1:Play()
    
    t1.Completed:Connect(function()
        t2:Play()
        if cb then
            t2.Completed:Connect(cb)
        end
    end)
end
