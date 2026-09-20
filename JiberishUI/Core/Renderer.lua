local _, J = ...
local U = J.Util
local R={}; J.Renderer=R
local names={'tl','tr','bl','br','top','bottom','left','right'}
function R.Create(owner, region, variant)
    local layer=owner:CreateTexture(nil,'BORDER',nil,0)
    layer:Hide()
    local record={owner=owner,region=region,variant=variant,pieces={tl=layer}}
    for i=2,#names do record.pieces[names[i]]=owner:CreateTexture(nil,'BORDER',nil,0) end
    if J.Variants[variant].ornament then record.ornament=owner:CreateTexture(nil,'BACKGROUND',nil,0) end
    return record
end
function R.Apply(record,config)
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
