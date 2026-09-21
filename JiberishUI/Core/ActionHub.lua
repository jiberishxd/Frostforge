local _,J=...
local U,R,F=J.Util,J.Renderer,J.Fantasy
local H={candidates={},status='No surround attached.'};J.ActionHub=H
local function visible(frame)
    if not frame or (frame.IsForbidden and frame:IsForbidden()) then return false end
    local shown
    if frame.IsVisible then shown=frame:IsVisible() else shown=frame:IsShown() end
    if not U.Safe(shown) or shown~=true then return false end
    local alpha
    if frame.GetEffectiveAlpha then alpha=frame:GetEffectiveAlpha() else alpha=frame:GetAlpha() end
    return U.Number(alpha) and alpha>0
end
local function rect(frame)
    if not visible(frame) or not frame.GetRect then return end
    local ok,l,b,w,h=pcall(frame.GetRect,frame)
    if not ok then return end
    local scale,parentScale=frame:GetEffectiveScale(),UIParent:GetEffectiveScale()
    if not U.Number(l) or not U.Number(b) or not U.Number(w) or not U.Number(h) or not U.Number(scale) or not U.Number(parentScale) then return end
    if w<=0 or h<=0 or scale<=0 or parentScale<=0 then return end
    local m=scale/parentScale
    return {l*m,b*m,(l+w)*m,(b+h)*m}
end
local function union(a,b)
    return {math.min(a[1],b[1]),math.min(a[2],b[2]),math.max(a[3],b[3]),math.max(a[4],b[4])}
end
function H.Bounds(candidates,scope,extras)
    local boxes={}
    for _,frame in ipairs(candidates) do local box=rect(frame);if box then boxes[#boxes+1]=box end end
    if #boxes==0 then return end
    -- Seed from the lowest central action button, then include adjacent rows.
    -- Side bars stay outside the surround unless All bars is selected.
    local parentWidth=UIParent:GetWidth();if not U.Number(parentWidth) or parentWidth<=0 then return end
    local center=parentWidth/2
    local seed,score=1,math.huge
    for i,box in ipairs(boxes) do
        local value=box[2]*4+math.abs((box[1]+box[3])/2-center)
        if value<score then score=value;seed=i end
    end
    local bounds=boxes[seed];local selected={[seed]=true};local changed=true;local count=1
    while changed do
        changed=false
        for i,box in ipairs(boxes) do
            if not selected[i] and (scope=='all' or
                (box[1]<=bounds[3]+64 and box[3]>=bounds[1]-64 and box[2]<=bounds[4]+48 and box[4]>=bounds[2]-48)) then
                bounds=union(bounds,box);selected[i]=true;count=count+1;changed=true
            end
        end
    end
    for _,frame in ipairs(extras or {}) do local box=rect(frame);if box then bounds=union(bounds,box);count=count+1 end end
    return bounds,count
end
function H:Create()
    if self.frame or U.Combat() then return end
    local frame=CreateFrame('Frame',nil,UIParent);self.frame=frame;frame:EnableMouse(false);frame:Hide()
    self.background=frame:CreateTexture(nil,'BACKGROUND');self.background:SetAllPoints(frame)
    self.border=R.Create(frame,frame,'rail')
    self.crest=frame:CreateTexture(nil,'BORDER',nil,1)
    -- A separate always-shown driver detects Edit Mode dragging and auto-hide
    -- while the decoration itself may be hidden. Only our own frame is moved.
    self.driver=CreateFrame('Frame',nil,UIParent)
    local elapsed=0
    self.driver:SetScript('OnUpdate',function(_,delta)
        elapsed=elapsed+delta;if elapsed<0.25 then return end;elapsed=0
        local wasApplied=self.applied
        J:Protect('action-surround',self.Layout,self,not U.Combat())
        if wasApplied~=self.applied then J:Schedule() end
    end)
end
function H:Layout(layout)
    local config=self.config
    if not self.frame then return end
    local enabled=config and config.enabled and (config.actionMode=='surround' or config.actionMode=='both') and not J.conflicts.actionbars
    if not enabled then self.frame:Hide();self.applied=false;self.status='Surround disabled.';return end
    if not layout then
        local any=false;for _,frame in ipairs(self.candidates) do if visible(frame) then any=true;break end end
        self.frame:SetShown(self.ready and any or false);self.applied=self.ready and any or false
        return
    end
    local bounds,count=H.Bounds(self.candidates,config.hubScope,self.extras)
    if not bounds then self.frame:Hide();self.applied=false;self.ready=false;self.status='No visible action buttons with usable geometry.';return end
    local style=F.Resolve(config.hubStyle,{unit='player'})
    local cfg=U.Copy(config);cfg.skin=style and style.skin or config.skin;cfg.ornament=0;cfg.inset=0
    cfg.thickness=U.Clamp(config.thickness,2,6);cfg.opacity=config.hubOpacity
    if style then cfg.tint=U.Copy(J.Skins[style.skin].defaults.tint) end
    local padding=config.hubPadding
    local x,y,w,h=bounds[1]-padding,bounds[2]-padding,bounds[3]-bounds[1]+2*padding,bounds[4]-bounds[2]+2*padding
    if self.lastConfig~=config or not self.bounds or self.bounds[1]~=x or self.bounds[2]~=y or self.bounds[3]~=w or self.bounds[4]~=h then
        self.frame:ClearAllPoints();self.frame:SetPoint('BOTTOMLEFT',UIParent,'BOTTOMLEFT',x,y);self.frame:SetSize(w,h)
        self.background:SetColorTexture(0.025,0.028,0.04,config.hubBackdrop*config.hubOpacity)
        if not R.Apply(self.border,cfg) then
            self.frame:Hide();self.applied=false;self.ready=false;self.status='Surround artwork unavailable; native art retained.';return
        end
        self.crest:Hide()
        if style then
            if self.crest:SetTexture(style.path)==false then
                self.frame:Hide();self.applied=false;self.ready=false;self.status='Class artwork unavailable; native art retained.';return
            end
            local width=math.min(w*0.65,260)*config.hubArtworkScale
            self.crest:ClearAllPoints();self.crest:SetSize(width,width/3)
            -- Keep art in a header above buttons, where it cannot cover keys,
            -- cooldown numbers, micro-menu notices, or bag counts.
            self.crest:SetPoint('BOTTOM',self.frame,'TOP',0,2)
            self.crest:SetVertexColor(1,1,1,config.hubOpacity);self.crest:Show()
        end
        self.bounds={x,y,w,h};self.lastConfig=config
    end
    self.ready=true;self.frame:Show();self.applied=true
    self.status=string.format('One surround: %d visible components, %.0f x %.0f UI units.',count,w,h)
end
function H:Update(descriptors,layout)
    self.config=J.active.actionbars;self.candidates={};self.extras={}
    for _,desc in ipairs(descriptors) do
        if desc.group=='actionbars' and (desc.kind=='button' or desc.kind=='externalbutton') then self.candidates[#self.candidates+1]=desc.frame end
    end
    local config=self.config
    if config and layout then
        local function extra(primary,fallback)
            local frame=primary and rect(primary) and primary or fallback
            if frame then self.extras[#self.extras+1]=frame end
        end
        if config.hubMicro then
            extra(ElvUI_MicroBar,MicroMenu)
        end
        if config.hubBags then extra(ElvUIBagBar,BagsBar) end
    end
    if layout and #self.candidates>0 then self:Create() end
    self:Layout(layout)
end
