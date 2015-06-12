------------------------------------------------------------------------------------------------
--  1Version ver. @project-version@
--  Authored by Chrono Syz -- Entity-US / Wildstar
--  Build @project-hash@
--  Copyright (c) Chronosis. All rights reserved
--
--  https://github.com/chronosis/1Version
------------------------------------------------------------------------------------------------
-- 1Version-Utils.lua
------------------------------------------------------------------------------------------------
require "Window"
require "Item"
require "GameLib"

local OneVersion = Apollo.GetAddon("1Version")
local Info = Apollo.GetAddonInfo("1Version")
local Utils = Apollo.GetPackage("SimpleUtils-1.0").tPackage

-----------------------------------------------------------------------------------------------
-- Wrappers for debug functionality
-----------------------------------------------------------------------------------------------
function OneVersion:ToggleDebug()
  if self.settings.user.debug then
    self:PrintDB("Debug turned off")
    self.settings.user.debug = false
  else
    self.settings.user.debug = true
    self:PrintDB("Debug turned on")
  end
end

function OneVersion:BuildVersionString(major, minor, patch, suffix)
  -- This is a stupid fix to get around the LUA zero-index stupidity
  local sfx = (suffix or 0)
  if sfx == 0 then
    sfx = tostring(sfx)
  end
  local strVer = string.format("%d.%d.%d%s", major, minor, patch, OneVersion.CodeEnumAddonSuffixMap[sfx])
  return strVer
end

function OneVersion:GetPlayerName()
  local player = GameLib.GetPlayerUnit()
  local playerName = ""
  if player ~= nil then
    playerName = player:GetName()
  end

  if playerName ~= nil then
    return playerName
  end

  return ""
end

function OneVersion:Bool2Bit(b)
  if type(b) == "boolean" then
    if b then
      return 1
    end
  end
  return 0
end

function OneVersion:AddonSort(a,b)
  local a_str = tostring(self:Bool2Bit(a.upgrade)) .. a.label
  local b_str = tostring(self:Bool2Bit(b.upgrade)) .. b.label
  return a_str < b_str
end

function OneVersion:PrintParty(str)
  Utils:pprint("[OneVersion]: " .. str)
end

function OneVersion:PrintDB(str)
  if self.settings.user.debug then
    Utils:debug("[OneVersion]: " .. str)
  end
end

function OneVersion:DestroyWindowList(list)
  for key,value in pairs(list) do
    list[key]:Destroy()
  end
  list = {}
end
