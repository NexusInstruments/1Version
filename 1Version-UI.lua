------------------------------------------------------------------------------------------------
--  1Version ver. @project-version@
--  Authored by Chrono Syz -- Entity-US / Wildstar
--  Build @project-hash@
--  Copyright (c) Chronosis. All rights reserved
--
--  https://github.com/chronosis/1Version
------------------------------------------------------------------------------------------------
-- 1Version-UI.lua
------------------------------------------------------------------------------------------------

require "Window"
require "Item"
require "GameLib"

local OneVersion = Apollo.GetAddon("1Version")
local Info = Apollo.GetAddonInfo("1Version")
local Utils = Apollo.GetPackage("SimpleUtils-1.0").tPackage

---------------------------------------------------------------------------------------------------
-- OneVersion General UI Functions
---------------------------------------------------------------------------------------------------
function OneVersion:OnToggleOneVersion()
  if self.state.isOpen == true then
    self.state.isOpen = false
    self:SaveLocation()
    self:CloseMain()
  else
    self.state.isOpen = true
    self.state.windows.main:Invoke() -- show the window
  end
end

function OneVersion:SaveLocation()
  self.settings.positions.main = self.state.windows.main:GetLocation():ToTable()
  self.settings.positions.alert = self.state.windows.alert:GetLocation():ToTable()
end

function OneVersion:CloseMain()
  self.state.windows.main:Close()
end

---------------------------------------------------------------------------------------------------
-- OneVersion OneVersionWindow UI Functions
---------------------------------------------------------------------------------------------------
function OneVersion:OnOneVersionClose( wndHandler, wndControl, eMouseButton )
  self.state.isOpen = false
  self:SaveLocation()
  self:CloseMain()
end

function OneVersion:OnOneVersionClosed( wndHandler, wndControl )
  self.state.isOpen = false
end

-----------------------------------------------------------------------------------------------
-- OneVersion OnConfigure
-----------------------------------------------------------------------------------------------
function OneVersion:OnConfigure()
  if self.state.windows.options == nil then
    self.state.windows.options = Apollo.LoadForm(self.xmlDoc, "OneVersionOptionsWindow", nil, self)
    -- Load Options
    --self.state.windows.options:FindChild("AutoMLButton"):SetCheck(self.settings.options.autoSetMasterLootWhenLeading)

    self.state.windows.options:Show(true)
  end
  self.state.windows.options:ToFront()
end

-----------------------------------------------------------------------------------------------
-- OneVersion Configuration UI Functions
-----------------------------------------------------------------------------------------------

function OneVersion:OnOptionsSave( wndHandler, wndControl, eMouseButton )
  --self.settings.options.autoSetMasterLootWhenLeading = self.state.windows.options:FindChild("AutoMLButton"):IsChecked()
  self:CloseOptions()
  -- Update addon state based on new settings
  self:ProcessOptions()
end

function OneVersion:OnOptionsCancel( wndHandler, wndControl, eMouseButton )
  self:CloseOptions()
end

function OneVersion:OnOptionsClosed( wndHandler, wndControl )
  self:CloseOptions()
end

function OneVersion:CloseOptions()
  self.state.windows.options:Show(false)
  self.state.windows.options:Destroy()
  self.state.windows.options = nil
end

---------------------------------------------------------------------------------------------------
-- OneVersion UI Refresh
---------------------------------------------------------------------------------------------------
function OneVersion:RefreshUI()
  -- Location Restore
  if self.settings.positions.main ~= nil and self.settings.positions.main ~= {} then
    locSavedLoc = WindowLocation.new(self.settings.positions.main)
    self.state.windows.main:MoveToLocation(locSavedLoc)
  end

  -- Location Restore
  if self.settings.positions.alert ~= nil and self.settings.positions.alert ~= {} then
    local locSavedLoc = WindowLocation.new(self.settings.positions.alert)
    self.state.windows.alert:MoveToLocation(locSavedLoc)
  end

  -- Set Enabled Flag
  self.state.windows.main:FindChild("EnabledButton"):SetCheck(self.settings.user.enabled)

  -- Sort List Items
  self.state.windows.addonList:ArrangeChildrenVert()
end

function OneVersion:ShowAlert()
  self.state.windows.alert:Invoke()

  -- Location Restore
  if self.settings.positions.alert ~= nil and self.settings.positions.alert ~= {} then
    local locSavedLoc = WindowLocation.new(self.settings.positions.alert)
    self.state.windows.alert:MoveToLocation(locSavedLoc)
  end
end

function OneVersion:CloseAlert()
  self.state.windows.alert:Close()
end

function OneVersion:ProcessLock()
  if self.settings.user.unlocked == true then
    self:ShowAlert()
    self.state.windows.alert:AddStyle("Moveable")
    self.state.windows.alert:FindChild("Button"):Enable(false)
    self.state.windows.alert:AddStyle("Moveable")
    self.state.windows.alert:SetTooltip("-Drag to Move-")
  else
    self.state.windows.alert:RemoveStyle("Moveable")
    self.state.windows.alert:FindChild("Button"):Enable(true)
    self.state.windows.alert:SetTooltip("-OneVersion Alert-")
    if self.state.isAlerted == false then
      self:CloseAlert()
    end
  end
  self.state.windows.moveWindow:Show(self.settings.user.unlocked)
end

function OneVersion:OnUnlockCheck( wndHandler, wndControl, eMouseButton )
  local checked = wndControl:IsChecked()
  self.settings.user.unlocked = checked
  self:ProcessLock()
end

function OneVersion:OnAlertMove( wndHandler, wndControl, nOldLeft, nOldTop, nOldRight, nOldBottom )
  self:SaveLocation()
end

function OneVersion:OnOpenAlerts()
  if self.state.isOpen ~= true then
    self.state.windows.main:Show(true)
  end
  self.state.isAlerted = false
  self:CloseAlert()
end

---------------------------------------------------------------------------------------------------
-- OneVersion Addon List UI Maintenance Functions
---------------------------------------------------------------------------------------------------
function OneVersion:ClearAddonListItem()
  self:DestroyWindowList(self.state.listItems.addons)
end


function OneVersion:AddAddonListItem(index, item)
  local wnd = Apollo.LoadForm(self.xmlDoc, "AddonListItem", self.state.windows.addonList, self)
  local mine = {
    major = (item.mine.major or 0),
    minor = (item.mine.minor or 0),
    patch = (item.mine.patch or 0),
    suffix = (item.mine.suffix or 0)
  }
  local reported = {
    major = (item.reported.major or 0),
    minor = (item.reported.minor or 0),
    patch = (item.reported.patch or 0),
    suffix = (item.reported.suffix or 0)
  }
  wnd:SetData(index)
  -- Populate List Items fields from the item data
  wnd:FindChild("Type"):SetText(item.type)
  wnd:FindChild("Label"):SetText(item.label)
  wnd:FindChild("Mine"):SetText(self:BuildVersionString(mine.major, mine.minor, mine.patch, mine.suffix))
  wnd:FindChild("Reported"):SetText(self:BuildVersionString(reported.major, reported.minor, reported.patch, reported.suffix))
  wnd:FindChild("Upgrade"):Show(item.upgrade)
  table.insert(self.state.listItems.addons, wnd)
end

function OneVersion:RebuildAddonListItems()
  local vScrollPos = self.state.windows.addonList:GetVScrollPos()
  self:SaveLocation()
  self:ClearAddonListItem()
  for key,item in pairs(self.state.trackedAddons) do
    self:AddAddonListItem(idx, item)
  end
  self.state.windows.addonList:SetVScrollPos(vScrollPos)
  self:RefreshUI()
end
