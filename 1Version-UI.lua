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
  self.settings.user.savedWndLoc = self.state.windows.main:GetLocation():ToTable()
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

function OneVersion:OnEnableChecked( wndHandler, wndControl, eMouseButton )
  self.settings.user.enabled = true
end

function OneVersion:OnEnableUnchecked( wndHandler, wndControl, eMouseButton )
  self.settings.user.enabled = false
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
  if self.settings.user.savedWndLoc then
    locSavedLoc = WindowLocation.new(self.settings.user.savedWndLoc)
    self.state.windows.main:MoveToLocation(locSavedLoc)
  end

  -- Set Enabled Flag
  self.state.windows.main:FindChild("EnabledButton"):SetCheck(self.settings.user.enabled)

  -- Sort List Items
  self.state.windows.addonList:ArrangeChildrenVert()
end

function OneVersion:ShowAlert()
  self.state.windows.alert = Apollo.LoadForm(self.xmlDoc, "AlertWindow", nil, self)
end

function OneVersion:OnOpenAlerts()
  if self.state.isOpen ~= true then
    self.state.windows.main:Show(true)
    self.state.windows.alert:Show(false)
    self.state.windows.alert:Destroy()
  end
end

---------------------------------------------------------------------------------------------------
-- OneVersion Addon List UI Maintenance Functions
---------------------------------------------------------------------------------------------------
function OneVersion:ClearAddonListItem()
  self:DestroyWindowList(self.state.listItems.addons)
end


function OneVersion:AddAddonListItem(index, item)
  local wnd = Apollo.LoadForm(self.xmlDoc, "AddonListItem", self.state.windows.addonList, self)
  wnd:SetData(index)
  -- Populate List Items fields from the item data
  wnd:FindChild("Type"):SetText(item.type)
  wnd:FindChild("Label"):SetText(item.label)
  wnd:FindChild("Mine"):SetText(self:BuildVersionString((item.mine.major or 0), (item.mine.minor or 0), (item.mine.patch or 0)))
  wnd:FindChild("Reported"):SetText(self:BuildVersionString((item.reported.major or 0), (item.reported.minor or 0), (item.reported.patch or 0)))
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
