%%
clear cutoff delta e_field endtime fm_times Fs fs1 fs2 keithley loc pk time

files = dir(['./charged_glass_drop_K_*.txt']);
files2 = dir(['./charged_glass_drop_S*.dat']);
files = [files; dir(['./charged_glass_drop_KM_*.txt'])];

common_time = linspace(-5, 35, 401);  % Adjust range and resolution as needed
all_keithley_interp = [];
all_e_field_interp = [];

% Read data from each file and store all x, z, Bz values
for i = 1:length(files)
    % Read data from file
    fs1 = files(i).name;
    fs2 = files2(i).name;

    [keithley,time,delta,Fs,cutoff,endtime,M] = keithley_import(fs1,200);

    [e_field,fm_times,pk,loc] = fm_import(fs2,cutoff,endtime);

    if i == 1
        loc = 4.8;
    elseif i == 2
        loc = 10.9;
    elseif i == 3
        loc = 5.6;
    elseif i == 4
        loc = 6;
        keithley = keithley - 10.8;
    elseif i == 5
        loc = 7.1;
        keithley = keithley - 11.39;
    elseif i == 6
        loc = 10.4;
        keithley = keithley - 12.75;
    end
    
    time = time - loc;
    fm_times = fm_times - loc;
    if i == 1
        figure
        tiledlayout(2,1)
    end
    nexttile(1)
    plot(time,keithley) 
    hold on
    ylabel('Charge [pC]')
    nexttile(2)
    plot(fm_times,e_field)
    hold on
    ylabel('Electric Field [V/m]')
    
    keithley_interp = interp1(time, keithley, common_time, 'linear', 'extrap');
    e_field_interp = interp1(fm_times, e_field, common_time, 'linear', 'extrap');

    all_keithley_interp = [all_keithley_interp, keithley_interp(:)];
    all_e_field_interp = [all_e_field_interp, e_field_interp(:)];

end
mean_keithley = mean(all_keithley_interp, 2);
mean_e_field = mean(all_e_field_interp, 2);

nexttile(1)
plot(common_time,mean_keithley,'k','LineWidth',3)
nexttile(2)
plot(common_time,mean_e_field,'k','LineWidth',3)

function[down_keithley,down_time,delta_keithley,Fs,cutoff,endtime,M] = keithley_import(fs1,range)
    opts = delimitedTextImportOptions("NumVariables", 7);
    opts.DataLines = [1, Inf];
    opts.Delimiter = ",";
    opts.VariableTypes = ["string", "string", "string", "string", "string", "string", "string"];
    temp = readmatrix(fs1,opts);
    range_fac = range/2;
    keithley = str2double(temp(4:end,7)) * range_fac;
    keithley = keithley * (28e-12/1e-12); %capacitance is 28e-12 and convert to pC
    Fs = str2double(temp(2,2));
    M = str2double(temp(4:end,1:6));
    time = transpose(linspace(0,length(keithley)/Fs, length(keithley)));
    cutoff = datetime(temp(1,1),'format','dd/MM/uuuu HH:mm:ss.SSSSSS');
    endtime = time(end);
    max_keithley = 10;
    block = Fs / max_keithley;
    new_l = length(keithley)/block;
    down_keithley = NaN(new_l,1);
    down_time = linspace(0,length(keithley)/Fs,new_l);
    delta_keithley = NaN(new_l,1);
    for i = 1:new_l
        down_keithley(i) = mean(keithley(1+block*(i-1):block*i));
    end
    for i = 2:new_l
        delta_keithley(i) = down_keithley(i) - down_keithley(i-1);
    end
end

function [e_field,fm_times,pk,loc] = fm_import(fs2,cutoff,endtime)
    opts = delimitedTextImportOptions("NumVariables", 8);
    opts.DataLines = [5, Inf];
    opts.Delimiter = ",";
    opts.VariableTypes = ["string", "string", "string", "string", "string", "string", "string", "string"];
    temp = readmatrix(fs2,opts);
    e_field = str2double(temp(:,3));
    times = temp(:,1);
    for i = 1:length(times)
        if times{i}(end-1) ~= '.'
            times{i} = strcat(times{i},'.0');
        end
    end
    fm_times = datetime(times,'format','dd/MM/uuuu HH:mm:ss.S');
    e_field = e_field(fm_times>cutoff);
    fm_times = fm_times(fm_times>cutoff);

    fm_times = seconds(datetime(fm_times) - datetime(fm_times(1)));

    e_field = e_field(fm_times<endtime);
    fm_times = fm_times(fm_times<endtime);

    [pk,loc] = findpeaks(e_field,'MinPeakHeight',0.5);
    if isempty(pk)
        [pk,loc] = findpeaks(-e_field,'MinPeakHeight',0.5);
    end
    if length(pk) > 1
        [pk,loc] = findpeaks(e_field,'MinPeakHeight',1);
        if isempty(pk)
            [pk,loc] = findpeaks(-e_field,'MinPeakHeight',1);
        end
    end
    loc = fm_times(loc);
end