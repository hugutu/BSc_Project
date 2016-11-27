% Name : Hashan Roshantha Mendis (10030637)
% Date Updated : 20/04/08
% GMSK - Modulation/Demodulation with AWGN and Fading Channel
% [Main Script]
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
clear all;%close all
tic % STOPWATCH ON
% =========================================================================
samples = 36;
Tb = 1; % bit duration
SamplePeriod = Tb*(1/samples); 

%m = [-1 -1 -1 1 1 -1 1 1 1 1 -1 1 -1 1 -1 -1]; % message bits
Pe =[];
 
for EbNo = (0:1:10)
    m = randsrc(1,10000); % produces random -1's and 1's
    
    %t1 = 0:SamplePeriod:(length(m)*Tb); % define timeline
    %t1(:, length(t1)) = []; % get rid of extra column in timeline
    
    % -------------------------------------------------------------------------
    % ---------------------------- GMSK Modulation ----------------------------
    % -------------------------------------------------------------------------
   
    % the following converts message into a series of unipolar NRZ data.
    rect = kron(m,ones(1,samples)); % use the kron function to upsample the bits.
    
    % create gaussian low pass filter(defined in the gaussian_filter.m)
    gaussfilter = GMSK_gaussian_filter(Tb,samples);
    %gaussfilter = gaussfilter(1:length(gaussfilter)-1); % remove 1 sample from the end.

    % pass message signal through Gaussian LPF
    m_filtered = conv(gaussfilter,rect);
    %figure;plot(m_filtered);title('filtered data');
    m_filtered = [m_filtered m_filtered(length(m_filtered))]; % add extra sample at end.
    
    m_filtered1 = cumsum(m_filtered); % integrate the data.
    
    m_filtered2_real = cos(m_filtered1);
    m_filtered2_imag = sin(m_filtered1);
    m_filtered2 = m_filtered2_real + j*m_filtered2_imag;

    % -------------------------------------------------------------------------
    % -------------------------- FADING + AWGN Channel ------------------------
    % -------------------------------------------------------------------------

    %h2 = scatterplot(m_filterde2);
    
    % pass through the fading channel
    faded_signal = rayleigh_sim(m_filtered2,samples);
    
    % First test : without noise , noise = Nil (uncomment as necessary)
    %noisy_real = m_filtered2_real;
    %noisy_imag = m_filtered2_imag;
    %noisy_real = AWGN_channel(real(m_filtered2), EbNo, Tb); 
    %noisy_imag = AWGN_channel(imag(m_filtered2), EbNo, Tb); 
   
    
    % Now introduce AWGN into the signal.
    %EbNo = 10; % EbNo in db
    noisy_real = AWGN_channel(real(faded_signal), EbNo, Tb); % apply noise to I-channel
    noisy_imag = AWGN_channel(imag(faded_signal), EbNo, Tb); % apply noise to Q-channel
            
    % -------------------------------------------------------------------------
    % ------------------------- GMSK De-Modulation ----------------------------
    % -------------------------------------------------------------------------

    % pass I and Q through Matched Filter(defined in the matched_filter.m)
    mfilt_samples = 7;
    matchfilter = GMSK_matched_filter(Tb,mfilt_samples);
    %matchfilter = matchfilter(1:length(matchfilter)-1); % remove 1 sample from the end.

    %filt_noisy_imag = noisy_imag;
    %filt_noisy_real = noisy_real;

    % convolve the filter with the signal and add an extra sample to the
    % end.
    filt_noisy_real = conv(matchfilter,noisy_real);
    filt_noisy_imag = conv(matchfilter,noisy_imag);
    filt_noisy_real = [filt_noisy_real filt_noisy_real(length(filt_noisy_real))];
    filt_noisy_imag = [filt_noisy_imag filt_noisy_imag(length(filt_noisy_imag))];

    % obtaining the phase of the analog signal
    phase = unwrap(angle(filt_noisy_real+filt_noisy_imag*j));

    % obtain the derivative of the signal.
    derivative = diff(phase);
    derivative = [phase(1) derivative]; 
   
    % downsample the signal
    rx_dwnsmpled = GMSK_downsample(70,71,samples,derivative);

    % GMSK_ADC
    rx_digital = GMSK_ADC(rx_dwnsmpled);

    %figure;stem(derivative);figure;stem(rx_dwnsmpled);
    [num,rat] = symerr(m,rx_digital);
    
    %store Pe values
    Pe = [Pe rat];
    
    fprintf('end of %d \n',EbNo);
    
end

% ---------------- Generate EbNo vs. BER plot -----------------

EbNo_temp = 0:1:10;
semilogy(EbNo_temp,Pe);title('GMSK (BT=0.3) - EbNo vs. BER');hold on

total_time = toc; % STOPWATCH OFF
