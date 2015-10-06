------------------------------------------------------------------------------------------------
--  1Version ver. @project-version@
--  Authored by Chrono Syz -- Entity-US / Wildstar
--  Build @project-hash@
--  Copyright (c) Chronosis. All rights reserved
--
--  https://github.com/chronosis/1Version
------------------------------------------------------------------------------------------------
-- 1Version.lua
------------------------------------------------------------------------------------------------

require "Window"
require "GroupLib"
require "ChatSystemLib"
require "ICComm"

-----------------------------------------------------------------------------------------------
-- OneVersion Module Definition
-----------------------------------------------------------------------------------------------
local OneVersion = {}
local Utils = Apollo.GetPackage("SimpleUtils-1.0").tPackage

-----------------------------------------------------------------------------------------------
-- OneVersion Enums
-----------------------------------------------------------------------------------------------
OneVersion.CodeEnumAddonSuffixLevel = {
  Alpha = -2,
  Beta = -1,
  None = 0,
  LetterA = 1,
  LetterB = 2,
  LetterC = 3,
  LetterD = 4,
  LetterE = 5,
  LetterF = 6,
  LetterG = 7,
  LetterH = 8,
  LetterI = 9,
  LetterJ = 10,
  LetterK = 11,
  LetterL = 12,
  LetterM = 13,
  LetterN = 14,
  LetterO = 15,
  LetterP = 16,
  LetterQ = 17,
  LetterR = 18,
  LetterS = 19,
  LetterT = 20,
  LetterU = 21,
  LetterV = 22,
  LetterW = 23,
  LetterX = 24,
  LetterY = 25,
  LetterZ = 26
}

OneVersion.CodeEnumAddonSuffixMap = {
  ["0"] = "",  -- To account for LUA stupidity with indexing the zero-index
  [-2] = "α",
  [-1] = "β",
  [0] = "",
  [1] = "a",
  [2] = "b",
  [3] = "c",
  [4] = "d",
  [5] = "e",
  [6] = "f",
  [7] = "g",
  [8] = "h",
  [9] = "i",
  [10] = "j",
  [11] = "k",
  [12] = "l",
  [13] = "m",
  [14] = "n",
  [15] = "o",
  [16] = "p",
  [17] = "q",
  [18] = "r",
  [19] = "s",
  [20] = "t",
  [21] = "u",
  [22] = "v",
  [23] = "w",
  [24] = "x",
  [25] = "y",
  [26] = "z"
}

OneVersion.CommInfo = {
  CommAttemptDelay = 3,           -- The delay between attempts to load channel
  MaxCommAttempts = 10,           -- The number of attempts made to connect to Comm Channel before abandoning
  CommChannelName = "OneVersion", -- The channel name
  CommChannelTimer = nil
}

-----------------------------------------------------------------------------------------------
-- OneVersion constants
-----------------------------------------------------------------------------------------------
-- The number of attempts made to connect to Comm Channel before abandoning
local CommAttemptDelay = 3 -- The delay between attempts to load channel
local MaxCommAttempts = 10 -- The number of attempts made to connect to Comm Channel before abandoning
local CommChannelName = "OneVersion" -- The channel name
local CommChannelTimer = nil

local Major, Minor, Patch, Suffix = 1, 5, 0, 0
local ONEVERSION_CURRENT_VERSION = string.format("%d.%d.%d%s", Major, Minor, Patch, OneVersion.CodeEnumAddonSuffixMap[Suffix])

local tDefaultSettings = {
  version = ONEVERSION_CURRENT_VERSION,
  user = {
    debug = false,
    unlocked = false
  },
  positions = {
    main = nil,
    alert = nil
  },
  options = {
  }
}

local tDefaultState = {
  isOpen = false,
  isAlerted = false,
  isLoaded = false,
  windows = {           -- These store windows for lists
    main = nil,
    options = nil,
    addonList = nil,
    alert = nil,
    moveWindow = nil
  },
  listItems = {         -- These store windows for lists
    addons = {},
  },
  channel = {
    attemptsCount = 0,
    timerActive = false,
    ready = false
  },
  trackedAddons = {},
  messageQueue = {},
  updateCount = 0
}


-----------------------------------------------------------------------------------------------
-- OneVersion Constructor
-----------------------------------------------------------------------------------------------
function OneVersion:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self

  -- Saved and Restored values are stored here.
  o.settings = shallowcopy(tDefaultSettings)
  -- Volatile values are stored here. These are impermenant and not saved between sessions
  o.state = shallowcopy(tDefaultState)

  return o
end

-----------------------------------------------------------------------------------------------
-- OneVersion Init
-----------------------------------------------------------------------------------------------
function OneVersion:Init()
  local bHasConfigureFunction = true
  local strConfigureButtonText = "OneVersion"
  local tDependencies = {
    -- "UnitOrPackageName",
  }
  Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)

  self.settings = shallowcopy(tDefaultSettings)
  -- Volatile values are stored here. These are impermanent and not saved between sessions
  self.state = shallowcopy(tDefaultState)
end

-----------------------------------------------------------------------------------------------
-- OneVersion OnLoad
-----------------------------------------------------------------------------------------------
function OneVersion:OnLoad()
  Apollo.LoadSprites("1VersionSprites.xml")

  self.xmlDoc = XmlDoc.CreateFromFile("1Version.xml")
  self.xmlDoc:RegisterCallback("OnDocLoaded", self)
  self.state.timerActive = true

  Apollo.RegisterEventHandler("Generic_ToggleOneVersion", "OnToggleOneVersion", self)
  Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", "OnInterfaceMenuListHasLoaded", self)

  -- When someone joins the group
  Apollo.RegisterEventHandler("Group_Add","OnGroupAdd", self)					-- ( name )
  Apollo.RegisterEventHandler("Group_Join","OnGroupJoin", self)				-- ()

  -- When an addon reports the version
  Apollo.RegisterEventHandler("OneVersion_ReportAddonInfo",	"OnAddonReportInfo", self)
end

-----------------------------------------------------------------------------------------------
-- OneVersion OnDocLoaded
-----------------------------------------------------------------------------------------------
function OneVersion:OnDocLoaded()
  if self.xmlDoc == nil then
    return
  end

  self.shareChannel = nil

  self.state.windows.main = Apollo.LoadForm(self.xmlDoc, "OneVersionWindow", nil, self)
  self.state.windows.addonList = self.state.windows.main:FindChild("ItemList")

  self.state.windows.alert = Apollo.LoadForm(self.xmlDoc, "AlertWindow", nil, self)
  self.state.windows.moveWindow = self.state.windows.alert:FindChild("UnlockInfo")

  self.state.windows.main:Show(false)
  self.state.windows.alert:Show(false)

  Apollo.RegisterSlashCommand("onever", "OnSlashCommand", self)

  -- Setup Comms
  Apollo.RegisterTimerHandler("OneVersion_UpdateCommChannel", "UpdateCommChannel", self)
  CommChannelTimer = ApolloTimer.Create(5, false, "UpdateCommChannel", self) -- make sure everything is loaded, so after 5sec

  -- Rebuild List Items and refreshUI
  self.state.isLoaded = true
  self:RestoreLocations()
  self:RebuildAddonListItems()
end

-----------------------------------------------------------------------------------------------
-- OneVersion OnSlashCommand
-----------------------------------------------------------------------------------------------
-- Handle slash commands
function OneVersion:OnSlashCommand(cmd, params)
  args = params:lower():split("[ ]+")

  if args[1] == "debug" then
    self:ToggleDebug()
  elseif args[1] == "show" then
    self:OnToggleOneVersion()
  elseif args[1] == "defaults" then
    self:LoadDefaults()
  elseif args[1] == "rejoin" then
    self.state.shareChannel = nil
    self.state.channel.attemptsCount = 0
    self:UpdateCommChannel()
  elseif args[1] == "broadcast" then
    self:BroadcastAddons(self:GetPlayerName())
  else
    Utils:cprint("OneVersion v" .. self.settings.version)
    Utils:cprint("Usage:  /onever <command>")
    Utils:cprint("============================================")
    Utils:cprint("   show           Open Rules Window")
    Utils:cprint("   debug          Toggle Debug")
    Utils:cprint("   defaults       Loads defaults")
    Utils:cprint("   rejoin         Force rejoin comms channel")
    Utils:cprint("   broadcast      Force broadcast addons")
  end
end

-----------------------------------------------------------------------------------------------
-- OneVersion OnInterfaceMenuListHasLoaded
-----------------------------------------------------------------------------------------------
function OneVersion:OnInterfaceMenuListHasLoaded()
  Event_FireGenericEvent("InterfaceMenuList_NewAddOn", "OneVersion", {"Generic_ToggleOneVersion", "", "OneVersionSprites:OneIcon"})

  -- Report Self
  Event_FireGenericEvent("OneVersion_ReportAddonInfo", "OneVersion", Major, Minor, Patch, Suffix, false)
end

-----------------------------------------------------------------------------------------------
-- OneVersion ProcessOptions
-----------------------------------------------------------------------------------------------
function OneVersion:ProcessOptions()

end

function OneVersion:UpdateOther(mine, other)
  if tonumber(other.major) > tonumber(mine.major) then
    mine.major = other.major
    mine.minor = other.minor
    mine.patch = other.patch
    mine.suffix = other.suffix
  elseif (tonumber(other.major) == tonumber(mine.major) and tonumber(other.minor) > tonumber(mine.minor)) then
    mine.minor = other.minor
    mine.patch = other.patch
    mine.suffix = other.suffix
  elseif (tonumber(other.major) == tonumber(mine.major) and tonumber(other.minor) == tonumber(mine.minor) and tonumber(other.patch) > tonumber(mine.patch)) then
    mine.patch = other.patch
    mine.suffix = other.suffix
  elseif (tonumber(other.major) == tonumber(mine.major) and tonumber(other.minor) == tonumber(mine.minor) and tonumber(other.patch) == tonumber(mine.patch) and tonumber(other.suffix) > tonumber(mine.suffix)) then
    mine.suffix = other.suffix
  end
end

function OneVersion:RequireUpgrade(mine, other)
  if tonumber(mine.major) < tonumber(other.major) then
    return true
  end

  if tonumber(mine.minor) < tonumber(other.minor) then
    return true
  end

  if tonumber(mine.patch) < tonumber(other.patch) then
    return true
  end

  if tonumber(mine.suffix) < tonumber(other.suffix) then
    return true
  end

  return false
end

-----------------------------------------------------------------------------------------------
-- OneVersion OnReceiveAddonInfo
-----------------------------------------------------------------------------------------------
function OneVersion:OnGroupAdd( name )
  -- Broadcast a message to the channel announcing all addon versions.
  self:BroadcastAddons(name)
end

function OneVersion:OnGroupJoin() -- I joined a group
  -- Broadcast a message to the channel announcing all addon versions.
  local name = self:GetPlayerName()
  self:BroadcastAddons(name)
end

function OneVersion:BroadcastAddons(name)
  for key,value in pairs(self.state.trackedAddons) do
    msg = self:AddonInfoToMessage(name, value)
    self:SendMessage(msg)
  end
end

function OneVersion:GetAddonInfoFromMessage(msg)
  local parts = msg:split("|")
  local t = {
    label = parts[2],
    type = parts[3],
    major = parts[4],
    minor = parts[5],
    patch = parts[6],
    suffix = parts[7]
  }
  return parts[1], t
end

function OneVersion:AddonInfoToMessage(name,addonInfo)
  return string.format("%s|%s|%s|%d|%d|%d|%d", name, addonInfo.label, addonInfo.type, addonInfo.mine.major, addonInfo.mine.minor, addonInfo.mine.patch, addonInfo.mine.suffix)
  --return name .. "|" .. addonInfo.label .. "|" .. addonInfo.type .. "|" .. addonInfo.mine.major .. "|" .. addonInfo.mine.minor .. "|" .. addonInfo.mine.patch .. "|" .. addonInfo.mine.suffix
end

-----------------------------------------------------------------------------------------------
-- OneVersion OnReceiveAddonInfo
-----------------------------------------------------------------------------------------------
function OneVersion:OnReceiveAddonInfo(chan, msg)
  self:DBPrint("(ReceiveMessage) " .. msg)

  -- Read addon information
  local name,addon = self:GetAddonInfoFromMessage(msg)
  local alertRequired = false

  -- Update addon and check/compare version info
  -- Only update addons we're already watching
  if self.state.trackedAddons[addon.label] then
    self:UpdateOther(self.state.trackedAddons[addon.label].reported, addon)
    local upgrade = self:RequireUpgrade(self.state.trackedAddons[addon.label].mine, self.state.trackedAddons[addon.label].reported)
    self.state.trackedAddons[addon.label].upgrade = upgrade
    if upgrade then
      alertRequired = true
    end

    if alertRequired then
      self.state.isAlerted = true
      self:ShowAlert()
      self:ProcessLock()
    end
  end
  if self.state.isLoaded == true then
    self:RebuildAddonListItems()
  end
end

function OneVersion:RecalculateOutdatedCount()
  self.state.updateCount = 0
  for k,v in pairs(self.state.trackedAddons) do
    if v.upgrade == true then
      self.state.updateCount = self.state.updateCount + 1
    end
  end
end

-----------------------------------------------------------------------------------------------
-- OneVersion Communication Logic
-----------------------------------------------------------------------------------------------
function OneVersion:UpdateCommChannel()
  if not self.shareChannel then
    self:DBPrint(" InitComms")
    self.shareChannel = ICCommLib.JoinChannel(CommChannelName, ICCommLib.CodeEnumICCommChannelType.Group)
    self.shareChannel:SetJoinResultFunction("OnCommJoin", self)
  end

  if self.shareChannel:IsReady() then
    self:DBPrint(" Channel is ready." )
    self.shareChannel:SetReceivedMessageFunction("OnReceiveAddonInfo", self)
    self.shareChannel:SetSendMessageResultFunction("OnMessageSent", self)
    self.shareChannel:SetThrottledFunction("OnChannelThrottle", self)
    self.state.channel.ready = true

    -- Check the message queue and push waiting messages
    while #self.state.messageQueue > 0 do
      self:SendMessage(self.state.messageQueue[1])
      table.remove(self.state.messageQueue, 1)
    end
  else
    self:DBPrint(" Channel is not ready, retrying.")
    -- Channel not ready yet, repeat in a few seconds
    if self.state.channel.attemptsCount < MaxCommAttempts then
      self.state.timerActive = true
      Apollo.CreateTimer("OneVersion_UpdateCommChannel", CommAttemptDelay, false)
      Apollo.StartTimer("OneVersion_UpdateCommChannel")
    else
      -- Comms disabled, send alert
      self.state.timerActive = false
      Utils:cprint("[OneVersion] Could not initialize comm channel.  Group Comm channels appear to be disabled -- please open a ticket with Carbine.")
    end
    -- Increment the number of attempts
    self.state.channel.attemptsCount = self.state.channel.attemptsCount + 1
  end
end

function OneVersion:SendMessage(msg)
  self:DBPrint("(SendMessage) " .. msg )
  if not self.shareChannel or not self.state.channel.ready then
    -- Reinitialize only if the timer is not active
    if not self.state.timerActive then
      self:DBPrint(" Error sending Addon info. Attempting to fix this now.")
      -- Attempt to re-initialize chanel
      self.state.channel.attemptsCount = 0
      self:UpdateCommChannel()
    end
    -- Queue the message
    table.insert(self.state.messageQueue, msg)
    return false
  else
    self:DBPrint("(Sent)")
    return self.shareChannel:SendMessage(msg)
  end
end

function OneVersion:OnCommJoin(channel, eResult)
  self:DBPrint( string.format("(JoinResult) %s:%s", channel:GetName(), tostring(eResult)) )
end

function OneVersion:OnMessageSent(channel, eResult, idMessage)
  self:DBPrint( string.format("(MessageResult) %s:%s", channel:GetName(), tostring(eResult)) )
end

function OneVersion:OnChannelThrottle(channel, strSender, idMessage)
  self:DBPrint( string.format("(ChannelThrottle) %s:%s:%s", channel:GetName(), strSender, tostring(idMessage) ) )
end
-----------------------------------------------------------------------------------------------
-- OneVersion OnAddonReportInfo
-----------------------------------------------------------------------------------------------
function OneVersion:OnAddonReportInfo(name, major, minor, patch, suffix, isLib)
  -- Drop out if name or major number isn't provided
  if not name or not major or name == "" then
    return
  end

  local addonInfo = self:GetBaseAddonInfo()

  local atype = ""
  local minr = (tonumber(minor) or 0)
  local ptch = (tonumber(patch) or 0)
  local sufx = (tonumber(suffix) or 0)
  if type(isLib) ~= "boolean" then
    isLib = false
  end
  local lib = (isLib or false)

  self:DBPrint( "(AddonReport) " .. string.format("%s|%d|%d|%d|%d|%s", name, major, minr, ptch, sufx, tostring(lib)) )

  if lib == true then
    atype = "Library"
  else
    atype = "Add-On"
  end

  addonInfo.label = name
  addonInfo.type = atype
  addonInfo.mine.major = major
  addonInfo.reported.major = major
  addonInfo.mine.minor = minr
  addonInfo.reported.minor = minr
  addonInfo.mine.patch = ptch
  addonInfo.reported.patch = ptch
  addonInfo.mine.suffix = sufx
  addonInfo.reported.suffix = sufx
  addonInfo.upgrade = false

  self.state.trackedAddons[name] = addonInfo

  local playerName = self:GetPlayerName()
  if self.state.isLoaded == true then
    self:RebuildAddonListItems()
  end

  self:BroadcastAddons(playerName)
end

-----------------------------------------------------------------------------------------------
-- Save/Restore functionality
-----------------------------------------------------------------------------------------------
function OneVersion:OnSave(eType)
  if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then return end

  return deepcopy(self.settings)
end

function OneVersion:OnRestore(eType, tSavedData)
  if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then return end

  if tSavedData and tSavedData.user then
    -- Copy the settings wholesale
    self.settings = deepcopy(tSavedData)

    -- Fill in any missing values from the default options
    -- This Protects us from configuration additions in the future versions
    for key, value in pairs(tDefaultSettings) do
      if self.settings[key] == nil then
        self.settings[key] = deepcopy(tDefaultSettings[key])
      end
    end

    -- This section is for converting between versions that saved data differently
    if self.settings.version ~= ONEVERSION_CURRENT_VERSION then
      -- reset main window position
      self.settings.positions.main = nil
    end

    -- Now that we've turned the save data into the most recent version, set it
    self.settings.version = ONEVERSION_CURRENT_VERSION

  else
    self.tConfig = deepcopy(tDefaultOptions)
  end
end

function OneVersion:DBPrint(msg)
  if self.settings.user.debug then
    Utils:debug( "[OneVersion]" .. msg )
  end
end

-----------------------------------------------------------------------------------------------
-- OneVersion Instance
-----------------------------------------------------------------------------------------------
local OneVersionInst = OneVersion:new()
OneVersionInst:Init()
