local _, J = ...
local U = J.Util
local R={}; J.Renderer=R
local names={'tl','tr','bl','br','top','bottom','left','right'}
-- Reuse the native shell's alpha silhouette. Its anchors include the actual
-- portrait cutout, curved bar ends, and portrait-off/vehicle variants.
function R.CreateSilhouette(source)
    local owner=source:GetParent()
    local layer,level=source:GetDrawLayer()
    local mask=owner:CreateMaskTexture(nil,'BACKGROUND')
    local base=owner:CreateTexture(nil,layer,nil,math.min(level or 0,7))
    local material=owner:CreateTexture(nil,layer,nil,math.min(level or 0,7))
    base:AddMaskTexture(mask);material:AddMaskTexture(mask)
    base:Hide();material:Hide()
    return {owner=owner,region=source,variant='silhouette',mode='silhouette',mask=mask,
        pieces={base=base,material=material},extraMasks={},maskPool={}}
end
local function copyMask(mask,source,layout)
    local atlas=source.GetAtlas and source:GetAtlas()
    local path=source:GetTexture()
    if not U.Safe(atlas) or not U.Safe(path) then return false end
    if type(atlas)=='string' then mask:SetAtlas(atlas,false,nil,false,'CLAMPTOBLACKADDITIVE','CLAMPTOBLACKADDITIVE')
    elseif type(path)=='string' or U.Number(path) then
        if mask:SetTexture(path,'CLAMPTOBLACKADDITIVE','CLAMPTOBLACKADDITIVE')==false then return false end
    else return false end
    local coords={source:GetTexCoord()}
    for _,v in ipairs(coords) do if not U.Number(v) then return false end end
    if #coords~=4 and #coords~=8 then return false end
    mask:SetTexCoord(unpack(coords))
    if mask.SetSnapToPixelGrid then mask:SetSnapToPixelGrid(false);mask:SetTexelSnappingBias(0) end
    if layout then mask:ClearAllPoints();mask:SetAllPoints(source) end
    return true
end
local function syncMasks(record,source,layout)
    if not copyMask(record.mask,source,layout) then R.Hide(record);return false end
    local maskCount=source.GetNumMaskTextures and source:GetNumMaskTextures() or 0
    if not U.Number(maskCount) or maskCount<0 or maskCount>4 then return false end
    for i=1,maskCount do
        local native=source:GetMaskTexture(i)
        if not record.extraMasks[i] then
            if not layout then return false end
            local mask=record.maskPool[i] or record.owner:CreateMaskTexture(nil,'BACKGROUND')
            record.maskPool[i]=mask;record.extraMasks[i]=mask
            for _,piece in pairs(record.pieces) do piece:AddMaskTexture(mask) end
        end
        if not copyMask(record.extraMasks[i],native,layout) then return false end
    end
    if #record.extraMasks>maskCount then
        if not layout then return false end
        for i=#record.extraMasks,maskCount+1,-1 do
            for _,piece in pairs(record.pieces) do piece:RemoveMaskTexture(record.extraMasks[i]) end
            record.extraMasks[i]=nil
        end
    end
    return true
end
function R.Silhouette(record,config,layout)
    local source=record.region
    local shown=source:IsShown()
    if not U.Safe(shown) then return false end
    if not shown then R.Hide(record);return true end
    local skin=J.Skins[config.skin]
    if not skin or not skin.qualified then return false end
    if not syncMasks(record,source,layout) then return false end
    local w,h=source:GetWidth(),source:GetHeight()
    if not U.Number(w) or not U.Number(h) or w<=0 or h<=0 then return false end
    local material=record.pieces.material
    if material:SetTexture(skin.path..'top.tga','REPEAT','REPEAT')==false then return false end
    -- Tile the racial/class material over the shell; geometry stays native.
    if layout then
        for _,piece in pairs(record.pieces) do
            piece:ClearAllPoints();piece:SetAllPoints(source)
            if piece.SetSnapToPixelGrid then piece:SetSnapToPixelGrid(false);piece:SetTexelSnappingBias(0) end
        end
        local repeatSize=24
        material:SetTexCoord(0,w/repeatSize,0,h/repeatSize)
    end
    local alpha=config.opacity*(record.nativeAlpha and record.nativeAlpha() or 1)
    record.pieces.base:SetColorTexture(config.tint[1]*0.22,config.tint[2]*0.22,config.tint[3]*0.22,alpha)
    material:SetVertexColor(config.tint[1],config.tint[2],config.tint[3],alpha)
    for _,piece in pairs(record.pieces) do piece:SetShown(shown) end
    record.config=config
    return true
end
-- Blizzard's decorative atlas also contains bar backdrops. Never paint its full
-- rectangle or hide it: place edge-only pieces over it and clip to its silhouette.
function R.CreateContour(source,regions)
    local owner=source:GetParent()
    local layer,level=source:GetDrawLayer()
    local record={owner=owner,region=source,mode='contour',pieces={},arcs={},bars={},blockers={},
        portrait=regions.portrait,extraMasks={},maskPool={},mask=owner:CreateMaskTexture(nil,'BACKGROUND')}
    for _,bar in ipairs({regions.health,regions.power}) do
        if bar then
            local border=R.Create(owner,bar,'nativebar');record.bars[#record.bars+1]=border
            for _,piece in pairs(border.pieces) do
                piece:SetDrawLayer(layer,level);piece:AddMaskTexture(record.mask)
                record.pieces[#record.pieces+1]=piece
            end
            local mask=owner:CreateMaskTexture(nil,'BACKGROUND')
            record.blockers[#record.blockers+1]={mask=mask,bar=bar}
        end
    end
    if record.portrait then
        for i=1,32 do
            local piece=owner:CreateTexture(nil,layer,nil,level)
            piece:AddMaskTexture(record.mask)
            for _,entry in ipairs(record.blockers) do piece:AddMaskTexture(entry.mask) end
            piece:Hide();record.arcs[i]=piece;record.pieces[#record.pieces+1]=piece
        end
    end
    R.Hide(record)
    return record
end
function R.Contour(record,config,layout)
    local source=record.region
    local shown=source:IsShown()
    if not U.Safe(shown) then return false end
    if not shown then R.Hide(record);return true end
    local skin=J.Skins[config.skin]
    if not skin or not skin.qualified or not syncMasks(record,source,layout) then return false end
    local nativeAlpha=source:GetAlpha()
    local _,_,_,vertexAlpha=source:GetVertexColor()
    if not U.Number(nativeAlpha) or not U.Number(vertexAlpha) then return false end
    local cfg=U.Copy(config);cfg.opacity=config.opacity*nativeAlpha*vertexAlpha
    cfg.thickness=2;cfg.inset=0;cfg.ornament=0
    for _,border in ipairs(record.bars) do
        local visible=border.region:IsShown()
        if not U.Safe(visible) then return false end
        if visible then
            local ok=layout and R.Apply(border,cfg) or (not layout and R.Refresh(border,cfg))
            if not ok then return false end
        else R.Hide(border) end
    end
    local portrait=record.portrait
    local visible=portrait and portrait:IsShown()
    if not U.Safe(visible) then return false end
    if visible and config.portraitBorder~=false then
        local portraitConfig=J.Fantasy.PortraitConfig(config)
        local portraitSkin=J.Skins[portraitConfig.skin]
        if not portraitSkin or not portraitSkin.qualified then return false end
        if layout then
            local scale,ps=record.owner:GetEffectiveScale(),portrait:GetEffectiveScale()
            local w,h=portrait:GetWidth(),portrait:GetHeight()
            local sourceHeight=source:GetHeight()
            if not U.Number(scale) or scale<=0 or not U.Number(ps) or ps<=0 or not U.Number(w) or not U.Number(h) or
                w<=0 or h<=0 or not U.Number(sourceHeight) or sourceHeight<=0 then return false end
            local rx,ry=w*ps/scale/2,h*ps/scale/2
            -- Preserve every bar interior, including empty/dead areas beneath the portrait junction.
            for _,entry in ipairs(record.blockers) do
                local barShown=entry.bar:IsShown()
                if not U.Safe(barShown) then return false end
                entry.mask:ClearAllPoints();entry.mask:SetPoint('CENTER',entry.bar,'CENTER')
                if barShown then
                    local bw,bs=entry.bar:GetWidth(),entry.bar:GetEffectiveScale()
                    if not U.Number(bw) or bw<=0 or not U.Number(bs) or bs<=0 then return false end
                    if entry.mask:SetTexture(J.MediaRoot..'outside-rect.tga','CLAMP','CLAMP','NEAREST')==false then return false end
                    entry.mask:SetSize(bw*bs/scale*2,sourceHeight*8)
                else
                    if entry.mask:SetTexture(J.Neutral,'CLAMP','CLAMP')==false then return false end
                    entry.mask:SetSize(1,1)
                end
            end
            local bases={{-0.5,0.5},{-0.5,-0.5},{0.5,0.5},{0.5,-0.5}}
            local repeats=math.pi*(rx+ry)/24
            for i,piece in ipairs(record.arcs) do
                piece:ClearAllPoints();piece:SetPoint('CENTER',portrait,'CENTER');piece:SetSize(1,1)
                local a,b=-(i-1)*2*math.pi/#record.arcs,-i*2*math.pi/#record.arcs
                local vertices={{math.cos(a)*(rx+12),math.sin(a)*(ry+12)},
                    {math.cos(a)*math.max(1,rx-6),math.sin(a)*math.max(1,ry-6)},
                    {math.cos(b)*(rx+12),math.sin(b)*(ry+12)},
                    {math.cos(b)*math.max(1,rx-6),math.sin(b)*math.max(1,ry-6)}}
                for k,v in ipairs(vertices) do piece:SetVertexOffset(k,v[1]-bases[k][1],v[2]-bases[k][2]) end
                piece:SetTexCoord((i-1)*repeats/#record.arcs,i*repeats/#record.arcs,0,1)
                if piece.SetSnapToPixelGrid then piece:SetSnapToPixelGrid(false);piece:SetTexelSnappingBias(0) end
            end
            record.arcReady=true
        end
        if not record.arcReady then return false end
        for _,piece in ipairs(record.arcs) do
            if piece:SetTexture(portraitSkin.path..'top.tga','REPEAT','CLAMP')==false then return false end
            local tint=portraitConfig.tint
            piece:SetVertexColor(tint[1],tint[2],tint[3],cfg.opacity*(config.portraitOpacity or 1));piece:Show()
        end
    else for _,piece in ipairs(record.arcs) do piece:Hide() end end
    record.config=config
    return true
end
function R.Create(owner, region, variant)
    local layer=owner:CreateTexture(nil,'BORDER',nil,0)
    layer:Hide()
    local record={owner=owner,region=region,variant=variant,pieces={tl=layer}}
    for i=2,#names do record.pieces[names[i]]=owner:CreateTexture(nil,'BORDER',nil,0) end
    if J.Variants[variant].ornament then record.ornament=owner:CreateTexture(nil,'BACKGROUND',nil,0) end
    return record
end
function R.Apply(record,config)
    if record.mode=='contour' then return R.Contour(record,config,true) end
    if record.mode=='silhouette' then return R.Silhouette(record,config,true) end
    local region,p=record.region,record.pieces
    local w,h=region:GetWidth(),region:GetHeight()
    if not U.Number(w) or not U.Number(h) or w<=0 or h<=0 then return false end
    local skin=J.Skins[config.skin]
    if not skin or not skin.qualified then return false end
    local variant=J.Variants[record.variant]
    local maximum=math.min(variant.max,w/3,h/3)
    local edge=U.Pixel(U.Clamp(config.thickness,math.min(variant.min,maximum),maximum),record.owner)
    if edge<=0 then return false end
    local inset=U.Pixel(U.Clamp(config.inset,-math.min(w,h)/4,12),record.owner)
    local function point(tex,anchor,rel,offsetX,offsetY)
        tex:SetPoint(anchor,region,rel,offsetX,offsetY)
    end
    for _,key in ipairs(names) do
        local tex=p[key]; tex:ClearAllPoints()
        if tex:SetTexture(skin.path..key..'.tga','REPEAT','REPEAT')==false then R.Hide(record); return false end
        tex:SetVertexColor(config.tint[1],config.tint[2],config.tint[3],config.opacity)
        tex:SetTexCoord(0,1,0,1); tex:SetSize(edge,edge); tex:Show()
    end
    point(p.tl,'TOPLEFT','TOPLEFT',-edge-inset,edge+inset)
    point(p.tr,'TOPRIGHT','TOPRIGHT',edge+inset,edge+inset)
    point(p.bl,'BOTTOMLEFT','BOTTOMLEFT',-edge-inset,-edge-inset)
    point(p.br,'BOTTOMRIGHT','BOTTOMRIGHT',edge+inset,-edge-inset)
    p.top:SetPoint('TOPLEFT',p.tl,'TOPRIGHT'); p.top:SetPoint('TOPRIGHT',p.tr,'TOPLEFT')
    p.bottom:SetPoint('BOTTOMLEFT',p.bl,'BOTTOMRIGHT'); p.bottom:SetPoint('BOTTOMRIGHT',p.br,'BOTTOMLEFT')
    p.left:SetPoint('TOPLEFT',p.tl,'BOTTOMLEFT'); p.left:SetPoint('BOTTOMLEFT',p.bl,'TOPLEFT')
    p.right:SetPoint('TOPRIGHT',p.tr,'BOTTOMRIGHT'); p.right:SetPoint('BOTTOMRIGHT',p.br,'TOPRIGHT')
    local horizontal=math.max(0.01,(w+2*inset)/(edge*2))
    local vertical=math.max(0.01,(h+2*inset)/(edge*2))
    p.top:SetTexCoord(0,horizontal,0,1); p.bottom:SetTexCoord(0,horizontal,0,1)
    p.left:SetTexCoord(0,1,0,vertical); p.right:SetTexCoord(0,1,0,vertical)
    if record.ornament then
        local ornament=record.ornament; ornament:ClearAllPoints()
        ornament:SetTexture(skin.path..'ornament.tga')
        local width=math.min(w*0.75,96)*config.ornament
        ornament:SetSize(math.max(1,width),math.max(1,width/2))
        -- Outside the content rectangle; a background layer cannot cover functional overlays.
        ornament:SetPoint('TOP',region,'BOTTOM',0,-edge-inset)
        ornament:SetVertexColor(config.tint[1],config.tint[2],config.tint[3],config.opacity)
        ornament:SetShown(config.ornament>0)
    end
    record.config=config
    return true
end
function R.Refresh(record,config)
    if record.mode=='contour' then return R.Contour(record,config,false) end
    if record.mode=='silhouette' then return R.Silhouette(record,config,false) end
    -- Combat refresh changes only artwork and color; geometry waits until combat ends.
    local skin=J.Skins[config.skin]; if not skin or not skin.qualified then return false end
    for key,texture in pairs(record.pieces) do
        if texture:SetTexture(skin.path..key..'.tga','REPEAT','REPEAT')==false then return false end
        texture:SetVertexColor(config.tint[1],config.tint[2],config.tint[3],config.opacity)
        texture:Show()
    end
    if record.ornament then record.ornament:SetShown(config.ornament>0) end
    return true
end
function R.Hide(record)
    for _,texture in pairs(record.pieces) do texture:Hide() end
    if record.ornament then record.ornament:Hide() end
end
function R.Button(button,config,layout)
    local skin=J.Skins[config.skin]; if not skin or not skin.qualified then return false end
    for _,entry in ipairs({{'GetNormalTexture','normal'},{'GetPushedTexture','pushed'},{'GetHighlightTexture','highlight'},{'GetCheckedTexture','checked'}}) do
        local getter=button[entry[1]]; local texture=getter and getter(button)
        if texture then
            local previousAtlas=texture.GetAtlas and texture:GetAtlas()
            local previousPath=texture:GetTexture()
            if texture:SetTexture(skin.path..'button-'..entry[2]..'.tga')==false then
                if U.Safe(previousAtlas) and previousAtlas then texture:SetAtlas(previousAtlas)
                elseif U.Safe(previousPath) and previousPath then texture:SetTexture(previousPath) end
                return false
            end
            texture:SetTexCoord(0,1,0,1)
            texture:SetVertexColor(config.tint[1],config.tint[2],config.tint[3],config.opacity)
            if layout then
                local pad=U.Pixel(U.Clamp(config.thickness,3,10)-4+config.inset,button)
                texture:ClearAllPoints()
                texture:SetPoint('TOPLEFT',button,'TOPLEFT',-pad,pad)
                texture:SetPoint('BOTTOMRIGHT',button,'BOTTOMRIGHT',pad,-pad)
            end
        end
    end
    return true
end

function R.CaptureButton(record,state)
    record.buttonNative=record.buttonNative or {}
    local texture=record.frame['Get'..state..'Texture'](record.frame)
    if not texture then record.buttonNative[state]={absent=true};return end
    local path,atlas=texture:GetTexture(),texture.GetAtlas and texture:GetAtlas()
    if not U.Safe(path) or not U.Safe(atlas) then return end
    -- A native setter can call a texture setter internally; its second hook must
    -- not capture the artwork our first hook just reapplied.
    if type(path)=='string' and path:find(J.MediaRoot,1,true)==1 then return end
    local coords,color={texture:GetTexCoord()},{texture:GetVertexColor()}
    for _,values in ipairs({coords,color}) do for _,v in ipairs(values) do if not U.Number(v) then return end end end
    local previous=record.buttonNative[state]
    local value={path=path,atlas=atlas,coords=coords,color=previous and previous.color or color,points={}}
    if texture.GetNumPoints then
        for i=1,texture:GetNumPoints() do
            local point={texture:GetPoint(i)}
            if not U.Number(point[4]) or not U.Number(point[5]) then return end
            value.points[#value.points+1]=point
        end
    end
    record.buttonNative[state]=value
end
function R.CaptureButtonColor(record,state,r,g,b,a)
    local value=record.buttonNative and record.buttonNative[state]
    if value and U.Number(r) and U.Number(g) and U.Number(b) and U.Safe(a) and (a==nil or U.Number(a)) then
        value.color={r,g,b,a or 1}
    end
end
function R.RestoreButton(record,layout)
    if not record.buttonCustom then return end
    for state,value in pairs(record.buttonNative or {}) do
        if value.absent then record.frame['Set'..state..'Texture'](record.frame,nil)
        else
            local texture=record.frame['Get'..state..'Texture'](record.frame)
            if texture then
                if value.atlas then texture:SetAtlas(value.atlas) else texture:SetTexture(value.path) end
                texture:SetTexCoord(unpack(value.coords));texture:SetVertexColor(unpack(value.color))
                if layout and #value.points>0 then
                    texture:ClearAllPoints()
                    for _,point in ipairs(value.points) do texture:SetPoint(unpack(point)) end
                end
            end
        end
    end
    record.buttonCustom=false
end
