--[[
################################################################################
#
# Copyright (c) 2014-2018 Ultraschall (http://ultraschall.fm)
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
-- dofile(reaper.GetResourcePath().."/Scripts/ser.lua")

-- local serialize = require (reaper.GetResourcePath().."/Scripts/ser")


-- string buf = reaper.GetTrackName(MediaTrack track)
-- trackname = ultraschall.GetTrackName(integer tracknumber, optional string TrackStateChunk)


function buildRoutingMatrix ()

	local AllMainSends, number_of_tracks = ultraschall.GetAllMainSendStates()

  for i=1, number_of_tracks do
  	AllMainSends[i]["MainSendOn"] = 1	-- alle Kanäle senden auf den Main - solange Preshow nicht aktiv ist
  end

  retval = ultraschall.ApplyAllMainSendStates(AllMainSends)	-- setze alle Sends zum Master

  for i=1, number_of_tracks do

    if ultraschall.GetTrackName(i) == "Soundboard" then

      -- retval = ultraschall.AddTrackHWOut(i, 0, 0, 1, 0, 0, 0, 0, -1, 0, false) -- Soundboard-Spuren gehen immer auf den MainHardwareOut Zurück

      if ultraschall.GetUSExternalState("ultraschall_settings_soundboard_ducking_editing","Value", "ultraschall-settings.ini") == "1" then -- Ducking ist in den Settings aktiviert

        for j=1, number_of_tracks do
          if ultraschall.GetTrackName(j) ~= "Soundboard" then -- jeder Track der nicht Soundboard ist schickt sein Signal auf den 3/4 Kanal des Soundboards

            setstate = ultraschall.AddTrackAUXSendReceives(i, j, 0, 1, 0, 0, 0, 0, 0, 2, -1, 0, 0, false)
            -- print(i.j)
          end
        end
      end
    end
  end
end
  


retval = ultraschall.ClearRoutingMatrix(true, true, true, true, false)
retval = ultraschall.AddTrackHWOut(0, 0, 0, 1, 0, 0, 0, 0, -1, 0, false) -- Soundboard-Spuren gehen immer auf den MainHardwareOut Zurück
buildRoutingMatrix ()

reaper.SetProjExtState(0, "ultraschall_magicrouting", "step", "editing")

is_new,name,sec,cmd,rel,res,val = reaper.get_action_context()
state = reaper.GetToggleCommandStateEx(sec, cmd)

ID_1 = reaper.NamedCommandLookup("_Ultraschall_set_Matrix_Preshow") -- Setup Button
ID_2 = reaper.NamedCommandLookup("_Ultraschall_set_Matrix_Recording") -- Record Button
ID_3 = reaper.NamedCommandLookup("_Ultraschall_set_Matrix_Editing") -- Edit Button

if state <= 0 then
  reaper.SetToggleCommandState(sec, cmd, 1)
end

reaper.SetToggleCommandState(sec, ID_1, 0)
reaper.SetToggleCommandState(sec, ID_2, 0)
reaper.SetProjExtState(0, "gui_statemanager", "_Ultraschall_set_Matrix_Editing", 1)
reaper.SetProjExtState(0, "gui_statemanager", "_Ultraschall_set_Matrix_Recording", 0)
reaper.SetProjExtState(0, "gui_statemanager", "_Ultraschall_set_Matrix_Preshow", 0)

reaper.RefreshToolbar2(sec, cmd)
