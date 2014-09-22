--------------------------------------------------------
--                Ramsteinz Present
--          
--             Karthus - King of Dead
-- 
--  v1.02
--    - Prodiction 1.4 support [VIP] 
--    - Packet Cast added [VIP]
--    - Free Lag Circle added [Free\VIP]
--  
--  v1.01
--    - Ult Notify modification (No More Spam) [Free\VIP]
--  
--  v1.00
--    - Released
--           
--------------------------------------------------------
if myHero.charName ~= "Karthus" then return end

--------------------------------------------------------
--  Update Libs and Main Script
--------------------------------------------------------
local version = "1.02"
local DOWNLOADING_LIBS, DOWNLOAD_COUNT = false, 0
local UPDATE_NAME = "Karthus - King of Dead"
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/Ramsteinz/Project-X/master/Karthus%20-%20King%20of%20Dead.lua" .. "?rand=" .. math.random(1, 10000)
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
  if VIP_USER then
    Prod = ProdictManager.GetInstance()
    UseQ = Prod:AddProdictionObject(_Q, Skill.Q.range, Skill.Q.speed, Skill.Q.delay, Skill.Q.width)
    UseW = Prod:AddProdictionObject(_W, Skill.W.range, Skill.W.speed, Skill.W.delay, Skill.W.width)
  end
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
      if VIP_USER then
        if Menu.Combo.predict == 1 then
          local CastPosition, HitChance, nTargets = VP:GetCircularAOECastPosition(ts.target, Skill.Q.delay, Skill.Q.width, Skill.Q.range + 50, Skill.Q.speed, myHero)
          if HitChance >= 2 then
            if Menu.Combo.packet then
              Packet("S_CAST", { spellID = _Q, fromX = CastPosition.x, fromY = CastPosition.z, toX = CastPosition.x, toY = CastPosition.z }):send()
            else
              CastSpell(_Q, CastPosition.x, CastPosition.z)
            end
          end
        elseif Menu.Combo.predict == 2 then
          local CastPosition, Infos = UseQ:GetPrediction(ts.target)
          CastSpell(_Q, CastPosition.x, CastPosition.z)
        end
      else
        local CastPosition, HitChance, nTargets = VP:GetCircularAOECastPosition(ts.target, Skill.Q.delay, Skill.Q.width, Skill.Q.range + 50, Skill.Q.speed, myHero)
        if HitChance >= 2 then 
          CastSpell(_Q, CastPosition.x, CastPosition.z)
        end         
      end
    end
  end
end

function CastW()
  if ValidTarget(ts.target, Skill.W.range) then
    if GetDistance(ts.target) <= Skill.W.range then
      if VIP_USER then
        if Menu.Combo.predict == 1 then
          local CastPosition, HitChance, nTargets = VP:GetCircularAOECastPosition(ts.target, Skill.W.delay, Skill.W.width, Skill.W.range + 50, Skill.W.speed, myHero)
          if HitChance >= 2 then
            if Menu.Combo.packet then
              Packet("S_CAST", { spellID = _W, fromX = CastPosition.x, fromY = CastPosition.z, toX = CastPosition.x, toY = CastPosition.z }):send()
            else
              CastSpell(_W, CastPosition.x, CastPosition.z)
            end
          end
        elseif Menu.Combo.predict == 2 then
          local CastPosition, Infos = UseW:GetPrediction(ts.target)
          CastSpell(_W, CastPosition.x, CastPosition.z)
        end
      else
        local CastPosition, HitChance, nTargets = VP:GetCircularAOECastPosition(ts.target, Skill.W.delay, Skill.W.width, Skill.W.range + 50, Skill.W.speed, myHero)
        if HitChance >= 2 then 
          CastSpell(_W, CastPosition.x, CastPosition.z)
        end         
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
      DrawCircle2(myHero.x, myHero.y, myHero.z, Skill.Q.range, ARGB(150, 128, 128, 128))
    end
    if WREADY and Menu.Draw.drawW then
      DrawCircle2(myHero.x, myHero.y, myHero.z, Skill.W.range, ARGB(150, 128, 128, 128))
    end
    if EREADY and Menu.Draw.drawE then
      DrawCircle2(myHero.x, myHero.y, myHero.z, Skill.E.range, ARGB(150, 128, 128, 128))
    end
  end
end

function DrawCircle2(x, y, z, radius, color)
  local vPos1 = Vector(x, y, z)
  local vPos2 = Vector(cameraPos.x, cameraPos.y, cameraPos.z)
  local tPos = vPos1 - (vPos1 - vPos2):normalized() * radius
  local sPos = WorldToScreen(D3DXVECTOR3(tPos.x, tPos.y, tPos.z))
  if Menu.Draw.freeLag and OnScreen({ x = sPos.x, y = sPos.y }, { x = sPos.x, y = sPos.y })  then
    DrawCircleNextLvl(x, y, z, radius, 1, color, 75)
  else
    DrawCircle(x, y, z, radius, 0xFF111111)
  end
end

function DrawCircleNextLvl(x, y, z, radius, width, color, chordlength)
  radius = radius or 300
  quality = math.max(8,math.floor(180/math.deg((math.asin((chordlength/(2*radius)))))))
  quality = 2 * math.pi / quality
  radius = radius*.92
  local points = {}
  for theta = 0, 2 * math.pi + quality, quality do
    local c = WorldToScreen(D3DXVECTOR3(x + radius * math.cos(theta), y, z - radius * math.sin(theta)))
    points[#points + 1] = D3DXVECTOR2(c.x, c.y)
  end
  DrawLines2(points, width or 1, color or 4294967295)
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
    if VIP_USER then
      Menu.Combo:addParam("predict", "Prediction settings to load", SCRIPT_PARAM_LIST, 1, { "VPred", "Prodiction"})
    end
    Menu.Combo:addParam("key", "Combo Key", SCRIPT_PARAM_ONKEYDOWN, false, 32)
    if VIP_USER then
      Menu.Combo:addParam("packet", "Use packet to cast spells", SCRIPT_PARAM_ONOFF, false)
    end
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
    Menu.Draw:addParam("freeLag", "Use Free Lag Draw", SCRIPT_PARAM_ONOFF, true)
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
