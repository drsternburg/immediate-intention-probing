
function iip_initialCleanup(subj_code,phase_name)

global BTB opt

ds_list = dir(BTB.MatDir);
ds_idx = strncmp(subj_code,{ds_list.name},5);
ds_name = ds_list(ds_idx).name;
filename = sprintf('%s%s/%s_%s_%s_mrk',BTB.MatDir,ds_name,opt.session_name,phase_name,subj_code);

if exist(filename,'file')
    error('Original markers were already modified.')
else
    fprintf('Performing basic cleanup for dataset %s|%s.\n',subj_code,phase_name)
end

mrk = rfb_loadData(subj_code,phase_name);

% remove trailing BPs (double or multiple successive BPs, happens sometimes)
ci_bp = find(strcmp(mrk.className,'pedal press'));
remove = [];
for ii = 1:length(mrk.time)-1
    if find(mrk.y(:,ii))==ci_bp && find(mrk.y(:,ii+1))==ci_bp
        remove = [remove ii+1];
    end
end
mrk = mrk_selectEvents(mrk,'not',remove,'RemoveVoidClasses',0);
fprintf('%d trailing pedal presses removed.\n',numel(remove))

% save new marker struct
save(filename,'mrk')































