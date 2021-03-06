--------------------------------------------------------
--                Ramsteinz Present
--          
--                 Project-X Ahri
--  
--  v1.00
--    - Released
--           
--------------------------------------------------------
if myHero.charName ~= "Ahri" then return end

--------------------------------------------------------
--  Update Libs and Main Script
--------------------------------------------------------
local version = "1.00"
local DOWNLOADING_LIBS, DOWNLOAD_COUNT = false, 0
local UPDATE_NAME = "Project-X Ahri"
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/Ramsteinz/Project-X/master/Project-X%20Ahri.lua" .. "?rand=" .. math.random(1, 10000)
local UPDATE_FILE_PATH = SCRIPT_PATH..UPDATE_NAME..".lua"
local UPDATE_URL = "http://"..UPDATE_HOST..UPDATE_PATH
local REQUIRED_LIBS = nil
REQUIRED_LIBS = {
  ["SOW"] = "https://raw.githubusercontent.com/Ramsteinz/Project-X/master/SOW.lua",
  ["VPrediction"] = "https://raw.githubusercontent.com/Ramsteinz/Project-X/master/VPrediction.lua"
}

_G.UseUpdater = true

function AfterDownload()
  DOWNLOAD_COUNT = DOWNLOAD_COUNT - 1
  if DOWNLOAD_COUNT == 0 then
    DOWNLOADING_LIBS = false
    print("<b><font color=\"#6699FF\">Project-X Ahri</font></b> <font color=\"#FFFFFF\">Required libraries downloaded successfully, please reload (double F9).</font>")
  end
end

for DOWNLOAD_LIB_NAME, DOWNLOAD_LIB_URL in pairs(REQUIRED_LIBS) do
  if FileExist(LIB_PATH .. DOWNLOAD_LIB_NAME .. ".lua") then
    require(DOWNLOAD_LIB_NAME)
  else
    DOWNLOADING_LIBS = true
    DOWNLOAD_COUNT = DOWNLOAD_COUNT + 1
    DownloadFile(DOWNLOAD_LIB_URL, LIB_PATH .. DOWNLOAD_LIB_NAME..".lua", AfterDownload)
  end
end

if DOWNLOADING_LIBS then return end

function AutoupdaterMsg(msg) print("<b><font color=\"#6699FF\">"..UPDATE_NAME..":</font></b> <font color=\"#FFFFFF\">"..msg..".</font>") end
if _G.UseUpdater then
  local ServerData = GetWebResult(UPDATE_HOST, UPDATE_PATH)
  if ServerData then
    local ServerVersion = string.match(ServerData, "local version = \"%d+.%d+\"")
    ServerVersion = string.match(ServerVersion and ServerVersion or "", "%d+.%d+")
    if ServerVersion then
      ServerVersion = tonumber(ServerVersion)
      if tonumber(version) < ServerVersion then
        AutoupdaterMsg("New version available"..ServerVersion)
        AutoupdaterMsg("Updating, please don't press F9")
        DownloadFile(UPDATE_URL, UPDATE_FILE_PATH, function () AutoupdaterMsg("Successfully updated. ("..version.." => "..ServerVersion.."), press F9 twice to load the updated version.") end)  
      else
        AutoupdaterMsg("You have got the latest version ("..ServerVersion..")")
      end
    end
  else
    AutoupdaterMsg("Error downloading version info")
  end
end
