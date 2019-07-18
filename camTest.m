% fps  = 15;
% dur  = 10; %in seconds
% 
% vid = videoinput('pointgrey', 1);
% 
% start(vid);
% pause(1);
% 
% preview(vid);
% 
% while true
% im  = getsnapshot(vid);
% im  = imresize(im, 0.33);
% imshow([im, im]);
% 
% 
% end
% 
 thr  = 80;
% minA = 100;
% maxA = 500000;
% fps  = 15;
% dur  = 10; %in seconds
% fpDu = fps * dur;


global cut; 
cut = true;
%h_fig = figure;
%set(h_fig,'KeyPressFcn',@kF);

%ard = arduino('com7', 'uno');
vid = videoinput('pointgrey', 1);
aviObject = VideoWriter('myVideo.avi');  % Create a new AVI file

%triggerconfig(vid, 'manual');
%vid.FramesPerTrigger = fps * dur;

%fArr = {@film @flash};
%arguments = {vid, aviObject, fpDu; vid, aviObject, ard};
%solutions = cell(1,2);                 % initialize the solution 

start(vid);
open(aviObject);
pause(1);
preview(vid)

while true
    im  = getsnapshot(vid);
    im  = imresize(im, 0.33);
    
    

    tm  = imgaussfilt(im, 12);
    tIm = tm < thr;

    %fIm = bwareafilt(tIm,[minA maxA]);
    %imshow([im, fIm]);
    %props = regionprops(fIm, 'Area', 'Perimeter','PixelIdxList');

    imshow([im, tIm]);
    
    writeVideo(aviObject, im);
    
%         if size(props) > 0
%             flash(vid, aviObject, ard);  
%         end


%             else
%                 writeDigitalPin(ard, 'D5', 1); %lights off
%                 disp('No');
%                 pause(1)
%                 %imshowpair(fIm, im, 'montage');
%        end
end

delete(vid)