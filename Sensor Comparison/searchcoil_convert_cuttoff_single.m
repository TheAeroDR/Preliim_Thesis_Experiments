function output = searchcoil_convert_cuttoff_single(filename,sc_flag)       
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
    data = import(:,3) * 1000;
    clear import;
    
    L = length(data);
    f1 = Fs * (0:(L/2))/L;
    Ts = 1/Fs;
    Y = fft(data);
    if sc_flag ==1
        fd = (1/(2 * pi)) * (2/Ts) * atan((2 * pi * f1 * Ts)/2); %account for bilinear transform causing non-linear frequency warping    
        gain_nf = interp1(lemi_tf(:,1),lemi_tf(:,2),fd,'linear');
        phase_nf = interp1(lemi_tf(:,1),lemi_tf(:,3),fd,'linear');
        TF_nf = (gain_nf .* exp(sqrt(-1) * deg2rad(phase_nf)))';
        TFf_nf = flip(TF_nf);
        TF_nf = [TF_nf; TFf_nf(2:end-1)];
        
        Y_nf = Y;
        Yc_nf = Y_nf ./ TF_nf;
        
        %set <10 Hz to 0 (NaN breaks the ifft)
        Yc_nf(isnan(TF_nf)) = -60;
    else
        Yc_nf = Y .* 35;
    end
    
    P2c_nf = abs(Yc_nf/L);
    P1c_nf = P2c_nf(1:L/2+1);
    P1c_nf(2:end-1) = 2 * P1c_nf(2:end-1);
    
    datac_nf = ifft(Yc_nf);
    
    output.data = datac_nf;
    output.Y = Yc_nf;
    output.P1 = P1c_nf;