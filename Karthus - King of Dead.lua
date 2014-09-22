--------------------------------------------------------
--                Ramsteinz Present
--          
--             Karthus - King of Dead
-- 
--  v1.01
--    - Ult Notify modification (No More Spam)
--  
--  v1.00
--    - Released
--           
--------------------------------------------------------
if myHero.charName ~= "Karthus" then return end

--------------------------------------------------------
--  Update Libs and Main Script
--------------------------------------------------------
local version = "1.01"
local DOWNLOADING_LIBS, DOWNLOAD_COUNT = false, 0
local UPDATE_NAME = "Karthus - King of Dead"
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/Ramsteinz/Project-X/master/Karthus%20-%20King%20of%20Dead.lua" .. "?rand=" .. math.random(1, 10000)
local UPDATE_FILE_PATH = SCRIPT_PATH..UPDATE_NAME..".lua"
local UPDATE_URL = "http://"..UPDATE_HOST..UPDATE_PATH
local REQUIRED_LIBS = {
  ["SOW"] = "https://raw.githubusercontent.com/Ramsteinz/Project-X/master/SOW.lua",
  ["VPrediction"] = "https://raw.githubusercontent.com/Ramsteinz/Project-X/master/VPrediction.lua",
}

_G.UseUpdater = true

function AfterDownload()
  DOWNLOAD_COUNT = DOWNLOAD_COUNT - 1
  if DOWNLOAD_COUNT == 0 then
    DOWNLOADING_LIBS = false
    print("<b><font color=\"#6699FF\">Karthus - King of Dead</font></b> <font color=\"#FFFFFF\">Required libraries downloaded successfully, please reload (double F9).</font>")
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
  LvlSeqQERW = { 1,3,1,2,1,4,3,1,1,3,4,3,3,2,2,4,2,2 }
  Skill = {
    Q = { name = "Lay Waste", range = 875, delay = 0.5, width = 160, speed = 1000, col = false },
    W = { name = "Wall of Pain", range = 1000, delay = 0.5, width = 525, speed = 1600, col = false },
    E = { name = "Defile", range = 525 },
    R = { name = "Requiem" }
  }
end

--------------------------------------------------------
-- OnLoad Function
--------------------------------------------------------
function OnLoad()
  EACTIVE = false
  isKillable = 0
  HeroData()
  VP = VPrediction()
  SOW = SOW(VP)
  Menu()
end

--------------------------------------------------------
-- OnTick Function
--------------------------------------------------------
function OnTick()
  QREADY = myHero:CanUseSpell(_Q) == READY
  EREADY = myHero:CanUseSpell(_E) == READY
  WREADY = myHero:CanUseSpell(_W) == READY
  RREADY = myHero:CanUseSpell(_R) == READY
  
  ts:update()
  enemyMinions:update()
  
  CastR()
  if Menu.Combo.key then
    if QREADY and Menu.Combo.useQ then
      CastQ()
    end
    if WREADY and Menu.Combo.useW then
      CastW()
    end
  end
  if EREADY and Menu.AutoE.enable then
    CastE()
  end
  
  if Menu.Farm.key then
    Farm()
  end
  
  if Menu.Extra.level then
    if Menu.Extra.seq == 1 then
      autoLevelSetSequence(LvlSeqQERW)
    end
  end
end

--------------------------------------------------------
-- Combo Functions
--------------------------------------------------------
function CastQ()
  if ValidTarget(ts.target, Skill.Q.range) then
    if  GetDistance(ts.target) < Skill.Q.range then
      local CastPosition, HitChance, nTargets = VP:GetCircularAOECastPosition(ts.target, Skill.Q.delay, Skill.Q.width, Skill.Q.range, Skill.Q.speed, myHero)
      if HitChance >= 2 then
        CastSpell(_Q, CastPosition.x, CastPosition.z)
      end
    end
  end
end

function CastW()
  if ValidTarget(ts.target, Skill.W.range) then
    if GetDistance(ts.target) <= Skill.W.range then
      local CastPosition, HitChance, Position = VP:GetLineCastPosition(ts.target, Skill.W.delay, Skill.W.width, Skill.W.range, Skill.W.speed, myHero, Skill.W.col)
      if HitChance >= 2 then
        CastSpell(_W, CastPosition.x, CastPosition.z)
      end
    end
  end
end

--------------------------------------------------------
-- CastE if Target Get Too Close
--------------------------------------------------------
function CastE()
  if ValidTarget(ts.target, Skill.E.range) then
    if GetDistance(ts.target) < Skill.E.range and not EACTIVE then
      if (myHero.mana / myHero.maxMana) * 100 > Menu.AutoE.mana then
        CastSpell(_E)
      end
    end
  elseif ts.target == nil or GetDistance(ts.target) > Skill.E.range then
    if EACTIVE then
      CastSpell(_E)
    end
  end
end

--------------------------------------------------------
-- CastR if One or More Target can Be Kill 
--------------------------------------------------------
function CastR()
  isKillable = 0
  players = heroManager.iCount
  for i = 1, players, 1 do
    target = heroManager:getHero(i)
    if target ~= nil and target.team ~= player.team and target.visible and not target.dead then
      rDmg = getDmg("R",target,myHero)
      if rDmg > target.health then
        isKillable = isKillable + 1
        if Menu.Ult.auto then
          CastSpell(_R)
        end
      end
    end
  end
end

--------------------------------------------------------
-- Farm Function
--------------------------------------------------------
function Farm()
  if Menu.Farm.key then
    if enemyMinions ~= nil then
      for _, minion in pairs(enemyMinions.objects) do
        if ValidTarget(minion, Skill.Q.range) then
          if minion.health <= getDmg("AD", minion, myHero) then
            myHero:Attack(minion)
          else
            if Menu.Farm.useQ then
              local CastPosition, HitChance, nTargets = VP:GetCircularAOECastPosition(minion, Skill.Q.delay, Skill.Q.width, Skill.Q.range, Skill.Q.speed, myHero)
              if HitChance >= 2 and nTargets >= 1 then
                CastSpell(_Q, CastPosition.x, CastPosition.z)
              end
            end
            if Menu.Farm.useE then
              if GetDistance(minion) < Skill.E.range and not EACTIVE then
                CastSpell(_E)
              end
            end
          end
        end
      end
    end
  end
end

--------------------------------------------------------
-- OnDraw Function
--------------------------------------------------------
function OnDraw()
  if RREADY and isKillable > 0 then
    local heroPos = WorldToScreen(D3DXVECTOR3(myHero.x,myHero.y,myHero.z))
    DrawText("Target Killable : "..isKillable, 24, heroPos.x - 80, heroPos.y - 150,ARGB(255,0,255,0))
  end
  if Menu.Draw.enable then
    if QREADY and Menu.Draw.drawQ then
      DrawCircle(myHero.x, myHero.y, myHero.z, Skill.Q.range, 0x111111)
    end
    if WREADY and Menu.Draw.drawW then
      DrawCircle(myHero.x, myHero.y, myHero.z, Skill.W.range, 0x111111)
    end
    if EREADY and Menu.Draw.drawE then
      DrawCircle(myHero.x, myHero.y, myHero.z, Skill.E.range, 0x111111)
    end
  end
end

--------------------------------------------------------
-- Create and Delete Objet
-- E cast condition
--------------------------------------------------------
function OnCreateObj(object)
  if object.name == "Karthus_Base_E_Defile.troy" then
    EACTIVE = true
  end
end

function OnDeleteObj(object)
  if object.name == "Karthus_Base_E_Defile.troy" then
    EACTIVE = false
  end
end

--------------------------------------------------------
-- Create Menu
--------------------------------------------------------
function Menu()
  Menu = scriptConfig("Karthus - King of Death v"..version, "Ramsteinz")
  
  Menu:addSubMenu("Combo Settings", "Combo")
    Menu.Combo:addParam("key", "Combo Key", SCRIPT_PARAM_ONKEYDOWN, false, 32)
    Menu.Combo:addParam("useQ", "(Q) - Use "..Skill.Q.name.." in combo", SCRIPT_PARAM_ONOFF, true)
    Menu.Combo:addParam("useW", "(W) - Use "..Skill.W.name.." in combo", SCRIPT_PARAM_ONOFF, true)
    
  Menu:addSubMenu("(E) Auto Settings", "AutoE")
    Menu.AutoE:addParam("enable", "(E) - Auto Cast when target in range", SCRIPT_PARAM_ONOFF, true)
    Menu.AutoE:addParam("mana", "Min. (%) Mana to Cast", SCRIPT_PARAM_SLICE, 20, 0, 100, 0)
  
  Menu:addSubMenu("(R) Ult Settings", "Ult")
    Menu.Ult:addParam("auto", "Auto Cast Ult on Killable Enemies", SCRIPT_PARAM_ONOFF, false)
  
  Menu:addSubMenu("Farm Settings", "Farm")
    Menu.Farm:addParam("key", "Farm Key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
    Menu.Farm:addParam("useQ", "(Q) - Use "..Skill.Q.name.." to farm", SCRIPT_PARAM_ONOFF, true)
    Menu.Farm:addParam("useE", "(E) - Use "..Skill.E.name.." to farm", SCRIPT_PARAM_ONOFF, false)
    
  Menu:addSubMenu("Draw Settings", "Draw")
    Menu.Draw:addParam("enable", "Enable Drawing", SCRIPT_PARAM_ONOFF, true)
    Menu.Draw:addParam("drawQ", "(Q) - Draw "..Skill.Q.name.." range", SCRIPT_PARAM_ONOFF, true)
    Menu.Draw:addParam("drawW", "(W) - Draw "..Skill.W.name.." range", SCRIPT_PARAM_ONOFF, false)
    Menu.Draw:addParam("drawE", "(E) - Draw "..Skill.E.name.." range", SCRIPT_PARAM_ONOFF, false)
    
  Menu:addSubMenu("Extra Settings", "Extra")
    Menu.Extra:addParam("level", "Auto Level enable", SCRIPT_PARAM_ONOFF, false)
    Menu.Extra:addParam("seq", "Auto Level Sequence Priority", SCRIPT_PARAM_LIST, 1, { "Q-E-R-W" })
  
  Menu:addSubMenu("Orbwalking Settings", "Orbwalking")
    SOW:LoadToMenu(Menu.Orbwalking)
    
  ts = TargetSelector(TARGET_LESS_CAST_PRIORITY, Skill.W.range, DAMAGE_MAGIC, true)
  ts.name = "Karthus"
  Menu:addTS(ts)
  
  enemyMinions = minionManager(MINION_ENEMY, Skill.Q.range, myHero, MINION_SORT_MAXHEALTH_DEC)
end
