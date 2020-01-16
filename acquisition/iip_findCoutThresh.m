
function [P,Fmax,thresh_move,thresh_idle] = iip_findCoutThresh(C,b)

%% define possible threshold range
x_all = cellfun(@(f)getfield(f,'x'),C,'UniformOutput',false);
x_all = [x_all{:}];
thresh = linspace(0,prctile(x_all,99.5),100);

%%
Nth = length(thresh);
Nt = length(C);
T = inf(Nt,Nth);
for jj = 1:Nt
    tind = C{jj}.t<=0;
    x = C{jj}.x(tind);
    t = C{jj}.t(tind);
    for kk = 1:Nth
        ind = find(diff(sign(x-thresh(kk)))==2,1);
        if not(isempty(ind))
            T(jj,kk) = t(ind);
        end
    end
end

%%
edges = [-Inf -500 0 Inf];
P = zeros(Nth,length(edges)-1);
for kk = 1:Nth
    P(kk,:) = histcounts(T(:,kk),edges,'normalization','probability');
end
F = fScore(P(:,1),P(:,2),P(:,3),b);
F = smooth(F,10);
[Fmax,ind] = max(F);

P = P(ind,:);
thresh_move = thresh(ind);

thresh_idle = median(x_all);
