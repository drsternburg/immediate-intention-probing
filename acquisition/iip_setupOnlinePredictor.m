
function iip_setupOnlinePredictor(subj_code)

global opt

%% load and prepare data
[cnt,mrk,mnt] = proc_loadDataset(subj_code,'Phase1');
cnt = proc_commonAverageReference(cnt);
must_contain = 'movement onset';
trial_mrk = mrk_getTrialMarkers(mrk,must_contain);
mrk = mrk_selectEvents(mrk,[trial_mrk{:}]);

%% Exclude too short waiting times
mrk_mo = mrk_selectClasses(mrk,'movement onset');
mrk_ts = mrk_selectClasses(mrk,'trial start');
t_ts2mo = mrk_mo.time - mrk_ts.time;
ind_valid = t_ts2mo>=-opt.cfy_rp.fv_window(1);
trial_mrk = mrk_getTrialMarkers(mrk);
mrk = mrk_selectEvents(mrk,[trial_mrk{ind_valid}]);
t_ts2mo = t_ts2mo(ind_valid);

%% get amplitudes
mrk_ = mrk_selectClasses(mrk,{'trial start','movement onset'});
epo = proc_segmentation(cnt,mrk_,opt.cfy_rp.fv_window);
epo = proc_baseline(epo,opt.cfy_rp.baseln_len,opt.cfy_rp.baseln_pos);
rsq = proc_rSquareSigned(epo);
amp = proc_meanAcrossTime(epo,opt.cfy_rp.ival_amp);

%% visualize ERPs
figure
H = grid_plot(epo,mnt,'PlotStat','sem');%,'ShrinkAxes',[.9 .9]);
grid_addBars(rsq,'HScale',H.scale,'Height',1/7);

%% channel selection
amp = proc_selectChannels(amp,opt.cfy_rp.clab_base);
[~,pval1] = ttest(squeeze(amp.x(1,:,logical(amp.y(2,:))))',0,'tail','left'); % RP amplitudes must be smaller than zero
[~,pval2] = ttest2(squeeze(amp.x(1,:,logical(amp.y(2,:))))',...
    squeeze(amp.x(1,:,logical(amp.y(1,:))))',...
    'tail','left'); % RP amplitudes must be smaller than No-RP amplitudes
chanind_sel = pval1<.05&pval2<.05;
opt.cfy_rp.clab = epo.clab(chanind_sel);
fprintf('\nSelected channels:\n')
fprintf('%s\n',opt.cfy_rp.clab{:})

%% define online filter
Nc = length(opt.acq.clab);
rc = util_scalpChannels(opt.acq.clab);
rrc = util_chanind(opt.acq.clab,opt.cfy_rp.clab);
opt.acq.A = eye(Nc,Nc);
opt.acq.A(rc,rrc) = opt.acq.A(rc,rrc) - 1/length(rc);
opt.acq.A = opt.acq.A(:,rrc);

%% re-load data and apply online filter
cnt = proc_loadDataset(subj_code,'Phase1');
cnt = proc_linearDerivation(cnt,opt.acq.A);

%% train classifier and assess accuracy
fv = proc_segmentation(cnt,mrk,opt.cfy_rp.fv_window);
fv = proc_baseline(fv,opt.cfy_rp.baseln_len,opt.cfy_rp.baseln_pos);
fv = proc_jumpingMeans(fv,opt.cfy_rp.ival_fv);
fv = proc_flaten(fv);

opt.cfy_rp.C = train_RLDAshrink(fv.x,fv.y);

warning off
loss = crossvalidation(fv,@train_RLDAshrink,'SampleFcn',@sample_leaveOneOut);
warning on
fprintf('\nClassification accuracy: %2.1f%%\n',100*(1-loss))

%% sliding classifier output
mrk_ = mrk_selectClasses(mrk,{'trial start','movement onset','trial end'});
opt2 = struct('ivals_fv',opt.cfy_rp.ival_fv,'baseln_len',opt.cfy_rp.baseln_len,'baseln_pos',opt.cfy_rp.baseln_pos);
cout = proc_slidingClassification(cnt,mrk_,opt2);

%% define threshold
[R,thresh] = iip_selectThreshold(cout);

%% either terminate experiment, or draw No-RP probe times
if isempty(R)
    return
else
    opt.pred.cout_thresh = thresh;
    for jj = 3:6
        opt.feedback.pyff_params(jj).ir_idle_waittime = iip_drawNoRPProbeTimes(1000,t_ts2mo,sum(R)*100);
    end
end






















