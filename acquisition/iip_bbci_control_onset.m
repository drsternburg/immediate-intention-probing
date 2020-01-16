
function packet = iip_bbci_control_onset(cfy_out,event,opt)

if cfy_out >= 0
    packet = {'i:accel',1};
else
    packet = {'i:accel',0};
end