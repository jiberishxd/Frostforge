local test=...
local blue="|cff4da6ffFrostforge|r"

-- Model native pooled construction, then provider layout hooks, then Frostforge.
-- This checks geometry and callback ownership, not WoW's secure execution engine.
local function menuFixture(M,skin,gamepad)
    local menu=M.native("GameMenuFrame",256,400)
    menu.shown=false;menu.pool={};menu.active={};menu.builds=0;menu.layouts=0
    menu.gameMenuGeometry=true
    menu.buttonPool={EnumerateActive=function() return pairs(menu.active) end}
    if skin=="EllesmereUI" then
        EllesmereUIDB={popupMenuButtonBackgroundColor={r=.12,g=.13,b=.14,a=.8}}
        EllesmereUI={_applyBlizzardConfiguredBorder=function(frame,key)
            assert(not frame.native and key=="popupMenuButton");frame.euiBorder=true
        end}
        C_AddOns={IsAddOnLoaded=function(name) return name=="EllesmereUIBlizzardSkin" end}
    elseif skin=="ElvUI" then
        ElvUI={{private={skins={blizzard={enable=true,misc=true}}},GetModule=function(_,name)
            assert(name=="Skins")
            return {HandleButton=function(_,button) assert(not button.native);button.elvStyle=true end}
        end}}
    end
    if skin~="Blizzard" then menu.providerButton=CreateFrame("Button",nil,menu) end
    local building=false
    function menu:AddButton(label,callback)
        assert(building,"Addon entered Blizzard's pooled button constructor")
        local i=self.nextLayoutIndex
        local b=self.pool[i]
        if not b then
            b=CreateFrame("Button",nil,self,"MainMenuFrameButtonTemplate")
            b:SetText(label)
            b.native=true;b.gameMenuGeometry=true;self.pool[i]=b
        end
        b.layoutIndex=i;b.text=label;b.callback=callback;b.scripts.OnClick=callback
        b.originalCallback=callback;b.originalIndex=i
        b.fontString.font={skin..".ttf",skin=="Blizzard" and 16 or 13,""}
        self.nextLayoutIndex=i+1;self.active[b]=true
        if gamepad then self.buttons[#self.buttons+1]=b end
        return b
    end
    function menu:InitButtons()
        assert(building,"Addon rebuilt the native Game Menu")
        self.builds=self.builds+1
        self.nextLayoutIndex=1;self.active={};self.buttons={}
        self:AddButton(GAMEMENU_OPTIONS,function() self.optionsOpened=true end)
        if self.shop then self:AddButton("Shop",function() end) end
        if not self.noAddons then self:AddButton(ADDONS,function() self.addonsOpened=true end) end
        self:AddButton("Macros",function() end)
        self:AddButton("Log Out",function() self.logoutClicked=true;self.shown=false end)
        self:AddButton(EXIT_GAME,function() self.quitClicked=true;self.shown=false end)
        if not gamepad then self:AddButton("Return to Game",function() self.shown=false end) end
    end
    function menu:Layout()
        self.layouts=self.layouts+1
        local count=self.nextLayoutIndex-1
        self.h=count*36+82
        for row in pairs(self.active) do
            row.w,row.h=200,36;row.points={{"TOPLEFT",self,"TOPLEFT",28,-48-(row.layoutIndex-1)*36}}
        end
        -- Provider custom rows are unpooled and already placed before our hook.
        if skin=="EllesmereUI" then
            local anchor=self:Find(self.shop and "Shop" or GAMEMENU_OPTIONS)
            self.providerButton.points={{"TOPLEFT",anchor,"BOTTOMLEFT",0,-4}}
            self.providerButton.w,self.providerButton.h=200,36
            for row in pairs(self.active) do
                if row.layoutIndex>anchor.layoutIndex then row.points[1][5]=row.points[1][5]-40 end
            end
            self.h=self.h+40
        elseif skin=="ElvUI" then
            local anchor=self:Find("Macros")
            self.providerButton.points={{"TOPLEFT",anchor,"BOTTOMLEFT",0,0}}
            self.providerButton.w,self.providerButton.h=200,36
            for row in pairs(self.active) do
                if row.layoutIndex>anchor.layoutIndex then row.points[1][5]=row.points[1][5]-36 end
            end
            self.h=self.h+36
        end
        self.providerHeight=self.h
    end
    function menu:OpenNative()
        self.shown=true;building=true;self:InitButtons();building=false;self:Layout()
    end
    function menu:Find(label)
        for b in pairs(self.active) do if b.text==label then return b end end
    end
    return menu
end

local function assertNativeCallbacks(menu)
    for row in pairs(menu.active) do
        assert(row.callback==row.originalCallback and row.scripts.OnClick==row.originalCallback)
        assert(row.layoutIndex==row.originalIndex,"Addon modified native layout indices")
    end
end

for _,interface in ipairs({120100,16001}) do
    for _,skin in ipairs({"Blizzard","ElvUI","EllesmereUI"}) do
        test(skin.." Game Menu includes a matching blue Frostforge row without pooled callbacks on "..interface,function(M)
            local J=M.load({interface=interface});local menu=menuFixture(M,skin)
            local addButton,initButtons,hooks=menu.AddButton,menu.InitButtons,M.hooks or 0
            M.tick(J.Core)
            local b=J.Access.gameMenuButton
            assert(b and b:GetParent()==menu and not b:IsShown() and not b:IsVisible())
            assert(not b:GetFontString(),"Fresh native button text should be lazy")
            assert(b.layoutIndex==nil and not menu.active[b] and menu.builds==0)
            local maxObjects
            for i=1,8 do
                menu.shop=i%2==0;menu:OpenNative();M.tick(J.Core)
                assert(J.Access.gameMenuButton==b and b:IsVisible() and not menu:Find(blue))
                local anchor=menu:Find(ADDONS)
                local p,relative,rp,x,y=b:GetPoint(1)
                assert(p=="TOPLEFT" and relative==anchor and rp=="BOTTOMLEFT" and x==0 and y==0)
                assert(b:GetWidth()==anchor:GetWidth() and b:GetHeight()==anchor:GetHeight())
                assert(b:GetText()==blue and b:GetFontString():GetFont()==anchor:GetFontString():GetFont())
                if skin=="EllesmereUI" then assert(b.inset.euiBorder and b.inset.backdropColor[1]==.12)
                elseif skin=="ElvUI" then assert(b.elvStyle) end
                local _,aY=anchor:GetRect();local _,bY=b:GetRect();local _,nextY=menu:Find("Macros"):GetRect()
                assert(bY+b:GetHeight()==aY and nextY+36==bY,"Inserted row overlaps its neighbors")
                local _,bottom=menu:Find("Return to Game"):GetRect()
                assert(bottom>=0 and menu:GetHeight()==menu.providerHeight+36,"Row fell outside menu background")
                assertNativeCallbacks(menu)
                local height,writes=menu:GetHeight(),M.gameMenuWrites
                M.tick(J.Core);M.tick(J.Core)
                assert(menu:GetHeight()==height and M.gameMenuWrites==writes,"Tick grew/repositioned the menu")
                menu:Layout();assert(menu:GetHeight()==height,"Repeated native layout accumulated space")
                if i==2 then maxObjects=#M.objects elseif i>2 then assert(#M.objects==maxObjects,"Reopening leaked frames") end
                menu:Find("Log Out").callback();assert(menu.logoutClicked and not b:IsVisible())
                menu:OpenNative();menu:Find(EXIT_GAME).callback();assert(menu.quitClicked and not b:IsVisible())
            end
            assert(menu.AddButton==addButton and menu.InitButtons==initButtons and M.hooks==hooks+1)
            assert(menu.builds==16 and #menu.pool==7)
            menu:OpenNative();b.scripts.OnClick()
            assert(M.closedPanel==menu and not b:IsVisible() and J.SettingsUI.frame:IsShown())
            J.SettingsUI.frame:Hide();menu:OpenNative();menu:Find(ADDONS).callback();assert(menu.addonsOpened)
            menu:Find(GAMEMENU_OPTIONS).callback();assert(menu.optionsOpened)
            menu:Find("Return to Game").callback();assert(not b:IsVisible())
            assertNativeCallbacks(menu)
            assert(M.nativeWrites==0 and not next(J.Core.notices))
        end)
    end
    test("Game Menu defers combat layout and recovers without rebuilding on "..interface,function(M)
        local J=M.load({interface=interface});local menu=menuFixture(M,"EllesmereUI")
        M.combat=true;menu:OpenNative();M.tick(J.Core);J.Access:RegisterGameMenu()
        assert(not J.Access.gameMenu)
        M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED")
        local b=J.Access.gameMenuButton
        assert(b and b:IsVisible() and menu.builds==1 and menu.layouts==1)
        M.combat=true;b.scripts.OnClick();assert(menu.shown and not J.SettingsUI.frame)
        local writes=M.gameMenuWrites
        menu:OpenNative();assert(not b:IsShown() and M.gameMenuWrites==writes)
        M.tick(J.Core);assert(M.gameMenuWrites==writes)
        M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED")
        assert(b:IsVisible() and menu.builds==2 and menu:GetHeight()==menu.providerHeight+36)
        b.scripts.OnClick();assert(J.SettingsUI.frame:IsShown() and not menu.shown and not next(J.Core.notices))
    end)
    test("Game Menu stays usable when optional provider styling fails on "..interface,function(M)
        local J=M.load({interface=interface});local menu=menuFixture(M,"EllesmereUI")
        EllesmereUI._applyBlizzardConfiguredBorder=function() error("Provider border unavailable") end
        menu:OpenNative();M.tick(J.Core)
        local b=J.Access.gameMenuButton
        assert(b:IsVisible() and b:GetText()==blue)
        assert(select(2,b:GetPoint(1))==menu:Find(ADDONS))
        assert(menu:GetHeight()==menu.providerHeight+b:GetHeight())
        assert(J.Core.notices["game menu style"]:find("Provider border unavailable",1,true))
        assertNativeCallbacks(menu)
        b.scripts.OnClick();assert(J.SettingsUI.frame:IsShown() and not menu.shown)
        menu:OpenNative();menu:Find("Log Out").callback();assert(menu.logoutClicked)
        menu:OpenNative();menu:Find(EXIT_GAME).callback();assert(menu.quitClicked)
        assertNativeCallbacks(menu)
    end)
end

test("Forever Game Menu keeps native gamepad order when AddOns is unavailable",function(M)
    local J=M.load({interface=16001});local menu=menuFixture(M,"Blizzard",true)
    menu.noAddons=true;menu:OpenNative();M.tick(J.Core)
    local b=J.Access.gameMenuButton
    assert(b:IsVisible() and select(2,b:GetPoint(1))==menu:Find(EXIT_GAME))
    for _,native in ipairs(menu.buttons) do assert(native~=b) end
    assert(#menu.buttons==4 and menu.buttons[#menu.buttons].text==EXIT_GAME)
    assert(not menu:Find("Return to Game") and not next(J.Core.notices))
end)

test("Game Menu registration tolerates unavailable, forbidden and replaced menus",function(M)
    local J=M.load();GameMenuFrame=M.native("GameMenuFrame",200,400)
    M.tick(J.Core);assert(not J.Access.gameMenu)
    local menu=menuFixture(M,"Blizzard");menu.forbidden=true
    M.tick(J.Core);assert(not J.Access.gameMenu)
    menu.forbidden=false;menu:OpenNative();M.tick(J.Core);assert(J.Access.gameMenu==menu)
    local old=J.Access.gameMenuButton;assert(old:IsVisible())
    local replacement=menuFixture(M,"Blizzard");replacement:OpenNative();M.tick(J.Core)
    assert(J.Access.gameMenu==replacement and not old:IsVisible())
    assert(J.Access.gameMenuButton:IsVisible() and J.Access.gameMenuButton:GetParent()==replacement)
    assert(replacement.builds==1 and not next(J.Core.notices))
end)
