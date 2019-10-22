
function wt = iip_drawNoRPProbeTimes(n,t,r)
% n : number of WTs to draw
% t : either 1x2 vector with [WT_min WT_max],
%     or a vector with collected waiting times from which the 10 and 90
%     percentiles are used to determine [WT_min WT_max]
% wt: 1xn vector with WTs

if length(t)==2
    wt_mnmx = t;
else
    wt_mnmx = prctile(t,[50-r/2 50+r/2]);
end
wt = rand(1,n)*(diff(wt_mnmx))+wt_mnmx(1);