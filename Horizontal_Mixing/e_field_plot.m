fs1 = 'mgs_1c_air_grounded.txt';
fs2 = 'mgs_1c_air_grounded_S.dat';

opts = delimitedTextImportOptions("NumVariables", 1);
opts.VariableTypes = ["string"];
opts.DataLines = [1, 1];
import1 = readmatrix(fs1,opts);
cutoff = datetime(import1,'format','dd/MM/uuuu HH:mm:ss.SSSSSS');

[e_field,times,~,~] = fm_import(fs2,cutoff,60);

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