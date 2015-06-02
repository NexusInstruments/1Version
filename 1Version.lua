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

-----------------------------------------------------------------------------------------------
-- OneVersion constants
-----------------------------------------------------------------------------------------------
local Major, Minor, Patch, Suffix = 1, 1, 0, 0
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
  trackedAddons = {}
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

  Apollo.RegisterEventHandler("Generic_ToggleOneVersion", "OnToggleOneVersion", self)
  Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", "OnInterfaceMenuListHasLoaded", self)

  -- Setup Comms
  self.shareChannel = ICCommLib.JoinChannel("OneVersion", ICCommLib.CodeEnumICCommChannelType.Group)
  self.shareChannel:SetReceivedMessageFunction("OnReceiveAddonInfo", self)

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

  self.state.windows.main = Apollo.LoadForm(self.xmlDoc, "OneVersionWindow", nil, self)
  self.state.windows.addonList = self.state.windows.main:FindChild("ItemList")

  self.state.windows.alert = Apollo.LoadForm(self.xmlDoc, "AlertWindow", nil, self)
  self.state.windows.moveWindow = self.state.windows.alert:FindChild("UnlockInfo")

  self.state.windows.main:Show(false)
  self.state.windows.alert:Show(false)

  Apollo.RegisterSlashCommand("onever", "OnSlashCommand", self)

  -- Restore positions and junk
  self:RefreshUI()
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
  else
    Utils:cprint("OneVersion v" .. self.settings.version)
    Utils:cprint("Usage:  /onever <command>")
    Utils:cprint("====================================")
    Utils:cprint("   show           Open Rules Window")
    Utils:cprint("   debug          Toggle Debug")
    --Utils:cprint("   defaults       Loads defaults")
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

-----------------------------------------------------------------------------------------------
-- OneVersion OnReceiveAddonInfo
-----------------------------------------------------------------------------------------------
function OneVersion:OnReceiveAddonInfo(chan, msg)
  if self.settings.user.debug == true then
    Utils:debug(msg)
  end

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

    if alertRequired and self.state.windows.alert == nil then
      self.state.isAlerted = alertRequired
      self:ShowAlert()
      self:ProcessLock()
    end
  end
  self:RebuildAddonListItems()
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
  local name = GameLib.GetPlayerUnit():GetName()
  self:BroadcastAddons(name)
end

function OneVersion:BroadcastAddons(name)
  for key,value in pairs(self.state.trackedAddons) do
    msg = self:AddonInfoToMessage(name, value)
    self.shareChannel:SendMessage(msg)
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
-- OneVersion OnAddonReportInfo
-----------------------------------------------------------------------------------------------
function OneVersion:OnAddonReportInfo(name, major, minor, patch, suffix, isLib)
  -- Drop out if name isn't provided
  if not name or name == ""
    return
  end

  local addonInfo = self:GetBaseAddonInfo()

  local type = ""
  local minr = (minor or 0)
  local ptch = (patch or 0)
  local sufx = (suffix or 0)
  local lib = (isLib or false)

  if self.settings.user.debug == true then
    Utils:debug( string.format("%s|%d|%d|%d|%d|%s", name, major, minr, ptch, sufx, tostring(lib)) )
  end

  if lib == true then
    type = "Library"
  else
    type = "Add-On"
  end

  addonInfo.label = name
  addonInfo.type = type
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

  self:RebuildAddonListItems()
  self:BroadcastAddons(GameLib.GetPlayerUnit():GetName())
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

    -- Now that we've turned the save data into the most recent version, set it
    self.settings.version = ONEVERSION_CURRENT_VERSION

  else
    self.tConfig = deepcopy(tDefaultOptions)
  end
end

-----------------------------------------------------------------------------------------------
-- OneVersion Instance
-----------------------------------------------------------------------------------------------
local OneVersionInst = OneVersion:new()
OneVersionInst:Init()
