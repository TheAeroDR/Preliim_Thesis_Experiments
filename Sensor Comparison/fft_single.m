function output = fft_single(filename,col)

    import = readmatrix(filename);
    
    %old file layout: data = import(4:end,2) * 1000 (V to mV);
    data = import(:,col) * 1000;
    clear import;
    Fs = readmatrix(filename,"Range","B2:B2");
    if isnan(Fs)
        Fs = readmatrix(filename,"Range","B2:B2",'LineEnding','Hz');
    end

    L = length(data);
    f = Fs*(0:(L/2))/L;
    alpha = 0.1;

    window = tukeywin(L,alpha);
    data = data .* window;

    N_fft = 2^nextpow2(L);
    data = [zeros(floor(N_fft/2) - L, 1); data; zeros(ceil(N_fft/2) - L, 1)]; 

    

    Y = fft(data);
    %matlab fft doesn't normalise by size
    %make double sided spectrum
    P2 = abs(Y/L);
    %make single sided spectrum
    P1 = P2(1:L/2+1);
    P1(2:end-1) = 2 * P1(2:end-1);

    output.data = data;
    output.Y = Y;
    output.P1 = P1;
    output.f = f;
end