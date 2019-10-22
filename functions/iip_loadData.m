
function [mrk,cnt,mnt] = iip_loadData(subj_code,phase_name)

global BTB

ds_list = dir(BTB.MatDir);
ds_idx = strncmp(subj_code,{ds_list.name},5);
ds_name = ds_list(ds_idx).name;

session_name = 'IntentionProbing';

filename_eeg = sprintf('%s_%s_%s',session_name,phase_name,subj_code);
filename_eeg = fullfile(ds_name,filename_eeg);
filename_mrk = sprintf('%s%s_mrk.mat',BTB.MatDir,filename_eeg);

%fprintf('Loading data set %s, %s...\n',ds_name,phase_name)

if nargout>1 || not(exist(filename_mrk,'file'))
    [cnt,mrk,mnt] = file_loadMatlab(filename_eeg);
    mnt.scale_box = [];
    mnt = mnt_scalpToGrid(mnt);
end
if exist(filename_mrk,'file')
    load(filename_mrk)
end