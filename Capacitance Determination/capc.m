close all; clear all; clc;
%% import data
id = 8;

temp = importdata(['data_', num2str(id),'.txt']);
sfreq = split(temp.textdata{2,1},',');
data{1,1} = temp.data;
data{1,2} = str2double(sfreq{2,1}(1:end-2));
data{1,3} = temp.textdata{1,1};
data{1,4} = length(data{1,1});
timebase = linspace(0,data{1,4}/data{1,2},data{1,4});
%calc dv/dt
[a1,b1] = findpeaks(data{1,1}(:,1),'MinPeakWidth',10);
[a2,b2] = findpeaks(-data{1,1}(:,1),'MinPeakWidth',10);
dvdt = (a2(length(a2))+a1(length(a1)))/((1/data{1,2})*(b2(length(b2))-b1(length(b1))));
%1 -> waveform gen
%2 -> keithley
%needs converting 2V to keithley range (20pA)
data{1,1}(:,2) = data{1,1}(:,2) * 10;
%3 -> search coil
%%
figure
yyaxis left
plot(timebase,data{1,1}(:,1),'LineWidth',1.5);
ylabel('Voltage [V]');
hold on
yyaxis right
plot(timebase,-data{1,1}(:,2),'color',[211/255 211/255 211/255]);
ylabel('Current [pA]');
xlabel('Time [s]');
align_yyaxis_zero(gca);
%noise removal
[y1,x1] = findpeaks(-data{1,1}(:,2));
[y2,x2] = findpeaks(data{1,1}(:,2));
length1 = length(y1);
length2 = length(y2);
if length1 > length2
    x1 = x1(1:length2);
    y1 = y1(1:length2);
elseif length1 < length2
    x2 = x2(1:length1);
    y2 = y2(1:length1);
end
x = 0.5 * (x1 + x2);
y = 0.5 * (y1 - y2);
yyaxis right
plot(x/data{1,2},y,'-','LineWidth',1.5);
%% steady state picker
[ssy,ssxl] = findpeaks(y,'MinPeakWidth',1, 'Threshold',0.0001, 'MinPeakProminence',0.005,'MinPeakDistance',100);
figure
plot(x/data{1,2},y)
hold on
    switch id
        case 1
            ssxl = ssxl([3,4,6,7,9,11,13,14,15]);
            ssy = ssy([3,4,6,7,9,11,13,14,15]);
        case 2
            ssxl = ssxl([4,6:9,11:15]);
            ssy = ssy([4,6:9,11:15]);
        case 3
            ssxl = ssxl([3:5,7:11,13:17]);
            ssy = ssy([3:5,7:11,13:17]);
        case 4
            ssxl = ssxl([4:8,10:15,17,18]);
            ssy = ssy([4:8,10:15,17,18]);
        case 5
            ssxl = ssxl([2:4,6:9]);
            ssy = ssy([2:4,6:9]);
        case 6
            ssxl = ssxl([4,6,7,9:13]);
            ssy = ssy([4,6,7,9:13]);
        case 7
            ssxl = ssxl([4,6:8,10:12,14:16,17:21]);
            ssy = ssy([4,6:8,10:12,14:16,17:21]);
        case 8
            ssxl = ssxl([3:8,10:16,18]);
            ssy = ssy([3:8,10:16,18]);
        otherwise
    end

plot(x(ssxl)/data{1,2},ssy, 'x')
%% current average and cap calc
capcurrent = [mean(ssy(ssy>0)), mean(ssy(ssy<0))];

capacitance = abs(capcurrent) ./ abs(dvdt);
 
display(capcurrent)
display(capacitance)

%%
currents = [((ssy<0)+1) ssy];
currents = abs(currents);
pos_curr = zeros(length(currents),1);
neg_curr = pos_curr;
for ii = 1:length(currents)
    if currents (ii) == 1
        pos_curr(ii) = currents(ii,2);
    elseif currents(ii) == 2
            neg_curr(ii) = currents(ii,2);
    end
end
pos_curr = nonzeros(pos_curr);
neg_curr = nonzeros(neg_curr);
namedorder = categorical(currents(:,1),1:2,["Positive","Negative"]);
figure
boxchart(namedorder,currents(:,2))
hold on
meancurr = [mean(pos_curr) mean(neg_curr)];
plot(meancurr,'x','MarkerSize',10,'LineWidth',1.5)
xlabel('Applied Voltage Rate Sign')
ylabel('Current Magnitude [pA]')
legend('Current Data','Mean Current')
pos_std_err = std(pos_curr) / sqrt(length(pos_curr));
neg_std_err = std(neg_curr) / sqrt(length(neg_curr));
leakage_curr = meancurr(1) - meancurr(2);
poe_leakage_curr = sqrt(pos_std_err^2 + neg_std_err^2);

display(leakage_curr)

display(poe_leakage_curr)
%%
figure
iosr.statistics.boxPlot(["Rising Limb","Falling Limb"], [28.24,28.2,28.54,28.44,28.22,28.25,28.6,28.54;27.64,27.72,27.74,27.7,27.64,27.64,28.15,27.75]','scaleWidth',true,'notch',false,'xspacing','equal','showOutliers',true);
ylabel('Capacitance [pF]')
xlabel('')
%%
function align_yyaxis_zero(ax)
    % align zero for left and right
    yyaxis left;  yliml = get(ax,'Ylim');
    yyaxis right; ylimr = get(ax,'Ylim');
    
    % Remove potential zeros from the limits
    yliml = yliml - 0.05 * (yliml == 0) .* yliml([2 1]);
    ylimr = ylimr - 0.05 * (ylimr == 0) .* ylimr([2 1]);
    
    if yliml(1) > 0 && ylimr(1) > 0
        yliml = [0 yliml(2)];
        ylimr = [0 ylimr(2)];
    elseif yliml(2) < 0 && ylimr(2) < 0
        yliml = [yliml(1), 0];
        ylimr = [ylimr(1), 0];
    elseif yliml(1) > 0 && ylimr(2) < 0
        ratio = diff(yliml)/diff(ylimr);
        yliml = [ylimr(1)*ratio, yliml(2)];
        ylimr = [ylimr(1), yliml(2)/ratio];
    elseif yliml(2) < 0 && ylimr(1) > 0
        ratio = diff(yliml)/diff(ylimr);
        yliml = [yliml(1), ylimr(2)*ratio];
        ylimr = [yliml(1)/ratio, ylimr(2)];
    elseif yliml(1) > 0
        yliml(1) = yliml(2) * ylimr(1) / ylimr(2);
    elseif yliml(2) < 0
        yliml(2) = yliml(1) * ylimr(2) / ylimr(1);
    elseif ylimr(1) > 0
        ylimr(1) = ylimr(2) * yliml(1) / yliml(2);
    elseif ylimr(2) < 0
        ylimr(2) = ylimr(1) * yliml(2) / yliml(1);
    else
        dl = diff(yliml);
        dr = diff(ylimr);
        if yliml(2)/dl > ylimr(2)/dr
            ylimr(2) = yliml(2)*dr/dl;
            yliml(1) = ylimr(1)*dl/dr;
        else
            yliml(2) = ylimr(2)*dl/dr;
            ylimr(1) = yliml(1)*dr/dl;
        end
    end
    yyaxis left;  set(ax, 'YLim', yliml);
    yyaxis right; set(ax, 'Ylim', ylimr);
end
