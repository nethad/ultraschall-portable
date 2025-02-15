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

--[[

Aufbau der ultraschall-settings.ini

Die Ultraschall-Settings werden aus drei Bereichen dynamisch befüllt und über drei reiter angezeigt:
1. General Settings
2. Soundcheck Settings
3. Interface Settings

--------------------
1. General Settings
--------------------
Enthält alle Einträge, die in einem Abschnitt
[ultraschall_settings_wasuachimmer]
liegen.
Es werden immer diese Felder benötigt (Beispiel):

[ultraschall_settings_startsceen]
Description=Should the Ultraschall start screen be displayed at every launch? -- erscheint als Erklärtext wenn man auf den "?" Button  drückt
name=Show the start screen -- sichtbarer Text des Settings-Eintrags
position=1 -- An welcher Position der Eintrag steht. Achtung: muss unique sein sonst überlappen sich Einträge
settingstype=checkbox -- derzeit möglich: checkbox (an/aus) oder Slider (s.u.)
Value=1 -- Wert des Eintrages. Bei Checkbox 0=aus 1=an, beim Slider ein numerischer Wert (s.u.)

Zusätzliche Felder beim Typ "Slider":

maximum=1.0  -- Maximalwert des Sliders ganz rechts
minimum=0.0  -- Minimalwert des Sliders ganz links
steps=10     -- Anzahl der Zwischenschritte für Rasterung
actualstep=5 -- auf welchem Rasterschritt der Slider gerade steht (korrespondiert mit Value)

-----------------------
2. Soundcheck Settings
-----------------------
Enthält alle Einträge, die in einem Abschnitt
[ultraschall_soundcheck_wasuachimmer]
liegen.
Es werden immer diese Felder benötigt (Beispiel):

[ultraschall_soundcheck_mic]
Button1Action=40099 -- Aktion, die auf dem ersten Soundcheck-Button liegt
Button1Label=Change interface... -- Label des ersten Buttons
CheckAllXSeconds=1 -- Intervall, in dem der Soundcheck im Hintergrund prüft
CheckForXSeconds=0 -- steht immer auf 0
CheckFunction=SoundcheckMic -- Funktion, die den eigentlichen Check durchführt, muss in ultraschall_soundcheck_functions.lua liegen. Liefert die Funktion false ist das Ereignis nicht eingetreten, bei true hat der Check angeschlagen.
Description=Prevents you from accidentally recording with the built-in microphone|instead of using your dedicated sound interface. -- Hilfetext auf dem "?" Button in den Settings
DescriptionWarning=You have just armed a track for recording, but your recording interface seems to be the internal microphone. |This results in very poor sound quality. |You can ignore this and still continue or change the sound interface. -- Text, der im Soundcheck-Fenster direkt angezeigt wird
EventIdentifier=Ultraschall_Eventidentifier: {B78C2305-5EBF-8F42-90CA-EE2A31F2FB05} -- wird bei jedem Start neu vergeben, nicht von Nutzern zu verändern
EventNameDisplay=Check for internal microphone -- Name des Soundcheck in den Settings
EventPaused=false -- EventManager Flag, steht immer auf false
Position=4 -- Position in den Settings. Wichtig: muss unique sein sonst überlappen sich Einträge
settingstype=checkbox -- ist immer checkbox bei Soundchecks
StartActionsOnceDuringTrue=false -- EventManager Flag, steht immer auf false
StartFunction=_Ultraschall_Soundcheck_Startgui -- die Aktion, die ausgeführt wird wenn der Check anschlägt. Ist in den meisten Fällen das starten der Soundcheck-GUI
Value=0 -- 0 = Soundcheck abgeschaltet, 1 = angeschaltet (Status der Checkbox)

Jeder Soundcheck _muss_ einen Call-to-Action Button haben. Optional kann auch ein zweiter konfiguriert werden (aber kein dritter):

Button2Action= -- Aktion, die auf dem zweiten Soundcheck-Button liegt
Button2Label= -- Label des zweiten Buttons

Jede Änderung in den Settings wirkt sich unmittelbar auf den EventManager aus. Alle aktiven Soundchecks sind in diesem registriert.

-----------------------
3. Interface Settings
-----------------------

Enthält alle Einträge, die in dem Abschnitt
[ultraschall_devices]
liegen.

Über die EInträge werden zum einen Devices verwaltet, die gängig sind und von denen wir wissen, ob sie Direct Monitoring können, etwa das Zoom H6:

CoreAudio H6=2

Zum anderen werden dort alle bisher unbekannten Devices mit ihrem Namen eingetragen, die NutzerIn anschließt. Wenn ein bisher unbekanntes Device (noch kein Eintrag in diesen Settings) angeschlossen wird, meldet sich ein Soundcheck mit der Abfrage, ob direct monitoring möglich ist oder nicht. Der Wert wird dann eingetragen.

Wird ein Device über die GUI "gelöscht", so verbleibt der Eintrag in den Settings, wird aber auf unsichtbar geschaltet (Wert 2 oder 3). Wenn das Gerät doch noch einmal angeschlossen wird, erscheint dann kein Soundcheck sondern der entsprechende Wert wird auf 0 oder 1 gesetzt.


die States im Überblick:

-- 0 = eingeblendet, kann/soll kein lokales Monitoring
-- 1 = eingeblendet, kann/soll lokales Monitoring
-- 2 = ausgeblendet, kann/soll lokales Monitoring
-- 3 = ausgeblendet, kann/soll kein lokales Monitoring


]]

dofile(reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua")
dofile(reaper.GetResourcePath().."/Scripts/ultraschall_soundcheck_functions.lua")


------------------------------------
-- Blacklist für Devices, von denen wir wissen, dass sie kein lokales Monitoring bieten.
-- Könnte perspektivich in eine separate .ini Datei ausgelagert werden.
------------------------------------

devices_blacklist = {}
devices_blacklist['CoreAudio Built-in Microph']=1
devices_blacklist['CoreAudio Mic96K + Anlage']=1
devices_blacklist['CoreAudio Mic96K']=1


------------------------------------------------------
-- Open a URL in a browser - OS agnostic
------------------------------------------------------

function open_url(url)

  local operationSystem = reaper.GetOS() -- Mac
  if string.match(operationSystem, "OS") then
    os.execute("open ".. url)
  else
    os.execute("start ".. url)
  end
end


function run_action(commandID)

  CommandNumber = reaper.NamedCommandLookup(commandID)
  reaper.Main_OnCommand(CommandNumber,0)

end



local function splitWords(Lines, limit)
  while #Lines[#Lines] > limit do
          Lines[#Lines+1] = Lines[#Lines]:sub(limit+1)
          Lines[#Lines-1] = Lines[#Lines-1]:sub(1,limit)
  end
end


local function wrap(str, limit)
  local Lines, here, limit, found = {}, 1, limit or 72, str:find("(%s+)()(%S+)()")

  if found then
          Lines[1] = string.sub(str,1,found-1)  -- Put the first word of the string in the first index of the table.
  else Lines[1] = str end

  str:gsub("(%s+)()(%S+)()",
          function(sp, st, word, fi)  -- Function gets called once for every space found.
                  splitWords(Lines, limit)

                  if fi-here > limit then
                          here = st
                          Lines[#Lines+1] = word                                                                                   -- If at the end of a line, start a new table index...
                  else Lines[#Lines] = Lines[#Lines].." "..word end  -- ... otherwise add to the current table index.
          end)

  splitWords(Lines, limit)

  return Lines
end


------------------------------------------------------
-- Switch State of an event in the Soundcheck
------------------------------------------------------

function SwitchEvent(EventIdentifier, newvalue, sectionName)

  if newvalue == "0" then -- remove the event

    ultraschall.EventManager_RemoveEvent(EventIdentifier)

  elseif newvalue == "1" then -- add the event

    SetSoundcheck(sectionName)

  end
end


------------------------------------------------------
--  Setting new Values to ultraschall.ini
------------------------------------------------------

function set_values()

  for i = 1, #GUI["elms"] , 1 do  -- Anzahl der Einträge ist immer doppelt so hoch durch die Info-Buttons pro Eintrag

      -- Buttons und Label werden übersprungen
    EventIdentifier = ""

    if (GUI["elms"][i]["type"]) == "Checklist" or (GUI["elms"][i]["type"]) == "Sldr" then

      -- hole den aktuellen Wert der Checkbox aus der GUI:

      if GUI["elms"][i]["type"] == "Checklist" then
        newvalue = tostring(GUI["elms"][i]["retval"][1])
      elseif GUI["elms"][i]["type"] == "Sldr" then
        newvalue = tostring(GUI["elms"][i]["retval"])
      end

      if GUI["elms"][i]["sectionname"] == "ultraschall_devices" then
        device_name = GUI["elms"][i]["optarray"][1]
        stored_value = ultraschall.GetUSExternalState("ultraschall_devices", device_name, "ultraschall-settings.ini")
        -- print (device_name.."-"..newvalue.."-"..stored_value)

      else
        stored_value = ultraschall.GetUSExternalState(GUI["elms"][i]["sectionname"],"Value", "ultraschall-settings.ini")
      end

      if newvalue ~= stored_value then  -- wurde eine Schalter/Slider umgelegt?

        if GUI["elms"][i]["sectionname"] == "ultraschall_devices" and (stored_value ~= 2 and stored_value ~= 3) then

          update = ultraschall.SetUSExternalState(GUI["elms"][i]["sectionname"], device_name, newvalue, "ultraschall-settings.ini")

        else
          update = ultraschall.SetUSExternalState(GUI["elms"][i]["sectionname"], "Value", newvalue, "ultraschall-settings.ini")

          EventIdentifier = ultraschall.GetUSExternalState(GUI["elms"][i]["sectionname"],"EventIdentifier", "ultraschall-settings.ini")

          if EventIdentifier ~= "" then   -- der Eintrag ist ein gerade laufender Soundcheck-Event

            SwitchEvent(EventIdentifier, newvalue, GUI["elms"][i]["sectionname"])

          end

        end

        -- Ausnahme: für Slider wird auch noch die Position geschrieben (könnte man prinzipiell auch berechnen lassen)

        if GUI["elms"][i]["type"] == "Sldr" then
          update = ultraschall.SetUSExternalState(GUI["elms"][i]["sectionname"], "actualstep", tostring(GUI["elms"][i]["curstep"]),"ultraschall-settings.ini")
        end

        if GUI["elms"][i]["sectionname"] == "ultraschall_settings_soundboard_ducking" or GUI["elms"][i]["sectionname"] == "ultraschall_devices" then
          reaper.SetProjExtState(0, "ultraschall_magicrouting", "override", "on")  -- Soundboard ducking wurde aktiviert/deaktibiert also Routing Matrix neu aufbauen
        end

        ---------------
        -- Start Action
        ---------------

        if newvalue ~= "0" and ultraschall.GetUSExternalState(GUI["elms"][i]["sectionname"],"StartFunction", "ultraschall-settings.ini") ~= "" and EventIdentifier == "" then
          -- ein Setting wurde aktiviert, das auch eine Start-Action hat. Ausnahme sind Soundchecks, die starten ohnehin bei Bedarf.

          cmd=reaper.NamedCommandLookup(ultraschall.GetUSExternalState(GUI["elms"][i]["sectionname"],"StartFunction", "ultraschall-settings.ini"))
          reaper.Main_OnCommand(cmd,0)
          -- führe die StartAction aus

        end

      end
    end
  end
end


------------------------------------------------------
--  Show the GUI menu item. Wird verwendet, um Info-Texte hinter den Buttins anzuzeigen.
------------------------------------------------------

function show_menu(str)

  gfx.x, gfx.y = GUI.mouse.x+20, GUI.mouse.y-10
  selectedMenu = gfx.showmenu(str)
  return selectedMenu

end


------------------------------------------------------
--  Schaltet einen Device-Eintrag in der ultraschall.ini auf ausgeblendet (Wert 2)
------------------------------------------------------

function remove_device(device_name)


  clear_devices()
  local device_state = ultraschall.GetUSExternalState("ultraschall_devices",device_name,"ultraschall-settings.ini")

  if device_state == "0" then -- Device kann/soll kein lokales Monitoring
    ultraschall.SetUSExternalState("ultraschall_devices", device_name, "3", "ultraschall-settings.ini")
  else -- lokales Monitoring möglich
    ultraschall.SetUSExternalState("ultraschall_devices", device_name, "2", "ultraschall-settings.ini")
  end
  show_devices()
  SettingsPageDevices()

end


------------------------------------------------------
--  Schaltet einen Device-Eintrag in der ultraschall.ini auf ausgeblendet (Wert 2)
------------------------------------------------------

function clear_devices()

  for i = GUI.counter+1, #GUI["elms"] , 1 do

    val = table.remove (GUI["elms"], GUI.counter+1)

  end
end


------------------------------------------------------
--  Baut die Liste der bisher verwendeten/bekannten Devices auf. Alleinige Quelle ist die ultraschall.ini
------------------------------------------------------

function show_devices()

  retval, actual_device_name = reaper.GetAudioDeviceInfo("IDENT_IN", "") -- gerade aktives device
  sectionName = "ultraschall_devices"
  key_count = ultraschall.CountUSExternalState_key(sectionName, "ultraschall-settings.ini")
  position = 170
  local x_position = 75
  truncate = 50 -- angezeigte maximale Länge des Devicenamens

  for i = 1, key_count , 1 do
    device_name = ultraschall.EnumerateUSExternalState_key(sectionName, i,"ultraschall-settings.ini")
    device_name_displayed = string.sub (device_name, 1, truncate)

    stored_device_state = tonumber(ultraschall.GetUSExternalState(sectionName,device_name,"ultraschall-settings.ini"))

    if stored_device_state ~= 2 and stored_device_state ~= 3  then  -- Device ist nicht ausgeblendet

      position = position+30  -- Y-position des Eintrags

      if actual_device_name ~= device_name then -- kein Delete-Button beim gerade aktiven Gerät

        -- Delete-Button
        button_id = (#GUI["elms"])
        delete = GUI.Btn:new(x_position + 500, position+3, 60, 20,         " Delete", remove_device, device_name)
        table.insert(GUI.elms, delete)
        color = "txt"

      else
        color = "white"
        label_active = GUI.Lbl:new( x_position + 500, position+6,                  " Active - cannot be deleted",          0, color)
        table.insert(GUI.elms, label_active)

      end

      if devices_blacklist[device_name] == 1 then -- das Gerät kann bekanntermaßen kein direct monitoring

        id = GUI.Lbl:new(          x_position + 40, position+7,                  device_name,          0, color)

      else

        id = GUI.Checklist:new(x_position, position, 240, 30,         "", device_name, 4, tonumber(ultraschall.GetUSExternalState(sectionName,device_name,"ultraschall-settings.ini")), sectionName, truncate, color)
      end

      table.insert(GUI.elms, id)


    end
  end
end


function changeTab(tab_number)

  ultraschall.SetUSExternalState("ultraschall_gui","settingsview",tostring(tab_number))
  buildGUI()

end


------------------------------------------------------
--  End of functions
------------------------------------------------------


-- Grab all of the functions and classes from our GUI library

local info = debug.getinfo(1,'S');
script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
GUI = dofile(script_path .. "ultraschall_gui_lib.lua")
gfx_path=script_path.."/Ultraschall_Gfx/Settings/"
header_path = script_path.."/Ultraschall_Gfx/Headers/"

---- Window settings and user functions ----

GUI.name = "Ultraschall 5 - Settings"
GUI.w, GUI.h = 820, 657   -- ebentuell dynamisch halten nach Anzahl der Devices-Einträge?

------------------------------------------------------
-- position always in the center of the screen
------------------------------------------------------

l, t, r, b = 0, 0, GUI.w, GUI.h
__, __, screen_w, screen_h = reaper.my_getViewport(l, t, r, b, l, t, r, b, 1)
GUI.x, GUI.y = (screen_w - GUI.w) / 2, (screen_h - GUI.h) / 2



  -- body
  ---- GUI Elements ----


------------------------------------------------------
--  Aufbau der nicht interkativen GUI-Elemente wie Logos etc.
------------------------------------------------------



function buildGUI()

  settings_view = ultraschall.GetUSExternalState("ultraschall_gui","settingsview")
  if settings_view == "" then
    settings_view = 1
    ultraschall.SetUSExternalState("ultraschall_gui","settingsview","1")
  else
    settings_view = tonumber(settings_view)
  end

  GUI.elms = {

  }

  -----------------------------
  ------- Header Settings
  -----------------------------

  header_height = 42

  header = GUI.Area:new(0,0,1000,header_height,0,1,1,"header_bg")
  table.insert(GUI.elms, header)

  logo = GUI.Pic:new(          0,  0,   0,  0,    1,   header_path.."settings_logo.png")
  table.insert(GUI.elms, logo)

  headertxt = GUI.Pic:new(          74,  10,   0,  0,    0.8,   header_path.."headertxt_settings.png")
  table.insert(GUI.elms, headertxt)


  -----------------------------
  ------- Tabs
  -----------------------------

  for i = 1, 3, 1 do

    tab_x_offset = - 105 + (i*150)

    if i == settings_view then
      tab_image = "tab_settingsview_active_" .. i .. ".png"
    else
      tab_image = "tab_settingsview_inactive_" .. i .. ".png"
    end

    tab = GUI.Pic:new(tab_x_offset,  header_height + 45,   150,  50,    0.5,   header_path..tab_image, changeTab, i)
    table.insert(GUI.elms, tab)


  end

  if settings_view == 3 then
    SettingsPageDevices()
  elseif settings_view == 2 then
    SettingsPageSoundcheck()
  else
    SettingsPageSettings()
  end


end

---- Put all of your own functions and whatever here ----


function SettingsPageSettings()

  -----------------------------------------------------------------
  -- initialise the settings - coming from the ultraschall-settings.ini file
  -----------------------------------------------------------------

  section_count = ultraschall.CountUSExternalState_sec("ultraschall-settings.ini")

  ------------------------------------------------------
  -- Gehe alle Sektionen der ultraschall.ini durch und baut die normalen Settings auf.
  -- Kann perspektivisch in eine Funktion ausgelagert werden
  ------------------------------------------------------

  x_offset = 55

  block = GUI.Area:new(45, header_height + 92,730, 480,5,1,1,"section_bg")
    table.insert(GUI.elms, block)


  for i = 1, section_count , 1 do

    sectionName = ultraschall.EnumerateUSExternalState_sec(i, "ultraschall-settings.ini")

    -- Suche die Sections der ultraschall-settings.ini heraus, die in der Settings-GUI angezeigt werden sollen

    if sectionName and string.find(sectionName, "ultraschall_settings", 1) then

      position = header_height + 80 + (tonumber(ultraschall.GetUSExternalState(sectionName,"position", "ultraschall-settings.ini")) * 30) -- Feintuning notwendig
      settings_Type = ultraschall.GetUSExternalState(sectionName, "settingstype","ultraschall-settings.ini")

      if settings_Type == "checkbox" then
        id = GUI.Checklist:new(20+x_offset, position, 240, 30,         "", ultraschall.GetUSExternalState(sectionName,"name","ultraschall-settings.ini"), 4, tonumber(ultraschall.GetUSExternalState(sectionName,"Value","ultraschall-settings.ini")), sectionName)
        table.insert(GUI.elms, id)

        -- Info-Button
        info = GUI.Btn:new(440+x_offset, position+3, 20, 20,         " ?", show_menu, ultraschall.GetUSExternalState(sectionName,"description","ultraschall-settings.ini"))
        table.insert(GUI.elms, info)

      elseif settings_Type == "slider" then
        position = position+8
        id = GUI.Sldr:new(325+x_offset, position, 80, ultraschall.GetUSExternalState(sectionName,"name","ultraschall-settings.ini"), ultraschall.GetUSExternalState(sectionName,"minimum","ultraschall-settings.ini"), ultraschall.GetUSExternalState(sectionName,"maximum","ultraschall-settings.ini"), ultraschall.GetUSExternalState(sectionName,"steps","ultraschall-settings.ini"), ultraschall.GetUSExternalState(sectionName,"Value","ultraschall-settings.ini"), ultraschall.GetUSExternalState(sectionName,"actualstep","ultraschall-settings.ini"), sectionName)
        table.insert(GUI.elms, id)

        -- Info-Button
        info = GUI.Btn:new(440+x_offset, position-6, 20, 20,         " ?", show_menu, ultraschall.GetUSExternalState(sectionName,"description","ultraschall-settings.ini"))
        table.insert(GUI.elms, info)

      end
    end
  end
end


function SettingsPageSoundcheck()


  -- Soundcheck Settings

  -----------------------------
  ------- Header Soundcheck
  -----------------------------

  section_count = ultraschall.CountUSExternalState_sec("ultraschall-settings.ini")

  position = header_height + 102

  position_old = position +5
  y_offset = 80
  x_offset = 55

  block = GUI.Area:new(45,position-10,730, 400,5,1,1,"section_bg")
      table.insert(GUI.elms, block)


  for i = 1, section_count , 1 do

    sectionName = ultraschall.EnumerateUSExternalState_sec(i,"ultraschall-settings.ini")
    if sectionName and string.find(sectionName, "ultraschall_soundcheck", 1) then

      position = position_old + (tonumber(ultraschall.GetUSExternalState(sectionName,"Position","ultraschall-settings.ini")) * 30) -- Feintuning notwendig

      id = GUI.Checklist:new(20+x_offset, position, 240, 30,         "", ""..ultraschall.GetUSExternalState(sectionName,"EventNameDisplay","ultraschall-settings.ini"), 4, tonumber(ultraschall.GetUSExternalState(sectionName,"Value","ultraschall-settings.ini")), sectionName)
      table.insert(GUI.elms, id)

      -- Info-Button
      info = GUI.Btn:new(400+x_offset, position+3, 20, 20,         " ?", show_menu, ultraschall.GetUSExternalState(sectionName,"Description","ultraschall-settings.ini"))
      table.insert(GUI.elms, info)

    end
  end
end


function SettingsPageDevices()


  ------------------------------------------------------
  --  Anzahl der Elemente vor der Devices-Sektion
  ------------------------------------------------------

  GUI.counter = #GUI.elms

  ------------------------------------------------------
  --  Das gerade aktive Device wird immer noch einmal aktualisiert/überschrieben.
  --  So werden unsichtbar geschaltete Einträge wieder sichtbar.
  ------------------------------------------------------

  retval, actual_device_name = reaper.GetAudioDeviceInfo("IDENT_IN", "")

  stored_device_state = ultraschall.GetUSExternalState("ultraschall_devices",actual_device_name,"ultraschall-settings.ini")

  if stored_device_state == "3" or stored_device_state == "0" then
    ultraschall.SetUSExternalState("ultraschall_devices", actual_device_name, "0", "ultraschall-settings.ini")
  else
    ultraschall.SetUSExternalState("ultraschall_devices", actual_device_name, "1", "ultraschall-settings.ini")
  end

  ------------------------------------------------------
  --  Info-Button für Devices
  ------------------------------------------------------

  local position = header_height + 102

  block = GUI.Area:new(45,position-10,730, 400,5,1,1,"section_bg")
      table.insert(GUI.elms, block)


  local label_table = GUI.Lbl:new( 85, position+20,                  "Direct Monitoring on/off",          0, "white")
      table.insert(GUI.elms, label_table)

  -- local label_table2 = GUI.Lbl:new( 575, position+20,                  "Delete",          0, "white")
   --   table.insert(GUI.elms, label_table2)


  devicetext = "This list shows all audio interfaces you ever connected. If you can plug a headphone to your audio interface, it supports Direct Monitoring. If you can not connect a headphone direct into your audio interface, make shure to uncheck the Direct Monitoring box to get the audio routing right. You can delete obsolete devices."

  infotable = wrap(devicetext,100) -- Zeilenumbruch 80 Zeichen für Warnungsbeschreibung



  infoposition = position + 280


	for k, warningtextline in pairs(infotable) do

		local infotext = GUI.Lbl:new(85, infoposition, warningtextline, 0, "txt_grey")
		table.insert(GUI.elms, infotext)
		infoposition = infoposition +20

		-- print(k, v)
	end


  -- info_device = GUI.Btn:new(568, 119, 20, 20,         " ?", show_menu, devicetext)
  -- table.insert(GUI.elms, info_device)

  show_devices()        -- Baue die rechte Seite mit den Audio-Interfaces

end

buildGUI()

--GUI.func = buildGUI   -- Dauerschleife

  GUI.func = set_values
  GUI.freq = 1          -- Aufruf jede Sekunde



-- Open Settings Screen, when it hasn't been opened yet

if reaper.GetExtState("Ultraschall_Windows", GUI.name) == "" then windowcounter=0 -- Check if window was ever opened yet(and external state for it exists already).  yes, use temporarily 0 as opened windows-counter;will be changed by ultraschall_gui_lib.lua later
else windowcounter=tonumber(reaper.GetExtState("Ultraschall_Windows", GUI.name)) end -- get number of opened windows

if windowcounter<1 then -- you can choose how many GUI.name-windows are allowed to be opened at the same time.
                        -- 1 means 1 window, 2 means 2 windows, 3 means 3 etc
  GUI.Init()
  GUI.Main()
end

function atexit()
  reaper.SetExtState("Ultraschall_Windows", GUI.name, 0, false)
end

reaper.atexit(atexit)
