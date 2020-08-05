--[[
################################################################################
#
# Copyright (c) 2014-2020 Ultraschall (http://ultraschall.fm)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
################################################################################
]]

dofile(reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua")

cmd = reaper.NamedCommandLookup("_Ultraschall_toggle_item_labels")
state = reaper.GetToggleCommandStateEx(0, cmd)

if state <= 0 then
	newstate = 1
	reaper.SetToggleCommandState(0, cmd, newstate)
else
	newstate = 0
	reaper.SetToggleCommandState(0, cmd, newstate)
end

reaper.Main_OnCommand(40651,0)      -- toggle item labels view

reaper.SetProjExtState(0, "gui_statemanager", "_Ultraschall_toggle_item_labels", tostring(newstate)) -- speichere den aktuellen GUI-Status in Projektdatei


reaper.RefreshToolbar2(0, cmd)

-- Msg(cmd)
-- Msg(ID_2)