stateHelper = require("stateHelper")
local BaseWorld = class("BaseWorld")

function BaseWorld:__init(test)

    self.data =
    {
        general = {
            currentMpNum = 0
        },
        journal = {},
        factionRanks = {},
        factionExpulsion = {},
        factionReputation = {},
        topics = {},
        kills = {}
    };
end

function BaseWorld:HasEntry()
    return self.hasEntry
end

function BaseWorld:GetCurrentMpNum()
    return self.data.general.currentMpNum
end

function BaseWorld:SetCurrentMpNum(currentMpNum)
    self.data.general.currentMpNum = currentMpNum
    self:Save()
end

function BaseWorld:SaveJournal(pid)
    stateHelper:SaveJournal(pid, self)
end

function BaseWorld:SaveFactionRanks(pid)
    stateHelper:SaveFactionRanks(pid, self)
end

function BaseWorld:SaveFactionExpulsion(pid)
    stateHelper:SaveFactionExpulsion(pid, self)
end

function BaseWorld:SaveFactionReputation(pid)
    stateHelper:SaveFactionReputation(pid, self)
end

function BaseWorld:SaveTopics(pid)

    for i = 0, tes3mp.GetTopicChangesSize(pid) - 1 do

        local topicId = tes3mp.GetTopicId(pid, i)

        if tableHelper.containsValue(self.data.topics, topicId) == false then
            table.insert(self.data.topics, topicId)
        end
    end

    self:Save()
end

function BaseWorld:SaveKills(pid)

    for i = 0, tes3mp.GetKillChangesSize(pid) - 1 do

        local refId = tes3mp.GetKillRefId(pid, i)
        local number = tes3mp.GetKillNumber(pid, i)
        self.data.kills[refId] = number
    end

    self:Save()
end

function BaseWorld:LoadJournal(pid)
    stateHelper:LoadJournal(pid, self)
end

function BaseWorld:LoadFactionRanks(pid)
    stateHelper:LoadFactionRanks(pid, self)
end

function BaseWorld:LoadFactionExpulsion(pid)
    stateHelper:LoadFactionExpulsion(pid, self)
end

function BaseWorld:LoadFactionReputation(pid)
    stateHelper:LoadFactionReputation(pid, self)
end

function BaseWorld:LoadTopics(pid)

    tes3mp.InitializeTopicChanges(pid)

    for index, topicId in pairs(self.data.topics) do

        tes3mp.AddTopic(pid, topicId)
    end

    tes3mp.SendTopicChanges(pid)
end

function BaseWorld:LoadKills(pid)

    tes3mp.InitializeKillChanges(pid)

    for refId, number in pairs(self.data.kills) do

        tes3mp.AddKill(pid, refId, number)
    end

    tes3mp.SendKillChanges(pid)
end

return BaseWorld
