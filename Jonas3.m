time = 60 * 10;  %how long program runs 
run(time);

%all other params defined in rec ()
function rec (name)
    vidName = name; 

    thr  = 50;      %threshold (the lower, the less inclusive)
    minA = 10000;   %minimum area
    maxA = 500000;  %maximum area
    fps  = 30;      %frames per second
    dur  = 10;      %duration of light flashign in seconds
    tOut = 60;      %time before program gives up in seconds
    lWt  = 0.0;     %how long before initial flash (after detection)
    lBtw = .5;      %how long between flashes
    lDur = .5;      %how long flash lasts
    lStr = 4.5;     %streangth of light (lower is stronger)
    numF = 4;       %number of flashes
    
    global cut; 
    cut = true;

    aviObject           = VideoWriter(vidName);  % Create a new AVI file
    aviObject.FrameRate = fps;
    open(aviObject);
    
    ard                  = arduino('com7', 'uno');
    vid                  = videoinput('pointgrey', 1);
    vid.FramesPerTrigger = Inf;

    %Beginning to create arrays to keep track of frames where light is
    %triggered and frames where light is turned off
    
    lFrames = [;];
    %dFrames = [];
       
    check1 = true;   %starting image aquisition

    
    %--------------------------------------------------------------------
    
    
    writeDigitalPin(ard, 'D5', 1);
    
    %preview(vid);
      
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
                check1 = false;
                start(vid);             %starts recording video after detection
            
            else
                while true              %fly is detected and rec started

                    %disp('yus');

                    d = round(toc(c));  %checks timer since object was detected

                    disp(d);
                    
                    if mod(d, lWt)   %initial wait time over
                        %disp('butt');
                        count = 0;
                        while d < dur                             %once waitime over
                            s          = size(lFrames,1) + 1;     %set variables for
                            m          = 1;                       %light frames
                            
                            if count < numF
                                
                                writePWMVoltage(ard, 'D5', lStr); %lights on
                                disp('light on');
                                fa = vid.FramesAcquired;
                                lFrames(s,m) = fa;  
                                pause(lDur);
                                m = 2;

                                writeDigitalPin(ard, 'D5', 1);    %lights off
                                disp('light off');
                                fa = vid.FramesAcquired;
                                lFrames(s,m) = fa;
                                disp(fa);
                                pause(lBtw)
                                count = count + 1;
                            end
                            
                            d = round(toc(c));   %checks timer since object was detected
                        end
                        break          %break out of while true loop
                    
                    elseif d < lWt   %initial wait time not reached
                        %disp('not yet'); 
                    end
                    
                end
                break    %break out of overall loop when vid is over
            end
            
        else
            b = toc(a);  %refreshes timer that times out program
        end
        
        writeDigitalPin(ard, 'D5', 1);  %this is if nothing's been detected yet
        %disp('nah');
    end
    
    
    frames = getdata(vid);

    for f = 1:size(frames, 4)
        for grp = 1:size(lFrames)
            if f > lFrames(grp, 1) && f < lFrames(grp, 2)
                
                frames(931:950,1251:1270,:,f) = 255*ones(20,20);
                frames(936:945,1256:1265,:,f) = zeros(10,10);
            end
        end 
    end
    
    writeVideo(aviObject, frames);
    close(aviObject);
    delete(vid);
    
end


function run (time)
    
    a   = tic;
    num = 1;
    b   = toc(a);
    while b > time
        writeDigitalPin(ard, 'D5', 1);
        name = ['flyVid' num2str(num)];
        rec(name);
        num =+ 1;
        b = toc(a);
        pause()
    end    
end

