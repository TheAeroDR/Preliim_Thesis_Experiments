function output = searchcoil_convert_single(filename,col,sc_flag)       
    import = readmatrix(filename);
    if sc_flag == 1
        load lemi_tf_dat.mat lemi_tf
    end
    %old file layout: Fs = 1 / import(2,2);
    Fs = readmatrix(filename,"Range","B2:B2");
    if isnan(Fs)
        Fs = readmatrix(filename,"Range","B2:B2",'LineEnding','Hz');
    end
    %old file layout: data = import(4:end,2) * 1000 (V to mV);
    data = import(:,col) * 1000;
    clear import;
    
    L = length(data);
    f1 = Fs * (0:(L/2))/L;
    Ts = 1/Fs;
    Y = fft(data);
    if sc_flag ==1
        fd = (1/(2 * pi)) * (2/Ts) * atan((2 * pi * f1 * Ts)/2); %account for bilinear transform causing non-linear frequency warping
        fd = f1;
        gain = interp1(lemi_tf(:,1),lemi_tf(:,2),fd,'linear','extrap');
        phase = interp1(lemi_tf(:,1),lemi_tf(:,3),fd,'linear','extrap');
        TF = (gain .* exp(sqrt(-1) * deg2rad(phase)))';
    
    %need to make bilinear (account for negative freqs) 0 - 500, -500 - 0
    %(minus first and last value)
        TFf = flip(TF);
        TF = [TF; TFf(2:end-1)];
    
        Yc = Y ./ TF;
    else
        Yc = Y .* 35;
    end
    P2c = abs(Yc/L);
    P1c = P2c(1:L/2+1);
    P1c(2:end-1) = 2 * P1c(2:end-1);
    
    %reverse fft
    datac = ifft(Yc);

    output.data = datac;
    output.Y = Yc;
    output.P1 = P1c;
    output.f = f1;
end