VFrame = VFrame or {
    registered = {}
}

function VFrame:new(group)
    local newObj = {}
    setmetatable(newObj, self)
    self.__index = self

    newObj.chatGroup = group
    newObj.slots = {"11", "12", "13", "21", "22", "23", "31", "32", "33"}
    newObj.form = {}

    return newObj
end


function VFrame:playerData(playerInfo)

    local name, hp, maxHp, mana, maxMana, buffs = string.match(playerInfo, "(%S+),(%d+),(%d+),(%d+),(%d+),(.*)")

    if not (name or hp or maxHp or mana or maxMana) then
        return
    end

    -- find player in slot
    local found, slot = self:findSlot(name)
    if found then
        --display("Found " .. from .. " in slot " .. slot) 

        -- parse playerInfo
        --display("playerInfo for "..from.." '"..playerInfo.."'")

        --display("got data from: " .. from)
        hp = tonumber(hp)
        maxHp = tonumber(maxHp)
        mana = tonumber(mana)
        maxMana = tonumber(maxMana)

        self.form[slot].hpBar:setValue(hp, maxHp, "<b>"..hp.."hp</b>")
        local hpSheet = self:getStyleSheet(hp, maxHp)
        self.form[slot].hpBar.front:setStyleSheet(hpSheet)

        self.form[slot].manaBar:setValue(mana, maxMana, "<b>"..mana.."mn</b>")
        local manaSheet = self:getStyleSheet(mana, maxMana)
        self.form[slot].manaBar.front:setStyleSheet(manaSheet)

    else
        VFrame.registerPlayer(name)
    end

end


function VFrame.registerPlayer(name)
    table.insert(VFrame.registered, name)
end

function VFrame.listAvailable()
    echo("Available VFrames:\n")
    for k, v in pairs(VFrame.registered) do
        echo(v .. "\n")
    end
    cecho("<white>Type <yellow>vfadd <player><white> to add them to your frame\n")
end


function VFrame:sendPlayerData(myStats)

    local outStr = string.format("%s,%d,%d,%d,%d,%s",
      chatName(), myStats.hp, myStats.maxHp, myStats.mana, myStats.maxMana, myStats.buffs)

    --display("chatGroup: " .. self.chatGroup .. " msg: " .. outStr)
    chatSideChannel(self.chatGroup, outStr)
end

function VFrame:findSlot(playerName)
  playerName = string.lower(playerName)

  for _, slot in ipairs(self.slots) do
    -- Check if the slot is empty
    if self.form[slot] ~= nil then
      if self.form[slot].player and self.form[slot].player == playerName then
        return true, slot
      end
    end
  end
  return false
end

function VFrame:findEmptySlot(playerName)
  playerName = string.lower(playerName)

  for _, slot in ipairs(self.slots) do
    -- Check if the slot is empty
    if self.form[slot] == nil then
      -- Slot is empty, add the object here
      self.form[slot] = {
        player = playerName,
      }
      return true, slot
    end
  end
  return false
end

local backStyleSheet =[[background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #666666, stop: 1 #cccccc);
        border-width: 1px;
        border-color: black;
        border-style: solid;
        border-radius: 5;
        padding: 2px;
    ]]

function VFrame:getStyleSheet(current, max)
  local gradMax
  local gradMin
  
  local pct = current/max * 100
    
  if pct > 90 then
    gradMax = "#0047b3" -- blue
    gradMin = "#b3d1ff"
  elseif pct > 75 then
    gradMax = "#98f041" -- green
    gradMin = "#66cc00"
  elseif pct > 25 then
    gradMax = "#ffff00" -- yellow
    gradMin = "#ffff66"
  else
    gradMax = "#ff0000" -- red
    gradMin = "#ff6666"
  end

  local styleSheet = string.format(
  "background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 %s, stop: 1 %s);\
    border-top: 1px black solid;\
    border-left: 1px black solid;\
    border-bottom: 1px black solid;\
    border-radius: 5;\
    padding: 2px;", gradMax, gradMin)
    
  return styleSheet
end

function VFrame:addPlayer(playerName)

    local plrIdx = table.index_of(playerName)
    if plrIdx then
        table.remove(VFrame.registered, plrIdx)
    else
        cecho("<orange>Player <yellow>"..playerName.."<orange> not found\n")
        return
    end

    self:setupContainers()

    local found, slot = self:findEmptySlot(playerName)

    if found then
        local gridSlot = "grid."..slot
        --display("assigned " .. playerName .. " to slot " .. slot .. " gridSlot " .. gridSlot)

        --the playerContainer is in self.grid[xx]

        --make them some gauges

        self.form[slot].label = Geyser.Label:new({
            x=5, y=0,
            name = playerName,
            width="90%", height=15,
        }, self.grid[slot])
        self.form[slot].label:echo(playerName, "white", "c")

        self.form[slot].hpBar = Geyser.Gauge:new({
            name="hpbar."..playerName,
            x=5, y=15,
            width="90%", height=20,
        }, self.grid[slot])
        self.form[slot].hpBar.back:setStyleSheet(backStyleSheet)
        self.form[slot].hpBar.front:setStyleSheet(self:getStyleSheet(100, 100))

        self.form[slot].manaBar = Geyser.Gauge:new({
            name="manabar."..playerName,
            x=5, y=40,
            width="90%", height=20,
        }, self.grid[slot])
        self.form[slot].manaBar.back:setStyleSheet(backStyleSheet)
        self.form[slot].manaBar.front:setStyleSheet(self:getStyleSheet(100, 100))

        self.grid[slot]:flash()

    end

end

function VFrame:buildRow(rowNum)
    self.grid = self.grid or {}

    -- row1, row2, etc
    local rowId = "row"..rowNum
    self[rowId] = Geyser.HBox:new({
        name = "vframe."..rowId,  -- vframe.row1, vframe.row2, etc
        x=0, y=(rowNum - 1) * 100,
        width="100%", height=100,
    }, self.container)

    -- 3 columns

    -- grid.11, grid.12, etc
    self.grid[rowNum.."1"] = Geyser.Container:new({
        name = "vframe.grid"..rowNum.."1",  -- vframe.grid11, vframe.grid12, etc
        width=100, height=100,
    }, self[rowId])

    self.grid[rowNum.."2"] = Geyser.Container:new({
        name = "vframe.grid"..rowNum.."2",
        width=100, height=100,
    }, self[rowId])

    self.grid[rowNum.."3"] = Geyser.Container:new({
        name = "vframe.grid"..rowNum.."3",
        width=100, height=100,
    }, self[rowId])
end

function VFrame:setupContainers()
  if not self.container then
    --setBorderRight(300)
    
    self.adj_container = Adjustable.Container:new({
      name = "VFrames",
      x = -300, y = 0,
      width = 400, height = "50%",
      lockStyle = "border",
      adjLabelstyle = "background-color:darkred; border: 0; padding: 1px;",
      autoLoad = true,
      autoSave = true
    })
    
    self.bkglabel = Geyser.Label:new({
      x=0, y=0,
      width="100%", height="100%",
      color="black"
    }, self.adj_container)
    
    
    self.container = Geyser.Container:new({
      name = "vframe_container",
      x=0, y=0,
      width = "100%", height="100%",
    }, self.adj_container)
    
    
    self:buildRow(1)
    self:buildRow(2)
    self:buildRow(3)
  end
end

function VFrame.updateVitals()

    local gmcpVitals = gmcp.Char.Vitals

    if myVFrame then

        --display("sending player data")

        myVFrame:sendPlayerData({
          hp = gmcpVitals.hp or 0,
          maxHp = gmcpVitals.maxHp or 0,
          mana = gmcpVitals.mana or 0,
          maxMana = gmcpVitals.maxMana or 0,
          buffs = ""
        })
      end
end

function VFrame.eventHandler(event, ...)
  if event == "gmcp.Char.Vitals" then
    --display("got prompt data")

    VFrame.updateVitals()

  elseif event == "sysChatChannelMessage" then
    --display("event: " .. event .. " from: " .. arg[1] .. " channel: " .. arg[2] .. " message: " .. arg[3])
    if arg[2] == "vFrame" and myVFrame then -- check if its actually for us
      myVFrame:playerData(arg[3])
    end
  elseif event == "sysUninstallPackage"  then
    for _,id in ipairs(VFrame.registeredEvents) do
        killAnonymousEventHandler(id)
    end
  end
   
end

VFrame.registeredEvents = {
  registerAnonymousEventHandler("gmcp.Char.Vitals", "VFrame.eventHandler"),
  registerAnonymousEventHandler("sysChatChannelMessage", "VFrame.eventHandler"),
  registerAnonymousEventHandler("sysUninstallPackage", "VFrame.eventHandler")
}

myVFrame = VFrame:new("vFrame")

if VFrame.listAlias then
    killAlias(VFrame.listAlias)
end

VFrame.listAlias = tempAlias([[^vflist]], function() VFrame.listAvailable() end)

if VFrame.addAlias then
    killAlias(VFrame.addAlias)
end

VFrame.addAlias = tempAlias([[^vfadd (.*)]], function()
    if myVFrame then
        myVFrame:addPlayer(matches[2])
    end
end)
