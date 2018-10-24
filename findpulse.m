function windowStarts = findpulse(thisData)

[C, nSamples] = size(thisData);

M = movmean(thisData,5000,2);
S = 10*std(thisData,[],2);

pulse = (thisData >= M + S) + (thisData <= M - S);

for k = 1:nSamples
    for c = 1:C
        if ~pulse(c,k), continue, end
        pulse(:,k) = ones(C,1);
        pulse(:,k+1:k+357) = zeros(C,357);
        k = k + 357;
    end
end

windowStarts = find(pulse(1,:));