function V = PCA_FilterBank(InImg, PatchSize, NumFilters,lamda) 
% =======INPUT=============
% InImg            Input images (cell structure)  
% InImgIdx         Image index for InImg (column vector)
% PatchSize        the patch size, asumed to an odd number.
% NumFilters       the number of PCA filters in the bank.
% givenV           the PCA filters are given. 
% =======OUTPUT============
% V                PCA filter banks, arranged in column-by-column manner
% OutImg           filter output (cell structure)
% OutImgIdx        Image index for OutImg (column vector)
% ========= CITATION ============
% T.-H. Chan, K. Jia, S. Gao, J. Lu, Z. Zeng, and Y. Ma, 
% "PCANet: A simple deep learning baseline for image classification?" submitted to IEEE TPAMI. 
% ArXiv eprint: http://arxiv.org/abs/1404.3606 

% Tsung-Han Chan [thchan@ieee.org]
% Please email me if you find bugs, or have suggestions or questions!

addpath('./Utils')

% to efficiently cope with the large training samples, we randomly subsample 100000 training subset to learn PCA filter banks
ImgZ = length(InImg);
MaxSamples = 100000;
NumRSamples = min(ImgZ, MaxSamples); 
RandIdx = randperm(ImgZ);
RandIdx = RandIdx(1:NumRSamples);


%% Learning PCA filters (V)
NumChls = size(InImg{1},3);
Rx = zeros(NumChls*PatchSize^2,NumChls*PatchSize^2);
for i = RandIdx 
    im = im2col_general(InImg{i},[PatchSize PatchSize]); % collect all the patches of the ith image in a matrix
    im = bsxfun(@minus, im, mean(im)); % patch-mean removal 
    [row_v, col_v,value_v,size_v] = getConnectivityMatrixSparse(im,[PatchSize PatchSize],size(InImg{1}),[0 1 0; 1 0 1; 0 1 0]);
    S = sparse(row_v, col_v,value_v,size_v(1),size_v(2));
    %S = getConnectivityMatrix(im,[PatchSize PatchSize],size(InImg{1}),[0 1 0; 1 0 1; 0 1 0]);
    D = diag(sum(S));
    Rx = Rx + im*(D-S-eye(size(S,1))/lamda)*im'; % sum of all the input images' covariance matrix
end
Rx = Rx/(NumRSamples*size(im,2));
[E D] = eig(Rx);
[trash ind] = sort((diag(D)),'ascend');
% I add some codes for whitening

V = E(:,ind(1:NumFilters));  % principal eigenvectors 
%Diag_D = diag(D); 
%V = V*sqrt(inv(diag(Diag_D(ind(1:NumFilters)))));


 



