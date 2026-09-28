-- Run against the relocated package, not the source-directory namespace.
local directory,interface=arg[1],tonumber(arg[2])
local M=dofile("tests/mock_wow.lua")
local old=M.load({interface=interface})
old.ProfileManager:Set("targetFrame","unitFrameShown",true)
old.ProfileManager:Set("targetFrame","unitFrameWidth",117)
local backup,activeID=old.ProfileManager:Export(),old.ProfileManager.activeID
local saved,character=JiberishUIDB,JiberishUICharacterDB

-- Represents the existing saved files copied to Frostforge.lua by the user.
M=dofile("tests/mock_wow.lua")
local J=M.load({interface=interface,addonDirectory=directory,addonName="Frostforge",
    db=saved,characterDB=character,noStart=true})
local registered
local E={Options={args={}},Libs={EP={RegisterPlugin=function(_,name,callback)
    registered=name;callback()
end}}}
ElvUI={E}
M.loggedIn=true
M.event(J.Core,"ADDON_LOADED","JiberishUI")
assert(not J.Core.started,"New install still listens for the old addon name")
M.event(J.Core,"ADDON_LOADED","Frostforge")
assert(J.Core.started and J.Core.client)
assert(J.Build.flavor==(interface==16001 and "forever" or "retail"))
assert(JiberishUIDB==saved and JiberishUICharacterDB==character)
assert(J.ProfileManager.activeID==activeID and J.ProfileManager:Export()==backup)
assert(registered=="Frostforge" and E.Options.args.frostforge)
assert(J.Media.logo=="Interface\\AddOns\\Frostforge\\Media\\Branding\\frostforge-logo.png")
for _,object in ipairs(M.objects) do
    if type(object.path)=="string" and object.path:find("Interface\\AddOns\\",1,true) then
        assert(object.path:find("Interface\\AddOns\\Frostforge\\",1,true)==1,object.path)
    end
end

-- The previous combat fix must work from the renamed install too.
M.unitData.target.player=false;M.tick(J.Core);M.combat=true
M.unitData.target.player=true;M.unitData.target.class="DRUID"
M.event(J.Core,"PLAYER_TARGET_CHANGED")
assert(J.UnitSkins.units.targetFrame.health.id=="CLASS_DRUID")
assert(J.UnitSkins.units.targetFrame.health.trim.frame.shown)
M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED")
E.Options.args.frostforge.args.open.func()
assert(J.SettingsUI.frame.shown and not next(J.Core.notices),next(J.Core.notices))
print("PASS Frostforge package startup, saved profiles, media, ElvUI registration and combat artwork on "..interface)
