function formatFigureMovie(figureHandle, info, fontSize)

%FORMATFIGURE Formats figure for printing and saving
% 
%   formatFigure(figureHandle) resizes figures for display on HD monitors,
%   and reformats all text for uniformity.  credit to Daniel P. Dougherty
%   (dpdoughe@stat.ncsu.edu)
%   See http://www.mathworks.com/matlabcentral/newsreader/view_thread/14623


if nargin < 3
    
    fontSize = 24;
    
end

defaultX = 1000;
defaultY = 1000;

defaultXPaper = 45;
defaultYPaper = 45;

% resize
set(figureHandle, 'Position', [0 0 defaultX defaultY]);
set(figureHandle, 'PaperUnits', 'centimeters');
set(figureHandle, 'PaperPosition', [0 0 defaultXPaper  defaultYPaper]);


%background color
 set(figureHandle, 'color', 'white');

% Set figure properties: 
h = findobj(figureHandle,'Type','axes'); %Get handles to all axes and
%set their properties.
set(h,'FontName','Arial'); %Desired font.
set(h,'LineWidth',1); %Desired line width for line-plots etc.
set(h,'FontSize', fontSize); %Fontsize of axis labels, xlabel, ylabel etc.

%Loop through in case there are sub-plots.
for i = 1:length(h)
set(get(h(i),'YLabel'),'FontSize',fontSize);
set(get(h(i),'XLabel'),'FontSize',fontSize);
set(get(h(i),'Title'),'FontSize', fontSize);
set(get(h(i),'Title'),'FontWeight','bold');
ht = findobj(h(i),'Type','text');
set(ht,'FontSize',fontSize);
end


% Set legend properties: 
k = findobj(figureHandle,'Type','legend'); %Get handles to all axes and
%set their properties.
set(k,'FontName','Arial'); %Desired font.
set(k,'FontSize', 12); %Fontsize of axis labels, xlabel, ylabel etc.


end
