
function a = iip_drawTrialAssignments(n,p)
% n: number of assignments
% p: 1x4 vector with probabilities
% a: 1xn vector with assignments

x = rand(1,n);
p = p/sum(p);
e = [0 cumsum(p)];
[~,a] = histc(x,e);