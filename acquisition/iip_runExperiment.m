
global opt

%% setup participant
acq_makeDataFolder;

%% Test the triggers
bbci_trigger_parport(10,BTB.Acq.IoLib,BTB.Acq.IoAddr);

%% Practicing Phase 1
iip_startRecording('Phase1_practice')

%% Phase 1
iip_startRecording('Phase1')

%% Preprocess & setup online predictor
iip_convertBVData(BTB.Tp.Code,'Phase1',0);
iip_initialCleanup(BTB.Tp.Code,'Phase1');
iip_registerOnsets(BTB.Tp.Code,'Phase1');
iip_setupOnlinePredictor(BTB.Tp.Code,'Phase1');
save([fullfile(BTB.Tp.Dir,opt.session_name) '_' BTB.Tp.Code '_opt'],'opt')

%% Practicing Phase 2
iip_startRecording('Phase2_practice')

%% Phase 2
iip_startRecording('Phase2')

%% Practicing Phase 3
iip_startRecording('Phase3_practice')

%% Phase 3
iip_startRecording('Phase3')