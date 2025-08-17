-- RarityRadar Addon for WoW MoP Classic
local addonName = "RarityRadar"
local RR = {}

-- Rarity constants (MoP values)
local RARITY = {
    POOR = 0,      -- Gray
    COMMON = 1,    -- White
    UNCOMMON = 2,  -- Green
    RARE = 3,      -- Blue
    EPIC = 4,      -- Purple
    LEGENDARY = 5, -- Orange
    ARTIFACT = 6   -- Red (not in MoP but included for completeness)
}

-- Loot type constants (based on WoW API - GetLootSlotInfo doesn't return loot type in MoP)
-- We'll determine type based on itemLink presence and other factors

-- Default settings
local defaults = {
    enabled = true,
    minRarity = RARITY.UNCOMMON, -- Default to green+
    autoGreedEnabled = true,
    autoConfirmSoulbound = true, -- Auto-confirm soulbound item dialogs
    lootCloth = false, -- Auto-loot cloth items regardless of rarity
    debug = false,
    verboseDebug = false -- Extra detailed debugging
}

-- Initialize saved variables
function RR:InitializeDB()
    if not RarityRadarDB then
        RarityRadarDB = {}
    end
    
    -- Set defaults for missing values
    for key, value in pairs(defaults) do
        if RarityRadarDB[key] == nil then
            RarityRadarDB[key] = value
        end
    end
end

-- Debug print function
function RR:DebugPrint(msg)
    if RarityRadarDB.debug then
        print("|cFF00FF00[RR Debug]|r " .. msg)
    end
end

-- Verbose debug print function
function RR:VerboseDebugPrint(msg)
    if RarityRadarDB.verboseDebug then
        print("|cFF00FFFF[RR Verbose]|r " .. msg)
    end
end

-- Main print function
function RR:Print(msg)
    print("|cFFFF6600[RarityRadar]|r " .. msg)
end

-- Check if item is soulbound (simplified - disable for now to focus on main functionality)
function RR:IsItemSoulbound(itemLink)
    -- For now, return false to disable soulbound checking
    -- This can be re-enabled once core functionality is working
    return false
end

-- Auto-confirm soulbound item dialogs
function RR:AutoConfirmSoulbound()
    if not RarityRadarDB.autoConfirmSoulbound then
        return false
    end
    
    -- Check for the standard loot confirmation dialog
    if StaticPopup1 and StaticPopup1:IsVisible() then
        local popup = StaticPopup1
        if popup.which == "LOOT_BIND" then
            self:DebugPrint("Auto-accepting soulbound item confirmation")
            if popup.button1 and popup.button1:IsEnabled() then
                popup.button1:Click()
                return true
            end
        end
    end
    
    -- Check additional static popup slots
    for i = 1, 4 do
        local popup = _G["StaticPopup" .. i]
        if popup and popup:IsVisible() and popup.which == "LOOT_BIND" then
            self:DebugPrint("Auto-accepting soulbound item confirmation (popup " .. i .. ")")
            if popup.button1 and popup.button1:IsEnabled() then
                popup.button1:Click()
                return true
            end
        end
    end
    
    return false
end

-- Check if item meets rarity requirement and is not soulbound
function RR:ShouldLootItem(itemLink)
    if not itemLink then 
        self:VerboseDebugPrint("No item link provided")
        return false 
    end
    
    local _, _, quality = GetItemInfo(itemLink)
    if not quality then 
        self:VerboseDebugPrint("Quality not available for item: " .. tostring(itemLink))
        return false 
    end
    
    -- Check rarity requirement
    local meetsRarity = quality >= RarityRadarDB.minRarity
    self:VerboseDebugPrint("Item quality: " .. quality .. ", required: " .. RarityRadarDB.minRarity .. ", meets requirement: " .. tostring(meetsRarity))
    
    if not meetsRarity then
        return false
    end
    
    -- Check if soulbound (skip soulbound items)
    local isSoulbound = self:IsItemSoulbound(itemLink)
    if isSoulbound then
        self:DebugPrint("Skipping soulbound item: " .. itemLink)
        return false
    end
    
    return true
end

-- Check if loot slot is currency (money)
function RR:IsLootSlotCurrency(slotIndex)
    local lootIcon, lootName, lootQuantity, lootSlotType, quality, locked = GetLootSlotInfo(slotIndex)
    local itemLink = GetLootSlotLink(slotIndex)
    
    -- Currency has no itemLink and usually contains "Silver", "Gold", "Copper"
    if not itemLink then
        local name = lootName or ""
        if string.find(string.lower(name), "copper") or 
           string.find(string.lower(name), "silver") or 
           string.find(string.lower(name), "gold") then
            return true
        end
    end
    
    return false
end

-- Check if item is cloth
function RR:IsItemCloth(itemLink)
    if not itemLink then return false end
    
    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType = GetItemInfo(itemLink)
    
    if not itemType then 
        self:VerboseDebugPrint("Item type not available for: " .. tostring(itemLink))
        return false 
    end
    
    -- Check if it's a Trade Good and specifically cloth
    if itemType == "Trade Goods" or itemType == "Tradeskill" then
        if itemSubType and (string.find(string.lower(itemSubType), "cloth") or 
                           string.find(string.lower(itemName or ""), "cloth")) then
            return true
        end
    end
    
    -- Also check for specific cloth item names
    local clothItems = {
        "linen cloth", "wool cloth", "silk cloth", "mageweave cloth", 
        "runecloth", "netherweave cloth", "frostweave cloth", "embersilk cloth"
    }
    
    local itemNameLower = string.lower(itemName or "")
    for _, clothName in ipairs(clothItems) do
        if string.find(itemNameLower, clothName) then
            return true
        end
    end
    
    return false
end

-- Check if we're in a crafting/disenchanting scenario
function RR:IsCraftingScenario()
    -- Check if trade skill window is open
    if TradeSkillFrame and TradeSkillFrame:IsVisible() then
        self:VerboseDebugPrint("Trade skill window is open - crafting scenario detected")
        return true
    end
    
    -- Check if enchanting window is open
    if EnchantingFrame and EnchantingFrame:IsVisible() then
        self:VerboseDebugPrint("Enchanting window is open - disenchanting scenario detected")
        return true
    end
    
    -- Check if we recently cast a crafting spell
    local currentTime = GetTime()
    if RR.lastCraftTime and (currentTime - RR.lastCraftTime) < 5 then
        self:VerboseDebugPrint("Recent crafting activity detected - crafting scenario (time since cast: " .. string.format("%.1f", currentTime - RR.lastCraftTime) .. "s)")
        return true
    end
    
    self:VerboseDebugPrint("No crafting scenario detected - normal loot mode")
    return false
end

-- Check if item is a disenchanting/crafting result
function RR:IsDisenchantingResult(itemName)
    if not itemName then return false end
    
    local itemNameLower = string.lower(itemName)
    
    -- Common disenchanting materials (removed "cloth" from here since it's handled separately)
    local disenchantResults = {
        "strange dust", "soul dust", "vision dust", "dream dust", "illusion dust",
        "lesser magic essence", "greater magic essence", "lesser astral essence", "greater astral essence",
        "lesser mystic essence", "greater mystic essence", "lesser nether essence", "greater nether essence",
        "lesser eternal essence", "greater eternal essence", "lesser planar essence", "greater planar essence",
        "lesser cosmic essence", "greater cosmic essence", "arcane dust", "infinite dust",
        "small brilliant shard", "large brilliant shard", "nexus crystal", "void crystal",
        "abyss crystal", "maelstrom crystal", "heavenly shard", "celestial essence",
        "mysterious essence", "ethereal shard", "sha crystal", "hypnotic dust",
        -- Other crafting materials (removed cloth, ore, leather, herb since they have specific settings)
        "gem", "crystal", "shard", "essence", "dust"
    }
    
    for _, material in ipairs(disenchantResults) do
        if string.find(itemNameLower, material) then
            self:VerboseDebugPrint("Disenchanting/crafting material detected: " .. itemName)
            return true
        end
    end
    
    return false
end

-- Track crafting activities
function RR:OnSpellCast(spellName)
    if not spellName then return end
    
    local craftingSpells = {
        "disenchant", "enchanting", "blacksmithing", "leatherworking", 
        "tailoring", "engineering", "alchemy", "jewelcrafting", 
        "inscription", "cooking", "first aid"
    }
    
    local spellLower = string.lower(spellName)
    for _, craft in ipairs(craftingSpells) do
        if string.find(spellLower, craft) then
            RR.lastCraftTime = GetTime()
            self:VerboseDebugPrint("Crafting spell detected: " .. spellName)
            return
        end
    end
end

-- Handle auto-looting
function RR:HandleAutoLoot()
    if not RarityRadarDB.enabled then 
        self:VerboseDebugPrint("Addon disabled, skipping auto-loot")
        return 
    end
    
    local numLootItems = GetNumLootItems()
    if numLootItems == 0 then 
        self:VerboseDebugPrint("No loot items found")
        return 
    end
    
    -- Check if we're in a crafting scenario
    local isCraftingScenario = self:IsCraftingScenario()
    if isCraftingScenario then
        self:DebugPrint("Crafting scenario detected - will auto-loot all items regardless of rarity")
    end
    
    -- Check if any item looks like disenchanting/crafting results
    local hasDisenchantResults = false
    for i = 1, numLootItems do
        local lootIcon, lootName, lootQuantity, lootSlotType, quality, locked = GetLootSlotInfo(i)
        if lootName and self:IsDisenchantingResult(lootName) then
            hasDisenchantResults = true
            self:DebugPrint("Disenchanting/crafting results detected in loot - will auto-loot all items")
            break
        end
    end
    
    self:DebugPrint("Loot window opened with " .. numLootItems .. " items")
    local itemsLooted = 0
    
    -- Simple single pass through all items
    for i = 1, numLootItems do
        local lootIcon, lootName, lootQuantity, lootSlotType, quality, locked = GetLootSlotInfo(i)
        local itemLink = GetLootSlotLink(i)
        
        self:VerboseDebugPrint("Slot " .. i .. ": " .. (lootName or "Unknown") .. 
                              " (Type: " .. tostring(lootSlotType) .. 
                              ", Quality: " .. tostring(quality) .. 
                              ", Locked: " .. tostring(locked) .. 
                              ", HasLink: " .. tostring(itemLink ~= nil) .. ")")
        
        if locked then
            self:VerboseDebugPrint("Slot " .. i .. " is locked, skipping")
            
        -- Check if it's currency (money)
        elseif self:IsLootSlotCurrency(i) then
            self:DebugPrint("Auto-looting currency: " .. (lootName or "Money") .. 
                           " x" .. (lootQuantity or 1))
            LootSlot(i)
            itemsLooted = itemsLooted + 1
            
        -- Check if it's an item with itemLink
        elseif itemLink then
            local shouldLoot = false
            local lootReason = ""
            
            -- If crafting scenario OR has disenchant results, loot everything regardless of rarity
            if isCraftingScenario or hasDisenchantResults then
                shouldLoot = true
                lootReason = "crafting/disenchanting result"
                self:VerboseDebugPrint("Crafting/disenchanting scenario - overriding rarity check for: " .. (lootName or "Unknown") .. " (Quality: " .. (quality or 0) .. ")")
            -- Check if it's cloth and cloth looting is enabled (do this BEFORE disenchanting check)
            elseif RarityRadarDB.lootCloth and self:IsItemCloth(itemLink) then
                shouldLoot = true
                lootReason = "cloth item"
            -- Check if it's a specific disenchanting result (but NOT cloth since that's handled above)
            elseif self:IsDisenchantingResult(lootName or "") then
                shouldLoot = true
                lootReason = "disenchanting material"
                self:VerboseDebugPrint("Disenchanting material detected: " .. (lootName or "Unknown"))
            -- Check if it meets rarity requirements (only for non-crafting scenarios)
            elseif self:ShouldLootItem(itemLink) then
                shouldLoot = true
                lootReason = "meets rarity requirement"
            end
            
            if shouldLoot then
                local itemName = GetItemInfo(itemLink) or lootName or "Unknown"
                self:DebugPrint("Auto-looting item: " .. itemLink .. " (" .. lootReason .. ", Quality: " .. (quality or 0) .. ")")
                LootSlot(i)
                itemsLooted = itemsLooted + 1
                -- Start checking for soulbound confirmation dialog
                self:StartSoulboundConfirmationCheck()
            else
                local reason = "below rarity threshold"
                if self:IsItemSoulbound(itemLink) then
                    reason = "soulbound"
                end
                self:VerboseDebugPrint("Skipping item: " .. (lootName or "Unknown") .. 
                                     " (Reason: " .. reason .. ", Quality: " .. (quality or 0) .. ")")
            end
        else
            -- No itemLink - could be currency, quest items, or other special items
            -- In crafting scenarios or with disenchant results, be more lenient
            if isCraftingScenario or hasDisenchantResults or self:IsDisenchantingResult(lootName or "") then
                self:DebugPrint("Auto-looting crafting/disenchanting result: " .. (lootName or "Unknown"))
                LootSlot(i)
                itemsLooted = itemsLooted + 1
            else
                self:VerboseDebugPrint("No itemLink for: " .. (lootName or "Unknown") .. " - skipping to be safe")
            end
        end
    end
    
    -- Close loot window after a short delay to allow looting to complete
    if itemsLooted > 0 then
        self:DebugPrint("Looted " .. itemsLooted .. " items, closing loot window")
        C_Timer.After(0.3, function()
            if LootFrame and LootFrame:IsVisible() then
                CloseLoot()
                self:VerboseDebugPrint("Loot window closed")
            end
        end)
    else
        self:VerboseDebugPrint("No items looted, leaving loot window open")
    end
end

-- Start a timer to check for soulbound confirmation dialogs
function RR:StartSoulboundConfirmationCheck()
    local checkCount = 0
    local maxChecks = 10 -- Check for 2 seconds (10 * 0.2s)
    
    local function checkTimer()
        checkCount = checkCount + 1
        if self:AutoConfirmSoulbound() then
            -- Found and clicked confirmation, stop checking
            return
        elseif checkCount >= maxChecks then
            -- Stop checking after max attempts
            return
        else
            -- Continue checking
            C_Timer.After(0.2, checkTimer)
        end
    end
    
    -- Start the first check with a small delay
    C_Timer.After(0.1, checkTimer)
end

-- Handle group loot rolling
function RR:HandleGroupLoot(rollID)
    if not RarityRadarDB.enabled or not RarityRadarDB.autoGreedEnabled then return end
    
    local texture, name, count, quality, bindType = GetLootRollItemInfo(rollID)
    
    if quality and quality >= RarityRadarDB.minRarity then
        local itemLink = GetLootRollItemLink(rollID)
        self:DebugPrint("Auto-greeding: " .. (itemLink or name or "Unknown"))
        RollOnLoot(rollID, 2) -- 2 = Greed
    else
        self:DebugPrint("Passing on: " .. (name or "Unknown") .. " (rarity: " .. (quality or 0) .. ")")
        RollOnLoot(rollID, 0) -- 0 = Pass
    end
end

-- Get rarity name from number
function RR:GetRarityName(rarity)
    local names = {
        [RARITY.POOR] = "Poor (Gray)",
        [RARITY.COMMON] = "Common (White)", 
        [RARITY.UNCOMMON] = "Uncommon (Green)",
        [RARITY.RARE] = "Rare (Blue)",
        [RARITY.EPIC] = "Epic (Purple)",
        [RARITY.LEGENDARY] = "Legendary (Orange)",
        [RARITY.ARTIFACT] = "Artifact (Red)"
    }
    return names[rarity] or "Unknown"
end

-- Slash command handlers
function RR:HandleSlashCommand(input)
    local args = {}
    for arg in string.gmatch(input, "%S+") do
        table.insert(args, string.lower(arg))
    end
    
    local command = args[1]
    
    if not command or command == "help" then
        self:Print("Commands:")
        print("  /rr enable/disable - Toggle addon on/off")
        print("  /rr rarity <level> - Set minimum rarity (0-5: poor, common, uncommon, rare, epic, legendary)")
        print("  /rr greed enable/disable - Toggle auto-greed in groups")
        print("  /rr confirm enable/disable - Toggle auto-confirm soulbound dialogs")
        print("  /rr cloth enable/disable - Toggle auto-loot cloth items")
        print("  /rr status - Show current settings")
        print("  /rr debug - Toggle debug mode")
        print("  /rr verbose - Toggle verbose debug mode (very detailed)")
        print("  /rr test - Test loot detection on current target")
        print("  /rr testloot - Analyze current loot window (open loot window first)")
        print("Note: Crafting/disenchanting results are always auto-looted regardless of rarity")
        
    elseif command == "enable" then
        RarityRadarDB.enabled = true
        self:Print("Addon enabled")
        
    elseif command == "disable" then
        RarityRadarDB.enabled = false
        self:Print("Addon disabled")
        
    elseif command == "rarity" then
        local level = tonumber(args[2])
        if level and level >= 0 and level <= 6 then
            RarityRadarDB.minRarity = level
            self:Print("Minimum rarity set to: " .. self:GetRarityName(level))
        else
            self:Print("Invalid rarity level. Use 0-5 (0=Poor, 1=Common, 2=Uncommon, 3=Rare, 4=Epic, 5=Legendary)")
        end
        
    elseif command == "greed" then
        if args[2] == "enable" then
            RarityRadarDB.autoGreedEnabled = true
            self:Print("Auto-greed enabled")
        elseif args[2] == "disable" then
            RarityRadarDB.autoGreedEnabled = false
            self:Print("Auto-greed disabled")
        else
            self:Print("Use: /rr greed enable or /rr greed disable")
        end
        
    elseif command == "confirm" then
        if args[2] == "enable" then
            RarityRadarDB.autoConfirmSoulbound = true
            self:Print("Auto-confirm soulbound dialogs enabled")
        elseif args[2] == "disable" then
            RarityRadarDB.autoConfirmSoulbound = false
            self:Print("Auto-confirm soulbound dialogs disabled")
        else
            self:Print("Use: /rr confirm enable or /rr confirm disable")
        end
        
    elseif command == "cloth" then
        if args[2] == "enable" then
            RarityRadarDB.lootCloth = true
            self:Print("Auto-loot cloth items enabled")
        elseif args[2] == "disable" then
            RarityRadarDB.lootCloth = false
            self:Print("Auto-loot cloth items disabled")
        else
            self:Print("Use: /rr cloth enable or /rr cloth disable")
        end
        
    elseif command == "status" then
        self:Print("Status:")
        print("  Enabled: " .. (RarityRadarDB.enabled and "Yes" or "No"))
        print("  Minimum Rarity: " .. self:GetRarityName(RarityRadarDB.minRarity))
        print("  Auto-Greed: " .. (RarityRadarDB.autoGreedEnabled and "Yes" or "No"))
        print("  Auto-Confirm Soulbound: " .. (RarityRadarDB.autoConfirmSoulbound and "Yes" or "No"))
        print("  Auto-Loot Cloth: " .. (RarityRadarDB.lootCloth and "Yes" or "No"))
        print("  Auto-Loot Crafting Results: Always enabled")
        print("  Debug Mode: " .. (RarityRadarDB.debug and "Yes" or "No"))
        print("  Verbose Debug: " .. (RarityRadarDB.verboseDebug and "Yes" or "No"))
        
    elseif command == "debug" then
        RarityRadarDB.debug = not RarityRadarDB.debug
        self:Print("Debug mode: " .. (RarityRadarDB.debug and "Enabled" or "Disabled"))
        
    elseif command == "verbose" then
        RarityRadarDB.verboseDebug = not RarityRadarDB.verboseDebug
        self:Print("Verbose debug mode: " .. (RarityRadarDB.verboseDebug and "Enabled" or "Disabled"))
        
    elseif command == "test" then
        self:Print("Testing loot detection...")
        if UnitExists("target") and UnitIsDead("target") then
            self:Print("Target corpse detected. Try looting to test the addon.")
        else
            self:Print("No valid target corpse found. Target a lootable corpse and try again.")
        end
        
    elseif command == "testloot" then
        self:Print("Manual loot analysis:")
        local numLootItems = GetNumLootItems()
        if numLootItems == 0 then
            self:Print("No loot window open or no items to loot.")
        else
            for i = 1, numLootItems do
                local lootIcon, lootName, lootQuantity, lootSlotType, quality, locked = GetLootSlotInfo(i)
                local itemLink = GetLootSlotLink(i)
                local isCurrency = self:IsLootSlotCurrency(i)
                print("Slot " .. i .. ": " .. (lootName or "Unknown") .. 
                      " | Quality: " .. tostring(quality) .. 
                      " | HasLink: " .. tostring(itemLink ~= nil) .. 
                      " | IsCurrency: " .. tostring(isCurrency))
            end
        end
        
    else
        self:Print("Unknown command. Type /rr help for available commands.")
    end
end

-- Create main frame for event handling
local frame = CreateFrame("Frame", "RarityRadarFrame")

-- Event handler
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == addonName then
            RR:InitializeDB()
            RR:Print("Loaded! Auto-loots currency + items " .. RR:GetRarityName(RarityRadarDB.minRarity) .. "+ (non-soulbound). Type /rr help for commands.")
            RR:DebugPrint("Debug mode active")
            RR:VerboseDebugPrint("Verbose debug mode active")
        end
        
    elseif event == "LOOT_OPENED" then
        -- Small delay to ensure loot info is available
        C_Timer.After(0.2, function() RR:HandleAutoLoot() end)
        
    elseif event == "START_LOOT_ROLL" then
        local rollID = ...
        -- Small delay to ensure roll info is available  
        C_Timer.After(0.2, function() RR:HandleGroupLoot(rollID) end)
        
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unitID, spellName = ...
        if unitID == "player" then
            RR:OnSpellCast(spellName)
        end
    end
end)

-- Register events
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("LOOT_OPENED")
frame:RegisterEvent("START_LOOT_ROLL")
frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
frame:RegisterEvent("ADDON_ACTION_BLOCKED")
frame:RegisterEvent("ADDON_ACTION_FORBIDDEN")

-- Register slash commands
SLASH_RARITYRADAR1 = "/rr"
SLASH_RARITYRADAR2 = "/rarityradar"
SlashCmdList["RARITYRADAR"] = function(input) RR:HandleSlashCommand(input) end