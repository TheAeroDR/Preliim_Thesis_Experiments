%%
filename = ['test_34000.txt'];

voltage_fft = fft_single(filename,2);

magnetic_fft1.P1 = voltage_fft.P1.*35;

voltage_fft = fft_single(filename,5);

magnetic_fft2.P1 = voltage_fft.P1.*35;

magnetic_fft = searchcoil_convert_single(filename,7,1);

magnetic_cutoff_fft = searchcoil_convert_cuttoff_single(filename,0);

%magnetic_notch_fft = notch_50Hz(magnetic_fft);

parameters.Fs = readmatrix(filename,"Range","B2:B2");
    if isempty(parameters.Fs)
        parameters.Fs = readmatrix(filename,"Range","B2:B2",'LineEnding','Hz');
    end
parameters.L = length(voltage_fft.data);
parameters.f1 = parameters.Fs * (0:(parameters.L/2))/parameters.L;
parameters.Ts = 1/parameters.Fs;
parameters.t1 = parameters.Ts * (0:parameters.L);

%magnetic_fft.P1(1) = 0;
figure
plot(parameters.f1,magnetic_fft.P1)
hold on
plot(parameters.f1,magnetic_fft1.P1)
plot(parameters.f1,magnetic_fft2.P1)
xlim([0,500])
xlabel('Frequency [Hz]');
ylabel('Magnetic Flux Density [nT]')
legend('LEMI 133','FLC3-70 \#1','FLC3-70 \#2')
set(gca,'YScale','log')