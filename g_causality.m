function [gcArray, labels] = g_causality(labels, data, fs, fres, separateWindows, momax)
% Frequency-domain granger causality
%    Estimates frequency-domain granger causality from x->y and y->x. Estimates
%    are given for all frequency bands given by f.
%    
%    INPUTS 
%    x, y: Signals. Each should be a NxW matrix of time windows (N: Time
%        points per window; W: number of windows).
%    fres: number of frequencies to evaluate (not including dc component)
%    fs: Sampling rate (Hz)
%    separateWindows: (optional) boolean indicating whether to model windows seperately
%    momax: maximum model order for model order estimation
%    OUTPUTS
%    gcArray: spectral granger causality estimates
%    f: frequencies corresponding to the elements of gcArray
%
% This function requires the MVGC toolbox. Portions of this code were taken from mvgc_demo script of that toolbox.

%VERBOSE = false;

if nargin < 6
  momax = ceil(fs/5); % fifth of a second     

  if nargin < 5
    separateWindows = true;
  end
end

data = permute( data, [2,1,3]);

% Calculate information criteria up to specified maximum model order.
% fprintf('Comparing model orders...\n')
% [~,~,order,~] = tsdata_to_infocrit(data, momax, 'LWR', VERBOSE) %;
order = momax;

f = sfreqs(fres, fs);

%%%% Modified section below
%%%% Don't want all possible combinations of channels - only want rows and
%%%% columns (directional pairs) with order specificity
CHANS = [4 5 6 8 9 10 11 12 13 14 15 18 19 20 21 22 23 24 25 26 28 29 30];
% rows = {[28, 19, 17, 15, 13, 4], [24, 22, 20, 12, 10, 8],...
%     [29, 27, 18, 14, 5, 3], [25, 23, 21, 11, 9, 7]};
% cols = {[28, 29], [24, 25], [22, 23], [19, 20, 21], [17, 18],...
%     [15, 14], [13, 12, 11], [10, 9], [8, 7], [4, 3]};

rows = {[29, 20, 18, 14, 5], [25, 23, 21, 13, 11, 9],...
    [30, 28, 19, 15, 6, 4], [26, 24, 22, 12, 10, 8]};
cols = {[29, 30], [25, 26], [23, 24], [20, 21, 22], [18, 19],...
    [12, 13, 14], [10, 11], [8, 9], [4, 5]};


for r = 1:length(rows)
    for c1 = 1:length(rows{r})
        rows{r}(c1) = find(CHANS == rows{r}(c1),1);
    end
end
for c = 1:length(cols)
    for c1 = 1:length(cols{c})
        cols{c}(c1) = find(CHANS == cols{c}(c1),1);
    end
end
permutations = [];
for r = 1:length(rows)
    pairs = nchoosek(rows{r},2);
    %permutations(size(permutations,1)+[1:size(pairs,1)*2],:) = [pairs; pairs(:,2) pairs(:,1)];
    permutations(size(permutations,1)+[1:size(pairs,1)],:) = pairs;
    clear pairs
end
permutations(size(permutations,1)+[1:size(permutations,1)],:) =...
    [permutations(:,2) permutations(:,1)];
rowstop = size(permutations,1);
for c = 1:length(cols)
    pairs = nchoosek(cols{c},2);
    %permutations(size(permutations,1)+[1:size(pairs,1)*2],:) = [pairs; pairs(:,2) pairs(:,1)];
    permutations(size(permutations,1)+[1:size(pairs,1)],:) = pairs;
    clear pairs
end
permutations(size(permutations,1)+[1:size(permutations(rowstop+1:end,:),1)],:) =...
    [permutations(rowstop+1:end, 2) permutations(rowstop+1:end, 1)];


if separateWindows
% loop over each window seperately
  [C,~,W] = size(data);
  F = numel(f);
  gcArray = zeros(size(permutations,1),F,W); %zeros(C,C,F,W);
else
% run through loop once using all windows
  W = 1;
  thisData = data;
end
labels.pairs = permutations;
a = tic;
for p = 1:size(permutations,1)
    fprintf('Starting permutation %2.3f%%: %2.1fs elapsed\n', p/size(permutations,1)*100, toc(a))
    for w = 1:W
        if separateWindows
            thisData = data(:, :, w);
        end
        c1 = permutations(p,1);
        c2 = permutations(p,2);
        gcArray(p,:,w) = GCCA_tsdata_to_smvgc(thisData, c2, ...
                    c1, order, fres, 'OLS');
    end
end
%{
a = tic;
for w = 1:W
    if separateWindows
        thisData = data(:, :, w);
        fprintf('Starting window %2.3f%%: %2.1fs elapsed\n', w/W*100, toc(a))
    end

    for r = 1:length(rows)
        for c1 = rows{r}
            for c2 = rows{r}
                if c1 == c2, continue, end
                gcArray(c1,c2,:,w) = GCCA_tsdata_to_smvgc(thisData, c2, ...
                    c1, order, fres, 'OLS');
            end
        end
    end
    for c = 1:length(cols)
        for c1 = cols{c}
            for c2 = cols{c}
                if c1 == c2, continue, end
                gcArray(c1,c2,:,w) = GCCA_tsdata_to_smvgc(thisData, c2, ...
                    c1, order, fres, 'OLS');
            end
        end
    end
    
    %{
    
    for c1 = 1:C
        for c2 = 1:C
            if c1 == c2, continue, end
            gcArray(c1,c2,:,w) = GCCA_tsdata_to_smvgc(thisData, c2, c1, order, ...
            fres, 'OLS');
        end
    end
    
    %}
end
%}