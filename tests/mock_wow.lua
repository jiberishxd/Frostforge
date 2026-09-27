-- Deliberately limited offline host. This does not simulate WoW's secure engine.
local M = {frames={},objects={},textures=0,fonts=0,nativeWrites=0,geometryWrites=0,writes=0,combat=false,messages={},atlasUVs={}}
local methods = {}
local function object(kind,parent,name)
    local self = setmetatable({kind=kind,parent=parent,name=name,w=100,h=30,scale=1,alpha=1,
        shown=true,points={},scripts={},events={},regions={}}, {__index=methods})
    if kind == "Frame" then M.frames[#M.frames+1]=self end
    M.objects[#M.objects+1]=self
    return self
end
local function readable(self)
    if self.forbidden then error("Forbidden frame inspected before gate") end
    M.reads = (M.reads or 0) + 1
end
local function writable(self,geometry)
    if self.native and (self.powerLayoutBar or self.euiLayoutBar or self.elvLayoutBar) and geometry then
        readable(self)
        assert(not M.combat,"Native power layout written in combat")
        M.nativeLayoutWrites=(M.nativeLayoutWrites or 0)+1
        if self.euiLayoutBar then M.euiLayoutWrites=(M.euiLayoutWrites or 0)+1 end
        if self.elvLayoutBar then M.elvLayoutWrites=(M.elvLayoutWrites or 0)+1 end
        return
    end
    if self.native and self.stockPresentation then
        readable(self)
        assert(not M.combat,"Stock presentation changed during combat")
        M.stockWrites=(M.stockWrites or 0)+1
        return
    end
    if self.native then M.nativeWrites=M.nativeWrites+1; error("Attempt to mutate Blizzard frame") end
    if M.combat and self.protected then error("Protected artwork changed during combat") end
    M.writes=M.writes+1
    if geometry then M.geometryWrites=M.geometryWrites+1 end
end
function methods:IsForbidden() return self.forbidden or false end
function methods:IsProtected() return self.protected or false end
function methods:GetParent() readable(self); return self.parent end
function methods:GetWidth() readable(self); return self.w end
function methods:GetHeight() readable(self); return self.h end
function methods:GetScale() readable(self); return self.scale end
function methods:GetEffectiveScale()
    readable(self)
    if self.secretScale then return M.secret end
    return self.scale * (self.parent and self.parent:GetEffectiveScale() or 1)
end
function methods:IsShown() readable(self); return self.shown end
function methods:IsVisible() readable(self); return self.shown and (not self.parent or self.parent:IsVisible()) end
function methods:GetAlpha() readable(self); return self.alpha end
function methods:GetEffectiveAlpha()
    readable(self)
    if self.secretAlpha then return M.secret end
    return self.alpha * (self.parent and self.parent:GetEffectiveAlpha() or 1)
end
function methods:SetSize(w,h) writable(self,true); self.w,self.h=w,h end
function methods:SetWidth(w) writable(self,true); self.w=w end
function methods:SetHeight(h) writable(self,true); self.h=h end
function methods:SetScale(scale) writable(self,true); self.scale=scale end
function methods:SetPoint(...)
    local _,relative=...
    if relative and relative.layoutAspect then assert(self.template=="DisableUntrustedLayoutScriptsTemplate","Missing aura layout aspect") end
    writable(self,true); self.points[#self.points+1]={...}
end
function methods:GetPoint(i) return unpack(self.points[i or 1]) end
function methods:GetNumPoints() readable(self);return #self.points end
function methods:ClearAllPoints() writable(self,true); self.points={}; self.center=nil; self.allPoints=nil end
function methods:SetAllPoints(relative) writable(self,true); self.allPoints=relative end
function methods:SetFrameStrata(value) writable(self); self.strata=value end
function methods:SetFixedFrameStrata(value) writable(self);self.fixedStrata=value end
function methods:SetFixedFrameLevel(value) writable(self);self.fixedLevel=value end
function methods:SetFrameLevel(value) writable(self); self.level=value end
function methods:GetFrameStrata() readable(self); return self.strata or "LOW" end
function methods:GetFrameLevel() readable(self); return self.level or 0 end
function methods:SetBackdrop(value) writable(self); assert(self.template=="BackdropTemplate"); self.backdrop=value end
function methods:SetBackdropColor(...) writable(self); self.backdropColor={...} end
function methods:SetBackdropBorderColor(...) writable(self); self.backdropBorderColor={...} end
function methods:SetBlendMode(value) writable(self); self.blend=value end
function methods:SetMovable(value) writable(self); self.movable=value end
function methods:SetClampedToScreen(value) writable(self); self.clamped=value end
function methods:RegisterForDrag(...) writable(self); self.dragButtons={...} end
function methods:StartMoving() writable(self,true); assert(self.movable); self.moving=true end
function methods:StopMovingOrSizing() writable(self,true); self.moving=false end
function methods:GetCenter()
    readable(self)
    if self.center then return unpack(self.center) end
    local point=self.points[1]
    if point and point[1]=="CENTER" and point[3]=="CENTER" then
        local x,y=point[2]:GetCenter()
        return x+point[4],y+point[5]
    end
    return self.w/2,self.h/2
end
function methods:GetOrientation() readable(self);return self.orientation or "HORIZONTAL" end
function methods:GetRect()
    readable(self)
    if self.secretRect then return M.secret,0,self.w,self.h end
    if self.rect then return self.rect[1],self.rect[2],self.w,self.h end
    local p=self.points[1]
    if not p then return 0,0,self.w,self.h end
    local anchors={TOPLEFT={0,1},TOP={.5,1},TOPRIGHT={1,1},LEFT={0,.5},CENTER={.5,.5},RIGHT={1,.5},BOTTOMLEFT={0,0},BOTTOM={.5,0},BOTTOMRIGHT={1,0}}
    local a,b=anchors[p[1]],anchors[p[3]]
    local x,y,w,h=p[2]:GetRect()
    local ratio=p[2]:GetEffectiveScale()/self:GetEffectiveScale()
    return (x+w*b[1])*ratio+(p[4] or 0)-self.w*a[1],(y+h*b[2])*ratio+(p[5] or 0)-self.h*a[2],self.w,self.h
end
function methods:EnableMouse(value) writable(self); self.mouse=value end
function methods:EnableMouseWheel(value) writable(self); self.wheel=value end
function methods:EnableKeyboard(value) writable(self); self.keyboard=value end
function methods:SetDrawLayer(value,sub) writable(self); self.layer,self.sub=value,sub end
local function appearance(self)
    if self.native and self.fillTexture then
        readable(self)
        assert(not M.combat or M.statusBarTextureWrite==self,"Native appearance written in combat")
        M.appearanceWrites=(M.appearanceWrites or 0)+1
    else writable(self) end
end
function methods:SetTexCoord(...) appearance(self); self.texCoord={...} end
function methods:GetTexCoord()
    readable(self)
    if self.secretCoords then return M.secret end
    if self.texCoord and #self.texCoord==8 then return unpack(self.texCoord) end
    local t=self.texCoord or {0,1,0,1}
    return t[1],t[3],t[1],t[4],t[2],t[3],t[2],t[4]
end
function methods:GetAtlas() readable(self); return self.atlas end
function methods:GetTexture() readable(self); return self.path end
function methods:SetAtlas(value)
    appearance(self);self.atlas=value;self.path="atlas-file"
    self.texCoord=M.atlasUVs[value] or {0,1,0,1}
end
function methods:GetStatusBarTexture() readable(self); return self.fill end
function methods:SetStatusBarTexture(value)
    assert(self.native and self.fill)
    -- Opt-in fixtures model asset selection on an existing native region.
    -- Direct texture/UV and all native geometry writes stay combat-gated.
    assert(not M.combat or self.combatTextureAllowed,"Unprepared combat texture selection")
    local previous=M.statusBarTextureWrite;M.statusBarTextureWrite=self.fill
    self.selectedTexture=value
    if M.atlasUVs[value] then self.fill:SetAtlas(value) else self.fill:SetTexture(value) end
    M.statusBarTextureWrite=previous
    return not M.missingTexture
end
function methods:SetTexture(value)
    appearance(self)
    self.path=value;self.atlas=nil
    return not M.missingTexture
end
function methods:SetColorTexture(...) writable(self); self.color={...} end
function methods:SetShown(value)
    writable(self)
    local changed=self.shown~=value
    self.shown=value
    local callback=self.scripts[value and "OnShow" or "OnHide"]
    if changed and callback then callback(self) end
end
function methods:Show() self:SetShown(true) end
function methods:Hide() self:SetShown(false) end
function methods:SetAlpha(value) writable(self); self.alpha=value end
function methods:CreateTexture(_,layer)
    writable(self)
    M.textures=M.textures+1
    local texture=object("Texture",self)
    texture.layer=layer
    self.regions[#self.regions+1]=texture
    return texture
end
function methods:CreateMaskTexture(_,layer)
    readable(self);assert(not M.combat,"Native effect mask created in combat")
    M.masks=(M.masks or 0)+1
    local mask=object("MaskTexture",self);mask.layer=layer
    return mask
end
function methods:AddMaskTexture(mask)
    appearance(self);self.masks=self.masks or {};self.masks[mask]=true
end
function methods:GetNumMaskTextures() readable(self);local n=0;for _ in pairs(self.masks or {}) do n=n+1 end;return n end
function methods:GetMaskTexture(i) readable(self);local n=0;for mask in pairs(self.masks or {}) do n=n+1;if n==i then return mask end end end
function methods:RemoveMaskTexture(mask)
    appearance(self);if self.masks then self.masks[mask]=nil end
end
function methods:CreateFontString(_,_,fontObject)
    writable(self)
    M.fonts=M.fonts+1
    local font=object("FontString",self)
    font.fontObject=fontObject
    self.regions[#self.regions+1]=font
    return font
end
function methods:SetText(text)
    writable(self)
    local changed=self.text~=text;self.text=text
    if changed and self.scripts.OnTextChanged then self.scripts.OnTextChanged(self,false) end
end
function methods:GetText() return self.text end
local function colorWrite(self)
    readable(self)
    if self.native then
        assert(self.stockColor or self.stockPresentation or self.fill or self.fillTexture,"Unexpected color target")
        M.colorWrites=(M.colorWrites or 0)+1
    else writable(self) end
end
function methods:SetDesaturated(value) writable(self);self.desaturated=value end
function methods:SetTextColor(...) colorWrite(self);self.color={...} end
function methods:GetTextColor() readable(self);return unpack(self.color or {1,.82,0,1}) end
function methods:SetVertexColor(...) colorWrite(self);self.color={...};self.gradient=nil end
function methods:GetStatusBarColor() readable(self);return unpack(self.barColor or {0,1,0,1}) end
function methods:SetStatusBarColor(...)
    colorWrite(self);self.barColor={...}
    if self.fill then self.fill.color={...};self.fill.gradient=nil end
end
function methods:SetGradient(orientation,low,high)
    colorWrite(self);self.gradient={orientation=orientation,low=low,high=high}
end
function CreateColor(r,g,b,a) return {r=r,g=g,b=b,a=a or 1} end
function methods:SetJustifyH(value) writable(self); self.justify=value end
function methods:SetAutoFocus(value) writable(self); self.autoFocus=value end
function methods:GetFont() readable(self);return unpack(self.font or {"Fonts/FRIZQT__.TTF",12,"OUTLINE"}) end
function methods:SetFont(path,size,flags) writable(self);self.font={path,size,flags};return true end
function methods:GetJustifyH() readable(self);return self.justify or "LEFT" end
function methods:SetFontObject(value) writable(self); self.fontObject=value end
function methods:SetTextInsets(...) writable(self); self.insets={...} end
function methods:SetMaxLetters(value) writable(self); self.maxLetters=value end
function methods:HasFocus() return self.focused or false end
function methods:SetFocus()
    writable(self)
    if not self.focused then
        self.focused=true
        if self.scripts.OnEditFocusGained then self.scripts.OnEditFocusGained(self) end
    end
end
function methods:ClearFocus()
    writable(self)
    if self.focused then
        self.focused=false
        if self.scripts.OnEditFocusLost then self.scripts.OnEditFocusLost(self) end
    end
end
function methods:HighlightText() writable(self); self.highlighted=true end
function methods:SetOrientation(value) writable(self); self.orientation=value end
function methods:SetMinMaxValues(a,b) writable(self); self.minimum,self.maximum=a,b end
function methods:SetValueStep(value) writable(self); self.step=value end
function methods:SetObeyStepOnDrag(value) writable(self); self.obeyStep=value end
function methods:SetThumbTexture(value) writable(self); self.thumb=value end
function methods:SetValue(value)
    writable(self)
    local changed=self.value~=value
    self.value=value
    if changed and self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,value) end
end
function methods:GetValue() return self.value end
function methods:RegisterEvent(event) writable(self); self.events[event]=true end
function methods:SetScript(event,callback) writable(self); self.scripts[event]=callback end
-- These APIs must never be used by the prototype, even on unprotected native UI.
function methods:SetParent() error("No reparenting permitted") end
function methods:SetAttribute() error("No secure attribute writes permitted") end
function hooksecurefunc(object,method,callback)
    local auraLayout=(object==TargetFrame or object==FocusFrame) and method=="AnchorAuraContainer"
    assert(object.native and (object.fillTexture or object.fill or object.stockPresentation or object.stockColor or auraLayout),"Only stock/skin presentation hooks permitted")
    assert(auraLayout or method=="SetTexture" or method=="SetAtlas" or method=="SetTexCoord" or method=="SetStatusBarTexture" or method=="SetStatusBarColor" or method=="SetTextColor" or method=="SetVertexColor" or method=="SetText")
    M.hooks=(M.hooks or 0)+1
    local original=object[method]
    object[method]=function(self,...)
        local result=original(self,...);callback(self,...);return result
    end
end
function CreateFrame(kind,name,parent,template)
    assert(not template or template=="BackdropTemplate" or (template=="DisableUntrustedLayoutScriptsTemplate" and not M.noLayoutTemplate),"Unsupported template")
    local frame=object(kind,parent,name)
    frame.template=template
    if name then _G[name]=frame end
    return frame
end
function InCombatLockdown() return M.combat end
function issecretvalue(value) return rawequal(value,M.secret) end
M.secret=setmetatable({}, {__tostring=function() error("Secret formatted") end, __index=function() error("Secret indexed") end})
function GetBuildInfo() return M.interface==16001 and "1.60.1" or "12.1.0","test","",M.interface or 120100 end
function IsLoggedIn() return M.loggedIn or false end
function UnitHealth() error("Unit data is out of scope") end
function UnitPower() error("Unit data is out of scope") end
M.unitData = {
    player={player=true,class="PALADIN",race="Scourge",faction="Horde"},
    target={player=true,class="ROGUE",race="Human",faction="Alliance"},
    focus={player=true,class="MAGE",race="Gnome",faction="Alliance"},
}
function UnitIsPlayer(unit) return M.unitData[unit] and M.unitData[unit].player end
function UnitClass(unit) return "localized",M.unitData[unit] and M.unitData[unit].class end
function UnitRace(unit) return "localized",M.unitData[unit] and M.unitData[unit].race end
function UnitFactionGroup(unit) return M.unitData[unit] and M.unitData[unit].faction end
function UnitGUID(unit) return M.unitData[unit] and M.unitData[unit].guid end
function UnitPlayerControlled(unit) return M.unitData[unit] and M.unitData[unit].controlled or false end
function GetTime() return M.time or 0 end
C_TooltipInfo=nil
C_Reputation=nil
GetFactionInfoByID=nil
DEFAULT_CHAT_FRAME={AddMessage=function(_,text) M.messages[#M.messages+1]=text end}
SlashCmdList={}
UISpecialFrames={}
JiberishUIOptionsFrame=nil
BLINKIISPORTRAITS=nil
ElvUI_mMediaTag=nil
mMT=nil
PlayerCastingBarFrame=nil
OverlayPlayerCastingBarFrame=nil
GamepadPlayerCastingBarFrame=nil
EllesmereUI=nil
ERB_CastBarFrame=nil
ERB_CastBar=nil
PartyFrame=nil
CompactPartyFrame=nil
CompactRaidFrameContainer=nil
PetFrame=nil
TargetFrameToT=nil
FocusFrameToT=nil
for i=1,5 do _G["Boss"..i.."TargetFrame"]=nil end
PlayerName=nil
PlayerLevelText=nil
RAID_CLASS_COLORS={PALADIN={r=.96,g=.55,b=.73},MAGE={r=.25,g=.78,b=.92},ROGUE={r=1,g=.96,b=.41},HUNTER={r=.67,g=.83,b=.45}}
LibStub=nil
for _,prefix in ipairs({"ElvUF_","EllesmereUIUnitFrames_"}) do
    for _,unit in ipairs({"Player","Target","Focus"}) do _G[prefix..unit]=nil end
end
ElvUI_Bar1=nil
EABBar_MainBar=nil
UIParent=object("Frame",nil,"UIParent")
UIParent.w,UIParent.h,UIParent.scale=1920,1080,0.64
UIParent.native=true
function M.native(name,w,h,scale)
    local frame=object("Frame",UIParent,name)
    frame.w,frame.h,frame.scale=w,h,scale or 1
    frame.native=true
    if name == "PlayerFrame" or name == "TargetFrame" or name == "FocusFrame" then
        local container=object("Frame",frame); container.native=true
        local portrait=object("Texture",container); portrait.native=true;portrait.stockPresentation=true
        if name == "PlayerFrame" then
            frame.PlayerFrameContainer=container; container.PlayerPortrait=portrait
        else
            frame.TargetFrameContainer=container; container.Portrait=portrait
        end
        local content=object("Frame",frame);content.native=true
        local main=object("Frame",content);main.native=true
        local healthContainer=object("Frame",main);healthContainer.native=true
        local manaArea=object("Frame",main);manaArea.native=true
        local function bar(parent,kind,w,h)
            local b=object("Frame",parent);b.native=true;b.w=w;b.h=h;b.level=5;b.strata="LOW"
            b.powerLayoutBar=kind=="Mana";b.points={{"TOPLEFT",parent,"TOPLEFT",0,-20}}
            b.fill=object("Texture",b);b.fill.native=true;b.fill.fillTexture=true
            b.fill.atlas="Native-"..name.."-"..kind;b.fill.path="native-textures";b.fill.texCoord={.1,.2,.1,.4,.7,.2,.7,.4}
            M.atlasUVs[b.fill.atlas]=b.fill.texCoord
            return b
        end
        local nameLabel=object("FontString",main)
        nameLabel.native=true;nameLabel.stockPresentation=true
        nameLabel.points={{"TOPLEFT",main,"TOPLEFT",5,8}};nameLabel.font={"Fonts/FRIZQT__.TTF",11,""}
        main.Name=nameLabel;frame.name=nameLabel
        if name=="PlayerFrame" then PlayerName=nameLabel end
        main.HealthBarsContainer=healthContainer
        healthContainer.HealthBar=bar(healthContainer,"Health",124,20)
        if name=="PlayerFrame" then
            frame.PlayerFrameContent=content;content.PlayerFrameContentMain=main
            main.ManaBarArea=manaArea;manaArea.ManaBar=bar(manaArea,"Mana",124,10)
        else
            frame.TargetFrameContent=content;content.TargetFrameContentMain=main
            main.ManaBar=bar(main,"Mana",134,10)
        end
    end
    _G[name]=frame
    return frame
end
function M.region(parent,kind,w,h)
    local region=object(kind or "Texture",parent)
    region.w,region.h,region.native=w,h,true
    return region
end
M.native("Minimap",198,198)
M.native("PlayerFrame",232,100,1.3)
M.native("TargetFrame",232,100)
M.native("FocusFrame",232,100,0.75)
M.native("MainActionBar",562,45)
function M.event(core,event,name) core.driver.scripts.OnEvent(core.driver,event,name) end
function M.tick(core) core.driver.scripts.OnUpdate(core.driver,0.21) end
function M.load(options)
    options=options or {}
    M.interface=options.interface or 120100
    JiberishUIDB=options.db
    JiberishUICharacterDB=options.characterDB or M.characterDB
    local J={}
    local toc=assert(io.open("JiberishUI/JiberishUI.toc")):read("*a")
    for path in toc:gmatch("[^\r\n]+") do
        if path:match("%.lua$") then
            local chunk=assert(loadfile("JiberishUI/"..path:gsub("\\","/")))
            chunk("JiberishUI",J)
        end
    end
    -- Existing shell tests explicitly isolate the per-unit renderer from the global stock texture option.
    if not options.stockStone then J.ThemeManager.registry.paladin_ret.playerFrame.blizzardStone=false end
    if options.flavor then J.Build.flavor=options.flavor end
    if not options.noStart then M.event(J.Core,"PLAYER_LOGIN") end
    M.characterDB=JiberishUICharacterDB
    return J
end
return M
