
function Jonas3 ()
    vidName = 'myVideo.avi';  

    thr  = 80;
    minA = 100;
    maxA = 500000;
    fps  = 15;
    dur  = 10; %in seconds
    
    global cut; 
    cut = true;

    aviObject = VideoWriter(vidName);  % Create a new AVI file
    open(aviObject);
    
    %aviObject.FrameRate = fps;
    ard       = arduino('com7', 'uno');
    vid       = videoinput('pointgrey', 1);
    vid.FramesPerTrigger = Inf;

       
    check = true;
    
    writeDigitalPin(ard, 'D5', 1);
    
    start(vid);
    preview(vid);
    
    b = tic;
    e = toc(b);
    
    
    while e <= dur
        im = getsnapshot(vid);
        im  = imresize(im, 0.33);
        
        tm  = imgaussfilt(im, 12);
        tIm = tm < thr;

        fIm = bwareafilt(tIm,[minA maxA]);
        fIm = imresize(fIm, .5);
        props = regionprops(fIm, 'Area', 'Perimeter','PixelIdxList');
        
        if size(props) > 0
            if check
                lOn = vid.FramesAcquired;
                check = false;
            end
            disp('yus');

            e = round(toc(b));
            
            if mod(e, 5)
                writeDigitalPin(ard, 'D5', 0); %lights on
            else
                writeDigitalPin(ard, 'D5', 1);
            end
            
        else
            writeDigitalPin(ard, 'D5', 1);
            disp('nah');
        end
        
    end
    
    frames = getdata(vid);
    
    
    for f = 1:size(frames, 4)
        
        if f > lOn
            frames(931:950,1251:1270,:,f) = 255*ones(20,20);
            frames(936:945,1256:1265,:,f) = zeros(10,10);
            
        end        
    end
    
    writeVideo(aviObject, frames);
    close(aviObject);
    delete(vid);
    