-- Deliberately limited offline host. This does not simulate WoW's secure engine.
local M = {frames={},textures=0,fonts=0,nativeWrites=0,geometryWrites=0,writes=0,combat=false,messages={}}
local methods = {}
local function object(kind,parent,name)
    local self = setmetatable({kind=kind,parent=parent,name=name,w=100,h=30,scale=1,alpha=1,
        shown=true,points={},scripts={},events={},regions={}}, {__index=methods})
    if kind == "Frame" then M.frames[#M.frames+1]=self end
    return self
end
local function readable(self)
    if self.forbidden then error("Forbidden frame inspected before gate") end
    M.reads = (M.reads or 0) + 1
end
local function writable(self,geometry)
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
function methods:SetPoint(...) writable(self,true); self.points[#self.points+1]={...} end
function methods:GetPoint(i) return unpack(self.points[i or 1]) end
function methods:ClearAllPoints() writable(self,true); self.points={} end
function methods:SetAllPoints(relative) writable(self,true); self.allPoints=relative end
function methods:SetFrameStrata(value) writable(self); self.strata=value end
function methods:SetFrameLevel(value) writable(self); self.level=value end
function methods:EnableMouse(value) writable(self); self.mouse=value end
function methods:EnableMouseWheel(value) writable(self); self.wheel=value end
function methods:EnableKeyboard(value) writable(self); self.keyboard=value end
function methods:SetDrawLayer(value,sub) writable(self); self.layer,self.sub=value,sub end
function methods:SetTexture(value)
    writable(self)
    self.path=value
    return not M.missingTexture
end
function methods:SetColorTexture(...) writable(self); self.color={...} end
function methods:SetShown(value) writable(self); self.shown=value end
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
function methods:CreateFontString()
    writable(self)
    M.fonts=M.fonts+1
    local font=object("FontString",self)
    self.regions[#self.regions+1]=font
    return font
end
function methods:SetText(text) writable(self); self.text=text end
function methods:GetText() return self.text end
function methods:SetTextColor(...) writable(self); self.color={...} end
function methods:SetJustifyH(value) writable(self); self.justify=value end
function methods:RegisterEvent(event) writable(self); self.events[event]=true end
function methods:SetScript(event,callback) writable(self); self.scripts[event]=callback end
-- These APIs must never be used by the prototype, even on unprotected native UI.
function methods:SetParent() error("No reparenting permitted") end
function methods:SetAttribute() error("No secure attribute writes permitted") end
function hooksecurefunc() error("No native hooks are needed by Phase 1") end
function CreateFrame(kind,name,parent,template)
    assert(not template,"No secure or native templates")
    local frame=object(kind,parent,name)
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
function UnitClass() error("Unit data is out of scope") end
DEFAULT_CHAT_FRAME={AddMessage=function(_,text) M.messages[#M.messages+1]=text end}
SlashCmdList={}
UIParent=object("Frame",nil,"UIParent")
UIParent.w,UIParent.h,UIParent.scale=1920,1080,0.64
UIParent.native=true
function M.native(name,w,h,scale)
    local frame=object("Frame",UIParent,name)
    frame.w,frame.h,frame.scale=w,h,scale or 1
    frame.native=true
    _G[name]=frame
    return frame
end
M.native("Minimap",198,198)
M.native("PlayerFrame",232,100,1.3)
M.native("TargetFrame",232,100)
M.native("MainActionBar",562,45)
function M.event(core,event,name) core.driver.scripts.OnEvent(core.driver,event,name) end
function M.tick(core) core.driver.scripts.OnUpdate(core.driver,0.21) end
function M.load(options)
    options=options or {}
    M.interface=options.interface or 120100
    JiberishUIDB=options.db
    local J={}
    local toc=assert(io.open("JiberishUI/JiberishUI.toc")):read("*a")
    for path in toc:gmatch("[^\r\n]+") do
        if path:match("%.lua$") then
            local chunk=assert(loadfile("JiberishUI/"..path:gsub("\\","/")))
            chunk("JiberishUI",J)
        end
    end
    if options.flavor then J.Build.flavor=options.flavor end
    if not options.noStart then M.event(J.Core,"PLAYER_LOGIN") end
    return J
end
return M
