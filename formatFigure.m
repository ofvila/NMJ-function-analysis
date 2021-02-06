function formatFigure(figureHandle, info, fontSize)

%FORMATFIGURE Formats figure for printing and saving
% 
%   formatFigure(figureHandle) resizes figures for display on HD monitors,
%   and reformats all text for uniformity.  credit to Daniel P. Dougherty
%   (dpdoughe@stat.ncsu.edu)
%   See http://www.mathworks.com/matlabcentral/newsreader/view_thread/14623


if nargin < 3
    
    fontSize = 36;
    
end

defaultX = 1920;
defaultY = 1030;
defaultXPaper = 45;
defaultYPaper = 30;

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
set(h,'LineWidth',2); %Desired line width for line-plots etc.
set(h,'FontSize', fontSize); %Fontsize of axis labels, xlabel, ylabel etc.

%Loop through in case there are sub-plots.
k = findobj(figureHandle,'Type','Line'); %Get handles to all lines and

for i = 1:length(k)
k(i).LineWidth = 1.5;
end

end
