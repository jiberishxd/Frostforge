local _,J=...
local A=J.AdapterCommon
J.Adapters.retail={id='retail',interface=120100,source='78282522143e25c3540583734fd192c3d69be910',
    units=J.Util.Copy(A.Units),bars=J.Util.Copy(A.Bars),buttonPrefixes=J.Util.Copy(A.ButtonPrefixes)}
