
function cout = proc_applySlidingClassifier(epo,C)

global opt

dt = 1000/epo.fs;

fv_wind = [opt.ivals_fv(1) opt.ivals_fv(end)];
fv_len = length(opt.ivals_fv(1):dt:opt.ivals_fv(end));
n_points = size(epo.x,1) - fv_len + 1;

cout.t = zeros(1,n_points);
cout.x = zeros(1,n_points);
T = epo.t(1) - fv_wind(1);
for ii = 1:n_points
    
    fv = proc_selectIval(epo,fv_wind+T);
    fv = proc_baseline(fv,opt.baseln_len,opt.baseln_pos);
    fv = proc_jumpingMeans(fv,opt.ivals_fv+T);
    
    cout.t(ii) = fv_wind(2)+T;
    cout.x(ii) = apply_separatingHyperplane(C,fv.x(:));
    
    T = T+dt;
end
