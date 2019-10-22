
function h = fig_init(paper_width,paper_height)

global BTB

if isfield(BTB,'FigPos')
    fig_pos = BTB.FigPos;
else
    fig_pos = [55 4];
end

if nargin~=2
    paper_width = 20;
    paper_height = 10;
end

h = figure('color','white',...
           'paperunits','centimeters',...
           'papersize',[paper_width paper_height],...
           'paperposition',[0 0 paper_width paper_height]);
set(h,'units','centimeters','pos',[fig_pos(1),fig_pos(2),paper_width,paper_height])
