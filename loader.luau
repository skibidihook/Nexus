local GAME_IDS = {
    TAXI_BOSS = 7305309231,
    BUILD_A_CAR = 88728793053496,
}
local SCRIPT_URL = {
    [GAME_IDS.TAXI_BOSS] = 'https://api.luarmor.net/files/v3/loaders/f8306c717a2437ae14bf86eaac7f337d.lua', -- Taxi Boss
    [GAME_IDS.BUILD_A_CAR] = 'https://api.luarmor.net/files/v3/loaders/1ee7125061fdbea9f196b7277ff05a30.lua', -- Build A Car
}

local thisGame = nil
for _, id in pairs(GAME_IDS) do
    if game.PlaceId == id then
        thisGame = id
        break
    end
end
if not thisGame then
    warn('Nexus: Only for Taxi Boss or Build A Car.')
    return
end

local G2L = {}

G2L['1'] = Instance.new(
    'ScreenGui',
    game:GetService('Players').LocalPlayer:WaitForChild('PlayerGui')
)
G2L['1']['ZIndexBehavior'] = Enum.ZIndexBehavior.Sibling
G2L['1'].Name = 'NexusFreemiumKeyUI'

G2L['2'] = Instance.new('Frame', G2L['1'])
G2L['2']['BackgroundColor3'] = Color3.fromRGB(255, 255, 255)
G2L['2']['Size'] = UDim2.new(0, 443, 0, 240)
G2L['2']['Position'] = UDim2.new(0.30245, 0, 0.35427, 0)
G2L['2']['BorderColor3'] = Color3.fromRGB(0, 0, 0)
G2L['2']['Name'] = 'main'
G2L['2']['SelectionGroup'] = true

G2L['3'] = Instance.new('UIGradient', G2L['2'])
G2L['3']['Rotation'] = -90
G2L['3']['Name'] = 'UIToolsGradient'
G2L['3']['Color'] = ColorSequence.new({
    ColorSequenceKeypoint.new(0.000, Color3.fromRGB(23, 64, 125)),
    ColorSequenceKeypoint.new(0.054, Color3.fromRGB(24, 51, 90)),
    ColorSequenceKeypoint.new(0.631, Color3.fromRGB(27, 34, 44)),
    ColorSequenceKeypoint.new(1.000, Color3.fromRGB(28, 29, 30)),
})

G2L['4'] = Instance.new('UICorner', G2L['2'])

G2L['5'] = Instance.new('Frame', G2L['2'])
G2L['5']['BorderSizePixel'] = 10
G2L['5']['BackgroundColor3'] = Color3.fromRGB(255, 255, 255)
G2L['5']['Size'] = UDim2.new(0, 375, 0, 54)
G2L['5']['Position'] = UDim2.new(0.07595, 0, 0.64182, 0)
G2L['5']['BorderColor3'] = Color3.fromRGB(41, 41, 41)
G2L['5']['Name'] = 'button'

G2L['6'] = Instance.new('TextLabel', G2L['5'])
G2L['6']['BorderSizePixel'] = 8
G2L['6']['TextSize'] = 22
G2L['6']['TextStrokeColor3'] = Color3.fromRGB(255, 255, 255)
G2L['6']['BackgroundColor3'] = Color3.fromRGB(255, 255, 255)
G2L['6']['FontFace'] = Font.new(
    [[rbxasset://fonts/families/HighwayGothic.json]],
    Enum.FontWeight.SemiBold,
    Enum.FontStyle.Normal
)
G2L['6']['TextColor3'] = Color3.fromRGB(255, 255, 255)
G2L['6']['BackgroundTransparency'] = 1
G2L['6']['RichText'] = true
G2L['6']['Size'] = UDim2.new(0, 200, 0, 50)
G2L['6']['BorderColor3'] = Color3.fromRGB(0, 0, 0)
G2L['6']['Text'] = 'Discord'
G2L['6']['Position'] = UDim2.new(-0.13067, 0, -0.16667, 0)

G2L['7'] = Instance.new('TextLabel', G2L['6'])
G2L['7']['TextWrapped'] = true
G2L['7']['BorderSizePixel'] = 6
G2L['7']['TextSize'] = 10
G2L['7']['TextXAlignment'] = Enum.TextXAlignment.Left
G2L['7']['TextTransparency'] = 0.4
G2L['7']['TextStrokeColor3'] = Color3.fromRGB(255, 255, 255)
G2L['7']['BackgroundColor3'] = Color3.fromRGB(255, 255, 255)
G2L['7']['TextDirection'] = Enum.TextDirection.RightToLeft
G2L['7']['FontFace'] = Font.new(
    [[rbxasset://fonts/families/Arial.json]],
    Enum.FontWeight.Bold,
    Enum.FontStyle.Normal
)
G2L['7']['TextColor3'] = Color3.fromRGB(255, 255, 255)
G2L['7']['BackgroundTransparency'] = 1
G2L['7']['RichText'] = true
G2L['7']['Size'] = UDim2.new(0, 158, 0, 60)
G2L['7']['BorderColor3'] = Color3.fromRGB(0, 0, 0)
G2L['7']['Text'] = 'Tap to join discord server for news and updates!'
G2L['7']['Position'] = UDim2.new(0.333, 0, 0.33333, 0)

G2L['8'] = Instance.new('UICorner', G2L['5'])
G2L['8']['CornerRadius'] = UDim.new(0, 6)

G2L['9'] = Instance.new('UIGradient', G2L['5'])
G2L['9']['Rotation'] = -22
G2L['9']['Color'] = ColorSequence.new({
    ColorSequenceKeypoint.new(0.000, Color3.fromRGB(44, 85, 161)),
    ColorSequenceKeypoint.new(0.439, Color3.fromRGB(25, 34, 52)),
    ColorSequenceKeypoint.new(1.000, Color3.fromRGB(22, 24, 29)),
})

G2L['a'] = Instance.new('TextButton', G2L['5'])
G2L['a']['BorderSizePixel'] = 0
G2L['a']['TextSize'] = 14
G2L['a']['TextColor3'] = Color3.fromRGB(0, 0, 0)
G2L['a']['BackgroundColor3'] = Color3.fromRGB(255, 63, 63)
G2L['a']['FontFace'] = Font.new(
    [[rbxasset://fonts/families/SourceSansPro.json]],
    Enum.FontWeight.Regular,
    Enum.FontStyle.Normal
)
G2L['a']['BackgroundTransparency'] = 1
G2L['a']['Size'] = UDim2.new(0, 375, 0, 50)
G2L['a']['BorderColor3'] = Color3.fromRGB(0, 0, 0)
G2L['a']['Text'] = ''
G2L['a']['Name'] = 'discord_button'
G2L['a']['Position'] = UDim2.new(0, 0, 0.03704, 0)

G2L['b'] = Instance.new('Frame', G2L['2'])
G2L['b']['BorderSizePixel'] = 0
G2L['b']['BackgroundColor3'] = Color3.fromRGB(41, 41, 41)
G2L['b']['Size'] = UDim2.new(0, 385, 0, 49)
G2L['b']['Position'] = UDim2.new(0.06123, 0, 0.31586, 0)
G2L['b']['BorderColor3'] = Color3.fromRGB(0, 0, 0)
G2L['b']['Name'] = 'backdrrop'

G2L['c'] = Instance.new('UICorner', G2L['b'])
G2L['c']['CornerRadius'] = UDim.new(0, 4)

G2L['d'] = Instance.new('TextLabel', G2L['2'])
G2L['d']['TextWrapped'] = true
G2L['d']['BorderSizePixel'] = 0
G2L['d']['TextSize'] = 24
G2L['d']['BackgroundColor3'] = Color3.fromRGB(255, 255, 255)
G2L['d']['FontFace'] = Font.new(
    [[rbxasset://fonts/families/HighwayGothic.json]],
    Enum.FontWeight.Bold,
    Enum.FontStyle.Normal
)
G2L['d']['TextColor3'] = Color3.fromRGB(255, 255, 255)
G2L['d']['BackgroundTransparency'] = 1
G2L['d']['Size'] = UDim2.new(0, 253, 0, 50)
G2L['d']['BorderColor3'] = Color3.fromRGB(0, 0, 0)
G2L['d']['Text'] = 'Nexus Freemium'
G2L['d']['Position'] = UDim2.new(-0.03386, 0, -0.00417, 0)

G2L['e'] = Instance.new('TextLabel', G2L['d'])
G2L['e']['TextWrapped'] = true
G2L['e']['BorderSizePixel'] = 0
G2L['e']['TextSize'] = 14
G2L['e']['TextXAlignment'] = Enum.TextXAlignment.Left
G2L['e']['TextStrokeColor3'] = Color3.fromRGB(255, 255, 255)
G2L['e']['BackgroundColor3'] = Color3.fromRGB(255, 255, 255)
G2L['e']['FontFace'] = Font.new(
    [[rbxasset://fonts/families/SourceSansPro.json]],
    Enum.FontWeight.Regular,
    Enum.FontStyle.Normal
)
G2L['e']['TextColor3'] = Color3.fromRGB(97, 97, 97)
G2L['e']['BackgroundTransparency'] = 1
G2L['e']['RichText'] = true
G2L['e']['Size'] = UDim2.new(0, 328, 0, 50)
G2L['e']['BorderColor3'] = Color3.fromRGB(0, 0, 0)
G2L['e']['Text'] =
    'The key link has been copied, if not                            to copy.'
G2L['e']['Position'] = UDim2.new(0.18914, 0, 0.52, 0)

G2L['f'] = Instance.new('TextLabel', G2L['e'])
G2L['f']['BorderSizePixel'] = 0
G2L['f']['TextSize'] = 14
G2L['f']['BackgroundColor3'] = Color3.fromRGB(255, 255, 255)
G2L['f']['FontFace'] = Font.new(
    [[rbxasset://fonts/families/SourceSansPro.json]],
    Enum.FontWeight.Regular,
    Enum.FontStyle.Normal
)
G2L['f']['TextColor3'] = Color3.fromRGB(255, 255, 255)
G2L['f']['BackgroundTransparency'] = 1
G2L['f']['Size'] = UDim2.new(0, 194, 0, 50)
G2L['f']['BorderColor3'] = Color3.fromRGB(0, 0, 0)
G2L['f']['Text'] = 'click here'
G2L['f']['Position'] = UDim2.new(0.32402, 0, 0.017, -1)
G2L['f'].Name = 'CopyKeyLabel'

G2L['10'] = Instance.new('UIGradient', G2L['f'])
G2L['10']['Name'] = 'UIToolsGradient'
G2L['10']['Color'] = ColorSequence.new({
    ColorSequenceKeypoint.new(0.000, Color3.fromRGB(86, 0, 128)),
    ColorSequenceKeypoint.new(0.647, Color3.fromRGB(86, 79, 128)),
    ColorSequenceKeypoint.new(1.000, Color3.fromRGB(86, 86, 128)),
})

G2L['11'] = Instance.new('TextLabel', G2L['d'])
G2L['11']['TextWrapped'] = true
G2L['11']['BorderSizePixel'] = 0
G2L['11']['TextSize'] = 14
G2L['11']['TextXAlignment'] = Enum.TextXAlignment.Left
G2L['11']['TextStrokeColor3'] = Color3.fromRGB(255, 255, 255)
G2L['11']['BackgroundColor3'] = Color3.fromRGB(255, 255, 255)
G2L['11']['FontFace'] = Font.new(
    [[rbxasset://fonts/families/SourceSansPro.json]],
    Enum.FontWeight.Regular,
    Enum.FontStyle.Normal
)
G2L['11']['TextColor3'] = Color3.fromRGB(97, 97, 97)
G2L['11']['BackgroundTransparency'] = 1
G2L['11']['RichText'] = true
G2L['11']['Size'] = UDim2.new(0, 328, 0, 50)
G2L['11']['BorderColor3'] = Color3.fromRGB(0, 0, 0)
G2L['11']['Text'] = 'Want to purchase subscription instead?  Join the discord.'
G2L['11']['Name'] = 'PurchaseLabel'
G2L['11']['Position'] = UDim2.new(0.17728, 0, 0.76, 0)

G2L['12'] = Instance.new('Frame', G2L['2'])
G2L['12']['BorderSizePixel'] = 0
G2L['12']['BackgroundColor3'] = Color3.fromRGB(34, 34, 34)
G2L['12']['Size'] = UDim2.new(0, 381, 0, 42)
G2L['12']['Position'] = UDim2.new(0.06772, 0, 0.33493, 0)
G2L['12']['BorderColor3'] = Color3.fromRGB(41, 41, 41)
G2L['12']['Name'] = 'text'

G2L['13'] = Instance.new('UICorner', G2L['12'])
G2L['13']['CornerRadius'] = UDim.new(0, 4)

G2L['14'] = Instance.new('ImageButton', G2L['12'])
G2L['14']['BorderSizePixel'] = 0
G2L['14']['BackgroundColor3'] = Color3.fromRGB(28, 30, 32)
G2L['14']['Image'] = 'rbxassetid://16095745843'
G2L['14']['Size'] = UDim2.new(0, 29, 0, 27)
G2L['14']['BorderColor3'] = Color3.fromRGB(0, 0, 0)
G2L['14']['Name'] = 'show'
G2L['14']['Position'] = UDim2.new(0.00787, 0, 0.16667, 0)

G2L['15'] = Instance.new('UICorner', G2L['14'])
G2L['15']['CornerRadius'] = UDim.new(0, 4)

G2L['16'] = Instance.new('ImageButton', G2L['12'])
G2L['16']['BorderSizePixel'] = 0
G2L['16']['Modal'] = true
G2L['16']['BackgroundColor3'] = Color3.fromRGB(28, 30, 32)
G2L['16']['ImageColor3'] = Color3.fromRGB(194, 194, 194)
G2L['16']['Image'] = 'http://www.roblox.com/asset/?id=9754130783'
G2L['16']['Size'] = UDim2.new(0, 29, 0, 27)
G2L['16']['BorderColor3'] = Color3.fromRGB(0, 0, 0)
G2L['16']['Position'] = UDim2.new(0.91601, 0, 0.16667, 0)

G2L['17'] = Instance.new('UICorner', G2L['16'])
G2L['17']['CornerRadius'] = UDim.new(0, 4)

G2L['18'] = Instance.new('TextBox', G2L['12'])
G2L['18']['CursorPosition'] = -1
G2L['18']['TextXAlignment'] = Enum.TextXAlignment.Left
G2L['18']['BorderSizePixel'] = 0
G2L['18']['TextWrapped'] = true
G2L['18']['AutoLocalize'] = false
G2L['18']['TextSize'] = 18
G2L['18']['TextColor3'] = Color3.fromRGB(94, 94, 94)
G2L['18']['BackgroundColor3'] = Color3.fromRGB(94, 94, 94)
G2L['18']['FontFace'] = Font.new(
    [[rbxasset://fonts/families/SourceSansPro.json]],
    Enum.FontWeight.Regular,
    Enum.FontStyle.Normal
)
G2L['18']['Size'] = UDim2.new(0, 304, 0, 42)
G2L['18']['Position'] = UDim2.new(0, 38, 0, 0)
G2L['18']['BorderColor3'] = Color3.fromRGB(0, 0, 0)
G2L['18']['Text'] = ''
G2L['18']['BackgroundTransparency'] = 1
G2L['18'].Name = 'KeyBox'
G2L['18'].ClearTextOnFocus = false

G2L['19'] = Instance.new('TextButton', G2L['2'])
G2L['19']['TextWrapped'] = true
G2L['19']['RichText'] = true
G2L['19']['BorderSizePixel'] = 0
G2L['19']['TextStrokeColor3'] = Color3.fromRGB(255, 255, 255)
G2L['19']['TextSize'] = 22
G2L['19']['TextColor3'] = Color3.fromRGB(255, 255, 255)
G2L['19']['BackgroundColor3'] = Color3.fromRGB(28, 29, 31)
G2L['19']['FontFace'] = Font.new(
    [[rbxasset://fonts/families/GothamSSm.json]],
    Enum.FontWeight.Regular,
    Enum.FontStyle.Normal
)
G2L['19']['Size'] = UDim2.new(0, 27, 0, 27)
G2L['19']['BorderColor3'] = Color3.fromRGB(0, 0, 0)
G2L['19']['Text'] = 'X'
G2L['19']['Position'] = UDim2.new(0.93769, 0, -0.0009, 0)
G2L['19'].Name = 'CloseButton'

G2L['1a'] = Instance.new('UICorner', G2L['19'])

local clipboard = setclipboard or toclipboard
local function copyKeyLink()
    if clipboard then
        clipboard('https://ads.luarmor.net/get_key?for=Nexus_Free-nIXRzeCGRuov')
    end
end

G2L['f'].MouseEnter:Connect(function()
    G2L['f'].TextColor3 = Color3.fromRGB(140, 212, 255)
end)
G2L['f'].MouseLeave:Connect(function()
    G2L['f'].TextColor3 = Color3.fromRGB(255, 255, 255)
end)
G2L['f'].InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        copyKeyLink()
    end
end)

G2L['a'].MouseButton1Click:Connect(function()
    if clipboard then
        clipboard('discord.gg/nexusx')
    end
    if request then
        request({ Url = 'https://discord.gg/nexusx', Method = 'GET' })
    end
end)

local keyBox = G2L['18']
keyBox.Text = ''
keyBox.TextTransparency = 1

local showing = false
local tries = 0
local already_loaded = false

local function crash()
    while true do end
end

local function proceed()
    if already_loaded then return end
    local key = keyBox.Text
    if not key or #key < 4 then return end
    getgenv().script_key = key
    local success, err = pcall(function()
        loadstring(game:HttpGet(SCRIPT_URL[thisGame]))()
    end)
    if getgenv().NexusLoaded then
        already_loaded = true
        if G2L['1'] then G2L['1']:Destroy() end
        return
    else
        tries = tries + 1
        if tries >= 20 then
            crash()
        else
            keyBox.Text = ''
            keyBox.PlaceholderText = 'Invalid key, try again! (' .. tostring(20 - tries) .. ' tries left)'
        end
    end
end

G2L['14'].MouseButton1Click:Connect(function()
    showing = not showing
    keyBox.TextTransparency = showing and 0 or 1
end)

G2L['16'].MouseButton1Click:Connect(function()
    if not already_loaded then
        proceed()
    end
end)

G2L['19'].MouseButton1Click:Connect(function()
    if G2L['1'] then G2L['1']:Destroy() end
end)

copyKeyLink()

keyBox.FocusLost:Connect(function(enter)
    if enter then proceed() end
end)
keyBox.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Return then
        proceed()
    end
end)

return G2L['1']
