--------------------------------------------------------
--                Ramsteinz Present
--          
--             Rengar - The Pentakiller
--  
--  v1.00
--    - Released
--           
--------------------------------------------------------
if myHero.charName ~= "Rengar" then return end

--------------------------------------------------------
--  Update Libs and Main Script
--------------------------------------------------------
local version = "1.00"
local DOWNLOADING_LIBS, DOWNLOAD_COUNT = false, 0
local UPDATE_NAME = "Rengar - The Pentakiller"
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/Ramsteinz/Project-X/master/Rengar%20-%20The%20Pentakiller.lua" .. "?rand=" .. math.random(1, 10000)
local UPDATE_FILE_PATH = SCRIPT_PATH..UPDATE_NAME..".lua"
local UPDATE_URL = "http://"..UPDATE_HOST..UPDATE_PATH
local REQUIRED_LIBS = nil
if VIP_USER then
  REQUIRED_LIBS = {
    ["SOW"] = "https://raw.githubusercontent.com/Ramsteinz/Project-X/master/SOW.lua",
    ["VPrediction"] = "https://raw.githubusercontent.com/Ramsteinz/Project-X/master/VPrediction.lua",
    ["Prodiction"] = "https://raw.githubusercontent.com/Ramsteinz/Project-X/master/Prodiction.lua"
  }
else
  REQUIRED_LIBS = {
    ["SOW"] = "https://raw.githubusercontent.com/Ramsteinz/Project-X/master/SOW.lua",
    ["VPrediction"] = "https://raw.githubusercontent.com/Ramsteinz/Project-X/master/VPrediction.lua"
  }
end

_G.UseUpdater = true

function AfterDownload()
  DOWNLOAD_COUNT = DOWNLOAD_COUNT - 1
  if DOWNLOAD_COUNT == 0 then
    DOWNLOADING_LIBS = false
    print("<b><font color=\"#6699FF\">Rengar - The Pentakiller</font></b> <font color=\"#FFFFFF\">Required libraries downloaded successfully, please reload (double F9).</font>")
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

--------------------------------------------------------
-- Champion Specific Data
--------------------------------------------------------
function HeroData()
  LvlSeqREQW = { 3,1,2,3,3,4,1,3,1,3,4,1,1,2,2,4,2,2 }
  Skill = {
    Q = { name = "Savagery", range = myHero.range + GetDistance(myHero, myHero.minBBox) },
    W = { name = "Battle Roar", range = 400 },
    E = { name = "Bola Strike", range = 1000, delay = 0.5, width = 70, speed = 1500, col = true },
    R = { name = "Thrill of the Hunt" }
  }
end

--------------------------------------------------------
-- OnLoad Function
--------------------------------------------------------
function OnLoad()
  Ferocity = false
  HeroData()
  VP = VPrediction()
  SOW = SOW(VP)
  Menu()
end

function OnTick()
  QREADY = myHero:CanUseSpell(_Q) == READY
  WREADY = myHero:CanUseSpell(_W) == READY
  EREADY = myHero:CanUseSpell(_E) == READY
  
  ts:update()
  
  if Menu.Combo.key then
      if not Ferocity then
          if Menu.Combo.Normal.useE and EREADY then
              CastE()
          end
          if Menu.Combo.Normal.useW and WREADY then
              CastW()
          end
          if Menu.Combo.Normal.useQ and QREADY then
              CastQ()
          end
      else
          if Menu.Combo.Ferocity.useW and WREADY then
              CastWFerocity()
          end
          if Menu.Combo.Ferocity.useQ and QREADY then
              CastQ()
          end
          if Menu.Combo.Ferocity.useE and EREADY then
              CastE()
          end
      end
  end

  autoLevelSetSequence(LvlSeqREQW)
end

function CastE()
    if ValidTarget(ts.target, Skill.E.range) then
        local CastPosition, HitChance, Position = VP:GetLineCastPosition(ts.target, Skill.E.delay, Skill.E.width, Skill.E.range, Skill.E.speed, myHero, true)
        if HitChance >= 2 then
            CastSpell(_E,CastPosition.x, CastPosition.z)
        end    
    end
end

function CastW()
    if ValidTarget(ts.target, Skill.W.range -10) then
        CastSpell(_W)
    end
end

function CastWFerocity()
    if (myHero.health / myHero.maxHealth) * 100 <= Menu.Combo.Ferocity.useWhp then
        CastSpell(_W)
    end
end

function CastQ()
    if ValidTarget(ts.target, Skill.Q.range) then
          CastSpell(_Q)
    end
end

--------------------------------------------------------
-- OnDraw Function
--------------------------------------------------------
function OnDraw()
    if Menu.Combo.Normal.useW and WREADY then
        DrawCircle(myHero.x, myHero.y, myHero.z, Skill.W.range, 0x00FF00)
    end
    if Menu.Combo.Normal.useE and EREADY then
        DrawCircle(myHero.x, myHero.y, myHero.z, Skill.E.range, 0x111111)  
    end
    DrawCircle(myHero.x, myHero.y, myHero.z, Skill.Q.range, 0x111111)
end

--------------------------------------------------------
-- OnCreateObj and OnDeleteObj for Ferocity
--------------------------------------------------------
function OnCreateObj(object)
  if object.name:find("Rengar_Base_P_Buf_Max.troy") then
    --PrintChat("Ferocity ON")
    Ferocity = true
  end
end

function OnDeleteObj(object)
  if object.name:find("Rengar_Base_P_Buf_Max.troy") then
    --PrintChat("Ferocity OFF")
    Ferocity = false
  end
end

function OnWndMsg(msg,key)

end

function OnSendChat(txt)

end

function OnProcessSpell(owner,spell)

end

--------------------------------------------------------
-- Create Menu
--------------------------------------------------------
function Menu()
  Menu = scriptConfig("Rengar v"..version, "Ramsteinz")
  
  Menu:addSubMenu("Combo Settings", "Combo")
    Menu.Combo:addParam("key", "Combo Key", SCRIPT_PARAM_ONKEYDOWN, false, 32)
      
  Menu.Combo:addSubMenu("Normal Stance Settings", "Normal")
    Menu.Combo.Normal:addParam("useQ", "(Q) - Use "..Skill.Q.name, SCRIPT_PARAM_ONOFF, true)
    Menu.Combo.Normal:addParam("useW", "(W) - Use "..Skill.W.name, SCRIPT_PARAM_ONOFF, true)
    Menu.Combo.Normal:addParam("useE", "(E) - Use "..Skill.E.name, SCRIPT_PARAM_ONOFF, true)
    Menu.Combo:addSubMenu("Ferocity Stance Settings", "Ferocity")
    Menu.Combo.Ferocity:addParam("useQ", "(Q) - Use "..Skill.Q.name, SCRIPT_PARAM_ONOFF, true)
    Menu.Combo.Ferocity:addParam("useW", "(W) - Use "..Skill.W.name, SCRIPT_PARAM_ONOFF, true)
    Menu.Combo.Ferocity:addParam("useWhp", "(W) - Min. % HP to Cast Spell", SCRIPT_PARAM_SLICE, 65, 0, 100, 0)
    Menu.Combo.Ferocity:addParam("useE", "(E) - Use "..Skill.E.name, SCRIPT_PARAM_ONOFF, true)
  
  Menu:addSubMenu("Lane Clear Settings", "LaneClear")
    Menu.LaneClear:addParam("key", "Lane Clear Key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
    Menu.LaneClear:addParam("useQ", "(Q) - Use "..Skill.Q.name, SCRIPT_PARAM_ONOFF, true)
    Menu.LaneClear:addParam("useW", "(W) - Use "..Skill.W.name, SCRIPT_PARAM_ONOFF, true)
    Menu.LaneClear:addParam("useE", "(E) - Use "..Skill.E.name, SCRIPT_PARAM_ONOFF, false)
      
  Menu:addSubMenu("Orbwalking Settings", "Orbwalking")
    SOW:LoadToMenu(Menu.Orbwalking)
      
  ts = TargetSelector(TARGET_CLOSEST, Skill.E.range, DAMAGE_PHYSIC, false)
  ts.name = "Rengar"
  Menu:addTS(ts)
end
