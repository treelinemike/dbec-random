% Apply Simple Fourier Transform to CMM data
%
% Given an input signal y = A*sin(a*x) + B*sin(b*x) + C*sin(c*x) + ...
% Identify the WEIGHTS: A, B, C, etc.
% as well as the 'FREQUENCIES': a, b, c, etc.
%
% Note: This is not a true reconstruction of the signal unless the input
% really is a series of unshifted sine terms. We look at only the
% magnitude of the Fourier transform, and thus get an accurate picture of
% the frequency content but have no information about phase. This could be
% modified to actually compute the Fourier sine series coefficients
% (coefficients of the sine and cosine terms) - then the terms with the
% same frequencies could be combined into shifted sine (or cosine) terms.
%
% Also note: sampling at a smaller angular step size (smaller angle increments from CMM)
% will allow for more precise discimination between 'frequencies'
%
% Author: M. Kokko
% Created: 06-Jul-2020

% restart
close all; clear all; clc;

% options
excel_filename = 'fourier_cmm_test.xlsx';  % must have column headings 'angle_degrees' and 'deflection'
doShowComplexFFT = 0;  % 0: don't show complex components of FFT; 1: show complex components of FFT

% load data from Excel
mydata = readtable(excel_filename);
theta = mydata.angle_degrees * pi/180;
y = mydata.deflection;

% % alternatively we could synthesize some toy data
% theta = 0:0.1:2*pi;
% sigma = 0.05;
% y = 2*sin(theta+ pi/6); %+ 1.2*sin(3*theta) + sigma*randn(1,length(theta));

% correct jumping when theta wraps
% this may make the raw plots display differently than Excel
[minVal,minIdx] = min(abs(theta));
theta_uw = unwrap(theta);
theta_uw = theta_uw-theta_uw(minIdx)+minVal;

% compute effective sampling rate
N = length(theta);
delta_x = mean(diff(theta_uw));

% resample data in case it isn't already given at a constant sampling rate
% need to be sure interp1() is allow to extrapolate for last point in
% theta_rs
theta_rs = theta_uw(1) + (0:N-1)*delta_x;
y_rs = interp1(theta_uw,y,theta_rs,'linear','extrap');

% center (de-mean) data
rs_mean = mean(y_rs);
y_rs = y_rs - rs_mean;
y = y - rs_mean;

% compute sampling frequency and frequency vector
delta_x_rs = mean(diff(theta_rs)); % this should be just delta_x!
fs = 1/delta_x_rs;
% freq = 2*pi*(1/(2*pi))*(-floor(N/2):1:ceil(N/2)-1);  % note: 2*pi cancels because we're scaling the x axis to show the coefficient 'a' in sin(a*theta)

% the freq vector above is easily interpreted but not quite correct; use
% this instead...
% the initial 2*pi factor scales the output so it is in "rad/s" rather than "Hz" (if x axis were in seconds; unfortunately it's in radians here which is confusing); 
% the other term is (fs/(N-1)) = (1/T) = (1/(max(theta_rs)-min(theta_rs)))
% if we sampled all the way around back to 2*pi the factors of 2*pi would
% cancel... they probably won't quite in practice
freq = 2*pi*(fs/(N-1))*(-floor(N/2):1:ceil(N/2)-1);

% compute FFT
Y = (1/N)*fftshift(fft(y_rs));

% prepare figure
figure;
if(doShowComplexFFT)
    numSubplots = 3;
else
    numSubplots = 2;
end

% plot original data
subplot(numSubplots,1,1);
hold on; grid on;
plot(theta_uw*180/pi,y,'.','MarkerSize',5,'Color',[0.0 0.0 0.8]);
plot(theta_rs*180/pi,y_rs,'o','MarkerSize',3','Color',[0.8 0.0 0.0]);
legend('Raw','Resampled');
xlabel('\bfAngle [deg]');
ylabel('\bfDeflection');

% plot FFT magnitude
ax = subplot(numSubplots,1,2);
hold on; grid on;
stem(freq,2*abs(Y),'LineWidth',1.6,'Color',[0.0 0.0 0.8],'MarkerSize',2);  % https://www.mathworks.com/matlabcentral/answers/84141-why-fft-function-returns-amplitude-divided-by-2
xlim([0, max(freq)]);
xlabel('\bf''Frequency'' of Component Sine Wave');
ylabel('\bfComponent Weight');

% show real and imaginary components of FFT if desired
if(doShowComplexFFT)
    ax(end+1) = subplot(numSubplots,1,3);
    hold on; grid on;
    stem(freq,real(Y),'-','LineWidth',1.6,'Color',[0.0 0.0 0.8],'MarkerSize',2);
    stem(freq,imag(Y),'-','LineWidth',1.6,'Color',[0.8 0.0 0.0],'MarkerSize',2);
    legend('Real','Imag');
    xlim([0, max(freq)]);
    linkaxes(ax,'x');
end