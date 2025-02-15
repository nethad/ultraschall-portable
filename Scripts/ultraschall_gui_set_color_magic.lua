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

-----------------
-- Functions
-----------------

function getNextColor (LastColor)

  local ColorPosition = t_invert[LastColor]

  -- print (ColorPosition)

  if ColorPosition == nil then
    ColorPosition = 0
  elseif ColorPosition > 9 then
    ColorPosition = ColorPosition - 9
  else
    ColorPosition = ColorPosition + 2
  end

  return t[ColorPosition]

end


function swapColors (color)

  if string.match(os, "OS") then
    r, g, b = reaper.ColorFromNative(color)
    -- print ("NewTrack: "..TrackColor.."-"..r.."-"..g.."-"..b)
    color = reaper.ColorToNative(b, g, r)
  end
  return color

end


function countColoredStudioLinkTracks ()

  local count = 0
  for i=1, numberOfTracks do

    local tracktype = ultraschall.GetTypeOfTrack(i)
    -- print (tracktype)
    if tracktype == "StudioLink" then

      local MediaTrack = reaper.GetTrack(0, i-1)
      local TrackColor = reaper.GetTrackColor(MediaTrack)
      -- print (TrackColor)
      if TrackColor ~= 0 then
        count = count +1
      end
    end
  end

  return count
end


-----------------
-- End of Functions
-----------------


-----------------
-- Init
-----------------

numberOfTracks = reaper.CountTracks(0)
max_color = 20  -- Number of colors to cycle
curtheme = reaper.GetLastColorThemeFile()
os = reaper.GetOS()
LastColor = 0
StudioLinkNr = 0
colored = 0

---------------------------------------------------------
-- Init: build table with color values from theme file
---------------------------------------------------------

t = {}   -- initiate table
t_invert = {}
file = io.open(curtheme, "r");

for line in file:lines() do
  index = string.match(line, "group_(%d+)")  -- use "Group" section
  index = tonumber(index)
    if index then
      if index < max_color then
      color_int = string.match(line, "=(%d+)")  -- get the color value
      -- color_int = swapColors (color_int)
      t[index] = tonumber(color_int)  -- put color into table
      t_invert[tonumber(color_int)] = index
    end
  end
end


--[[
for key,value in pairs(t_invert) do
  print (key.."-"..value)
end
]]

-----------------
-- Main
-----------------

for i=0, numberOfTracks-1 do

  MediaTrack = reaper.GetTrack(0, i)
  TrackColor = reaper.GetTrackColor(MediaTrack)
  TrackColor = swapColors(TrackColor)

  -- print(TrackColor)
  -- print(tostring(TrackColor))


  if TrackColor == 0 then -- frische Spur, noch keine Farbe gesetzt

    tracktype = ultraschall.GetTypeOfTrack(i+1)
    -- print (tracktype)

    if tracktype == "SoundBoard" then

      soundboardColor = reaper.ColorToNative(100, 100, 100)
      reaper.SetTrackColor(MediaTrack, soundboardColor)

    elseif tracktype == "StudioLink" then

      colored = countColoredStudioLinkTracks() or 0
      -- print (colored)
      StudioLinkColor = t[colored + 11]
      reaper.SetTrackColor(MediaTrack, swapColors(StudioLinkColor))
      StudioLinkNr = StudioLinkNr + 1

    else -- normaler Track

      NewTrackColor = getNextColor(LastColor)
      r, g, b = reaper.ColorFromNative(NewTrackColor)
      -- print ("NewTrack: "..NewTrackColor.."-"..r.."-"..g.."-"..b)
      -- NewTrackColor = reaper.ColorToNative(b, g, r)

      reaper.SetTrackColor(MediaTrack, swapColors(NewTrackColor))
      TrackColor = NewTrackColor
    end
  end

  LastColor = TrackColor

end