--!nocheck
--!nolint UnknownGlobal
--!nolint DeprecatedGlobal
--!nolint BuiltinGlobalWrite
--!optimize 2

local Games = {
    {
        Name = "Greenville",
        GameIds = { 371263894 },
        PlaceIds = { 891852901 },
        Loader = "https://api.luarmor.net/files/v4/loaders/0b96c0de7e8100d6b4e9eba9ba431e05.lua",
    },
    {
        Name = "Rensselaer County",
        GameIds = { 1525626450 },
        PlaceIds = { 4637668954 },
        Loader = "https://api.luarmor.net/files/v4/loaders/4001d0f7e1e434b1190cfd6788b4026d.lua",
    },
}

if not game:IsLoaded() then game.Loaded:Wait() end

local GlobalEnv = getgenv and getgenv() or _G
local MessageBox = messagebox or messageboxasync
local IconError, IconInfo = 0x10, 0x40

local function Notify(Text, Flags)
    if type(MessageBox) == "function" and pcall(MessageBox, Text, "Nexus", Flags or IconInfo) then return end
    warn(Text)
end

local function FindGame()
    for _, Entry in next, Games do
        if table.find(Entry.GameIds, game.GameId) or table.find(Entry.PlaceIds, game.PlaceId) then return Entry end
    end
    return nil
end

local Entry = FindGame()
if not Entry then
    local Names = {}
    for Index, Supported in next, Games do Names[Index] = Supported.Name end
    Notify(`This game is not supported.\nSupported games: {table.concat(Names, ", ")}`, IconError)
    return
end

if script_key ~= nil then GlobalEnv.script_key = script_key end

local Ok, Source = pcall(game.HttpGet, game, Entry.Loader)
if not Ok or type(Source) ~= "string" or Source == "" then
    Notify(`Could not reach the {Entry.Name} loader, try again`, IconError)
    return
end

local Chunk, CompileError = loadstring(Source)
if not Chunk then
    warn(CompileError)
    Notify(`The {Entry.Name} loader failed to load, try again`, IconError)
    return
end

task.spawn(Notify, `Loading {Entry.Name}...`, IconInfo)
Chunk()
