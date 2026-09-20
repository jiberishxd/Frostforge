local _,J=...
local U=J.Util
function J:Diagnostics()
    local lines={'JiberishUI '..self.version..' — development build; in-game validation pending.'}
    local c=self.client or {}; lines[#lines+1]=string.format('Client %s / build %s / interface %s',tostring(c.version),tostring(c.build),tostring(c.interface))
    lines[#lines+1]='Adapter: '..(self.adapter and self.adapter.id or 'unsupported')
    if self.adapter then lines[#lines+1]='Source revision: '..self.adapter.source end
    if self.Profiles.db then lines[#lines+1]='Profile: '..self.Profiles:Name() end
    local counts={}
    for _,record in pairs(self.records) do
        local value=counts[record.group] or {count=0,failed=0,geometry={}}
        value.count=value.count+1; if record.failed then value.failed=value.failed+1 end
        local w,h,scale=record.frame:GetWidth(),record.frame:GetHeight(),record.frame:GetEffectiveScale()
        if U.Number(w) and U.Number(h) and U.Number(scale) then value.geometry[string.format('%.1f × %.1f @ %.3f',w,h,scale)]=true end
        counts[record.group]=value
    end
    for _,group in ipairs(self.Groups) do
        local value=counts[group]; local geometry={}
        if value then for key in pairs(value.geometry) do geometry[#geometry+1]=key end; table.sort(geometry) end
        local state=self.active[group] and (self.active[group].enabled and 'enabled' or 'disabled') or 'uninitialized'
        lines[#lines+1]=string.format('%s: %s, %d attached%s%s',self.GroupLabels[group],state,value and value.count or 0,
            self.reloadGroups[group] and ', reload needed' or '',#geometry>0 and ' ['..table.concat(geometry,', ')..']' or '')
    end
    local failures={}; for key,message in pairs(self.failures) do failures[#failures+1]=key..': '..message end; table.sort(failures)
    if #failures>0 then lines[#lines+1]='Recorded notices (reload clears the history):' end
    for _,message in ipairs(failures) do lines[#lines+1]=message end
    if self.adapter and self.adapter.id=='forever' then lines[#lines+1]='Forever beta: restart persistence issue reported for build 69913; not reproduced here. Keep a profile export.' end
    return table.concat(lines,'\n')
end
