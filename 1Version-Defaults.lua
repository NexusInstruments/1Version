------------------------------------------------------------------------------------------------
--  1Version ver. @project-version@
--  Authored by Chrono Syz -- Entity-US / Wildstar
--  Build @project-hash@
--  Copyright (c) Chronosis. All rights reserved
--
--  https://github.com/chronosis/1Version
------------------------------------------------------------------------------------------------
-- 1Version-Defaults.lua
------------------------------------------------------------------------------------------------

require "Window"
require "Item"
require "GameLib"

local OneVersion = Apollo.GetAddon("1Version")
local Info = Apollo.GetAddonInfo("1Version")


local tBaseAddonInfo = {
  type = "",
  label = "",
  mine = {
    major = 0,
    minor = 0,
    patch = 0
  },
  reported = {
    major = 0,
    minor = 0,
    patch = 0
  },
  upgrade = false
}

function OneVersion:LoadDefaults()
  self:RefreshUI()
end

function OneVersion:GetBaseAddonInfo()
  return shallowcopy(tBaseAddonInfo)
end
