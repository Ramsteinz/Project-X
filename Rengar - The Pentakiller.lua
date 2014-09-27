--------------------------------------------------------
--                Ramsteinz Present
--          
--             Rengar - The Pentakiller
--  
--  v1.01
--    -- KS with Ignite
--    -- Support some items auto cast
--    -- Free Lag Drawing
--  
--  v1.00
--    - Released
--           
--------------------------------------------------------
if myHero.charName ~= "Rengar" then return end

--------------------------------------------------------
--  Update Libs and Main Script
--------------------------------------------------------
local version = "1.01"
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
-- Variables
--------------------------------------------------------
local IG = nil
local TIASlot, RHSlot,  BCSlot, BRKSlot, YGSlot = nil, nil, nil, nil, nil
local TIAReady, RHReady, BCReady, BRKReady, YGReady = false, false, false, false, false

--------------------------------------------------------
-- Champion Specific Data
--------------------------------------------------------
function HeroData()
  RQEW = { 3,1,2,1,1,4,1,3,1,3,4,3,3,2,2,4,2,2 }
  Skill = {
    Q = { name = "Savagery", range = myHero.range + GetDistance(myHero, myHero.minBBox) },
    W = { name = "Battle Roar", range = 400 },
    E = { name = "Bola Strike", range = 1000, delay = 0, width = 70, speed = 1500, col = true },
    R = { name = "Thrill of the Hunt" }
  }
end

--------------------------------------------------------
-- OnLoad Function
--------------------------------------------------------
function OnLoad()
  Ferocity = false
  Stealth = false
  HeroData()
  VP = VPrediction()
  SOW = SOW(VP)
  Menu()
end

--------------------------------------------------------
-- OnTick Function
--------------------------------------------------------
function OnTick()  
  TIASlot = GetInventorySlotItem(3077) -- Tiamat
  RHSlot = GetInventorySlotItem(3074) -- Ravenous Hydra
  BCSlot = GetInventorySlotItem(3144) -- Bilgewater Cutlass
  BRKSlot = GetInventorySlotItem(3153) -- Blade of the Ruined King
  YGSlot = GetInventorySlotItem(3142) -- Youmuu's Ghostblade

  QREADY = myHero:CanUseSpell(_Q) == READY
  WREADY = myHero:CanUseSpell(_W) == READY
  EREADY = myHero:CanUseSpell(_E) == READY
  IREADY = (IG ~= nil and myHero:CanUseSpell(IG) == READY)
  TIAReady = (TIASlot ~= nil and myHero:CanUseSpell(TIASlot) == READY)
  RHReady = (RHSlot ~= nil and myHero:CanUseSpell(RHSlot) == READY)
  BCReady = (BCSlot ~= nil and myHero:CanUseSpell(BCSlot) == READY)
  BRKReady = (BRKSlot ~= nil and myHero:CanUseSpell(BRKSlot) == READY)
  YGReady = (YGSlot ~= nil and myHero:CanUseSpell(YGSlot) == READY)
  
  ts:update()
  enemyMinions:update()
  
  if Menu.Combo.key then
      Combo()
      CastItem()
      if IG ~= nil and Menu.Combo.ignite then
          AutoIgnite()
      end
  end
  if Menu.Harass.key then
      Harass()
  end
  if Menu.LaneClear.key then
      LaneClear()
  end
  if Menu.Extra.Level.auto then
      if Menu.Extra.Level.seq == 1 then
          autoLevelSetSequence(RQEW)
      end
  end
end

--------------------------------------------------------
-- Spells Function
--------------------------------------------------------
function Combo()
    if not Ferocity then
        if Menu.Combo.Normal.useE and EREADY and not Stealth then
            CastE(ts.target)
        end
        if Menu.Combo.Normal.useW and WREADY then
            CastW(ts.target)
        end
        if Menu.Combo.Normal.useQ and QREADY then
            CastQ(ts.target)
        end
    else
        if Menu.Combo.Ferocity.useW and WREADY then
            CastWFerocity()
        end
        if Menu.Combo.Ferocity.useQ and QREADY then
              CastQ(ts.target)
        end
        if Menu.Combo.Ferocity.useE and EREADY then
            CastE(ts.target)
        end
    end
end

function Harass()
    if not Ferocity then
        if Menu.Harass.useE and EREADY and not Stealth then
            CastE(ts.target)
        end
    end
end

function LaneClear()
    if enemyMinions ~= nil then
        for _, minion in pairs(enemyMinions.objects) do
            if not Ferocity then
                if Menu.LaneClear.useQ and QREADY then
                    CastQ(minion)
                end
                if Menu.LaneClear.useW and WREADY then
                    CastW(minion)
                end
                if Menu.LaneClear.useE and EREADY then
                    CastE(minion)
                end
            else
                if Menu.Combo.Ferocity.useW and WREADY then
                    CastWFerocity()
                end
                if Menu.Combo.Ferocity.useQ and QREADY then
                    CastQ(minion)
                end
                if Menu.Combo.Ferocity.useE and EREADY then
                    CastE(minion)
                end
            end
        end
    end
end

function CastE(Target)
    if ValidTarget(Target, Skill.E.range) then
        local CastPosition, HitChance, Position = VP:GetLineCastPosition(Target, Skill.E.delay, Skill.E.width, Skill.E.range, Skill.E.speed, myHero, true)
        if HitChance >= 2 then
            CastSpell(_E,CastPosition.x, CastPosition.z)
        end    
    end
end

function CastW(Target)
    if ValidTarget(Target, Skill.W.range -10) then
        CastSpell(_W)
    end
end

function CastWFerocity()
    if (myHero.health / myHero.maxHealth) * 100 <= Menu.Combo.Ferocity.useWhp then
        CastSpell(_W)
    end
end

function CastQ(Target)
    if ValidTarget(Target, Skill.Q.range) then
          CastSpell(_Q)
    end
end

function CastItem()
    if TIAReady and ValidTarget(ts.target, Skill.Q.range) then
        CastSpell(TIASlot)
    end
    if RHReady and ValidTarget(ts.target, Skill.Q.range) then
        CastSpell(RHSlot)
    end
    if BCReady and ValidTarget(ts.target, Skill.W.range) then
        CastSpell(BCSlot, ts.target)
    end
    if BRKReady and ValidTarget(ts.target, Skill.W.range) then
        CastSpell(BRKSlot, ts.target)
    end
    if YGReady and ValidTarget(ts.target, Skill.W.range) then
        CastSpell(YGSlot, ts.target)
    end
end

function AutoIgnite()
  if ValidTarget(ts.target, 600) and ts.target.health < getDmg("IGNITE", ts.target, myHero) then
      if IREADY then
          CastSpell(IG, ts.target)
      end
  end
end

--------------------------------------------------------
-- OnDraw Function
--------------------------------------------------------
function OnDraw()
    if Menu.Draw.w and Menu.Combo.Normal.useW and WREADY then
        if Menu.Draw.freeLag then
            DrawCircleFL(myHero.x, myHero.y, myHero.z, Skill.W.range, ARGB(150, 128, 128, 128))
        else
            DrawCircle(myHero.x, myHero.y, myHero.z, Skill.W.range, 0x111111)
        end
    end
    if Menu.Draw.e and Menu.Combo.Normal.useE and EREADY then
        if Menu.Draw.freeLag then
            DrawCircleFL(myHero.x, myHero.y, myHero.z, Skill.E.range, ARGB(150, 128, 128, 128))
        else
            DrawCircle(myHero.x, myHero.y, myHero.z, Skill.E.range, 0x111111)  
        end
    end
    if Menu.Draw.ad then
        if Menu.Draw.freeLag then
            DrawCircleFL(myHero.x, myHero.y, myHero.z, Skill.Q.range, ARGB(150, 128, 128, 128))
        else
            DrawCircle(myHero.x, myHero.y, myHero.z, Skill.Q.range, 0x111111)
        end
    end
end

function DrawCircleFL(x, y, z, radius, color)
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
-- OnCreateObj and OnDeleteObj for Ferocity
--------------------------------------------------------
function OnCreateObj(object)
  if object.name:find("Rengar_Base_P_Buf_Max.troy") then
      --PrintChat("Ferocity ON")
      Ferocity = true
  end
  if object.name:find("Rengar_Base_R_Cas.troy") then
      --PrintChat("I am Stealth")
      Stealth = true
  end
end

function OnDeleteObj(object)
  if object.name:find("Rengar_Base_P_Buf_Max.troy") then
    --PrintChat("Ferocity OFF")
    Ferocity = false
  end
  if object.name:find("Rengar_Base_R_Buf.troy") then
      --PrintChat("No more Stealth")
      Stealth = false
  end
end

--------------------------------------------------------
-- Create Menu
--------------------------------------------------------
function Menu()
  if myHero:GetSpellData(SUMMONER_1).name:find("summonerdot") then
      IG = SUMMONER_1
  elseif myHero:GetSpellData(SUMMONER_2).name:find("summonerdot") then
      IG = SUMMONER_2
  end

  Menu = scriptConfig("Rengar - The Pentakiller v"..version, "Ramsteinz")
  
  Menu:addSubMenu("Combo Settings", "Combo")
    Menu.Combo:addParam("key", "Combo Key", SCRIPT_PARAM_ONKEYDOWN, false, 32)
    if IG ~= nil then
        Menu.Combo:addParam("ignite", "Auto Ignite on killable target", SCRIPT_PARAM_ONOFF, true)
    end
      
  Menu.Combo:addSubMenu("Normal Stance Settings", "Normal")
    Menu.Combo.Normal:addParam("useQ", "(Q) - Use "..Skill.Q.name, SCRIPT_PARAM_ONOFF, true)
    Menu.Combo.Normal:addParam("useW", "(W) - Use "..Skill.W.name, SCRIPT_PARAM_ONOFF, true)
    Menu.Combo.Normal:addParam("useE", "(E) - Use "..Skill.E.name, SCRIPT_PARAM_ONOFF, true)
    Menu.Combo:addSubMenu("Ferocity Stance Settings", "Ferocity")
    Menu.Combo.Ferocity:addParam("useQ", "(Q) - Use "..Skill.Q.name, SCRIPT_PARAM_ONOFF, true)
    Menu.Combo.Ferocity:addParam("useW", "(W) - Use "..Skill.W.name, SCRIPT_PARAM_ONOFF, true)
    Menu.Combo.Ferocity:addParam("useWhp", "(W) - Min. % HP to Cast Spell", SCRIPT_PARAM_SLICE, 65, 0, 100, 0)
    Menu.Combo.Ferocity:addParam("useE", "(E) - Use "..Skill.E.name, SCRIPT_PARAM_ONOFF, false)
    
  Menu:addSubMenu("Harass Setting", "Harass")
    Menu.Harass:addParam("key", "Harass Key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
    Menu.Harass:addParam("useE", "(E) - Use "..Skill.E.name, SCRIPT_PARAM_ONOFF, true)
  
  Menu:addSubMenu("Lane Clear Settings", "LaneClear")
    Menu.LaneClear:addParam("key", "Lane Clear Key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
    Menu.LaneClear:addParam("useQ", "(Q) - Use "..Skill.Q.name, SCRIPT_PARAM_ONOFF, true)
    Menu.LaneClear:addParam("useW", "(W) - Use "..Skill.W.name, SCRIPT_PARAM_ONOFF, true)
    Menu.LaneClear:addParam("useE", "(E) - Use "..Skill.E.name, SCRIPT_PARAM_ONOFF, false)
    
  Menu:addSubMenu("Draw Settings", "Draw")
    Menu.Draw:addParam("freeLag", "Use Free Lag Draw", SCRIPT_PARAM_ONOFF, false)
    Menu.Draw:addParam("ad", "(AD) - Draw Attack range", SCRIPT_PARAM_ONOFF, true)
    Menu.Draw:addParam("w", "(W) - Draw "..Skill.W.name.." range", SCRIPT_PARAM_ONOFF, true)
    Menu.Draw:addParam("e", "(E) - Draw "..Skill.E.name.." range", SCRIPT_PARAM_ONOFF, true)
    
  Menu:addSubMenu("Extra Settings", "Extra")
    Menu.Extra:addSubMenu("Auto Level", "Level")
    Menu.Extra.Level:addParam("auto", "Enable auto level", SCRIPT_PARAM_ONOFF, false)
    Menu.Extra.Level:addParam("seq", "Auto Level Sequence", SCRIPT_PARAM_LIST, 1, { "RQEW" })
      
  Menu:addSubMenu("Orbwalking Settings", "Orbwalking")
    SOW:LoadToMenu(Menu.Orbwalking)
      
  ts = TargetSelector(TARGET_CLOSEST, Skill.E.range, DAMAGE_PHYSIC, false)
  ts.name = "Rengar"
  Menu:addTS(ts)
  
  enemyMinions = minionManager(MINION_ENEMY, Skill.E.range, myHero, MINION_SORT_MAXHEALTH_DEC)
end
