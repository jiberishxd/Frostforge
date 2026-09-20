local _,J=...
local A=J.AdapterCommon
local adapter={id='forever',interface=16001,source='70ef1b2fd78061a73f886c4a1e79dc5b5cff6d5e',
    units=J.Util.Copy(A.Units),bars=J.Util.Copy(A.Bars),buttonPrefixes=J.Util.Copy(A.ButtonPrefixes)}
-- Camelot owns level/PvP medallions. Keep those semantic decorations, including
-- their frame layers and anchors, out of the replacement list.
adapter.preservedRegions={'LevelBackgroundCircle','PvpBackgroundCircle','PvpBackgroundIcon'}
adapter.bars[#adapter.bars+1]={'MultiCastActionBarFrame','totembar'}
adapter.buttonPrefixes[#adapter.buttonPrefixes+1]={'MultiCastActionButton','totembar',12}
J.Adapters.forever=adapter
