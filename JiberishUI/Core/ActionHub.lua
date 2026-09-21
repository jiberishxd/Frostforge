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
    self.console={}
    for i=1,9 do self.console[i]=frame:CreateTexture(nil,'BACKGROUND',nil,-1) end
    self.bays={}
    for _,key in ipairs({'actions','micro','bags'}) do
        local bay=CreateFrame('Frame',nil,frame);bay:EnableMouse(false);bay:Hide()
        self.bays[key]={frame=bay,border=R.Create(bay,bay,'external')}
    end
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
-- One nine-slice console: fixed sculpted corners, stretching only the plain
-- basin/rails. The generated master is never tiled or stretched as a whole.
function H:Console(config,cfg,w,h)
    local xs,ys={0,0.12,0.88,1},{0,0.43,0.72,1}
    local widths,heights={64,w-128,64},{55,h-90,35}
    local y=0
    for row=1,3 do
        local x=0
        for col=1,3 do
            local t=self.console[(row-1)*3+col]
            if t:SetTexture(J.MediaRoot..'hub\\console.tga')==false then return false end
            t:ClearAllPoints();t:SetPoint('TOPLEFT',self.frame,'TOPLEFT',x,-y);t:SetSize(widths[col],heights[row])
            t:SetTexCoord(xs[col],xs[col+1],ys[row],ys[row+1])
            local tint=cfg.tint
            local alpha=config.hubOpacity*((row==2 and col==2) and config.hubBackdrop or 1)
            t:SetVertexColor(0.5+tint[1]*0.5,0.5+tint[2]*0.5,0.5+tint[3]*0.5,alpha);t:Show()
            x=x+widths[col]
        end
        y=y+heights[row]
    end
    return true
end
function H:Bays(config,cfg,x,y)
    local bounds={actions=H.Bounds(self.candidates,config.hubScope,{})}
    if config.hubMicro and self.micro then bounds.micro=rect(self.micro) end
    if config.hubBags and self.bags then bounds.bags=rect(self.bags) end
    for key,bay in pairs(self.bays) do
        local b=bounds[key]
        -- Do not paint a huge empty span when a provider keeps controls outside
        -- this hub. The user positions those controls in that provider's editor.
        if b and b[1]>=x+8 and b[3]<=x+self.frame:GetWidth()-8 and b[2]>=y+8 and b[4]<=y+self.frame:GetHeight()-8 then
            local last=bay.bounds
            if bay.config~=config or not last or last[1]~=b[1] or last[2]~=b[2] or last[3]~=b[3] or last[4]~=b[4] then
                local p=4;bay.frame:ClearAllPoints();bay.frame:SetPoint('BOTTOMLEFT',self.frame,'BOTTOMLEFT',b[1]-x-p,b[2]-y-p)
                bay.frame:SetSize(b[3]-b[1]+2*p,b[4]-b[2]+2*p)
                bay.ready=R.Apply(bay.border,cfg)==true;bay.bounds=b;bay.config=config
            end
            bay.frame:SetShown(bay.ready==true)
        else bay.frame:Hide();bay.bounds=nil end
    end
end
function H:Layout(layout)
    local config=self.config
    if not self.frame then return end
    local enabled=config and config.enabled and (config.actionMode=='hub' or config.actionMode=='surround' or config.actionMode=='both') and not J.conflicts.actionbars
    if not enabled or J.HubLayout.Editing() then
        if layout then J.HubLayout:Release() end
        self.frame:Hide();self.applied=false;self.ready=false;self.lastConfig=nil
        self.status=J.HubLayout.Editing() and 'Hub paused for Edit Mode.' or 'Hub disabled.';return
    end
    if not layout then
        local any=false;for _,frame in ipairs(self.candidates) do if visible(frame) then any=true;break end end
        self.frame:SetShown(self.ready and any or false);self.applied=self.ready and any or false
        return
    end
    local bounds,count=H.Bounds(self.candidates,config.hubScope,self.extras)
    if not bounds then J.HubLayout:Release();self.frame:Hide();self.applied=false;self.ready=false;self.lastConfig=nil;self.status='No visible action buttons with usable geometry.';return end
    local style=F.Resolve(config.hubStyle,{unit='player'})
    local cfg=U.Copy(config);cfg.skin=style and style.skin or config.skin;cfg.ornament=0;cfg.inset=0
    cfg.thickness=U.Clamp(config.thickness,2,6);cfg.opacity=config.hubOpacity
    if style then cfg.tint=U.Copy(J.Skins[style.skin].defaults.tint) end
    local padding=config.hubPadding
    local x,y,w,h=bounds[1]-padding,bounds[2]-padding,bounds[3]-bounds[1]+2*padding,bounds[4]-bounds[2]+2*padding
    local hub=config.actionMode=='hub'
    if hub then x,y,w,h=J.HubLayout.Geometry(config) end
    if not x then self.frame:Hide();self.applied=false;self.ready=false;return end
    if self.lastConfig~=config or not self.bounds or self.bounds[1]~=x or self.bounds[2]~=y or self.bounds[3]~=w or self.bounds[4]~=h then
        self.frame:ClearAllPoints();self.frame:SetPoint('BOTTOMLEFT',UIParent,'BOTTOMLEFT',x,y);self.frame:SetSize(w,h)
        self.background:ClearAllPoints()
        if hub then
            self.background:SetPoint('TOPLEFT',self.frame,'TOPLEFT',64,-55)
            self.background:SetPoint('BOTTOMRIGHT',self.frame,'BOTTOMRIGHT',-64,35)
        else self.background:SetAllPoints(self.frame) end
        self.background:SetColorTexture(0.025,0.028,0.04,config.hubBackdrop*config.hubOpacity)
        self.background:SetShown(not hub)
        for _,t in ipairs(self.console) do t:Hide() end
        for _,bay in pairs(self.bays) do bay.frame:Hide();bay.bounds=nil end
        R.Hide(self.border)
        if not (hub and self:Console(config,cfg,w,h) or not hub and R.Apply(self.border,cfg)) then
            J.HubLayout:Release();self.frame:Hide();self.applied=false;self.ready=false;self.lastConfig=nil;self.status='Hub artwork unavailable; native art retained.';return
        end
        self.crest:Hide()
        if style then
            if self.crest:SetTexture(style.path)==false then
                J.HubLayout:Release();self.frame:Hide();self.applied=false;self.ready=false;self.lastConfig=nil;self.status='Class artwork unavailable; native art retained.';return
            end
            local width=math.min(w*0.65,260)*config.hubArtworkScale
            self.crest:ClearAllPoints();self.crest:SetSize(width,width/3)
            -- The default header clears the controls; users can adjust its
            -- position independently with the artwork X/Y controls.
            self.crest:SetPoint('BOTTOM',self.frame,'TOP',config.hubArtworkX or 0,2+(config.hubArtworkY or 0))
            self.crest:SetVertexColor(1,1,1,config.hubOpacity);self.crest:Show()
        end
        self.bounds={x,y,w,h};self.lastConfig=config
    end
    J.HubLayout:Apply(config)
    if hub then self:Bays(config,cfg,x,y) end
    self.ready=true;self.frame:Show();self.applied=true
    local provider=J.Integrations and J.Integrations.providers.actionbars
    local placement=provider and ('; position controls with '..provider) or config.hubDock and '; Blizzard controls docked' or '; free placement'
    self.status=string.format('%s: %d visible components, %.0f x %.0f UI units%s.',hub and 'Class fantasy hub' or 'One surround',count,w,h,hub and placement or '')
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
            return frame
        end
        if config.hubMicro then
            self.micro=extra(ElvUI_MicroBar,MicroMenu)
        end
        if config.hubBags then self.bags=extra(ElvUIBagBar,BagsBar) end
    end
    if layout and #self.candidates>0 then self:Create() end
    self:Layout(layout)
end
