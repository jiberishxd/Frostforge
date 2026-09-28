-- Development-only snapshots of the real options objects in the offline host.
-- Native Blizzard textures/fonts are approximated by the browser renderer.
local M=dofile("tests/mock_wow.lua")
local J=M.load({stockStone=true});local S=J.SettingsUI;S:Open()
-- Illustrative names only; generated in the offline fixture, never player data.
local P=J.ProfileManager;local initial=P.activeID
P:RenameProfile("Paladin raids");P:SaveAs("Night Elf hunter",true);P:UseProfile(initial)
local function json(v)
    if type(v)=="string" then return '"'..v:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n'):gsub('\r','\\r')..'"' end
    if type(v)~="table" then return tostring(v) end
    local result={}
    for k,x in pairs(v) do result[#result+1]=json(tostring(k))..":"..json(x) end
    table.sort(result);return "{"..table.concat(result,",").."}"
end
J.Setup:Create()
for _,kind in ipairs({"portrait","unit","cast","hub","minimap"}) do S:CreateCollection(kind) end
local ids={};for i,o in ipairs(M.objects) do ids[o]=i end
local snapshotRoot=S.frame
local function inside(o) return o and (o==snapshotRoot or inside(o.parent)) end
local function hoverOwner(o)
    if not o or not o.parent then return end
    if o==o.parent.hover then return o.parent end
    return hoverOwner(o.parent)
end
local function snapshot()
    local result={}
    for _,o in ipairs(M.objects) do
        local hover=hoverOwner(o)
        if inside(o) and (o:IsVisible() or (hover and hover:IsVisible())) then
            local item={id=ids[o],parent=ids[o.parent],kind=o.kind,w=o.w,h=o.h,level=o.level,layer=o.layer,alpha=o.alpha,
                text=o.text,font=o.fontObject,justify=o.justify,path=o.path,uv=o.texCoord,backdrop=o.backdrop,color=o.color,backdropColor=o.backdropColor,borderColor=o.backdropBorderColor,blend=o.blend,desaturated=o.desaturated,
                value=o.value,minimum=o.minimum,maximum=o.maximum,all=ids[o.allPoints],hoverFor=ids[hover],points={}}
            for i,p in ipairs(o.points) do item.points[i]={p[1],ids[p[2]],p[3],p[4] or 0,p[5] or 0} end
            result[ids[o]]=item
        end
    end
    return result
end
local out={root=ids[S.frame],pages={},roots={}}
for _,key in ipairs({"playerFrame","targetFrame","minimap","actionHub"}) do
    S:Select(key)
    for _,page in ipairs({"artwork","placement","fitting","cast","blizzard","advanced","guide","profiles","website"}) do
        S:SetPage(page);out.pages[key.."-"..page]=snapshot()
    end
    if key=="playerFrame" or key=="targetFrame" then
        S:SetPage("placement");S.separatePortraitSize=true;S:Refresh();out.pages[key.."-placement-advanced"]=snapshot()
        S.separatePortraitSize=false;S:Refresh()
        S:SetPage("blizzard")
        for _,group in ipairs(J.BlizzardUnits.textGroups) do
            S.textGroup=group;S:Refresh();out.pages[key.."-blizzard-"..group]=snapshot()
        end
        S.textGroup="Name"
        S.stockStyleButton.scripts.OnClick();out.pages[key.."-blizzard-style"]=snapshot()
        S.powerStyleButton.scripts.OnClick();out.pages[key.."-blizzard-power"]=snapshot()
        S.powerScopeButtons.party.scripts.OnClick();out.pages[key.."-blizzard-party-power"]=snapshot();S:HideMenus()
        if key=="targetFrame" then
            S.stockAurasButton.scripts.OnClick();out.pages[key.."-blizzard-auras"]=snapshot()
            S.stockCastPositionButton.scripts.OnClick();out.pages[key.."-blizzard-cast-position"]=snapshot();S:HideMenus()
        end
    end
end
S:Select("playerFrame");S:SetPage("artwork");S:ShowPortraitGroup("CLASS",1);S.picker:Show()
out.pages.collection=snapshot();S:HideMenus();S:ShowCollection("unit","CLASS",1);S.unitPicker:Show();out.pages["unit-collection"]=snapshot();S:ShowBackup("export");out.pages.backup=snapshot()
S:HideMenus();S.frame:Hide();J.Setup:Open();snapshotRoot=J.Setup.frame
for step=1,4 do
    J.Setup.step=step;J.Setup:Refresh();local name="setup-"..step
    out.pages[name]=snapshot();out.roots[name]=ids[J.Setup.frame]
end
for _,provider in ipairs({"BLIZZARD","ELVUI","ELLESMERE"}) do
    J.Setup.step=2;J.Setup.provider=provider;J.Setup:Refresh()
    local name="setup-2-"..provider:lower();out.pages[name]=snapshot();out.roots[name]=ids[J.Setup.frame]
end
local f=assert(io.open("artwork/settings/runtime-settings.js","w"));f:write("// Generated from Core/Settings.lua by tools/export_settings_preview.lua\nwindow.settingsSnapshots=",json(out),";\n");f:close()
