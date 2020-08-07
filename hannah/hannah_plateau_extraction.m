% Very simple script to find plateaus in load cell data
% This is a brute force approach, it requires tuning and may not be generalizable!
%
% Author: M. Kokko
% Date:   06-Aug-2020

% restart
close all; clear; clc;

% options
N_lp = 4;                    % order of low pass filter
fc_lp = 10;                  % [Hz] low pass cutoff frequency
mavg_window = 3000;          % size of moving average window (in samples)
deriv_threshold  = 1.5e-4;   % max allowable absolute derivative value in a plateau
min_plat_width = 5e3;        % minimum plateau width (in samples)

% load data from load cell
excel_filename = 'CouchBalanceTest-2.csv';
mydata = readtable(excel_filename,'HeaderLines',9);
t = mydata.Var1;
y = mydata.Var2;

% compute properties of signal
dt_samp = mean(diff(t));   % TODO: should check for consistency and resample if necessary, example data provided is sampled consistently
f_samp = 1/dt_samp;
N = length(t);

% apply low pass filter
wn_lp = fc_lp/(f_samp/2);
[b_lp,a_lp] = butter(N_lp,wn_lp,'low');
y_filt = filtfilt(b_lp,a_lp,y);

% smooth further with a moving average filter
y_mavg = movmean(y_filt,mavg_window);

% take derviative... remember derviatives make signals uglier
dydt = abs(gradient(y_mavg,t));

% find the plateaus as the areas where derivative is below some threshold 
lowvals = (dydt < deriv_threshold);

% now find the indices of all points that are NOT in plateaus
highValIdx = [find(lowvals == 0);length(lowvals)];  % note: added end of data here in case that is the edge of a plateau

% plateaus are in locations where there are lots of points between points that are NOT in plateaus 
platStarts = find(diff(highValIdx) > min_plat_width);
platStartIdx = highValIdx(platStarts);
platEndIdx = highValIdx(platStarts+1);
platCenterIdx = floor((platStartIdx+platEndIdx)/2);

% find mean value on each plateau; not very elegant!
platData = nan(length(platStartIdx),2);
for platIdx = 1:length(platStartIdx)
    platData(platIdx,1) = t(platCenterIdx(platIdx));
    platData(platIdx,2) = mean(y_filt(platStartIdx(platIdx):platEndIdx(platIdx)));
end

% show plateau data
platDataTable = table(platData(:,1),platData(:,2),'VariableNames',{'Plateu_Center_Time','Plateau_Mean_Value'});
platDataTable

% plot data and results
figure;
set(gcf,'Position',[0249 1.778000e+02 9.656000e+02 4.200000e+02]);
ax = subplot(3,1,1:2);
hold on; grid on;
plot(t,y,'-','Color',[0.0 0.0 0.8],'LineWidth',1.6);
plot(t,y_filt,'-','Color',[0.8 0.0 0.0],'LineWidth',1.6);
plot(t,y_mavg,'-','Color',[0.8 0.0 0.8],'LineWidth',1.6);
% plot(t(platCenterIdx),y(platCenterIdx),'.','MarkerSize',50,'Color',[0.8 0 0]);
plot(platData(:,1),platData(:,2),'.','MarkerSize',50,'Color',[0.8 0.0 0.0]);
ylabel('\bfLoad Cell Voltage');
legend('Raw','Low Pass', 'Moving Average','Plateau Centers');

ax(end+1) = subplot(3,1,3);
hold on; grid on;
plot(t,dydt,'Color',[0.8 0.0 0.8]);
xlabel('\bfTime [sec]');
ylabel('\bfdV/dt')

linkaxes(ax,'x');