
function packet = iip_bbci_control_cout(cfy_out,event,opt)

if cfy_out >= opt.pred.cout_thresh
    packet = {'i:cl_output',1};
elseif cfy_out < 0
    packet = {'i:cl_output',-1};
else
    packet = {'i:cl_output',0};
end