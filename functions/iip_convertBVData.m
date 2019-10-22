
function [cnt,mrk,mnt] = iip_convertBVData(subj_code,phase_name,do_car)

global opt BTB

if nargin==2
    do_car = true;
end

ds_list = dir(BTB.RawDir);
ds_idx = strncmp(subj_code,{ds_list.name},5);
ds_name = ds_list(ds_idx).name;
filename = fullfile(ds_name,sprintf('%s_%s_%s',opt.session_name,phase_name,subj_code));

% hdr = file_readBVheader(filename);
% if isfield(hdr,'impedances')
%     noninfclab = ['not' hdr.clab(isinf(hdr.impedances))];
% else
%     noninfclab = '*';
% end
noninfclab = '*';

% read raw data
[cnt,mrk] = file_readBV(filename,'fs',opt.acq.fs,'filt',opt.acq.filt,'clab',noninfclab);

% define markers
mrk = mrk_defineClasses(mrk,opt.mrk.def);
mrk = rmfield(mrk,'event');

% set montage
mnt = mnt_setElectrodePositions(cnt.clab);
mnt.scale_box = [];
mnt = mnt_scalpToGrid(mnt);

% perform CAR
if do_car
    rrclab = util_scalpChannels(cnt);
    cnt = proc_commonAverageReference(cnt,rrclab,rrclab);
    fprintf('Performing CAR...\n')
end

% save
if nargout==0
    file_saveMatlab(filename,cnt,mrk,mnt);
    fprintf('File %s successfully converted and saved.\n',filename)
end