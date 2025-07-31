clear all
str1 = ["train","test"];
str2 = ["circle","heart","square","star","triangle"];

t = 'kaze\';
mkdir(t);
tic
se = strel('disk',5,4);
windowSize = 4;
kernel = ones(windowSize) / windowSize ^ 2;
for j = 1:str1.length
    j
    for k = 1:str2.length
        k  
        folder = strcat('dataset\',str1(j),"\",str2(k),"\");
        data = dir(fullfile(folder, '*.png'));
        [b, a] = size(data);
        
        dataC = cell(b,5);
        for i = 1:b
            img1 = imread(strcat(folder,data(i).name));
            img1 = im2gray(img1);
            img2 = img1;
            img1 = imbinarize(img1,0.4);
            img1 = imfill(img1,'holes');
            img1 = bwareaopen(img1,4);
            img1 = imdilate(img1,se);
            
            blurryImage = conv2(single(img1), kernel, 'same');
            img1 = blurryImage > 0.5;
            cc = bwconncomp(img1);
            regions = cc.NumObjects;
            if regions == 0
                img1 = imbinarize(img2,0.15);
                img1 = imfill(img1,'holes');
                img1 = bwareaopen(img1,4);
                img1 = imdilate(img1,se);
                
                blurryImage = conv2(single(img1), kernel, 'same');
                img1 = blurryImage > 0.5;
                cc = bwconncomp(img1);
                regions = cc.NumObjects;
            end
    
            s = regionprops(cc,"Area");
            b= maxk(vertcat(s.Area),3);
            idx = find([s.Area] >= b(end));
            imgBW2 = ismember(labelmatrix(cc),idx);
            imgBW2 = edge(imgBW2,"sobel");
            feat = detectKAZEFeatures(imgBW2);%%%%%%%%%%%%%- Change detector algorithm -%%%%%%%%%%%%%%%%%
            if j == 4 || k == 4 || feat.Count == 0
                img1 = imbinarize(img2,0.25);
                img1 = imfill(img1,'holes');
                img1 = bwareaopen(img1,4);
                img1 = imdilate(img1,se);

                blurryImage = conv2(single(img1), kernel, 'same');
                img1 = blurryImage > 0.5;
                cc = bwconncomp(img1);
                regions = cc.NumObjects;
    
                s = regionprops(cc,"Area");
                b= maxk(vertcat(s.Area),3);
                idx = find([s.Area] >= b(end));
                imgBW2 = ismember(labelmatrix(cc),idx);
                imgBW2 = edge(imgBW2,"sobel");
                feat = detectKAZEFeatures(imgBW2);%%%%%%%%%%%%%- Change detector algorithm -%%%%%%%%%%%%%%%%%
            end

            dataC{i,3} = data(i).name;
            [dataC{i,1},dataC{i,2}] = extractFeatures(imgBW2,feat);
            dataC{i,4} = imgBW2;
            dataC{i,5} = regions;
            filename = t(1:end-1)+"_images\"+data(i).name+"_"+str1(j)+"_"+str2(k)+".png";
            imwrite(imgBW2,filename);
        end
        filename = t+"Npoints_"+str1(j)+"_"+str2(k)+".mat";
        save(filename,'dataC');
        
        clearvars -except j k str1 str2 t se p windowSize kernel
    end
end

match = cell(str2.length*str2.length,600*40);
matchMetrics = cell(2,1);
mkdir("match_"+t);
for i = 1:str2.length
    i
    for j = 1:str2.length
        %j
        folder_test = strcat(t , 'Npoints_',str1(2),"_",str2(i),'.mat');
        data_test = importdata(folder_test);
        folder_train = strcat(t , 'Npoints_',str1(1),"_",str2(j),'.mat');
        data_train = importdata(folder_train);

        for n = 1:size(data_test,1)
            for m = 1:size(data_train,1)
                f1 = data_test{n,1};
                f2 = data_train{m,1};
                vpts1 = data_test{n,2};
                vpts2 = data_train{m,2};
                [matchMetrics{1}, matchMetrics{2}] = matchFeatures(f1,f2,Unique=true);
                index1 = (i-1)*str2.length + j;
                index2 = (m-1)*size(data_test,1) + n;
                if isempty(match{index1,index2}) 
                    match{index1,index2} = matchMetrics;
                else 
                    ss="not Empty"
                    m
                    n
                    i
                    j
                end
            end
        end
    end
end
filename = "match_"+ t +"Nmatch_"+t(1:end-1)+".mat";
save(filename,'match');

thPoint = 7;           %[1 2 3 4 5 6 7 8 9 10 11 12];
dTH = 0.028;           %[0.009 0.015 0.018 0.02 0.024 0.028 0.032 0.038];

[TP,TN,FP,FN] = deal(zeros(15,1));
x=0;

for i = 1:str2.length
    % i
    for j = i:str2.length
        x = x+1;
        folder_test = strcat(t , 'Npoints_',str1(2),"_",str2(i),'.mat');
        data_test = importdata(folder_test);
        folder_train = strcat(t , 'Npoints_',str1(1),"_",str2(j),'.mat');
        data_train = importdata(folder_train);
        folder_match = strcat('match_' , t , 'Nmatch_', t(1:end-1) ,'.mat');
        match = importdata(folder_match);

        for n = 1:size(data_test,1)
            for m = 1:size(data_train,1)

                index1 = (i-1)*str2.length + j;
                index2 = (m-1)*size(data_test,1) + n;
                indexPairs = match{index1, index2}{1};
                matchMetric = match{index1, index2}{2};

                uniqMatch = sum(matchMetric<=dTH);
                if i==j 
                    if uniqMatch >= thPoint
                        TP(x) = TP(x) + 1;
                    else
                        FN(x) = FN(x) + 1;
                    end
                else
                    if uniqMatch >= thPoint
                        FP(x) = FP(x) + 1;
                    else
                        TN(x) = TN(x) + 1;
                    end
                end
            end
        end
    end
end
TP
TN
FP
FN

accuracy = sum(TP+TN)/sum(TP+TN+FP+FN)
precision = sum(TP)/sum(TP+FP)
recall = sum(TP)/sum(TP+FN)
toc