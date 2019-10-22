
function trial_mrk = iip_getTrialMarkers(mrk)
% Returns the cell trial_mrk that in each entry contains the marker indices
% of single trials, relative to the complete set of markers.

mrk = mrk_sortChronologically(mrk);
ci_ts = find(strcmp(mrk.className,'trial start'));
ci_te = find(strcmp(mrk.className,'trial end'));

% extract markers
idx = 1;
trial_mrk = [];
n_trial = 0;
while idx<length(mrk.time)
    if find(mrk.y(:,idx))==ci_ts
        event_idx = [];
        class_idx = [];
        while 1
            event_idx = [event_idx idx];
            class_idx = [class_idx find(mrk.y(:,idx))];
            if find(mrk.y(:,idx))==ci_te
                break
            end
            idx = idx+1;
        end
        n_trial = n_trial+1;
        trial_mrk{n_trial} = event_idx;
    end
    idx = idx+1;
end
