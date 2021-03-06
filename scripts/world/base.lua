--- World Base
-- @classmod world-base
stateHelper = require("stateHelper")
local BaseWorld = class("BaseWorld")

--- Keep this here because it's required in mathematical operations
BaseWorld.defaultTimeScale = 30

-- Month lengths
BaseWorld.monthLengths = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }

--- stored regions
-- @table BaseWorld.storedRegions
BaseWorld.storedRegions = {}

--- Init function
function BaseWorld:__init()

    self.data =
    {
        general = {
            currentMpNum = 0
        },
        fame = {
            bounty = 0,
            reputation = 0
        },
        journal = {},
        factionRanks = {},
        factionExpulsion = {},
        factionReputation = {},
        topics = {},
        kills = {},
        time = config.defaultTimeTable,
        mapExplored = {},
        customVariables = {}
    }
end

--- Check if world has entry
-- @return bool
function BaseWorld:HasEntry()
    return self.hasEntry
end

--- Ensure time data exists
function BaseWorld:EnsureTimeDataExists()

    if self.data.time == nil then
        self.data.time = config.defaultTimeTable
    end
end

--- Get region visitor count
-- @string regionName
-- @return int visitor count
function BaseWorld:GetRegionVisitorCount(regionName)

    if self.storedRegions[regionName] == nil then return 0 end

    return tableHelper.getCount(self.storedRegions[regionName].visitors)
end

--- Add region visitor
-- @int pid
-- @string regionName
function BaseWorld:AddRegionVisitor(pid, regionName)

    if self.storedRegions[regionName] == nil then
        self.storedRegions[regionName] = { visitors = {}, forcedWeatherUpdatePids = {} }
    end

    -- Only add new visitor if we don't already have them
    if not tableHelper.containsValue(self.storedRegions[regionName].visitors, pid) then
        table.insert(self.storedRegions[regionName].visitors, pid)
    end
end

--- Remove region visitor
-- @int pid
-- @string regionName
function BaseWorld:RemoveRegionVisitor(pid, regionName)

    local loadedRegion = self.storedRegions[regionName]

    -- Only remove visitor if they are actually recorded as one
    if tableHelper.containsValue(loadedRegion.visitors, pid) then
        tableHelper.removeValue(loadedRegion.visitors, pid)
    end

    -- Additionally, remove the visitor from the forcedWeatherUpdatePids if they
    -- are still in there
    self:RemoveForcedWeatherUpdatePid(pid, regionName)
end

--- Add forced weather update pid
-- @int pid
-- @string regionName
function BaseWorld:AddForcedWeatherUpdatePid(pid, regionName)

    local loadedRegion = self.storedRegions[regionName]
    table.insert(loadedRegion.forcedWeatherUpdatePids, pid)
end

--- Remove forced weather update pid
-- @int pid
-- @string regionName
function BaseWorld:RemoveForcedWeatherUpdatePid(pid, regionName)

    local loadedRegion = self.storedRegions[regionName]
    tableHelper.removeValue(loadedRegion.forcedWeatherUpdatePids, pid)
end

--- Is forced wather update pid
-- @int pid
-- @string regionName
function BaseWorld:IsForcedWeatherUpdatePid(pid, regionName)

    local loadedRegion = self.storedRegions[regionName]

    if tableHelper.containsValue(loadedRegion.forcedWeatherUpdatePids, pid) then
        return true
    end

    return false
end

--- Get region Authority
-- @string regionName
-- @return playerName or nil
function BaseWorld:GetRegionAuthority(regionName)

    if self.storedRegions[regionName] ~= nil then
        return self.storedRegions[regionName].authority
    end

    return nil
end

--- Get region Authority
-- @int pid
-- @string regionName
function BaseWorld:SetRegionAuthority(pid, regionName)

    self.storedRegions[regionName].authority = pid
    tes3mp.LogMessage(enumerations.log.INFO, "Authority of region " .. regionName .. " is now " ..
        logicHandler.GetChatName(pid))

    tes3mp.SetAuthorityRegion(regionName)
    tes3mp.SendWorldRegionAuthority(pid)
end

--- Increment day
function BaseWorld:IncrementDay()

    self.data.time.daysPassed = self.data.time.daysPassed + 1

    local day = self.data.time.day
    local month = self.data.time.month

    -- Is the new day higher than the number of days in the current month?
    if day + 1 > self.monthLengths[month] then

        -- Is the new month higher than the number of months in a year?
        if month + 1 > 12 then
            self.data.time.year = self.data.time.year + 1
            self.data.time.month = 1
        else
            self.data.time.month = month + 1
        end

        self.data.time.day = 1
    else

        self.data.time.day = day + 1
    end
end

--- Get current time scale
-- @return timeScale
function BaseWorld:GetCurrentTimeScale()

    if self.data.time.dayTimeScale == nil then self.data.time.dayTimeScale = self.defaultTimeScale end
    if self.data.time.nightTimeScale == nil then self.data.time.nightTimeScale = self.defaultTimeScale end

    if self.data.time.hour >= config.nightStartHour or self.data.time.hour <= config.nightEndHour then
        return self.data.time.nightTimeScale
    else
        return self.data.time.dayTimeScale
    end
end

--- Update frametiem multiplier
function BaseWorld:UpdateFrametimeMultiplier()
    self.frametimeMultiplier = WorldInstance:GetCurrentTimeScale() / WorldInstance.defaultTimeScale
end

--- Get current MpNum
-- @return string currentMpNum
function BaseWorld:GetCurrentMpNum()
    return self.data.general.currentMpNum
end

--- Get current MpNum
-- @string currentMpNum
function BaseWorld:SetCurrentMpNum(currentMpNum)
    self.data.general.currentMpNum = currentMpNum
    self:QuicksaveToDrive()
end

--- Load journal
-- @int pid
function BaseWorld:LoadJournal(pid)
    stateHelper:LoadJournal(pid, self)
end

--- Load faction ranks
-- @int pid
function BaseWorld:LoadFactionRanks(pid)
    stateHelper:LoadFactionRanks(pid, self)
end

--- Load faction expulsions
-- @int pid
function BaseWorld:LoadFactionExpulsion(pid)
    stateHelper:LoadFactionExpulsion(pid, self)
end

--- Load faction reputation
-- @int pid
function BaseWorld:LoadFactionReputation(pid)
    stateHelper:LoadFactionReputation(pid, self)
end

--- Load topics
-- @int pid
function BaseWorld:LoadTopics(pid)
    stateHelper:LoadTopics(pid, self)
end

--- Load bounty
-- @int pid
function BaseWorld:LoadBounty(pid)
    stateHelper:LoadBounty(pid, self)
end

--- Load reputation
-- @int pid
function BaseWorld:LoadReputation(pid)
    stateHelper:LoadReputation(pid, self)
end

--- Load map
-- @int pid
function BaseWorld:LoadMap(pid)
    stateHelper:LoadMap(pid, self)
end

--- Load kills
-- @int pid
-- @bool forEveryone
function BaseWorld:LoadKills(pid, forEveryone)

    tes3mp.ClearKillChanges(pid)

    for refId, killCount in pairs(self.data.kills) do

        tes3mp.AddKill(pid, refId, killCount)
    end

    tes3mp.SendKillChanges(pid, forEveryone)
end

--- Loading region weather
-- @string regionName
-- @int pid
-- @bool forEveryone
-- @param forceState
function BaseWorld:LoadRegionWeather(regionName, pid, forEveryone, forceState)

    local region = self.storedRegions[regionName]

    if region.currentWeather ~= nil then

        tes3mp.SetWeatherRegion(regionName)
        tes3mp.SetWeatherCurrent(region.currentWeather)
        tes3mp.SetWeatherNext(region.nextWeather)
        tes3mp.SetWeatherQueued(region.queuedWeather)
        tes3mp.SetWeatherTransitionFactor(region.transitionFactor)
        tes3mp.SetWeatherForceState(forceState)
        tes3mp.SendWorldWeather(pid, forEveryone)
    else
        tes3mp.LogMessage(enumerations.log.INFO, "Could not load weather in region " .. regionName ..
            " for " .. logicHandler.GetChatName(pid) .. " because we have no weather information for it")
    end
end

--- Load weather
-- @int pid
-- @bool forEveryone
-- @param forceState
function BaseWorld:LoadWeather(pid, forEveryone, forceState)

    for regionName, region in pairs(self.storedRegions) do

        if region.currentWeather ~= nil then
            self:LoadRegionWeather(regionName, pid, forEveryone, forceState)
        end
    end
end

--- Load time
-- @int pid
-- @bool forEveryone
function BaseWorld:LoadTime(pid, forEveryone)

    tes3mp.SetHour(self.data.time.hour)
    tes3mp.SetDay(self.data.time.day)

    -- The first month has an index of 0 in the C++ code, but
    -- table values should be intuitive and range from 1 to 12,
    -- so adjust for that by just going down by 1
    tes3mp.SetMonth(self.data.time.month - 1)

    tes3mp.SetYear(self.data.time.year)

    tes3mp.SetDaysPassed(self.data.time.daysPassed)

    tes3mp.SetTimeScale(self:GetCurrentTimeScale())

    tes3mp.SendWorldTime(pid, forEveryone)
end

--- Save journal
-- @int pid
function BaseWorld:SaveJournal(pid)
    stateHelper:SaveJournal(pid, self)
end

--- Save faction ranks
-- @int pid
function BaseWorld:SaveFactionRanks(pid)
    stateHelper:SaveFactionRanks(pid, self)
end

--- Save faction expulsions
-- @int pid
function BaseWorld:SaveFactionExpulsion(pid)
    stateHelper:SaveFactionExpulsion(pid, self)
end

--- Save faction reputation
-- @int pid
function BaseWorld:SaveFactionReputation(pid)
    stateHelper:SaveFactionReputation(pid, self)
end

--- Save topics
-- @int pid
function BaseWorld:SaveTopics(pid)
    stateHelper:SaveTopics(pid, self)
end

--- Save bounty
-- @int pid
function BaseWorld:SaveBounty(pid)
    stateHelper:SaveBounty(pid, self)
end

--- Save reputation
-- @int pid
function BaseWorld:SaveReputation(pid)
    stateHelper:SaveReputation(pid, self)
end

--- Save kills
-- @int pid
function BaseWorld:SaveKills(pid)

    for index = 0, tes3mp.GetKillChangesSize(pid) - 1 do

        local refId = tes3mp.GetKillRefId(pid, index)
        local number = tes3mp.GetKillNumber(pid, index)
        self.data.kills[refId] = number
    end

    self:QuicksaveToDrive()
end

--- Save region weather
-- @string regionName
function BaseWorld:SaveRegionWeather(regionName)

    local loadedRegion = self.storedRegions[regionName]
    loadedRegion.currentWeather = tes3mp.GetWeatherCurrent()
    loadedRegion.nextWeather = tes3mp.GetWeatherNext()
    loadedRegion.queuedWeather = tes3mp.GetWeatherQueued()
    loadedRegion.transitionFactor = tes3mp.GetWeatherTransitionFactor()
end

--- Save map exploration
-- @int pid
function BaseWorld:SaveMapExploration(pid)
    stateHelper:SaveMapExploration(pid, self)
end

--- Save map tiles
-- @int pid
function BaseWorld:SaveMapTiles(pid)

    tes3mp.ReadReceivedWorldstate()

    for index = 0, tes3mp.GetMapChangesSize() - 1 do

        local cellX = tes3mp.GetMapTileCellX(index)
        local cellY = tes3mp.GetMapTileCellY(index)
        local filename = cellX .. ", " .. cellY .. ".png"

        tes3mp.SaveMapTileImageFile(index, tes3mp.GetDataPath() .. "/map/" .. filename)
    end
end

return BaseWorld
