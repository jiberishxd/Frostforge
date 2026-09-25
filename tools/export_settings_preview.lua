-- Development-only snapshots of the real options objects in the offline host.
-- Native Blizzard textures/fonts are approximated by the browser renderer.
local M=dofile("tests/mock_wow.lua")
local J=M.load();local S=J.SettingsUI;S:Open()
local function json(v)
    if type(v)=="string" then return '"'..v:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n'):gsub('\r','\\r')..'"' end
    if type(v)~="table" then return tostring(v) end
    local result={}
    for k,x in pairs(v) do result[#result+1]=json(tostring(k))..":"..json(x) end
    table.sort(result);return "{"..table.concat(result,",").."}"
end
local ids={};for i,o in ipairs(M.objects) do ids[o]=i end
local function inside(o) return o and (o==S.frame or inside(o.parent)) end
local function snapshot()
    local result={}
    for _,o in ipairs(M.objects) do
        if inside(o) and o:IsVisible() then
            local item={id=ids[o],parent=ids[o.parent],kind=o.kind,w=o.w,h=o.h,level=o.level,layer=o.layer,alpha=o.alpha,
                text=o.text,font=o.fontObject,justify=o.justify,path=o.path,uv=o.texCoord,backdrop=o.backdrop,color=o.color,
                value=o.value,minimum=o.minimum,maximum=o.maximum,all=ids[o.allPoints],points={}}
            for i,p in ipairs(o.points) do item.points[i]={p[1],ids[p[2]],p[3],p[4] or 0,p[5] or 0} end
            result[ids[o]]=item
        end
    end
    return result
end
local out={root=ids[S.frame],pages={}}
for _,key in ipairs({"playerFrame","minimap","actionHub"}) do
    S:Select(key)
    for _,page in ipairs({"artwork","placement","fitting","cast","advanced","guide"}) do
        S:SetPage(page);out.pages[key.."-"..page]=snapshot()
    end
end
S:Select("playerFrame");S:SetPage("artwork");S:ShowPortraitGroup("CLASS",1);S.picker:Show()
out.pages.collection=snapshot();S:ShowBackup("export");out.pages.backup=snapshot()
local f=assert(io.open("artwork/settings/runtime-settings.js","w"));f:write("// Generated from Core/Settings.lua by tools/export_settings_preview.lua\nwindow.settingsSnapshots=",json(out),";\n");f:close()
