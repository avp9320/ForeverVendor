local ADDON_NAME = ...

local DEFAULTS = {
    enabled = true,
    showSummary = true,
}

local frame = CreateFrame("Frame")
local selling = false
local session = 0
local queue = {}
local queueIndex = 1
local soldCount = 0
local soldValue = 0
local manualRun = false

local function msg(text)
    print("|cffd8b45bForever Vendor:|r " .. tostring(text))
end

local function applyDefaults(db, defaults)
    for key, value in pairs(defaults) do
        if db[key] == nil then
            db[key] = value
        end
    end
end

local function boolText(value)
    return value and "on" or "off"
end

local function moneyText(copper)
    copper = math.max(0, tonumber(copper) or 0)

    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local coin = copper % 100

    if gold > 0 then
        return string.format("%dg %ds %dc", gold, silver, coin)
    elseif silver > 0 then
        return string.format("%ds %dc", silver, coin)
    else
        return string.format("%dc", coin)
    end
end

local function merchantIsOpen()
    return MerchantFrame and MerchantFrame.IsShown and MerchantFrame:IsShown()
end

local function getNumSlots(bag)
    if C_Container and C_Container.GetContainerNumSlots then
        return C_Container.GetContainerNumSlots(bag) or 0
    elseif GetContainerNumSlots then
        return GetContainerNumSlots(bag) or 0
    end
    return 0
end

local function getItemLink(bag, slot)
    if C_Container and C_Container.GetContainerItemLink then
        return C_Container.GetContainerItemLink(bag, slot)
    elseif GetContainerItemLink then
        return GetContainerItemLink(bag, slot)
    end
end

local function getItemCountAndLocked(bag, slot)
    if C_Container and C_Container.GetContainerItemInfo then
        local info = C_Container.GetContainerItemInfo(bag, slot)
        if info then
            return info.stackCount or 1, info.isLocked == true
        end
        return 0, false
    elseif GetContainerItemInfo then
        local _, count, locked = GetContainerItemInfo(bag, slot)
        return count or 1, locked == true
    end
    return 1, false
end

local function useItem(bag, slot)
    if C_Container and C_Container.UseContainerItem then
        C_Container.UseContainerItem(bag, slot)
    elseif UseContainerItem then
        UseContainerItem(bag, slot)
    end
end

local function getBagMax()
    return tonumber(NUM_BAG_SLOTS) or 4
end

local function buildQueue()
    queue = {}
    queueIndex = 1

    for bag = 0, getBagMax() do
        for slot = 1, getNumSlots(bag) do
            local link = getItemLink(bag, slot)
            if link then
                local _, _, quality, _, _, _, _, _, _, _, sellPrice = GetItemInfo(link)
                local count, locked = getItemCountAndLocked(bag, slot)

                -- Quality 0 is poor/gray. Only sell items the vendor actually values.
                if quality == 0 and not locked and (sellPrice or 0) > 0 then
                    queue[#queue + 1] = {
                        bag = bag,
                        slot = slot,
                        value = (sellPrice or 0) * math.max(1, count or 1),
                    }
                end
            end
        end
    end
end

local function finishRun()
    selling = false

    if soldCount > 0 and ForeverVendorDB.showSummary then
        msg(string.format("Sold %d junk item%s for %s.",
            soldCount,
            soldCount == 1 and "" or "s",
            moneyText(soldValue)))
    elseif soldCount == 0 and manualRun then
        msg("No junk to sell.")
    end

    manualRun = false
end

local function sellNext(runSession)
    if not selling or runSession ~= session then
        return
    end

    if not merchantIsOpen() then
        selling = false
        manualRun = false
        return
    end

    local item = queue[queueIndex]
    if not item then
        finishRun()
        return
    end

    queueIndex = queueIndex + 1

    local link = getItemLink(item.bag, item.slot)
    if link then
        local _, _, quality, _, _, _, _, _, _, _, sellPrice = GetItemInfo(link)
        local count, locked = getItemCountAndLocked(item.bag, item.slot)

        -- Re-check immediately before selling. This protects against bag changes
        -- between opening the vendor and processing the queued slot.
        if quality == 0 and not locked and (sellPrice or 0) > 0 then
            useItem(item.bag, item.slot)
            soldCount = soldCount + math.max(1, count or 1)
            soldValue = soldValue + ((sellPrice or 0) * math.max(1, count or 1))
        end
    end

    if C_Timer and C_Timer.After then
        C_Timer.After(0.08, function()
            sellNext(runSession)
        end)
    else
        sellNext(runSession)
    end
end

local function startSelling(isManual)
    if not ForeverVendorDB.enabled and not isManual then
        return
    end

    if not merchantIsOpen() then
        if isManual then
            msg("Open a vendor first.")
        end
        return
    end

    session = session + 1
    selling = true
    soldCount = 0
    soldValue = 0
    manualRun = isManual == true

    buildQueue()
    sellNext(session)
end

local function showHelp()
    msg("/fv status")
    msg("/fv on | off")
    msg("/fv summary on | off")
    msg("/fv sell   (sell junk now while a vendor is open)")
end

SLASH_FOREVERVENDOR1 = "/fv"
SLASH_FOREVERVENDOR2 = "/forevervendor"
SlashCmdList.FOREVERVENDOR = function(input)
    input = string.lower((input or ""):match("^%s*(.-)%s*$"))

    local command, arg = input:match("^(%S+)%s*(.-)$")
    command = command or ""
    arg = arg or ""

    if command == "on" then
        ForeverVendorDB.enabled = true
        msg("Automatic junk selling on.")
    elseif command == "off" then
        ForeverVendorDB.enabled = false
        msg("Automatic junk selling off.")
    elseif command == "status" then
        msg(string.format("auto-sell=%s, summary=%s",
            boolText(ForeverVendorDB.enabled),
            boolText(ForeverVendorDB.showSummary)))
    elseif command == "summary" then
        if arg == "on" then
            ForeverVendorDB.showSummary = true
            msg("Sale summary on.")
        elseif arg == "off" then
            ForeverVendorDB.showSummary = false
            msg("Sale summary off.")
        else
            msg("Sale summary is " .. boolText(ForeverVendorDB.showSummary) .. ".")
        end
    elseif command == "sell" then
        startSelling(true)
    else
        showHelp()
    end
end

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("MERCHANT_SHOW")
frame:RegisterEvent("MERCHANT_CLOSED")

frame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        ForeverVendorDB = ForeverVendorDB or {}
        applyDefaults(ForeverVendorDB, DEFAULTS)
    elseif event == "MERCHANT_SHOW" then
        if ForeverVendorDB and ForeverVendorDB.enabled then
            startSelling(false)
        end
    elseif event == "MERCHANT_CLOSED" then
        session = session + 1
        selling = false
        manualRun = false
    end
end)
