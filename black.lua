-- ============================================================
-- CONFIGURATION - CHANGE THESE!
-- ============================================================

local PLACE_ID = 109983668079237  
local RELAY_URL = "https://1123412312312-production.up.railway.app/latest"  

-- ============================================================
-- Services
-- ============================================================

local Http = game:GetService("HttpService")
local Teleport = game:GetService("TeleportService")
local Players = game:GetService("Players")

-- ============================================================
-- State
-- ============================================================

local running = false
local lastId = nil
local joined = 0
local checkCount = 0

-- ============================================================
-- GUI
-- ============================================================

local gui = Instance.new("ScreenGui")
gui.ResetOnSpawn = false
pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = Players.LocalPlayer.PlayerGui end

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 250, 0, 180)
frame.Position = UDim2.new(0.5, -125, 0.5, -90)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.Text = "Auto-Joiner [DEBUG]"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.Parent = frame

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 60)
status.Position = UDim2.new(0, 10, 0, 45)
status.BackgroundTransparency = 1
status.Text = "Status: Idle"
status.TextColor3 = Color3.fromRGB(200, 200, 200)
status.Font = Enum.Font.Code
status.TextSize = 11
status.TextWrapped = true
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextYAlignment = Enum.TextYAlignment.Top
status.Parent = frame

local counter = Instance.new("TextLabel")
counter.Size = UDim2.new(1, 0, 0, 20)
counter.Position = UDim2.new(0, 0, 0, 110)
counter.BackgroundTransparency = 1
counter.Text = "Joined: 0 | Checks: 0"
counter.TextColor3 = Color3.fromRGB(200, 200, 200)
counter.Font = Enum.Font.Gotham
counter.TextSize = 13
counter.Parent = frame

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(0, 200, 0, 40)
btn.Position = UDim2.new(0.5, -100, 1, -50)
btn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
btn.Text = "START"
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.Font = Enum.Font.GothamBold
btn.TextSize = 16
btn.Parent = frame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 8)
btnCorner.Parent = btn

-- ============================================================
-- Functions
-- ============================================================

local function updateStatus(text, color)
    status.Text = text
    status.TextColor3 = color or Color3.fromRGB(200, 200, 200)
    counter.Text = "Joined: " .. joined .. " | Checks: " .. checkCount
end

local function join(id)
    warn("🎮 ATTEMPTING JOIN: " .. id)
    local success, err = pcall(function()
        Teleport:TeleportToPlaceInstance(PLACE_ID, id, Players.LocalPlayer)
    end)
    
    if success then
        joined = joined + 1
        warn("✅ TELEPORT INITIATED!")
        updateStatus("✅ Joined server!\nID: " .. id:sub(1, 8) .. "...", Color3.fromRGB(76, 175, 80))
    else
        warn("❌ TELEPORT FAILED: " .. tostring(err))
        updateStatus("❌ Join failed\n" .. tostring(err), Color3.fromRGB(244, 67, 54))
    end
end

local function check()
    checkCount = checkCount + 1
    
    -- Try to get response using RequestAsync for better control
    local ok, response = pcall(function()
        return Http:RequestAsync({
            Url = RELAY_URL,
            Method = "GET",
            Headers = {
                ["Content-Type"] = "text/plain"
            }
        })
    end)
    
    -- ALWAYS print what we got
    warn("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    warn("CHECK #" .. checkCount)
    warn("Request Success: " .. tostring(ok))
    
    if ok and response then
        warn("Status Code: " .. tostring(response.StatusCode))
        warn("Status Message: " .. tostring(response.StatusMessage))
        warn("Success: " .. tostring(response.Success))
        warn("Body Type: " .. type(response.Body))
        warn("Raw Body: [" .. tostring(response.Body) .. "]")
        
        if response.Success and response.Body then
            local res = response.Body
            warn("✅ Got response body!")
            warn("Length before trim: " .. #res)
            
            -- Extract job ID from HTML <pre> tags if present
            local extracted = res:match("<pre[^>]*>%s*([^<]+)%s*</pre>")
            if extracted then
                warn("🔍 Extracted from <pre> tags: " .. extracted)
                res = extracted
            end
            
            -- Trim whitespace and newlines
            res = res:match("^%s*(.-)%s*$")
            
            warn("Trimmed Response: [" .. tostring(res) .. "]")
            warn("Length after trim: " .. #res)
        
        -- Check if response is empty or "null" or "none"
        if res == "" or res == "null" or res == "none" or res == "NULL" then
            warn("📭 No server available yet")
            updateStatus("⏳ Waiting for new server...\nLast: " .. (lastId and lastId:sub(1, 8) .. "..." or "None"), Color3.fromRGB(158, 158, 158))
        -- Check if it's a valid UUID (36 chars with dashes at positions 8, 13, 18, 23)
        elseif #res == 36 and res:match("^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$") then
            warn("✅ VALID JOB ID FORMAT")
            
            -- Check if it's different from last
            if res ~= lastId then
                warn("🆕 NEW ID DETECTED!")
                warn("Old: " .. tostring(lastId))
                warn("New: " .. res)
                
                lastId = res
                updateStatus("🆕 New server found!\n" .. res:sub(1, 13) .. "...", Color3.fromRGB(255, 193, 7))
                
                -- Wait a moment before joining
                task.wait(0.5)
                join(res)
                
                -- Clear from relay after successful join attempt
                task.wait(1)
                pcall(function()
                    local clearUrl = RELAY_URL:gsub("/latest", "/clear")
                    Http:RequestAsync({
                        Url = clearUrl,
                        Method = "GET"
                    })
                    warn("🗑️ Cleared from relay")
                end)
            else
                warn("⏭️ Same as last ID, skipping")
                updateStatus("⏳ Waiting for new server...\nLast: " .. (lastId and lastId:sub(1, 8) .. "..." or "None"), Color3.fromRGB(158, 158, 158))
            end
        else
            warn("❌ INVALID FORMAT: " .. tostring(res))
            warn("Expected 36-char UUID, got: " .. #res .. " chars")
            updateStatus("⚠️ Invalid server ID\nGot: " .. res:sub(1, 20), Color3.fromRGB(255, 152, 0))
        end
        else
            warn("❌ REQUEST UNSUCCESSFUL")
            warn("Status: " .. tostring(response.StatusCode))
            warn("Message: " .. tostring(response.StatusMessage))
            updateStatus("❌ Server error " .. tostring(response.StatusCode) .. "\n" .. tostring(response.StatusMessage):sub(1, 20), Color3.fromRGB(244, 67, 54))
        end
    else
        warn("❌ REQUEST FAILED COMPLETELY")
        warn("OK Status: " .. tostring(ok))
        if not ok then
            warn("Error Details: " .. tostring(response))
        end
        
        local errorMsg = not ok and tostring(response):sub(1, 40) or "Unknown error"
        updateStatus("❌ Request failed\n" .. errorMsg, Color3.fromRGB(244, 67, 54))
    end
    
    warn("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    
    counter.Text = "Joined: " .. joined .. " | Checks: " .. checkCount
end

local function start()
    running = true
    btn.Text = "STOP"
    btn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
    updateStatus("▶️ Starting monitor...", Color3.fromRGB(100, 181, 246))
    
    warn("🚀 AUTO-JOINER STARTED")
    warn("Place ID: " .. PLACE_ID)
    warn("Relay URL: " .. RELAY_URL)
    
    -- Test connection first
    warn("\n🔌 Testing connection...")
    local testOk, testRes = pcall(function()
        local baseUrl = RELAY_URL:gsub("/latest", "")
        return Http:RequestAsync({
            Url = baseUrl,
            Method = "GET"
        })
    end)
    
    if testOk and testRes and testRes.Success then
        warn("✅ Relay server is reachable!")
        warn("Status: " .. tostring(testRes.StatusCode))
        warn("Response: " .. tostring(testRes.Body))
        updateStatus("✅ Connected to relay\nWaiting for servers...", Color3.fromRGB(76, 175, 80))
    else
        warn("❌ RELAY SERVER UNREACHABLE!")
        if testOk and testRes then
            warn("Status Code: " .. tostring(testRes.StatusCode))
            warn("Error: " .. tostring(testRes.StatusMessage))
        else
            warn("Error: " .. tostring(testRes))
        end
        updateStatus("❌ Can't reach relay!\nCheck Railway URL", Color3.fromRGB(244, 67, 54))
    end
    
    spawn(function()
        while running do
            pcall(check)
            task.wait(1)
        end
    end)
end

local function stop()
    running = false
    btn.Text = "START"
    btn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    updateStatus("⏸️ Stopped", Color3.fromRGB(158, 158, 158))
    warn("⏸️ AUTO-JOINER STOPPED")
end

btn.MouseButton1Click:Connect(function()
    if running then stop() else start() end
end)

warn("👋 Auto-Joiner loaded! Click START to begin.")
updateStatus("Click START to begin", Color3.fromRGB(158, 158, 158))
