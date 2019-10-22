
function [Rsel,thresh] = iip_selectThreshold(cout)

%cout = COUT{19};

figure, hold on
clrs = lines;

[R2,~,thresh2] = iip_findCoutThresh(cout,1/2);
[R3,~,thresh3] = iip_findCoutThresh(cout,1/3);
R = [R2([2 1]) sum(R2(1:2)) R3([2 1]) sum(R3(1:2))];

xpos = [1 2 3 4.5 5.5 6.5];
ci = [5 2 1 5 2 1];
for kk = 1:6
    H = bar(xpos(kk),R(kk));
    H.FaceColor = clrs(ci(kk),:);
end
text(2,.8,'\beta=1/2','HorizontalAlignment','center')
text(5.5,.8,'\beta=1/3','HorizontalAlignment','center')
set(gca,'ylim',[0 1],'xlim',[0 7.5],'ygrid','on','xtick',xpos,'xticklabel',{'HIT','FA','PRB','HIT','FA','PRB'})

if all(R([1 4])<=.1)
    fprintf('All HIT rates <.1 ==> STOP\n')
    thresh = NaN;
    Rsel = [];
    return
end
if all([R(2)/R(1) R(5)/R(4)]>=2.99)
    fprintf('All FA rates 3-fold higher than HIT rates ==> STOP\n')
    thresh = NaN;
    Rsel = [];
    return
end
if R(6)<.25
    fprintf('Beta=3 PRB rate <.25 ==> Beta=2\n')
    thresh = thresh2;
    Rsel = R([1 2]);
    return
end
if diff(R([2 5]))/diff(R([1 4]))>=2.99
    if R(4)<=.1
        thresh = thresh2;
        Rsel = R([1 2]);
        fprintf('==> Beta=2\n')
        return
    end
    thresh = thresh3;
    Rsel = R([4 5]);
    fprintf('Change in FA more than 3-fold compared to change in HIT ==> Beta=3\n')
    return
end
thresh = thresh2;
Rsel = R([1 2]);
fprintf('==> Beta=2\n')