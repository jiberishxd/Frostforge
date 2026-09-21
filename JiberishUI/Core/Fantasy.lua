local _,J=...
local U=J.Util
local F={styles={},order={},classes={}};J.Fantasy=F
for _,skinID in ipairs(J.SkinOrder) do
    local skin=J.Skins[skinID]
    if skin.category=='class' then
        F.styles[skinID]={label=skin.label,skin=skinID,path=J.MediaRoot..'fantasy\\'..skinID..'.tga'}
        F.order[#F.order+1]=skinID;F.classes[skin.identity]=skinID
    end
end
for _,entry in ipairs({{'halloween','Halloween — Harvest Haunt','undead'}, {'christmas','Christmas — Winter Veil','forestwood'}}) do
    F.styles[entry[1]]={label=entry[2],skin=entry[3],path=J.MediaRoot..'fantasy\\'..entry[1]..'.tga'}
    F.order[#F.order+1]=entry[1]
end
function F.Resolve(id,owner,unitField)
    if id=='class' then id=F.classes[J.Colors.Class(owner,unitField)] end
    return id and F.styles[id] or nil
end
function F.PortraitConfig(config)
    local result=U.Copy(config)
    result.skin=config.portraitSkin~='inherit' and config.portraitSkin or config.skin
    result.tint=config.portraitTint or config.tint
    result.opacity=config.opacity*(config.portraitOpacity or 1)
    result.ornament=0
    return result
end
function F.CreatePortrait(owner,region,unitField)
    local texture=owner:CreateTexture(nil,'BORDER',nil,1);texture:Hide()
    return {owner=owner,region=region,unitField=unitField,texture=texture,active=true}
end
function F.Portrait(record,config,layout)
    local style=F.Resolve(config.portraitStyle,record.owner,record.unitField)
    local region,texture=record.region,record.texture
    local shown
    if region.IsVisible then shown=region:IsVisible() else shown=region:IsShown() end
    if record.active==false or not style or not U.Safe(shown) or not shown then texture:Hide();return true end
    if texture:SetTexture(style.path)==false then texture:Hide();return false end
    if layout then
        local scale,ps=record.owner:GetEffectiveScale(),region:GetEffectiveScale()
        local w=region:GetWidth()
        if not U.Number(scale) or scale<=0 or not U.Number(ps) or ps<=0 or not U.Number(w) or w<=0 then texture:Hide();return false end
        local width=math.min(110,w*ps/scale*1.4)*(config.portraitScale or 0.8)
        texture:ClearAllPoints();texture:SetPoint('BOTTOM',region,'TOP',config.portraitX or 0,1+(config.portraitY or 0))
        texture:SetSize(width,width/3);record.ready=true
    end
    texture:SetVertexColor(1,1,1,config.opacity*(config.portraitOpacity or 1))
    texture:SetShown(record.ready==true)
    return true
end
