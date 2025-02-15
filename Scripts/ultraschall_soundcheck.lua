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



-- Defer1: Soundcheck Daemon
-- Defer2: Samplerate
-- Defer3: Unsaved


---------------------------------------------------------------
-- Soundcheck Unsaved
-- Wenn ein Recording gestartet wird wird geprüft, ob das Projekt schon gespeichert wurde
---------------------------------------------------------------



function soundcheck_unsaved()


    -- print(reaper.GetPlayStateEx(0))
    --print(reaper.IsProjectDirty(0))

    if reaper.IsProjectDirty(0) and reaper.GetPlayStateEx(0) > 4 then -- das Projekt wurde noch nicht gespeichertund es läuft oder pausiert ein recording

      if tonumber(reaper.GetExtState ("soundcheck_timer", "unsaved"))+120 < reaper.time_precise() then
        soundcheck_unsaved_action()

      end
    end

    retval, defer3_identifier = ultraschall.Defer(soundcheck_unsaved, ultraschall.ScriptIdentifier..".defer_script03", 2, 3)
  end


function soundcheck_unsaved_action()

  -- print("noch da")
   return_value = ultraschall.MB("Your project has not been saved yet. It is strongly advised to save it before starting a recording.", "WARNING - Ultraschall Soundcheck",3, "Save as", "Ignore", "Settings")

  if return_value == 3 then
    reaper.SetExtState("soundcheck_timer", "unsaved", tostring(reaper.time_precise()), false)
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_Ultraschall_Settings"),0) -- öffne Ultraschall Settings

  elseif return_value == 2 then
    reaper.SetExtState("soundcheck_timer", "unsaved", tostring(reaper.time_precise()), false)
    reaper.Main_OnCommand(40022,0) -- öffne den Speichern unter Dialog

  end

end


function soundcheck_unsaved_controller()

  if ultraschall.GetUSExternalState("ultraschall_settings_unsaved", "value") == "0" then
    -- Soundcheck ist in den Settings deaktiviert

    if reaper.GetExtState("ultraschall", ultraschall.ScriptIdentifier..".defer_script03") == "running" then
      retval = ultraschall.StopDeferCycle(defer3_identifier)
    end

  else  -- Soundcheck ist in den Settings aktiviert

    if reaper.GetExtState("ultraschall", ultraschall.ScriptIdentifier..".defer_script03") ~= "running" then
      soundcheck_unsaved()
    end
  end
end



-------------------------------------------------------------------------------------
-- Soundcheck Samplerate
-- muss 48 KHz sein wenn mindestens eine StudioLink Spur im Projekt ist
-------------------------------------------------------------------------------------



function soundcheck_samplerate()

  retval, actual_samplerate = reaper.GetAudioDeviceInfo("SRATE", "")
  -- print("noch da")
  for i=1, reaper.CountTracks(0) do

    if (ultraschall.IsTrackStudioLink(i) or ultraschall.IsTrackStudioLinkOnAir(0)) and actual_samplerate == "48000" then  -- es gibt mindestens eine StudioLink Spur und Samplerate steht nicht auf 48000

      if tonumber(reaper.GetExtState ("soundcheck_timer", "samplerate"))+120 < reaper.time_precise() then

        soundcheck_samplerate_action()
        -- print(actual_samplerate)
        break
      end
    end
  end
  retval, defer2_identifier = ultraschall.Defer(soundcheck_samplerate, ultraschall.ScriptIdentifier..".defer_script02", 2, 3)
end


function soundcheck_samplerate_action()

  return_value = ultraschall.MB("Your samplerate is set to please set to 48000", "WARNING - Ultraschall Soundcheck",3, "gut", "ach nein", "blafasel")

  if return_value == 3 then
    reaper.SetExtState("soundcheck_timer", "samplerate", tostring(reaper.time_precise()), false)
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_Ultraschall_Settings"),0) -- öffne Ultraschall Settings

  elseif return_value == 2 then
    reaper.SetExtState("soundcheck_timer", "samplerate", tostring(reaper.time_precise()), false)
    reaper.Main_OnCommand(40099,0) -- öffne Audio device Settings

  end

end


function soundcheck_samplerate_controller()

  if ultraschall.GetUSExternalState("ultraschall_settings_samplerate", "value") == "0" then
    -- Soundcheck ist in den Settings deaktiviert

    if reaper.GetExtState("ultraschall", ultraschall.ScriptIdentifier..".defer_script02") == "running" then
      retval = ultraschall.StopDeferCycle(defer2_identifier)
    end

  else  -- Soundcheck ist in den Settings aktiviert

    if reaper.GetExtState("ultraschall", ultraschall.ScriptIdentifier..".defer_script02") ~= "running" then
      soundcheck_samplerate()
    end
  end
end


--------------------

function soundcheck_main()

  soundcheck_samplerate_controller()
  soundcheck_unsaved_controller()

  retval, defer1_identifier = ultraschall.Defer(soundcheck_main, ultraschall.ScriptIdentifier..".defer_script01", 2, 1)

end

-- soundcheck_samplerate_action ()


-- initialise variables

reaper.SetExtState("soundcheck_timer", "samplerate", "0", false)
reaper.SetExtState("soundcheck_timer", "unsaved", "0", false)


-- print(ultraschall.GetApiVersion())
-- print(reaper.IsProjectDirty(0))

dofile(reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua")
retval = ultraschall.WriteValueToFile(ultraschall.API_TempPath.."/Tudelu.txt", "Dingodongo")
ultraschall.ShowLastErrorMessage()

-- return_value2 = ultraschall.MB("Your samplerate is set to please set to 48000b", "WARNING - Ultraschall Soundcheck",3, "gut", "ach", "blafasel")

soundcheck_main()
