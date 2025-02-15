--[[
################################################################################
#
# Copyright (c) 2014-2019 Ultraschall (http://ultraschall.fm)
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
dofile(reaper.GetResourcePath().."/Scripts/ultraschall_soundcheck_functions.lua")


ultraschall.EventManager_Start()

-- print (start_id)

section_count = ultraschall.CountUSExternalState_sec("ultraschall-settings.ini")

for i = 1, section_count , 1 do

  sectionName = ultraschall.EnumerateUSExternalState_sec(i,"ultraschall-settings.ini")

  -- Suche die Sections der ultraschall.ini heraus, die in der Soundcheck-GUI angezeigt werden sollen

  if sectionName and string.find(sectionName, "ultraschall_soundcheck", 1) and ultraschall.GetUSExternalState(sectionName,"Value","ultraschall-settings.ini") ~= "0" then

    SetSoundcheck(sectionName)

  end

end

-- string event_identifier = ultraschall.EventManager_AddEvent(string EventName, integer CheckAllXSeconds, integer CheckForXSeconds, boolean StartActionsOnceDuringTrue, boolean EventPaused, function CheckFunction, table Actions)
