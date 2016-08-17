local LIP = require 'LIP';

local Player = {}
Player.__index = Player

setmetatable(Player, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function Player.new(pid)
    local self = setmetatable({}, Player)
    self.data =
    {
		general = {
			name = "",
			password = "",
			admin = 0,
		},
		character = {
			race = "",
			head = "",
			hair = "",
			sex = false,
--			class = "",
		},
		stats = {
			level = 1,
			healthBase = 1,
			healthCurrent = 1,
			magickaBase = 1,
			magickaCurrent = 1,
			fatigueBase = 1,
			fatigueCurrent = 1,
		},
		attributes = {
			strength = 1,
			intelligence = 1,
			willpower = 1,
			agility = 1,
			speed = 1,
			endurance = 1,
			personality = 1,
			luck = 1,
		},
		skills = {
			-- Combat
			armorer = 1,
			athletics = 1,
			axe = 1,
			block = 1,
			bluntWeapon = 1,
			heavyArmor = 1,
			longBlade = 1,
			mediumArmor = 1,
			spear = 1,
			-- Magic
			alchemy = 1,
			alteration = 1,
			conjuration = 1,
			destruction = 1,
			enchant = 1,
			illusion = 1,
			mysticism = 1,
			restoration = 1,
			unarmored = 1,
			-- Stealth
			acrobatics = 1,
			handToHand = 1,
			lightArmor = 1,
			marksman = 1,
			mercantile = 1,
			security = 1,
			shortBlade = 1,
			sneak = 1,
			speechcraft = 1,
		},
    };
	self.accountName = tes3mp.GetName(pid)..".txt"
	self.pid = pid
	self.loggedOn = false
	self.tid_login = nil
	self.admin = 0
	self.hasAccount = nil -- TODO Check account file exists
	return self
end

function Player:Destroy()
    if self.tid_login ~= nil then
        tes3mp.StopTimer(self.tid_login)
		self.tid_login = nil
	end
	if self.loggedOn and self.hasAccount then
		print("Saving player...")
		self:Save()
	end
	self.loggedOn = false
	self.hasAccount = nil
end

function Player:Kick()
	self:Destroy()
	tes3mp.Kick(self.pid)
end

function Player:Registered(passw)
	self.loggedOn = true
	self.data.general.password = passw
	if self.hasAccount == false then -- create account
		tes3mp.SetCharGenStage(self.pid, 1, 4)
	end
end

function Player:LoggedOn()
	self.loggedOn = true
	if self.hasAccount ~= false then -- load account
		self:LoadCharacter()
		self:LoadAttributes()
		self:LoadSkills()
	end
end

function Player:IsLoggedOn()
    return self.loggedOn
end

function Player:IsAdmin()
	return self.data.general.admin == 2
end

function Player:IsModerator()
	return self.data.general.admin == 1
end

function Player:PromoteModerator(other)
	if self.IsAdmin() then
		other.data.general.admin = 1
		return true
	end
	return false
end

function Player:GetHealth()
	self.data.stats.healthCurrent = tes3mp.GetHealth(self.pid)
	return self.data.stats.healthCurrent
end

function Player:SetHealth(health)
	self.data.stats.healthCurrent = health
	tes3mp.SetHealth(self.pid, health)
end

function Player:GetMaxHealth()
	self.data.stats.healthBase = tes3mp.GetBaseHealth(self.pid)
	return self.data.stats.healthBase
end

function Player:SetMaxHealth(health)
	self.data.stats.healthBase = health
	tes3mp.SetMaxHealth(self.pid, health)
end

function Player:HasAccount()
	if self.hasAccount == nil then
		local home = os.getenv("MOD_DIR").."/"
		local file = io.open(home..self.accountName, "r")
		if file ~= nil then
			io.close()
			self.hasAccount = true
		else
			self.hasAccount = false
		end
	end
	return self.hasAccount
end

function Player:Message(message)
	tes3mp.SendMessage(self.pid, message, 0)
end

function Player:CreateAccount()
	LIP.save(self.accountName, self.data)
	self.hasAccount = true
end

function Player:Save()
	if self.hasAccount and self.loggedOn then
		LIP.save(self.accountName, self.data)
	end
end

function Player:Load()
	self.data = LIP.load(self.accountName)
end

function Player:UpdateGeneral()
	self.data.general.name = tes3mp.GetName(self.pid)
end

function Player:UpdateCharacter()
	self.data.character.race = tes3mp.GetRace(self.pid)
	self.data.character.head = tes3mp.GetHead(self.pid)
	self.data.character.hair = tes3mp.GetHair(self.pid)
	self.data.character.sex = tes3mp.GetIsMale(self.pid)
--	self.data.character.class = tes3mp.GetClass(self.pid)
end

function Player:LoadCharacter()
	tes3mp.SetRace(self.pid,self.data.character.race)
	tes3mp.SetHead(self.pid,self.data.character.head)
	tes3mp.SetHair(self.pid,self.data.character.hair)
	tes3mp.SetIsMale(self.pid,self.data.character.sex)
	tes3mp.SendBaseInfo(self.pid)
--	tes3mp.GetClass(self.pid,self.data.character.class)
end

function Player:UpdateAttributes()
	for name--[[,value--]] in pairs(self.data.attributes) do
		self.data.attributes[name] = tes3mp.GetAttribute(self.pid, tes3mp.GetAttributeIdByName(name))
	end
end

function Player:LoadAttributes()
	for name,value in pairs(self.data.attributes) do
		print(name .. "=="..tostring(value))
		tes3mp.SetAttribute(self.pid, tes3mp.GetAttributeIdByName(name), value)
	end

	tes3mp.SendAttributes(self.pid)
end

function Player:SetAttribute(attribute, newValue)
	for name--[[,value--]] in pairs(self.data.attributes) do
		if name == attribute then
			self.data.attributes[name] = newValue
			tes3mp.SetAttribute(self.pid, tes3mp.GetAttributeIdByName(name), newValue)
			break
		end
	end
end

function Player:UpdateSkills()
	for name--[[,value--]] in pairs(self.data.skills) do
		self.data.skills[name] = tes3mp.GetSkill(self.pid, tes3mp.GetSkillIdByName(name))
	end
end

function Player:LoadSkills()
	for name,value in pairs(self.data.skills) do
		tes3mp.SetSkill(self.pid, tes3mp.GetSkillIdByName(name), value)
	end

	tes3mp.SendSkills(self.pid)
end

function Player:GetAttribute(attribute)
	return self.data.attributes[attribute]
end

return Player
