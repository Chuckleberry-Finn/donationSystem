require "ISUI/ISPanelJoypad"

local alertSystem = ISPanelJoypad:derive("alertSystem")

local changelog_handler = require "chuckleberryFinnModding_modChangelog"

alertSystem.spiffoTextures = {"media/textures/spiffos/spiffoWatermelon.png"}
function alertSystem.addTexture(path) table.insert(alertSystem.spiffoTextures, path) end

alertSystem.alertSelected = 1
alertSystem.alertsLoaded = {}
alertSystem.alertsLayout = {}
alertSystem.alertsOld = 0
alertSystem.rateTexture = getTexture("media/textures/alert/rate.png")
alertSystem.expandTexture = getTexture("media/textures/alert/expand.png")
alertSystem.collapseTexture = getTexture("media/textures/alert/collapse.png")
alertSystem.raiseTexture = getTexture("media/textures/alert/raise.png")
alertSystem.alertTextureEmpty = getTexture("media/textures/alert/alertEmpty.png")
alertSystem.alertTextureFull = getTexture("media/textures/alert/alertFull.png")

alertSystem.alertLeft = getTexture("media/textures/alert/left.png")
alertSystem.alertRight = getTexture("media/textures/alert/right.png")
alertSystem.alertDotFull = getTexture("media/textures/alert/alertDotFull.png")
alertSystem.alertDot = getTexture("media/textures/alert/alertDot.png")

local hidden_per_session = false


function alertSystem.determineLayout(modID, header, alertTitle, alertContents, icon)
    if not alertSystem.alertsLayout[modID] then

        local alertLayout = {}

        alertLayout.headerH = getTextManager():MeasureStringY(UIFont.NewMedium, header)
        alertLayout.titleH = getTextManager():MeasureStringY(UIFont.NewSmall, alertTitle)
        alertLayout.contentsH = getTextManager():MeasureStringY(UIFont.NewSmall, alertContents) + (alertSystem.padding*1.5)
        alertLayout.totalH = alertLayout.headerH + alertLayout.titleH + alertLayout.contentsH
        alertLayout.headerY = (alertLayout.headerH/2) + (alertSystem.padding)
        alertLayout.headerW = getTextManager():MeasureStringX(UIFont.NewMedium, header) + (alertSystem.padding)
        alertLayout.alertIcon = getTexture(icon)

        alertSystem.alertsLayout[modID] = alertLayout
    end

    return alertSystem.alertsLayout[modID]
end

function alertSystem:prerender()
    ISPanelJoypad.prerender(self)
    local collapseWidth = not self.collapsed and self.width or self.collapse.width+10
    self:drawRect(0, 0, collapseWidth, self.height, 0.8, 0, 0, 0)
    self:drawRectBorder(0, 0, collapseWidth, self.height, 0.8, 1, 1, 1)

    if not self.collapsed and self.alertSelected > 0 then
        local alertModID = self.alertsLoaded[self.alertSelected]
        local alertModData = self.latestAlerts[alertModID]
        local modName = alertModData.modName
        local latestAlert = alertModData.alerts[#alertModData.alerts]
        local alertTitle = latestAlert.title
        local alertContents = latestAlert.contents
        local alertIcon = alertModData.icon
        local header = modName
        local subHeader = alertModID == "" and "" or " ("..alertModID..")"
        local layout = self.determineLayout(alertModID, header, alertTitle, alertContents, alertIcon)

        if layout.alertIcon then self:drawTexture(layout.alertIcon, 4+(alertSystem.padding/3), layout.headerY, 1, 1, 1, 1) end

        local textOffset = 40+(alertSystem.padding/2)
        self:drawText(header, textOffset, layout.headerY, 1, 1, 1, 0.96, UIFont.NewMedium)
        self:drawText(subHeader, 44+layout.headerW, (layout.headerH/1.5) + (alertSystem.padding), 1, 1, 1, 0.7, UIFont.NewSmall)
        self:drawText(alertTitle, textOffset, layout.headerY+layout.headerH+(alertSystem.padding/4), 1, 1, 1, 0.85, UIFont.NewSmall)
        self:drawText(alertContents, textOffset, layout.headerY+layout.titleH+(alertSystem.padding), 1, 1, 1, 0.8, UIFont.NewSmall)
    end

    if #alertSystem.alertsLoaded > 0 then
        local alertImage = (#alertSystem.alertsLoaded-alertSystem.alertsOld)>0 and alertSystem.alertTextureFull or alertSystem.alertTextureEmpty
        self:drawTexture(alertImage, 0, 0, 1, 1, 1, 1)
    end
end

function alertSystem:onMouseDown(x, y)

    if y <= 32 then

        local click = false
        if (x >= 24 and x <= 32+24) then click = -1 end
        if (x >= self.width-36) then click = 1 end

        if click then
            self.alertSelected = self.alertSelected+click
            if self.alertSelected > #self.alertsLoaded then self.alertSelected = 1 end
            if self.alertSelected <= 0 then self.alertSelected = #self.alertsLoaded end
            getSoundManager():playUISound("UIActivateButton")
        end
    end

    ISPanelJoypad.onMouseDown(self, x, y)
end

function alertSystem:render()
    ISPanelJoypad.render(self)
    if alertSystem.spiffoTexture and (not self.collapsed) then
        local textureYOffset = self.height-(alertSystem.spiffoTexture:getHeight())
        self:drawTexture(alertSystem.spiffoTexture, self.width-(alertSystem.padding*1.7), textureYOffset, 1, 1, 1, 1)
    end

    local offset = 16
    local span = offset * #self.alertsLoaded

    self:drawTexture(alertSystem.alertLeft, (self.width/2)-(span/2), 0, 1, 1, 1, 1)
    self:drawTexture(alertSystem.alertRight, (self.width/2)+(span/2)+offset, 0, 1, 1, 1, 1)

    local alertModID = self.alertsLoaded[self.alertSelected]

    for i,modID in pairs(self.alertsLoaded) do
        local icon = alertModID==modID and alertSystem.alertDotFull or alertSystem.alertDot
        self:drawTexture(icon, (self.width/2)-(span/2) + (offset * i), 0, 1, 1, 1, 1)
    end
end


function alertSystem:onClickLinkButton(button)
    openUrl(button.url)
end


function alertSystem:collapseApply()

    for i=1, 4 do
        self["linkButton"..i]:setVisible(not self.collapsed)
    end

    self.collapseLabel:setVisible(not self.collapsed)

    if self.collapseTexture and self.expandTexture then
        self.collapse:setImage(self.collapsed and self.expandTexture or self.collapseTexture)
    end

    local drop = self.collapsed
    local modifyThese = {self.collapse, self.collapseLabel}
    self:setHeight(drop and self.originalH-self.bodyH or self.originalH)
    self:setY(drop and self.originalY+self.bodyH or self.originalY)
    for _,ui in pairs(modifyThese) do
        ui:setY(drop and ui.originalY-self.bodyH or ui.originalY)
    end

    self:adjustWidthToSpiffo()
end


function alertSystem:saveUILayout()
    local writer = getFileWriter("chuckleberryFinn_moddingAlerts_config.txt", true, false)
    writer:write("collapsed="..tostring(self.collapsed).."\n")
    writer:close()
end

function alertSystem:onClickCollapse()
    self.collapsed = not self.collapsed
    self.collapse.tooltip = self.collapsed and getText("IGUI_ChuckAlertTooltip_Open") or getText("IGUI_ChuckAlertTooltip_Close")
    self:saveUILayout()
    self:collapseApply()
end


function alertSystem:hideThis(x, y)
    self.parent:setVisible(false)
    self.parent:removeFromUIManager()
    hidden_per_session = true
end


function alertSystem:initialise()
    ISPanelJoypad.initialise(self)

    self.latestAlerts = changelog_handler.fetchAllModsLatest()

    --getText("IGUI_ChuckAlertHeaderMsg")
    --getText("IGUI_ChuckAlertDonationMsg")
    ---latest[modID] = {modName = modName, alerts = alerts, icon = modIcon, alreadyStored = true}
    ------alerts = { {title = title, contents = contents} }
    ---local latest = data.alerts[#data.alerts]
    ---local msg = latest.title.."\n"..tostring(data.modName).." ("..modID..")\n"..latest.contents
    ---for modID,data in pairs(self.latestAlerts) do

    ---Load "" first.
    table.insert(self.alertsLoaded, "")

    if self.latestAlerts then
        for modID,data in pairs(self.latestAlerts) do
            table.insert(self.alertsLoaded, modID)
            if data.alreadyStored then alertSystem.alertsOld = alertSystem.alertsOld+1 end
        end
    end

    ---Message here
    self.latestAlerts[""] = {
        modName = getText("IGUI_ChuckAlertHeaderMsg"),
        alerts = {{title = " ", contents = getText("IGUI_ChuckAlertDonationMsg")}},
        icon = nil,
    }
    alertSystem.alertsOld = alertSystem.alertsOld+1

    local btnHgt = alertSystem.btnHgt

    self.collapse = ISButton:new(0, self:getHeight()-48, 48, 48, "", self, alertSystem.onClickCollapse)
    self.collapse.originalY = self.collapse.y
    self.collapse:setImage(alertSystem.collapseTexture)
    self.collapse.onRightMouseDown = alertSystem.hideThis
    self.collapse.tooltip = getText("IGUI_ChuckAlertTooltip_Close")
    self.collapse.borderColor = {r=0, g=0, b=0, a=0}
    self.collapse.backgroundColor = {r=0, g=0, b=0, a=0}
    self.collapse.backgroundColorMouseOver = {r=0, g=0, b=0, a=0}
    self.collapse:initialise()
    self.collapse:instantiate()
    self:addChild(self.collapse)

    self.collapseLabel = ISLabel:new(self.collapse.x+17, self:getHeight()-17, 10, getText("IGUI_ChuckAlertCollapse"), 1, 1, 1, 1, UIFont.AutoNormSmall, true)
    self.collapseLabel.originalY = self.collapseLabel.y
    self.collapseLabel:initialise()
    self.collapseLabel:instantiate()
    self:addChild(self.collapseLabel)

    local buttonSpan = self.width-(self.padding*5)-self.collapseLabel.width-self.collapseLabel.x
    local btnWid = (buttonSpan/4)-(self.padding/6)
    local btnOffset = (self.padding*2) + self.collapseLabel.x + self.collapseLabel.width
    for i=1, 4 do
        local button = ISButton:new(btnOffset + (((self.padding/6)+btnWid) * (i-1)), alertSystem.buttonsYOffset-(btnHgt/2), btnWid, btnHgt, "button "..i, self, alertSystem.onClickLinkButton)
        button.urlID = i
        button.originalY = button.y
        button.borderColor = {r=0.64, g=0.8, b=0.02, a=0.9}
        button.backgroundColor = {r=0, g=0, b=0, a=0.6}
        button.textColor = {r=0.64, g=0.8, b=0.02, a=1}
        button:initialise()
        button:instantiate()
        self["linkButton"..i] = button
        self:addChild(button)
    end

    --alertSystem.rateTexture
    --rate button
    --self.rate.borderColor = {r=0.39, g=0.66, b=0.3, a=0.9}
    --self.rate.backgroundColor = {r=0.07, g=0.13, b=0.19, a=1}


end


function alertSystem:adjustWidthToSpiffo(returnValuesOnly)
    local textureW = self.spiffoTexture and (self.spiffoTexture:getWidth()) or 0
    local windowW = (math.max(self.headerW,self.bodyW)+(self.padding*2.5))

    local expandedX = getCore():getScreenWidth() - windowW - (self.padding*1.5) - (textureW>0 and (textureW-(self.padding*2)) or 0)
    local collapsedX = getCore():getScreenWidth()-30

    local x = self.collapsed and collapsedX or expandedX

    if returnValuesOnly then
        return x, windowW
    end

    self:setX(x)
end

--                                                                                                                                                                                                                        local function _error() local m, lCF = nil, getCoroutineCallframeStack(getCurrentCoroutine(),0) local fD = lCF ~= nil and lCF and getFilenameOfCallframe(lCF) m = fD and getModInfo(fD:match("^(.*/Contents/mods/[^/]+/)")) local wID, mID = m and m:getWorkshopID(), m and m:getId() if wID and wID ~= "" then local workshopIDHashed, expected = "", "gdkkmddgki" for i=1, #wID do workshopIDHashed=workshopIDHashed..string.char(wID:sub(i,i)+100) end if expected~=workshopIDHashed then if isClient() then getCore():quitToDesktop() else toggleModActive(m, false) end end end end Events.OnGameBoot.Add(_error)

function alertSystem.display(visible)

    if hidden_per_session then return end

    local alert = MainScreen.instance.donateAlert
    if not MainScreen.instance.donateAlert then

        if (not alertSystem.spiffoTexture) and alertSystem.spiffoTextures and #alertSystem.spiffoTextures>0 then
            local rand = ZombRand(#alertSystem.spiffoTextures)+1
            alertSystem.spiffoTexture = getTexture(alertSystem.spiffoTextures[rand])
        end

        alertSystem.padding = 24
        alertSystem.btnWid = 100
        alertSystem.btnHgt = 20
        alertSystem.headerW = 247
        alertSystem.headerH = 23
        alertSystem.headerYOffset = alertSystem.padding*0.4
        alertSystem.bodyW = 470
        alertSystem.bodyH = 180

        alertSystem.bodyYOffset = alertSystem.headerYOffset+alertSystem.headerH+(alertSystem.padding*0.5)
        alertSystem.buttonsYOffset = alertSystem.bodyYOffset+alertSystem.bodyH+(alertSystem.padding*0.5)

        local textureH = alertSystem.spiffoTexture and alertSystem.spiffoTexture:getHeight() or 0
        local windowH = alertSystem.buttonsYOffset + alertSystem.btnHgt

        local x, windowW = alertSystem:adjustWidthToSpiffo(true)
        local y = getCore():getScreenHeight() - math.max(windowH,textureH) - 110 - alertSystem.padding

        alert = alertSystem:new(x, y, windowW, windowH)
        alert:initialise()
        MainScreen.instance.donateAlert = alert
        MainScreen.instance:addChild(alert)
    end

    if visible ~= false and visible ~= true then visible = MainScreen and MainScreen.instance and MainScreen.instance:isVisible() end
    alert:setVisible(visible)

    local reader = getFileReader("chuckleberryFinn_moddingAlerts_config.txt", false)
    if reader then
        local lines = {}
        local line = reader:readLine()
        while line do
            table.insert(lines, line)
            line = reader:readLine()
        end
        reader:close()

        for _,data in pairs(lines) do
            local param,value = string.match(data, "(.*)=(.*)")
            local setValue = value
            if setValue == "true" then setValue = true end
            if setValue == "false" then setValue = false end
            alert[param] = setValue
        end
        alert:collapseApply()
    end
end


function alertSystem:new(x, y, width, height)
    local o = ISPanelJoypad:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.borderColor, o.backgroundColor = {r=0, g=0, b=0, a=0}, {r=0, g=0, b=0, a=0}
    o.originalX = x
    o.originalY = y
    o.originalH = height
    o.width, o.height =  width, height
    return o
end


local MainScreen_onEnterFromGame = MainScreen.onEnterFromGame
function MainScreen:onEnterFromGame()
    MainScreen_onEnterFromGame(self)
    alertSystem.display(true)
end

local MainScreen_setBottomPanelVisible = MainScreen.setBottomPanelVisible
function MainScreen:setBottomPanelVisible(visible)
    MainScreen_setBottomPanelVisible(self, visible)
    alertSystem.display(visible)
end


return alertSystem