-- A deliberately small Lua 5.1 host, not a substitute for WoW's secure runtime.
local M={timers={},textures=0,hooks=0,layoutWrites=0,combat=false,loaded={},messages={}}
local methods={}
local function object(kind,parent)
    local o=setmetatable({kind=kind,parent=parent,w=100,h=30,scale=1,shown=true,alpha=1,children={},regions={},scripts={},points={},coords={0,1,0,1},masks={}}, {__index=methods})
    if parent then local list=(kind=='Texture' or kind=='FontString') and parent.regions or parent.children; list[#list+1]=o end
    return o
end
M.object=object
function methods:GetObjectType() return self.kind end
function methods:GetParent() return self.parent end
function methods:GetChildren() return unpack(self.children) end
function methods:GetRegions() return unpack(self.regions) end
function methods:GetWidth() return self.w end
function methods:GetHeight() return self.h end
function methods:GetEffectiveScale() return self.scale end
function methods:SetSize(w,h) self.w=w;self.h=h; M.layoutWrites=M.layoutWrites+1 end
function methods:SetWidth(w) self.w=w end
function methods:SetHeight(h) self.h=h end
function methods:SetPoint(...) self.points[#self.points+1]={...}; M.layoutWrites=M.layoutWrites+1 end
function methods:ClearAllPoints() self.points={} end
function methods:SetAllPoints() M.layoutWrites=M.layoutWrites+1 end
function methods:CreateTexture() M.textures=M.textures+1; return object('Texture',self) end
function methods:CreateFontString() return object('FontString',self) end
function methods:SetTexture(path) if M.missing and type(path)=='string' and path:find(M.missing,1,true) then return false end; self.texture=path;self.atlas=nil; return true end
function methods:GetTexture() return self.texture end
function methods:SetAtlas(atlas) self.atlas=atlas;self.texture=42; self.coords={0,1,0,1} end
function methods:GetAtlas() return self.atlas end
function methods:SetTexCoord(...) self.coords={...} end
function methods:GetTexCoord() return unpack(self.coords) end
function methods:SetVertexColor(...) self.vertex={...} end
function methods:SetColorTexture(...) self.vertex={...} end
function methods:SetAlpha(a) self.alpha=a end
function methods:GetAlpha() return self.alpha end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
function methods:SetShown(v) self.shown=v end
function methods:IsShown() return self.shown end
function methods:SetStatusBarTexture(path)
    if not self.fill then self.fill=self:CreateTexture() end; self.fill:SetTexture(path)
end
function methods:GetStatusBarTexture() return self.fill end
function methods:SetStatusBarColor(...) self.color={...} end
function methods:GetStatusBarColor() return unpack(self.color or {1,1,1,1}) end
function methods:AddMaskTexture(mask) self.masks[#self.masks+1]=mask end
function methods:RemoveMaskTexture(mask) for i=#self.masks,1,-1 do if self.masks[i]==mask then table.remove(self.masks,i) end end end
function methods:GetNumMaskTextures() return #self.masks end
function methods:GetMaskTexture(i) return self.masks[i] end
function methods:SetScript(name,fn) self.scripts[name]=fn end
function methods:HookScript(name,fn) local old=self.scripts[name]; self.scripts[name]=function(...) if old then old(...) end; fn(...) end end
function methods:RegisterEvent() end
function methods:SetText(v) self.text=v end
function methods:GetText() return self.text or '' end
function methods:SetChecked(v) self.checked=v end
function methods:GetChecked() return self.checked end
function methods:SetValue(v) self.value=v; if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,v) end end
function methods:SetMinMaxValues(a,b) self.min=a;self.max=b end
for _,name in ipairs({'SetAutoFocus','SetMultiLine','SetFontObject','SetMaxLetters','SetJustifyH','SetFrameStrata','EnableMouse','SetBackdrop','SetBackdropColor','SetScrollChild','SetFocus','HighlightText','SetOrientation','SetValueStep','SetObeyStepOnDrag','SetThumbTexture'}) do methods[name]=function() end end
for _,state in ipairs({'Normal','Pushed','Highlight','Checked'}) do
    methods['Get'..state..'Texture']=function(self) return self[state] end
    methods['Set'..state..'Texture']=function(self,path) self[state]=self[state] or self:CreateTexture(); self[state]:SetTexture(path) end
    methods['Set'..state..'Atlas']=function(self,path) self[state]=self[state] or self:CreateTexture(); self[state]:SetAtlas(path) end
end
function CreateFrame(kind,name,parent) local frame=object(kind,parent); if name then _G[name]=frame end; return frame end
UIParent=CreateFrame('Frame'); SlashCmdList={}
function InCombatLockdown() return M.combat end
function issecretvalue(value) return value==M.secret end
M.secret=setmetatable({}, {__index=function() error('secret indexed') end,__tostring=function() error('secret formatted') end})
function hooksecurefunc(objectOrName,methodOrCallback,callback)
    local owner,key,fn
    if type(objectOrName)=='string' then owner,key,fn=_G,objectOrName,methodOrCallback else owner,key,fn=objectOrName,methodOrCallback,callback end
    local original=assert(owner[key],key); M.hooks=M.hooks+1
    owner[key]=function(...) local result={original(...)}; fn(...); return unpack(result) end
end
C_Timer={After=function(_,fn) M.timers[#M.timers+1]=fn end}
function M.flush()
    local rounds=0
    while #M.timers>0 do rounds=rounds+1; assert(rounds<20,'unbounded refresh loop'); local timers=M.timers; M.timers={}; for _,fn in ipairs(timers) do fn() end end
end
function GetBuildInfo() return '12.1.0','69875','',M.interface or 120100 end
function UnitFullName() return 'Test','Realm' end
function GetRealmName() return 'Realm' end
function UnitIsConnected() if M.restricted then return M.secret end; return M.connected~=false end
function UnitIsDeadOrGhost() return M.dead or false end
function UnitIsTapDenied() return M.tapped or false end
function UnitIsPlayer() return M.player~=false end
function UnitClass() return 'Mage','MAGE',8 end
function UnitSelectionColor() return 1,0.5,0 end
function UnitPowerType() if M.restrictedPower then return 0,M.secret end; return 0,'MANA' end
function UnitHealth() error('UnitHealth must never be queried') end
function UnitPower() error('UnitPower must never be queried') end
RAID_CLASS_COLORS={MAGE={r=0.4,g=0.8,b=1}}; PowerBarColor={MANA={r=0,g=0,b=1}}
C_AddOns={IsAddOnLoaded=function(name) return M.loaded[name] end}
DEFAULT_CHAT_FRAME={AddMessage=function(_,msg) M.messages[#M.messages+1]=msg end}
Settings={RegisterCanvasLayoutCategory=function() return {GetID=function() return 123 end} end,RegisterAddOnCategory=function() end,OpenToCategory=function(id) M.category=id end}
function ReloadUI() M.reload=true end
function CompactUnitFrame_UpdateAll() end
function CompactUnitFrame_SetUpFrame() end
function UnitFrameManaBar_UpdateType() end
function UnitFrameHealthBar_Update() end
function M.bar(parent,w,h)
    local bar=CreateFrame('StatusBar',nil,parent);bar:SetSize(w or 126,h or 20);bar:SetStatusBarTexture('native');bar:SetStatusBarColor(1,1,1,1);return bar
end
function M.compact(parent)
    local frame=CreateFrame('Button',nil,parent); frame.unit='raid1';frame.healthBar=M.bar(frame);frame.powerBar=M.bar(frame,126,8);return frame
end
return M
