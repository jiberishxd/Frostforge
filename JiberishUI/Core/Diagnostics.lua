local _,J=...
local U=J.Util
function J:Diagnostics()
    local lines={'JiberishUI '..self.version..' — development build; in-game validation pending.'}
    local c=self.client or {}; lines[#lines+1]=string.format('Client %s / build %s / interface %s',tostring(c.version),tostring(c.build),tostring(c.interface))
    lines[#lines+1]='Adapter: '..(self.adapter and self.adapter.id or 'unsupported')
    if self.adapter then lines[#lines+1]='Source revision: '..self.adapter.source end
    if self.Profiles.db then
        lines[#lines+1]='Profile: '..self.Profiles:Name()
        lines[#lines+1]='Settings at startup: '..self.Profiles:LoadStatus()
    end
    local counts={}
    for _,record in pairs(self.records) do if record.owned~=false then
        local value=counts[record.group] or {count=0,failed=0,applied=0,geometry={}}
        value.count=value.count+1; if record.failed then value.failed=value.failed+1 end
        if record.applied then value.applied=value.applied+1 end
        local w,h,scale=record.frame:GetWidth(),record.frame:GetHeight(),record.frame:GetEffectiveScale()
        if U.Number(w) and U.Number(h) and U.Number(scale) then value.geometry[string.format('%.1f × %.1f @ %.3f',w,h,scale)]=true end
        counts[record.group]=value
    end end
    for _,group in ipairs(self.Groups) do
        local value=counts[group]; local geometry={}
        if value then for key in pairs(value.geometry) do geometry[#geometry+1]=key end; table.sort(geometry) end
        local state=self.active[group] and (self.active[group].enabled and 'enabled' or 'disabled') or 'uninitialized'
        local provider=self.Integrations and self.Integrations.providers[group] or 'blizzard'
        lines[#lines+1]=string.format('%s (%s): %s, %d attached, %d applied, %d failed%s%s',self.GroupLabels[group],provider,state,value and value.count or 0,
            value and value.applied or 0,value and value.failed or 0,
            self.reloadGroups[group] and ', reload needed' or '',#geometry>0 and ' ['..table.concat(geometry,', ')..']' or '')
        if self.conflicts[group] then lines[#lines+1]='  Skipped: '..self.conflicts[group] end
    end
    local failures={}; for key,message in pairs(self.failures) do failures[#failures+1]=key..': '..message end; table.sort(failures)
    if self.ActionHub then lines[#lines+1]='Action-bar surround: '..self.ActionHub.status end
    if #failures>0 then lines[#lines+1]='Recorded notices (reload clears the history):' end
    for _,message in ipairs(failures) do lines[#lines+1]=message end
    if self.adapter and self.adapter.id=='forever' then lines[#lines+1]='Forever build 69913: settings loss after /reload has been reported even with valid saved files. Use /jui export before reloading and /jui import to restore.' end
    return table.concat(lines,'\n')
end
function J:LiveStatus(group)
    if self.failures.lifecycle then return 'Live updates failed. Open Diagnostics for the error location.' end
    if group~='global' and self.conflicts[group] then return 'Module skipped: '..self.conflicts[group] end
    if group~='global' and self.failures[group] then return self.failures[group] end
    local attached,applied,failed=0,0,0
    for _,record in pairs(self.records) do
        if record.owned~=false and (group=='global' or record.group==group) then
            attached=attached+1
            if record.applied then applied=applied+1 end
            if record.failed then failed=failed+1 end
        end
    end
    if failed>0 then return 'Some frames failed to update. Open Diagnostics for details.' end
    if attached==0 then return 'No supported frames available for this group yet. Preview shows your saved settings.' end
    return string.format('%d of %d frames styled. Shape and layout follow the owning UI.',applied,attached)
end
