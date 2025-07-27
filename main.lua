local scriptURL = "https://raw.githubusercontent.com/bypassv5/SabChecker/refs/heads/main/script.lua"
if queue_on_teleport then
    queue_on_teleport("loadstring(game:HttpGet('"..scriptURL.."'))()")
end

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local webhookURL = ""

-- Copy key link to clipboard
pcall(function()
    setclipboard("https://link-center.net/1375465/YAC3CDe8HuMX")
end)

local BrainrotsToCheck = {
    "Cocofanto Elephanto",
    "Girafa Celestre",
    "Tralalero Tralala",
    "Gattatino Neonino",
    "Odin Din Din Dun",
    "Tigroligre Frutonni",
    "Espresso Signora",
    "Orcalero Orcala",
    "Matteo",
    "Statutino Libertino",
    "Ballerino Lololo",
    "Trenostruzzo Turbo 3000",
    "Piccione Macchina",
    "Brainrot God Lucky Block",
    
    "La Vacca Saturno Saturnita",
    "Chimpanzini Spiderini",
    "Los Tralaleritos",
    "Las Tralaleritas",
    "Las Vaquitas Saturnitas",
    "Graipuss Medussi",
    "Torrtuginni Dragonfrutini",
    "Chicletera Bicicletera",
    "Pot Hotspot",
    "La Grande Combinasion",
    "Nuclearo Dinossauro",
    "Garama and Madundung",
    "Secret Lucky Block"
}

local PingBrainrots = {
    ["La Vacca Saturno Saturnita"] = true,
    ["Graipuss Medussi"] = true,
    ["La Grande Combinasion"] = true,
    ["Los Tralaleritos"] = true,
    ["Chimpanzini Spiderini"] = true,
    ["Las Tralaleritas"] = true,
    ["Las Vaquitas Saturnitas"] = true,
    ["Torrtuginni Dragonfrutini"] = true,
    ["Chicletera Bicicletera"] = true,
    ["Pot Hotspot"] = true,
    ["Nuclearo Dinossauro"] = true,
    ["Garama and Madundung"] = true,
    ["Secret Lucky Block"] = true,
}

local running = false
local teleporting = false
local stopOnRare = false

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Brainrot Finder",
    LoadingTitle = "Loading Brainrot Finder...",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "SabFinderV1",
        FileName = "Config",
    },
    KeySystem = true,
    KeySettings = {
        Title = "Brainrot Finder Key System",
        Subtitle = "Enter your key below",
        Note = "Get your key from https://link-center.net/1375465/YAC3CDe8HuMX (Key copied to clipboard)",
        FileName = "BrainrotFinderKey",
        SaveKey = true,
        Key = {"8MWlRfVTijY88Lk43h59ofCnC0iuxhoc"}
    }
})

local Tab = Window:CreateTab("Main")

Tab:CreateInput({
    Name = "Webhook URL (optional)",
    PlaceholderText = "Defaults to rare ping only",
    RemoveTextAfterFocusLost = false,
    OnChanged = function(text)
        webhookURL = text
    end
})

Tab:CreateToggle({
    Name = "Stop hopping when rare is found",
    CurrentValue = false,
    Flag = "StopOnRareToggle",
    Callback = function(val)
        stopOnRare = val
    end
})

local hoppingToggle = Tab:CreateToggle({
    Name = "Start Hopping",
    CurrentValue = false,
    Flag = "StartHop",
    Callback = function(val)
        running = val
        if running then
            task.spawn(hopLoop)
        end
    end
})

local function scanModels()
    local found = {}
    for _, name in ipairs(BrainrotsToCheck) do
        if workspace:FindFirstChild(name) then
            table.insert(found, name)
        end
    end
    return found
end

local function sendWebhook(foundModels)
    local req = (syn and syn.request) or http_request or (fluxus and fluxus.request)
    if not req then warn("No HTTP request method found.") return end

    local pingEveryone = false
    for _, name in ipairs(foundModels) do
        if PingBrainrots[name] then
            pingEveryone = true
            break
        end
    end

    local msg = (pingEveryone and "@everyone\n" or "") ..
        "Game `" .. game.JobId .. "`\n"

    if #foundModels > 0 then
        msg ..= "Found models:\n- " .. table.concat(foundModels, "\n- ")
    else
        msg ..= "No models found."
    end

    msg ..= "\n\nJoin: `game:GetService(\"TeleportService\"):TeleportToPlaceInstance(" ..
        game.PlaceId .. ', "' .. game.JobId .. '")`'

    pcall(function()
        req({
            Url = webhookURL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({content = msg})
        })
    end)

    if pingEveryone and stopOnRare then
        print("[RARE FOUND] Stopping hopping.")
        running = false
        hoppingToggle:Set(false)
    end
end


local function getOnePlayerServers()
    local ok, res = pcall(function()
        return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
    end)
    if not ok then return {} end

    local servers = {}
    for _, server in ipairs(res.data) do
        if server.playing == 1 and server.id ~= game.JobId then
            table.insert(servers, server.id)
        end
    end
    return servers
end

local function tryTeleport(serverId)
    if teleporting then return false end
    teleporting = true
    local ok, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, serverId, LocalPlayer)
    end)
    teleporting = false
    if not ok then
        warn("[Teleport Error]:", err)
    end
    return ok
end

function hopLoop()
    while running do
        local found = scanModels()
        sendWebhook(found)
        if not running then break end
        task.wait(0.5)

        local servers = getOnePlayerServers()
        if #servers >= 1 then
            if tryTeleport(servers[math.random(1, #servers)]) then
                print("[HOP] Teleporting...")
                break
            else
                task.wait(1)
            end
        else
            task.wait(1)
        end
    end
end

TeleportService.TeleportInitFailed:Connect(function()
    print("[Teleport Failed] Rejoining current server...")
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Q then
        running = not running
        hoppingToggle:Set(running)
        print(running and "[HOPPING STARTED]" or "[HOPPING PAUSED]")
        if running then
            task.spawn(hopLoop)
        end
    end
end)

Rayfield:Notify({
    Title = "Brainrot Finder",
    Content = "Loaded. Press Q or use toggle to start.",
    Duration = 5,
    Image = 4483362458
})

Rayfield:LoadConfiguration()
