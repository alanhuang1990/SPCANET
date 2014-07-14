% ==== PCANet Demo =======
% T.-H. Chan, K. Jia, S. Gao, J. Lu, Z. Zeng, and Y. Ma, 
% "PCANet: A simple deep learning baseline for image classification?" submitted to IEEE TPAMI. 
% ArXiv eprint: http://arxiv.org/abs/1404.3606 

% Tsung-Han Chan [thchan@ieee.org]
% Please email me if you find bugs, or have suggestions or questions!
% ========================

clear all; close all; clc; 
addpath('./Utils');
addpath('./Liblinear');


TrnSize = 2414; 
ImgSize = 32; 
ImgFormat = 'gray'; %'color' or 'gray'

DataSplitsAddrPre = './YALE_B/';


load('./YALE_B/YaleB_32x32.mat'); 


%normalize to unit
%factor = sqrt(sum(fea.^2,2))

%for i = 1:TrnSize
%    fea(i,:) = fea(i,:)/factor(i);
%end
%fea = fea/256;
PCANet.NumStages = 2;
PCANet.PatchSize = 7;
PCANet.NumFilters = [8 8];
PCANet.HistBlockSize = [15 15]; 
PCANet.BlkOverLapRatio = 0;
PCANet.Lamda=1;

t_num = [5 10 20 30 40 50];

for itr_train = 1:length(t_num)
    train_num = t_num(itr_train);

    F_acc = [];
    F_err = [];
    F_dims = [];
    for itr = 1:5
        DataSplitsAddr = [DataSplitsAddrPre int2str(train_num) 'Train/' int2str(itr) '.mat'];

        %fprintf(DataSplitsAddr);
        load(DataSplitsAddr);

        TrnData = fea(trainIdx,:)';  
        TrnLabels = gnd(trainIdx,:);
        TestData = fea(testIdx,:)';
        TestLabels = gnd(testIdx,:);
        
        
        clear testIdx;
        clear trainIdx;

        nTestImg = length(TestLabels);

        %% PCANet parameters (they should be funed based on validation set; i.e., ValData & ValLabel)
        % We use the parameters in our IEEE TPAMI submission
        

        fprintf('\n ====== PCANet Parameters ======= \n')
        PCANet

        %% PCANet Training with 10000 samples

        fprintf('\n ====== PCANet Training ======= \n')
        TrnData_ImgCell = mat2imgcell(TrnData,ImgSize,ImgSize,ImgFormat); % convert columns in TrnData to cells 
        TrnData_ImgCell=Resize_images(TrnData_ImgCell,[130 130]);
        
        tic;
        [ftrain V BlkIdx] = PCANet_train(TrnData_ImgCell,PCANet,1); % BlkIdx serves the purpose of learning block-wise DR projection matrix; e.g., WPCA
        PCANet_TrnTime = toc;
        clear TrnData_ImgCell;
        
        max_dim = (min(size(ftrain))-1);
        fprintf('\nPerform PCA on image feature...');
        PCA_V_max = PCA(ftrain', max_dim,1,10000);

        %% PCANet Feature Extraction and Testing 


            max_dim = (min(size(ftrain))-1);
            dim = max_dim;

            TestData_ImgCell = mat2imgcell(TestData,ImgSize,ImgSize,ImgFormat); % convert columns in TestData to cells 
            fprintf('\n ====== PCANet Testing ======= \n')
            
            
            TestData_ImgCell=Resize_images(TestData_ImgCell,[130 130]);
            
            nCorrRecog = 0;
            RecHistory = zeros(nTestImg,1);
            tic; 
            PCA_V=PCA_V_max(:,1:dim);    
            PCA_ftrain = ftrain'*PCA_V;
            for idx = 1:1:nTestImg

                ftest = PCANet_FeaExt(TestData_ImgCell(idx),V,PCANet); % extract a test feature using trained PCANet model 
                
                Y_Idx = knnsearch(PCA_ftrain,ftest'*PCA_V,'k',1,'distance','cosine');
                %Y_Idx = knnsearch(ftrain,ftest','k',1,'distance',@ChiDist);
                xLabel_est = TrnLabels(Y_Idx);
                if xLabel_est == TestLabels(idx)
                    RecHistory(idx) = 1;
                    nCorrRecog = nCorrRecog + 1;
                end

                if 0==mod(idx,nTestImg/100); 
                    fprintf('Accuracy up to %d tests is %.2f%%; taking %.2f secs per testing sample on average. \n',...
                        [idx 100*nCorrRecog/idx toc/idx]); 
                end 

                TestData_ImgCell{idx} = [];

            end
            Averaged_TimeperTest = toc/nTestImg;
            Accuracy = nCorrRecog/nTestImg; 
            ErRate = 1 - Accuracy;
            F_acc = [Accuracy;F_acc];
            F_err = [ErRate; F_err];
            F_dims = [dim, F_dims];
            fprintf('\n     Testing error rate for split %d with dim=%d : %.2f%%',itr,dim, 100*ErRate);
            save(['Large_YALEB32_' int2str(train_num) '_manifold_PCA_dfull_' num2str(PCANet.Lamda) '.mat'],'F_dims','F_acc','F_err','PCANet','V');
            clear TrnData TrnLabels TestData TestLabels PCA_V_max ftrain PCA_V PCA_ftrain ;

    end 
    %% Results display
    fprintf('\n ===== Results of PCANet, followed by a linear SVM classifier =====');
    fprintf('\n     PCANet training time: %.2f secs.', PCANet_TrnTime);
    fprintf('\n     Average testing error rate: %.2f%%', 100*mean(F_err));
    fprintf('\n     Average testing time %.2f secs per test sample. \n\n',Averaged_TimeperTest);
    save(['Large_YALEB32_' int2str(train_num) '_manifold_PCA_dfull_' num2str(PCANet.Lamda) '.mat'],'F_dims','F_acc','F_err','PCANet','V');
    %save(['YALEB32_Manifold_PCA_' int2str(train_num) '_d_Full' '_''_PCANET.mat'],'F_dims','F_acc','F_err','PCANet','V');
end 



    
