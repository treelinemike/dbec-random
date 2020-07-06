% restart
close all; clear all; clc;
warning('off', 'Images:initSize:adjustingMag');

% define files to overlay
%  fileList = {'LEFT-03030752000003.jpg','LEFT-03041452000002.jpg','LEFT-10062451000002.jpg','RIGHT-09010554000002.jpg','RIGHT-13062152000002.jpg'};
%fileList = {'LEFT-03030752000003.jpg','LEFT-03041452000002.jpg','LEFT-10062451000002.jpg'};
fileList = {'Slide1.jpg','Slide2.jpg','Slide3.jpg','Slide4.jpg','Slide5.jpg','Slide6.jpg','Slide7.jpg'};
% structure for all image data
imageData = [];

% store images in structure and extract bounding box parameters
for fileIdx = 1:length(fileList)
    
    % open image
    im = imread(fileList{fileIdx});
    imageData(fileIdx).raw = im;
    %     imageData(fileIdx).thsh1 = im(:,:,1) > 180 & ~(im(:,:,2) > 120);
    imhsv = rgb2hsv(im);
    imThsh1 = imhsv(:,:,1) < 0.05;
%     imThsh1 = imclose(imThsh1,strel('disk',2));
%     imThsh1 = imclose(imThsh1,strel('disk',2));
    imageData(fileIdx).thsh1 = imThsh1;
    
    % get regions
    rp = regionprops(imageData(fileIdx).thsh1,'Area','BoundingBox','Image');
    
    % determine biggest region
    bbArea = [];
    for rpIdx = 1:length(rp)
        bbArea(end+1) = prod(rp(rpIdx).BoundingBox(3:4));
    end
    [~,maxIdx] = max(bbArea);
    bb = floor(rp(maxIdx).BoundingBox);
    imageData(fileIdx).outline = rp(maxIdx).Image;
    imageData(fileIdx).bbSize = bb(3:4)';
    imageData(fileIdx).bbCrop = im(bb(2)+[0:bb(4)],bb(1)+[0:bb(3)],:);
    
end

% compute simple scaling factor for each image
% DOES NOT ACCOUNT FOR ROTATION OR LENS/PROJECTION DISTORTION!
bbSize = [imageData.bbSize];
bbScale = 1./(bbSize(1,:)/bbSize(1,1));
bbSizeNew = round(bbSize*diag(bbScale));

% compute composite boundary
imBB_composite = zeros(max(bbSizeNew(2,:)),bbSizeNew(1,1));
for imIdx = 1:length(imageData)
    
    % resize and pad images
    imFull = imresize(imageData(imIdx).bbCrop,fliplr(bbSizeNew(:,imIdx)'));
    imBB   = imresize(imageData(imIdx).outline,fliplr(bbSizeNew(:,imIdx)'));
    topPad = floor((size(imBB_composite,1)-size(imBB,1))/2);
    imBBPad = [zeros(topPad,size(imBB,2)); imBB; zeros(size(imBB_composite,1)-size(imBB,1)-topPad,size(imBB,2))];
    imageData(imIdx).imFull = [zeros(topPad,size(imFull,2),size(imFull,3)); imFull; zeros(size(imBB_composite,1)-size(imBB,1)-topPad,size(imFull,2),size(imFull,3))];
    
    % add outline to composite
    imBB_composite = imBB_composite + imBBPad;
end

% rescale composite and threshold
imBB_composite = imBB_composite/max(imBB_composite(:));
imBB_composite = imBB_composite > 0.1;

% consolidate outline
padWidth = 30;
imOutline = padarray(imBB_composite,padWidth*[1 1],0,'both');
imOutline1 = imdilate(imOutline,strel('disk',10));
imOutline2 = imerode(imOutline1,strel('disk',13));
imOutline3 = imOutline2((padWidth+1):(end-padWidth),(1+padWidth):(end-padWidth));
imshow(~imOutline3)

% extract pink patches from each image
imPatches = zeros(size(imOutline3));
allPatchAreas = zeros(length(fileList),1);
for imIdx = 1:length(imageData)
    
    % find red components
    imFull = imageData(imIdx).imFull;
    imhsv = rgb2hsv(imFull);
    imred = ((imhsv(:,:,1) < 0.15));
    
    % remove outer perimeter of patella from red mask
    imred = (imred & logical(~imdilate(imOutline3,strel('disk',10))));
    
    % extract regions, keeping only the largest ones
    rp = regionprops(imred,'Image','FilledImage','Area','BoundingBox');
    areas = [rp.Area];
    [areaSort,areaIdx] = sort(areas,'descend');
    areaIdx = areaIdx(areaSort > 30000);
    
    % overlay all patches, removing small occlusions
    currentImPatches = zeros(size(imOutline3));
    for i=1:length(areaIdx)
        bb = floor(rp(areaIdx(i)).BoundingBox);
        thisPatchImg = zeros(size(imPatches));
        thisPatchImg(bb(2)+(0:bb(4)-1),bb(1)+(0:bb(3)-1)) = rp(areaIdx(i)).Image;
        imPatch1 = imdilate(thisPatchImg,strel('disk',4));
        imPatch2 = imerode(imPatch1,strel('disk',4));
        currentImPatches = currentImPatches + imPatch2;
    end
    imPatches = imPatches + currentImPatches;
    
    % compute wear area (in pixels) in this individual image
    allPatchAreas(imIdx) = sum(currentImPatches(:));
    % fprintf('This patch area: %0.4f\n',sum(currentImPatches(:)));
end

% rescale patch overlay for red channel display
imPatchWhiteMask = (imPatches == 0);
imPatches = imPatches/max(imPatches(:));
tfParams = [0 1;max(imPatches(:)) 1]\[1;0.5];
imPatches = tfParams(1)*imPatches + tfParams(2);

% add patches to HSV image
imFinal = zeros(size(imPatches,1),size(imPatches,2),3); % Hue = 0 = red
imFinal(:,:,2) = ones(size(imFinal(:,:,2)));  % Sat = 100%
imFinal(:,:,3) = imPatches; % Intensity from # of overlapping patches

% convert to RGB image
imFinal = uint8(255*hsv2rgb(imFinal));
imFinal(:,:,1) = uint8(imFinal(:,:,1) + 255*uint8(imPatchWhiteMask));
imFinal(:,:,2) = uint8(imFinal(:,:,2) + 255*uint8(imPatchWhiteMask));
imFinal(:,:,3) = uint8(imFinal(:,:,3) + 255*uint8(imPatchWhiteMask));

% add outline to RGB image
imFinal(:,:,1) = imFinal(:,:,1) - uint8(imOutline3*255); % uint8 floors to zero
imFinal(:,:,2) = imFinal(:,:,2) - uint8(imOutline3*255); % uint8 floors to zero
imFinal(:,:,3) = imFinal(:,:,3) - uint8(imOutline3*255); % uint8 floors to zero

% show final image
imshow(imFinal);

% compute approximate patella area
totalPatchMask = imPatches < 1;  % binary mask
closedOutline = imclose(imOutline3,strel('disk',1000));
closedOutlineRPs = regionprops(closedOutline,'FilledImage');
if(length(closedOutlineRPs) > 1)
    error('Closing failed.');
end
totalPatellaMask = closedOutlineRPs.FilledImage;
patellaArea = sum(totalPatellaMask(:));

% compute area of union of all patches
patchArea = sum(totalPatchMask(:));

% display wear fractions
for fileIdx = 1:length(fileList)
    fprintf('%0.3f -> %s\n',allPatchAreas(fileIdx)/patellaArea,fileList{fileIdx});
end
fprintf('%0.3f -> total wear fraction\n',patchArea/patellaArea);
