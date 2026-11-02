local ADDON_NAME = ...

local CONFIG = {
    key = "vendor",
    display = "Forever Vendor",
    events = {
        "PLAYER_ENTERING_WORLD",
        "MERCHANT_SHOW",
        "MERCHANT_CLOSED",
        "BAG_UPDATE_DELAYED",
    },
}

_G.ForeverDebugRegistry = _G.ForeverDebugRegistry or { modules = {}, order = {}, slashInstalled = false }
local Registry = _G.ForeverDebugRegistry

local function GetMetadata(addon, field)
    if C_AddOns and C_AddOns.GetAddOnMetadata then return C_AddOns.GetAddOnMetadata(addon, field) end
    if GetAddOnMetadata then return GetAddOnMetadata(addon, field) end
end

local function IsLoaded(addon)
    if C_AddOns and C_AddOns.IsAddOnLoaded then return C_AddOns.IsAddOnLoaded(addon) end
    if IsAddOnLoaded then return IsAddOnLoaded(addon) end
    return true
end

local module = Registry.modules[ADDON_NAME]
if not module then
    module = {}
    Registry.modules[ADDON_NAME] = module
    Registry.order[#Registry.order + 1] = ADDON_NAME
end
module.addon = ADDON_NAME
module.key = CONFIG.key
module.display = CONFIG.display
module.lastEvent = module.lastEvent or "DEBUG_LOADED"
module.lastAt = module.lastAt or ((GetTime and GetTime()) or 0)
module.registeredEvents = 0
module.failedEvents = {}

local events = CreateFrame("Frame")
for _, eventName in ipairs(CONFIG.events) do
    local ok = pcall(events.RegisterEvent, events, eventName)
    if ok then module.registeredEvents = module.registeredEvents + 1 else module.failedEvents[#module.failedEvents + 1] = eventName end
end

events:SetScript("OnEvent", function(_, event)
    module.lastEvent = event
    module.lastAt = (GetTime and GetTime()) or 0
    if event == "MERCHANT_SHOW" then
        module.lastDetail = "vendor opened"
    elseif event == "MERCHANT_CLOSED" then
        module.lastDetail = "vendor closed"
    elseif event == "BAG_UPDATE_DELAYED" then
        module.lastDetail = "bags changed"
    elseif event == "PLAYER_ENTERING_WORLD" then
        module.lastDetail = "entered world"
    else
        module.lastDetail = nil
    end
end)

module.GetProbeText = function()
    local containerAPI = ((C_Container and C_Container.GetContainerItemInfo) or GetContainerItemInfo) and "OK" or "MISS"
    local merchantAPI = MerchantFrame and "OK" or "MISS"
    local eventText = #module.failedEvents > 0 and (" | events:" .. module.registeredEvents .. "/" .. #CONFIG.events) or ""
    return "Container:" .. containerAPI .. " | Merchant:" .. merchantAPI .. eventText
end

module.GetStateText = function()
    local db = ForeverVendorDB or {}
    local merchant = MerchantFrame and MerchantFrame.IsShown and MerchantFrame:IsShown() and "open" or "closed"
    return string.format("enabled=%s summary=%s merchant=%s", tostring(db.enabled), tostring(db.showSummary), merchant)
end

local function Trim(text)
    return (tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function SecondsSince(when)
    local now = (GetTime and GetTime()) or 0
    local delta = math.max(0, now - (tonumber(when) or now))
    return delta < 10 and string.format("%.1fs", delta) or (tostring(math.floor(delta + 0.5)) .. "s")
end

local function MatchesFilter(entry, filter)
    if filter == "" or filter == "all" then return true end
    local needle = string.lower(filter)
    return string.find(string.lower(entry.key or ""), needle, 1, true)
        or string.find(string.lower(entry.addon or ""), needle, 1, true)
        or string.find(string.lower(entry.display or ""), needle, 1, true)
end

Registry.Print = function(message)
    local filter = string.lower(Trim(message))
    if filter == "help" then
        local keys = {}
        for _, addon in ipairs(Registry.order) do
            local entry = Registry.modules[addon]
            if entry and entry.key then keys[#keys + 1] = entry.key end
        end
        table.sort(keys)
        print("|cffd9b93eForever Debug|r: /foreverdebug [all|" .. table.concat(keys, "|") .. "]")
        return
    end

    local version, build, interface = "?", "?", "?"
    if GetBuildInfo then
        local ok, v, b, _, i = pcall(GetBuildInfo)
        if ok then version, build, interface = tostring(v or "?"), tostring(b or "?"), tostring(i or "?") end
    end

    local count = 0
    for _, addon in ipairs(Registry.order) do
        local entry = Registry.modules[addon]
        if entry and MatchesFilter(entry, filter) then count = count + 1 end
    end
    print(string.format("|cffd9b93eForever Debug|r client=%s build=%s interface=%s project=%s modules=%d", version, build, interface, tostring(WOW_PROJECT_ID or "?"), count))

    local printed = 0
    for _, addon in ipairs(Registry.order) do
        local entry = Registry.modules[addon]
        if entry and MatchesFilter(entry, filter) then
            printed = printed + 1
            local addonVersion = GetMetadata(entry.addon, "Version") or "?"
            local loaded = IsLoaded(entry.addon) and "loaded" or "NOT loaded"
            local eventText = tostring(entry.lastEvent or "none") .. " " .. SecondsSince(entry.lastAt) .. " ago"
            if entry.lastDetail then eventText = eventText .. " (" .. tostring(entry.lastDetail) .. ")" end
            print(string.format("|cff66ccff%s|r v%s %s | last=%s", entry.display, addonVersion, loaded, eventText))
            if entry.GetProbeText then print("  API: " .. entry.GetProbeText()) end
            if entry.GetStateText then print("  State: " .. entry.GetStateText()) end
        end
    end
    if printed == 0 then print("No Forever addon matched '" .. tostring(filter) .. "'. Try /foreverdebug help") end
end

if not Registry.slashInstalled then
    Registry.slashInstalled = true
    SLASH_FOREVERDEBUG1 = "/foreverdebug"
    SlashCmdList = SlashCmdList or {}
    SlashCmdList.FOREVERDEBUG = function(message) Registry.Print(message) end
end
