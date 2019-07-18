


function Jonas2 ()
    vidName = 'myVideo.avi';  

    thr  = 100;
    minA = 100;
    maxA = 500000;
    fps  = 15;
    dur  = 10; %in seconds
    
    global cut; 
    cut = true;
    
    trig = false;
    
    h_fig = figure('Position', [10 10 90 60]);
    set(h_fig,'KeyPressFcn',@kF);

    ard       = arduino('com7', 'uno');
    vid       = videoinput('pointgrey', 1);
    aviObject = VideoWriter(vidName);  % Create a new AVI file
    
    check = true;
    
%     fArr = {@film @flash};
%     arguments = {vid, aviObject, fpDu; vid, aviObject, ard};
%     solutions = cell(1,2);                 % initialize the solution 
   
    start(vid);
    open(aviObject);
    pause(1);    
    preview(vid);

    while cut
        im  = getsnapshot(vid);
        im  = imresize(im, 0.33);
        
        tm  = imgaussfilt(im, 12);
        tIm = tm < thr;

        fIm = bwareafilt(tIm,[minA maxA]);
        fIm = imresize(fIm, .5);
        
        %montage({im, fIm});
        props = regionprops(fIm, 'Area', 'Perimeter','PixelIdxList');

        if size(props) > 0
            %disp('ls');
            
            if check
                iT    = tic;
                check = false;
            end
            
            trig = true;
            %disp('Triggered');
        
        elseif trig == false
            writeDigitalPin(ard, 'D5', 1); %lights off
            disp('No');
            pause(1)
            %imshowpair(fIm, im, 'montage');
        end
        
        if trig
            writeVideo(aviObject, im);
            %disp("written");
            
            nT = toc(iT);
            
            if mod(nT, dur/3)
                %disp('flash');
                flash(im, fIm, ard );
            else
                %disp('wait');
                writeDigitalPin(ard, 'D5', 1); %lights off
            end
                        
            if nT == dur
                disp('complete');
                break 
            end
        end

%             
%        end
    end
end

function kF (h, ~)
    global cut; 
    cut = false;
    close(h);
       
    close(aviObject);
    delete(vid);
    disp('done');
end

function flash(im, fIm, ard)
   
    writeDigitalPin(ard, 'D5', 0); %lights on
    %disp('Something there');
    montage({fIm, im});
    return;
end
