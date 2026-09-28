local test=...

-- Model Blizzard's pooled AddButton/Reset contract. Provider skins run only
-- after InitButtons has constructed the list, as in ElvUI and EllesmereUI.
local function menuFixture(M,skin,gamepad)
    local menu=M.native("GameMenuFrame",240,400)
    menu.shown=false;menu.pool={};menu.active={}
    menu.buttonPool={EnumerateActive=function() return pairs(menu.active) end}
    function menu:AddButton(label,callback,disabled,disabledText)
        local i=self.nextLayoutIndex
        local b=self.pool[i]
        if not b then b=CreateFrame("Button",nil,self);self.pool[i]=b end
        b.layoutIndex=i;b.text=label;b.callback=callback;b.disabled=disabled;b.disabledText=disabledText
        self.nextLayoutIndex=i+1;self.active[b]=true
        if gamepad then self.buttons[#self.buttons+1]=b end
        return b
    end
    function menu:InitButtons()
        self.nextLayoutIndex=1;self.active={};self.buttons={}
        self:AddButton("Options",function() end)
        if self.shop then self:AddButton("Shop",function() end) end
        self:AddButton(ADDONS,function() self.addonsOpened=true end)
        self:AddButton("Macros",function() end)
        self:AddButton("Exit Game",function() end)
        if not gamepad then self:AddButton("Return to Game",function() self.shown=false end) end
        self.height=(self.nextLayoutIndex-1)*40
        for b in pairs(self.active) do b.skin=skin;b.y=-b.layoutIndex*40 end
    end
    function menu:Find(label)
        local found,count=nil,0
        for b in pairs(self.active) do if b.text==label then found=b;count=count+1 end end
        return found,count
    end
    return menu
end

for _,interface in ipairs({120100,16001}) do
    for _,skin in ipairs({"Blizzard","ElvUI","EllesmereUI"}) do
        test(skin.." Game Menu adds one pooled Frostforge row and opens settings on "..interface,function(M)
            local J=M.load({interface=interface});local menu=menuFixture(M,skin)
            M.tick(J.Core);local hooks=M.hooks
            for i=1,8 do
                menu.shown=true;menu.shop=i%2==0;menu:InitButtons();M.tick(J.Core)
                local b,count=menu:Find("Frostforge")
                assert(count==1 and b.skin==skin and not b.disabled)
                assert(b.layoutIndex==menu:Find(ADDONS).layoutIndex+1)
                assert(menu:Find("Macros").layoutIndex==b.layoutIndex+1)
                assert(menu:Find("Return to Game").layoutIndex==menu.nextLayoutIndex-1)
                assert(menu.height==(menu.shop and 7 or 6)*40,"Menu grew on reopening")
                menu.shown=false
            end
            assert(M.hooks==hooks and #menu.pool==7,"Repeated menu opens accumulated hooks or buttons")
            menu.shown=true;menu:InitButtons();menu:Find("Frostforge").callback()
            assert(M.closedPanel==menu and not menu.shown and J.SettingsUI.frame:IsShown())
            J.SettingsUI.frame:Hide();menu:Find(ADDONS).callback();assert(menu.addonsOpened)
            assert(M.nativeWrites==0 and not next(J.Core.notices))
        end)
    end
    test("Game Menu combat and late load are safe on "..interface,function(M)
        local J=M.load({interface=interface});local menu=menuFixture(M,"Blizzard")
        M.combat=true;menu.shown=true;menu:InitButtons();M.tick(J.Core)
        assert(not J.Access.gameMenu and not menu:Find("Frostforge"))
        M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED")
        local b,count=menu:Find("Frostforge");assert(count==1,"Already-open menu was not refreshed")
        M.combat=true;b.callback();assert(menu.shown and not J.SettingsUI.frame)
        menu:InitButtons();b=menu:Find("Frostforge");assert(b.disabled and b.disabledText=="Available after combat.")
        M.combat=false;menu:InitButtons();b=menu:Find("Frostforge");assert(not b.disabled)
        b.callback();assert(J.SettingsUI.frame:IsShown() and not menu.shown and not next(J.Core.notices))
    end)
end

test("Forever Game Menu includes Frostforge in native gamepad button order",function(M)
    local J=M.load({interface=16001});local menu=menuFixture(M,"Blizzard",true)
    M.tick(J.Core);menu:InitButtons()
    local b=menu:Find("Frostforge")
    assert(menu.buttons[b.layoutIndex]==b and menu.buttons[#menu.buttons].text=="Exit Game")
    assert(not menu:Find("Return to Game") and not next(J.Core.notices))
end)

test("Game Menu registration tolerates unavailable and forbidden menus",function(M)
    local J=M.load();GameMenuFrame=M.native("GameMenuFrame",200,400)
    M.tick(J.Core);assert(not J.Access.gameMenu)
    local menu=menuFixture(M,"Blizzard");menu.forbidden=true
    M.tick(J.Core);assert(not J.Access.gameMenu)
    menu.forbidden=false;M.tick(J.Core);assert(J.Access.gameMenu==menu)
    local replacement=menuFixture(M,"Blizzard");M.tick(J.Core);replacement:InitButtons()
    local _,count=replacement:Find("Frostforge");assert(count==1 and not next(J.Core.notices))
end)
