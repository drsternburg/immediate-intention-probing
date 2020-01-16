
global BTB opt

opt = struct;
opt.session_name = 'IntentionProbing';

%%
if ispc
    BTB.PrivateDir = 'C:\bbci';
end
addpath(fullfile(BTB.PrivateDir,'toolbox_msk'))
addpath(fullfile(BTB.PrivateDir,'immediate-intention-probing','acquisition'))

%%
BTB.Acq.Geometry = [1281 1 1280 998];
BTB.Acq.Dir = fullfile(BTB.PrivateDir,'immediate-intention-probing','acquisition');
BTB.Acq.IoAddr = hex2dec('3EFC');
BTB.PyffDir = 'C:\bbci\pyff\src';
BTB.Acq.Prefix = 'i';
BTB.Acq.StartLetter = 'a';
BTB.FigPos = [1 1];

%% parameters for raw data
opt.acq.orig_fs = 1000;
Wps = [42 49]/opt.acq.orig_fs*2;
[n,Ws] = cheb2ord(Wps(1),Wps(2),3,40);
[opt.acq.filt.b,opt.acq.filt.a] = cheby2(n,50,Ws);
opt.acq.fs = 100;
opt.acq.clab = {'Fp1','Fp2',...
                'AF7','AF3','AFz','AF4','AF8',...
                'F7','F5','F3','F1','Fz','F2','F4','F6','F8',...
                'FT9','FT7','FC5','FC3','FC1','FC2','FC4','FC6','FT8','FT10'...
                'T7','C5','C3','C1','Cz','C2','C4','C6','T8',...
                'TP9','TP7','CP5','CP3','CP1','CPz','CP2','CP4','CP6','TP8','TP10'...
                'P7','P5','P3','P1','Pz','P2','P4','P6','P8',...
                'PO7','PO3','POz','PO4','PO8',...
                'O1','Oz','O2',...
                'X','Y','Z'
                };

%% markers
opt.mrk.def = { -2 'pedal press';...
               -30 'trial end'; ...
               -10 'trial start';...
               -11 'trial start move';...
               -12 'trial start idle';...
               -20 'beep silent';...
               -21 'beep move';...
               -22 'beep idle'
               }';

%% parameters for classification
opt.cfy_rp.clab_base = {'F1','Fz','F2',...
                        'FC3','FC1','FC2','FC4'...
                        'C3','C1','Cz','C2','C4'...
                        'CP3','CP1','CPz','CP2','CP4'...
                        'P1','Pz','P2'};
opt.cfy_rp.clab = opt.cfy_rp.clab_base;

Nc = length(opt.acq.clab);
rc = util_scalpChannels(opt.acq.clab);
rrc = util_chanind(opt.acq.clab,opt.cfy_rp.clab);
opt.acq.A = eye(Nc,Nc);
opt.acq.A(rc,rrc) = opt.acq.A(rc,rrc) - 1/length(rc);
opt.acq.A = opt.acq.A(:,rrc);

opt.cfy_rp.baseln_len = 100;
opt.cfy_rp.baseln_pos = 'beginning';
opt.cfy_rp.ival_fv = [-1200 -1100;
                      -1100 -1000;
                      -1000 -900;
                       -900 -800;
                       -800 -700;
                       -700 -600;
                       -600 -500;
                       -500 -400;
                       -400 -300;
                       -300 -200;
                       -200 -100;
                       -100   0];
opt.cfy_rp.fv_window = [opt.cfy_rp.ival_fv(1) 0];

opt.cfy_rp.ival_amp = [-200 0];

opt.cfy_acc.clab = {'X','Y','Z'};
opt.cfy_acc.ival_fv = [-200 0];
opt.cfy_acc.offset = 500;

% fake classifiers of phase 1:
opt.cfy_rp.C.gamma = randn;
opt.cfy_rp.C.b = randn;
opt.cfy_rp.C.w = randn(size(opt.cfy_rp.ival_fv,1)*length(opt.cfy_rp.clab),1);

opt.cfy_acc.C.gamma = randn;
opt.cfy_acc.C.b = randn;
opt.cfy_acc.C.w = randn(3,1);

%% parameters for finding optimal prediction threshold
opt.pred.tp_ival = [-500 0];
opt.pred.thresh_pos = 10; % for the fake classifier of phase 1
opt.pred.thresh_neg = -10; % for the fake classifier of phase 1

%% feedback parameters
opt.feedback.name  = 'IntentionBeep';
opt.feedback.block_name = {'Phase1_practice','Phase1','Phase2_practice','Phase2','Phase3_practive','Phase3'};
% record_audio = [            0                 0        1                 1        1                 1];
% make_interruptions = [      0                 0        1                 1        1                 1];
% delayed_prompts = [         0                 0        delayed(1)        delayed(1) delayed(2)      delayed(2)];
% end_pause_counter_type = [  1                 1        4                 4        4                 4]; % 1 - pedal press, 4 - seconds
% end_after_x_events = [      5                 100      1*60              60*60    1*60              60*60];
% pause_every_x_events = [    10                20       1*60              10*60    1*60              10*60];
% bci_delayed_idle =     [    0                 0        0                 1        0                 1];
% trial_assignment = {        1                 1        iip_drawTrialAssignments(100,[0 .5]) ...
%                                                                          iip_drawTrialAssignments(1500,[.5 .5])...
%                                                                                   iip_drawTrialAssignments(100,[0 .5]) ...
%                                                                                                     iip_drawTrialAssignments(1500,[.5 .5])};
record_audio = [            0                 0        1                 1        1                 1];
make_interruptions = [      0                 0        1                 1        1                 1];
delayed_prompts = [         0                 0        delayed(1)        delayed(1) delayed(2)      delayed(2)];
end_pause_counter_type = [  1                 1        4                 1        4                 4]; % 1 - pedal press, 4 - seconds
end_after_x_events = [      5                 4      1*60               10    1*60              60*60];
pause_every_x_events = [    10                2       1*60               5    1*60              10*60];
bci_delayed_idle =     [    0                 0        0                 1        0                 1];
trial_assignment = {        1                 1        iip_drawTrialAssignments(100,[0 .5]) ...
                                                                         iip_drawTrialAssignments(1500,[.5 .5])...
                                                                                  iip_drawTrialAssignments(100,[0 .5]) ...
                                                                                                    iip_drawTrialAssignments(1500,[.5 .5])};
listen_to_keyboard = [0 0 0 0 0 0 0];
for ii = 1:length(opt.feedback.block_name)
    opt.feedback.rec_params(ii).record_audio = record_audio(ii);
    opt.feedback.pyff_params(ii).listen_to_keyboard = int16(listen_to_keyboard(ii));
    opt.feedback.pyff_params(ii).make_interruptions = int16(make_interruptions(ii));
    opt.feedback.pyff_params(ii).delayed_prompts = int16(delayed_prompts(ii));
    opt.feedback.pyff_params(ii).end_pause_counter_type = int16(end_pause_counter_type(ii));
    opt.feedback.pyff_params(ii).end_after_x_events = int16(end_after_x_events(ii));
    opt.feedback.pyff_params(ii).pause_every_x_events = int16(pause_every_x_events(ii));
    opt.feedback.pyff_params(ii).bci_delayed_idle = int16(bci_delayed_idle(ii));
    if not(isempty(trial_assignment{ii}))
        opt.feedback.pyff_params(ii).trial_assignment = int16(trial_assignment{ii});
    end    
end
clear trial_assignment fv_ivals Wps Ws n record_audio save_opt listen_to_keyboard make_interruptions end_after_x_events end_pause_counter_type pause_every_x_events bci_delayed_idle ii delayed_prompts delayed









