
function Jonas3 ()
    vidName = 'myVideo.avi';  

    thr  = 80;      %threshold (the lower, the less inclusive)
    minA = 100;     %minimum area
    maxA = 500000;  %maximum area
    fps  = 15;      %frames per second
    dur  = 10;      %duration of light flashign in seconds
    tOut = 60;      %time before program gives up in seconds
    lWt  = 5.0;     %how long before initial flash (after detection)
    lBtw  = .5;     %how long between flashes
    lDur = .5;      %how long flash lasts
    lStr = 4.5;       %streangth of light (lower is stronger)
    
    global cut; 
    cut = true;

    aviObject           = VideoWriter(vidName);  % Create a new AVI file
    aviObject.FrameRate = fps;
    open(aviObject);
    
    ard                  = arduino('com7', 'uno');
    vid                  = videoinput('pointgrey', 1);
    vid.FramesPerTrigger = Inf;

       
    check1 = true;   %starting image aquisition

    writeDigitalPin(ard, 'D5', 1);
    
    preview(vid);
    
    %VIDEO ACQUISITION STARTS HERE AUTOMATICALLY. FOR A CONDITIONAL
    %START, PUT IT RIGHT HERE :)
    
    start(vid);
    
    a = tic;
    b = toc(a);
    
    
    while b <= tOut
        im  = getsnapshot(vid);
        im  = imresize(im, 0.33);
        
        tm  = imgaussfilt(im, 12);
        tIm = tm < thr;

        fIm = bwareafilt(tIm,[minA maxA]);
        fIm = imresize(fIm, .5);
        props = regionprops(fIm, 'Area', 'Perimeter','PixelIdxList');
        
        c = tic;     %baseline for timer d (when object is detected)
        
        if size(props) > 0
            if check1
                lOn    = vid.FramesAcquired;
                check1 = false;
            
            else
                while true              %fly is detected and rec started

                    disp('yus');

                    d = round(toc(c));  %checks timer since object was detected

                    disp(d);
                    if mod(d, lWt)   %initial wait time over
                        disp('butt');
                        while d < dur %once waitime over
                            writePWMVoltage(ard, 'D5', lStr); %lights on
                            disp('light on');
                            pause(lDur);
                            writeDigitalPin(ard, 'D5', 1);
                            disp('light off');
                            pause(lBtw)
                            d = round(toc(c));   %checks timer since object was detected
                        end
                        break          %break out of while true loop
                    
                    elseif d < lWt   %initial wait time not reached
                        disp('not yet'); 
                    end
                    
                end
                break    %break out of overall loop when vid is over
            end
            
        else
            b = toc(a);  %refreshes timer that times out program
        end
        
        writeDigitalPin(ard, 'D5', 1);  %this is if nothing's been detected yet
        disp('nah');
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
    