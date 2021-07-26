% Matlab code for FBR
% The reconstruction code is made by Lei ZHU. (LKB/ENS,Lei ZHU)
% Authors: Lei Zhu/ Fernando Soldevila / Claudio Moretti/ Alexandra d'Arco/Antoine Boniface/Xiaopeng Shao/Hilton B. de Aguiar/Sylvain Gigan
% contact: leizhu201806@hotmail.com // version 07/2021
% The presneted data is corresponding to the Fig.2b of manuscript
% copyright belongs to Lei ZHU
% If you use our code, please cite our paper.
%%
clear all, close all, clc;
%% Loading data and parameters (Experimental data set)
load('dataset.mat')% loads the images and the parameters of the iamge
% Lcam and ypixel are the parameters of image. if you want to play with your
% data (xxx.mat), please change them.
%% Demixing procedure see: Matlab help (COMMAND IN MATLAB: doc nnmf)
EstimatedNumber = 16; % the estimated rank \rho
fprintf('Start of demixing speckle.\n\n')
% # first NNMF: TO INITILIZE THE SECOND NNMF
opt = statset('MaxIter',30,'Display','final');
[W0,H0] = nnmf(FluoMATfilt,EstimatedNumber,'Replicates',10,...
    'options',opt,'algorithm','mult');
% # SECOND NNMF
opt = statset('MaxIter',1000,'Display','iter','TolFun',1e-6);
[W,H] = nnmf(FluoMATfilt,EstimatedNumber,'W0',W0,'H0',H0,...
    'options',opt,'algorithm','als');
fprintf('End of demixing speckle.\n\n');
clear FluoMATfilt % clean the variable
%% display the demixed patterns and store the fingerprints in variable 'M'.
% the size of image
global xpixel ypixel
xpixel = Lcam-2; % the size of the image in the X direction
ypixel = Ccam; % the size of the image in the Y direction
M = cell(EstimatedNumber,1);% create the empty matrix to store the fingerprint
for kk=1:EstimatedNumber
    M{kk} = reshape(H(kk,:),xpixel,ypixel);
    figure;
    imagesc(M{kk}),daspect([1 1 1]), title('Fluo speckle - raw data'), colormap hot;
    pause(0.5)
end
%% Deconvolution parameters
mu = 20;
opts.rho_r   = 1;
opts.rho_o   = 1;
opts.beta    = [1.0 1.0 0];
opts.gamma  = 2;
opts.print   = false;
opts.alpha   = 0.1;
opts.tol   = 1e-5;
opts.method  = 'l2';
opts.max_itr  = 100;
%% Deconvolution procedure
close all;
O = cell(EstimatedNumber,1);%Create the empty for the partial iamges
recon_image = zeros(xpixel,ypixel,EstimatedNumber);
Maximum_intensity = zeros(EstimatedNumber,EstimatedNumber);
xx = zeros(EstimatedNumber,EstimatedNumber);
yy = zeros(EstimatedNumber,EstimatedNumber);
for k=1:EstimatedNumber
    PSF = M{k};
    for i = 1:EstimatedNumber
        out = deconvtv(M{i},PSF, mu, opts);% Deconvolution for FBR
        recon_image(:,:,i) = out.f;
        [xx_temp,yy_temp] = find(recon_image(:,:,i) == max(max(recon_image(:,:,i))));% Record the position of maximum value of each image
        if size(xx_temp,1)>1 || size(yy_temp,1)>1
            xx(i,k) = NaN;
            yy(i,k) = NaN;
        else
            xx(i,k) = floor(mean(xx_temp(:)));
            yy(i,k) = floor(mean(yy_temp(:)));
        end
        Maximum_intensity(i,k) = max(max(recon_image(:,:,i)));% Record the maximum value of each image
    end
    O{k}=sum(recon_image,3);% the partial image O_{k} by summing up
end
%% display the different partial images
figure;
for jj=1:EstimatedNumber
    subplot(floor(sqrt(EstimatedNumber)+1),floor(sqrt(EstimatedNumber)+1),jj),imshow(O{jj},[]);colormap hot; title(['O_ #',num2str(jj)]), colormap hot;
    pause(0.1)
end
%% calculating the relative position by looking at the maximum value of pairwise deconvolution
% and emerge all partial images into one image with respect to each other according to the relative position
% # Because the current code just can search in one direction, we need two
% times reconstruction
% # first reconstruction: it is used to find the edge(labled as: first)
First_pattern = 2;
[Reached_Pattern,Global_image] = mergeimages(Maximum_intensity,O,EstimatedNumber,xx,yy,xpixel,ypixel,First_pattern);
% # the first pattern should not be noise pattern
figure;
imshow(Global_image(250+(-100:100),250+(-100:100)),[]);colormap hot;
% # second reconstruction: it is used to reconstruct the full object
[Reached_Pattern,Global_image] = mergeimages(Maximum_intensity,O,EstimatedNumber,xx,yy,xpixel,ypixel,Reached_Pattern(end));
figure;
imshow(Global_image(250+(-100:100),250+(-100:100)),[]);colormap hot;

