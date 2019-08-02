global ard;
%ard = arduino();
disp(class(ard));

time = 60 * 60 * 5; %how long program runs 
run(time);

%all other params defined in rec ()
function rec (name)
    vidName = name; 

    thr  = 110;      %threshold (the lower, the less inclusive)
    minA = 1200;     %minimum area
    maxA = 500000;   %maximum area
    fps  = 30;       %frames per second
    dur  = 10;       %5 of vid file
    tOut = 60*60*5;  %time before program gives up in seconds
    lWt  = 0.0;      %how long before initial flash (after detection)
    lBtw = .5;       %how long between flashes
    lDur = .5;       %how long flash lasts
    lStr = 4.5;      %streangth of light (lower is stronger)
    numF = 4;        %number of flashes
    
    global ard;
    global cut; 
    cut = true;

    aviObject           = VideoWriter(vidName);  % Create a new AVI file
    aviObject.FrameRate = fps;                   % Set frame rate
    disp('vid setup');
    
    vid                  = videoinput('pointgrey', 1);
    vid.FramesPerTrigger = Inf;
    
    % Configure the object for manual trigger mode.
    triggerconfig(vid, 'manual');

    %Beginning to create arrays to keep track of frames where light is
    %triggered
    
    lFrames = [;];
       
    check1 = true;   %starting image aquisition

    
    %--------------------------------------------------------------------
    
    
    writeDigitalPin(ard, 'D5', 1); %Light initially turned off
    
    preview(vid); %Starting preview
    start(vid);   %Start acquiring frames, but not logging them to mem
      
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
        flushdata(vid);

        if size(props) > 0
            disp('seen a guy');
            if check1
                
                check1 = false;
                %start(vid);             %starts recording video after detection
                trigger(vid);            %Starts logging frames to mem
                
            else
                while true              %fly is detected and rec started

                    %disp('yus');

                    d = round(toc(c));  %checks timer since object was detected

                    %disp(d);
                    
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
                                lFrames(s,m) = fa;                 %sets start to laserFrames sublist
                                pause(lDur);
                                m = 2;

                                writeDigitalPin(ard, 'D5', 1);    %lights off
                                disp('light off');
                                fa = vid.FramesAcquired;    
                                lFrames(s,m) = fa;                  %sets end to laserFrames sublist
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
    
    disp('done')
    frames = getdata(vid);

    
    for f = 1:size(frames, 4)
        for grp = 1:size(lFrames)
            if f > lFrames(grp, 1) && f < lFrames(grp, 2)
                
                frames(931:950,1251:1270,:,f) = 255*ones(20,20);
                frames(936:945,1256:1265,:,f) = zeros(10,10);
            end
        end 
    end
    
    open(aviObject);
    flushdata(vid);
    delete(vid);

    writeVideo(aviObject, frames);
    close(aviObject);    
end


function run (time)    
    a   = tic;
    num = 2;      %This is the number the first file will end with (should probably be 1 or 0)
    b   = toc(a);
    global ard;
    %ard = arduino('com7', 'uno');
    while b < time
        writePWMVoltage(ard, 'D5',3);
        name = ['flyVid' num2str(num)];
        rec(name);
        disp('file made');
        num = num+1;
        b = toc(a);
        
    end    
end

