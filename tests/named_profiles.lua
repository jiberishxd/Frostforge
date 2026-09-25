local test=...

for _,interface in ipairs({120100,16001}) do
    test("character assignments isolate paladin and hunter across relogs on "..interface,function(M)
        local J=M.load({interface=interface})
        local P=J.ProfileManager
        P:Set("playerFrame","portraitMode","FIXED");P:Set("playerFrame","portrait","CLASS_PALADIN")
        P:Set("playerFrame","unitFrameShown",true);P:Set("actionHub","width",1600)
        P:Set("targetFrame","castBarStrata","HIGH");P:Set("playerFrame","blizzardNameX",24)
        P:SetWindowPosition(55,66)
        assert(P:RenameProfile("Paladin raids"))
        local paladinID=P.activeID
        local db,paladin=JiberishUIDB,JiberishUICharacterDB
        M.unitData.player.class="HUNTER";M.unitData.player.race="NightElf"
        J=M.load({interface=interface,db=db,characterDB={}});P=J.ProfileManager
        local hunter=JiberishUICharacterDB
        assert(P.activeID~=paladinID and P.current~=db.profileStore.profiles[paladinID].settings)
        assert(J.ThemeManager:Resolve("playerFrame").portraitMode=="CLASS")
        assert(J.Core.modules.playerFrame.portraitID=="CLASS_HUNTER")
        assert(J.ThemeManager:Resolve("actionHub").width~=1600)
        assert(P:RenameProfile("Night Elf hunter"));P:Set("playerFrame","portraitMode","RACE")
        P:Set("playerFrame","width",142)
        local hunterID=P.activeID
        J=M.load({interface=interface,db=db,characterDB=paladin});P=J.ProfileManager
        assert(P.activeID==paladinID and P:ProfileName()=="Paladin raids")
        assert(J.ThemeManager:Resolve("playerFrame").portrait=="CLASS_PALADIN")
        assert(J.ThemeManager:Resolve("playerFrame").unitFrameShown)
        assert(J.ThemeManager:Resolve("targetFrame").castBarStrata=="HIGH")
        assert(P.current.window.x==55 and J.ThemeManager:Resolve("playerFrame").blizzardNameX==24)
        J=M.load({interface=interface,db=db,characterDB=hunter});P=J.ProfileManager
        assert(P.activeID==hunterID and P:ProfileName()=="Night Elf hunter")
        assert(J.ThemeManager:Resolve("playerFrame").portraitMode=="RACE")
        assert(J.ThemeManager:Resolve("playerFrame").width==142)
    end)
end

test("first character preserves the old setup and earlier renderer namespaces",function(M)
    local old={version=2,theme="paladin_ret",debug=true,window={x=31,y=72},modules={actionHub={hubMode="RACE",width=1550}}}
    local earlier={Default={custom="keep"}}
    local db={phase1=old,profiles=earlier,characters={old="Default"}}
    local J=M.load({db=db});local P=J.ProfileManager
    assert(P:ProfileName()=="Imported setup" and P.current.debug and P.current.window.y==72)
    assert(P.current.modules.actionHub.width==1550 and db.profiles==earlier and db.characters.old=="Default")
    assert(JiberishUICharacterDB.profile==P.activeID and db.phase1==P.current)
    local char=JiberishUICharacterDB
    J=M.load({db=db,characterDB=char})
    assert(#J.ProfileManager:ProfileList()==1 and J.ProfileManager.current.modules.actionHub.width==1550)
end)

test("named copies are independent and explicitly reusing a profile shares edits",function(M)
    local J=M.load();local P=J.ProfileManager
    local first=P.activeID
    P:Set("minimap","x",45);P.current.debug=true
    assert(P:SaveAs("Solo layout"));local solo=P.activeID
    assert(solo~=first and P.current.modules.minimap.x==45 and P.current.debug)
    P:Set("minimap","x",80)
    assert(P.store.profiles[first].settings.modules.minimap.x==45)
    local db,char=JiberishUIDB,JiberishUICharacterDB
    J=M.load({db=db,characterDB={}});P=J.ProfileManager
    assert(P:UseProfile(solo));local alt=JiberishUICharacterDB
    P:Set("minimap","x",94)
    J=M.load({db=db,characterDB=char});assert(J.ProfileManager.current.modules.minimap.x==94)
    assert(char.profile==alt.profile and J.ProfileManager.activeID==solo)
end)

test("fresh profiles and imported backups do not overwrite inactive setups",function(M)
    local J=M.load();local P=J.ProfileManager
    P:Set("playerFrame","blizzardStone",false);P:Set("playerFrame","unitFrameWidth",120)
    local original=P.activeID;local backup=P:Export()
    assert(P:SaveAs("Clean hunter",true));local fresh=P.activeID
    assert(not next(P.current.modules) and P.current~=P.store.profiles[original].settings)
    assert(P:Import(backup));assert(P.store.profiles[fresh].settings==P.current and JiberishUIDB.phase1==P.current)
    P:Reset("playerFrame")
    assert(P.store.profiles[original].settings.modules.playerFrame.unitFrameWidth==120)
    assert(P.current.modules.playerFrame==nil)
    assert(P:UseProfile(original));assert(P.current.modules.playerFrame.blizzardStone==false)
end)

test("names and switching validate before changing profiles or bindings",function(M)
    local J=M.load();local P=J.ProfileManager
    assert(P:RenameProfile("Paladin"));assert(P:SaveAs("Hunter"))
    local current,id=P.current,P.activeID
    for _,name in ipairs({"", "  ","paladin","bad|name","bad\nname",string.rep("x",65)}) do
        assert(not P:SaveAs(name));assert(not P:RenameProfile(name))
        assert(P.current==current and P.activeID==id and JiberishUICharacterDB.profile==id)
    end
    assert(not P:UseProfile("missing"))
    assert(P:RenameProfile("  Chasseur été  "));assert(P:ProfileName()=="Chasseur été")
    assert(JiberishUICharacterDB.profile==id)
    M.combat=true
    assert(not P:UseProfile("profile1") and not P:SaveAs("In combat"))
    assert(P.current==current and #P:ProfileList()==2)
    M.combat=false;assert(P:UseProfile("profile1"))
end)

test("unknown profile stores and character schemas remain untouched",function(M)
    for _,case in ipairs({
        {store={version=9,profiles={}},char={version=1,profile="later"}},
        {store="unknown",char={version=1}},
        {store={version=1,profiles={}},char={version=9,profile="later"}},
        {store={version=1,profiles={}},char="unknown"},
        {store={version=1,profiles={future={name="Later",settings={version=99}}}},char={version=1,profile="future"}},
    }) do
        local old={version=2,modules={}}
        local db={phase1=old,profileStore=case.store}
        local J=M.load({db=db,characterDB=case.char});local P=J.ProfileManager
        assert(not P.writable and db.profileStore==case.store and db.phase1==old and JiberishUICharacterDB==case.char)
        assert(not P:SaveAs("Overwrite") and not P:UseProfile("profile1") and not P:RenameProfile("Overwrite"))
        J.SettingsUI:Open();J.SettingsUI:SetPage("profiles")
        assert(J.SettingsUI.status.text==P.notice)
    end
end)

test("missing assignments start fresh and saved profile values are sanitized",function(M)
    local store={version=1,profiles={custom={name="Custom",settings={version=2,modules={playerFrame={width=200,scale=math.huge,blizzardNameX=99999}}}}}}
    local db={phase1={version=2,modules={playerFrame={width=333}}},profileStore=store}
    local J=M.load({db=db,characterDB={version=1,profile="missing"}})
    assert(J.ThemeManager:Resolve("playerFrame").width==128)
    assert(J.ProfileManager:UseProfile("custom"))
    assert(J.ThemeManager:Resolve("playerFrame").width==200 and J.ThemeManager:Resolve("playerFrame").scale==1)
    assert(J.ThemeManager:Resolve("playerFrame").blizzardNameX==0)
end)

test("switching to a fresh profile restores prior native presentation",function(M)
    local J=M.load();local P=J.ProfileManager
    local bars=J.Core.client:UnitBars("playerFrame")
    local path,atlas=bars.health.fill.path,bars.health.fill.atlas
    local portrait=PlayerFrame.PlayerFrameContainer.PlayerPortrait
    local name=PlayerFrame.name;local originalX=name.points[1][4]
    P:Set("playerFrame","unitFrameShown",true)
    P:Set("playerFrame","blizzardPortraitHidden",true)
    P:Set("playerFrame","blizzardNameEnabled",true);P:Set("playerFrame","blizzardNameX",35)
    assert(portrait.alpha==0 and name.points[1][4]==originalX+35)
    assert(bars.health.fill.path~=path)
    local previousTrim=J.UnitSkins.units.playerFrame.health.trim
    assert(P:SaveAs("Fresh profile",true))
    assert(portrait.alpha==1 and name.points[1][4]==originalX)
    assert(bars.health.fill.atlas==atlas)
    assert(bars.health.fill.texCoord[1]==.1 and bars.health.fill.texCoord[8]==.4)
    assert(not previousTrim.frame:IsShown())
end)

test("Profiles section creates renames assigns and paginates saved setups",function(M)
    local J=M.load();local S=J.SettingsUI;local P=J.ProfileManager;S:Open()
    S.profilesButton.scripts.OnClick();assert(S.page=="profiles" and S.pages.profiles:IsShown())
    assert(not S.pageButtons.artwork:IsShown() and not S.resetButton:IsShown())
    S.profileNameEdit:SetText("Paladin raids");S.renameProfileButton.scripts.OnClick()
    assert(P:ProfileName()=="Paladin raids")
    S.profileNameEdit:SetText("Hunter leveling");S.saveProfileButton.scripts.OnClick()
    assert(P:ProfileName()=="Hunter leveling" and #P:ProfileList()==2)
    for i=1,6 do assert(P:SaveAs("Alt "..i,true)) end
    S:Refresh();assert(S.profilePageLabel.text=="1 / 2")
    S.profilesNext.scripts.OnClick();assert(S.profilePageLabel.text=="2 / 2")
    S.profileRows[1].scripts.OnClick();local selected=S.profileRows[1].profileID
    S.useProfileButton.scripts.OnClick();assert(P.activeID==selected and JiberishUICharacterDB.profile==selected)
    S:Select("minimap");assert(S.page=="artwork" and not S.pages.profiles:IsShown())
    assert(S.resetButton:IsShown() and S.pageButtons.artwork:IsShown())
end)
