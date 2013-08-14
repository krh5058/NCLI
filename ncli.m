function ncli
% NCLI
% Presentation script for word discrimination task.
% Usage: ncli
% Prompts:
%   - Subject ID. 3 digit value corresponding to subject number and session
%   number
%   - Session overwrite or continue.  Allows for either entire session
%   restart or specify run number to begin on if session is already
%   present.
%   - Present practice.  If no, practice is entirely skipped.
%   - Auto-trigger use.  If yes, scanner trigger will begin sequence.  If
%   no, then manual input of TR values for DisDaqs to skip will be
%   requested.
%
% Presentation sequence:
%   1) Subject and session prompt
%   2) Practice prompt
%   3) Instruction screen (1)
%   4) Wait for experimenter spacebar press
%   5) Practice sequence (5 trials long)
%   6) Trigger prompt
%   7) Instruction screen (2)
%   8) Wait for experimenter spacebar press
%   9) Wait for auto-trigger or scanner operator spacebar
%   10) Task run (90 trials long)
%   11) Repeats 8-10 until run number (3) is reached
%
% Input for pres and prac.  Script searches within sub-directory 'stim' for
% a 'stim.xlsx'.  This is an excel file without headers and columns 1-3
% associated with Spanish/English/Homograph, respectively.  Due to
% experimental restrictions, Homographs must be equal or less than Spanish
% words.  Practice randomization is performed by shuffling all words within
% columns.  Then, a randomized selection between English and Spanish words
% are chosen to be inserted into cell, 'pres'.  If a Spanish word is chosen
% then a Homograph is chosen.  If a homograph space is empty, it is
% skipped.  Afterwards 'pres' is subdivided into three runs, according to
% trial length (90).  5 additional runs are taken for 'prac', the
% presentation cell for the practice session.
%
% Output.  Output is placed in the respective session folder within the
% subject's data folder in the sub-directory 'data'.  Each of the three
% run's including the practice data is recorded and placed within this
% folder.  'E.mat', or the efficiency calculations for each run is saved.
% A diary file is recorded for logging purposes as well.
%
% Created by Ken Hwang, M.S.
% Last modified 10/15/12
% Requested by Angela Chouinard
% PSU, SLEIC, Dept. of Psychology

PsychJavaTrouble;
rand('state',sum(clock*100));
randn('state',sum(clock*100));
% rng('shuffle'); % Initialize rng
KbName('UnifyKeyNames');
akey = KbName('a'); % Spanish
bkey = KbName('b'); % English
esckey = KbName('ESCAPE');
spkey = KbName('Space');
trial_length = 90; % Default

% Directory of this script
file_str = mfilename('fullpath');
[file_dir,~,~] = fileparts(file_str);

% Subj ID prompt
subj_prompt={'Subject ID:'};
subj_name='Enter Subject ID (ABC) AB = Subject #, C = Session #';
subj_numlines=1;
subj_defaultanswer={'111'};
s_name = inputdlg(subj_prompt,subj_name,subj_numlines,subj_defaultanswer);
subjID_double = str2double(regexp(s_name{1},'\d','match'));

% File directory organization
if length(num2str(subjID_double,'%d')) == 3
    s_ID = s_name{1}(1:2); % Subject ID
    sess_ID = s_name{1}(3); % Run Number
    
    [~,d] = system(['dir /ad/b "' file_dir filesep 'data"']);
    d = regexp(d(1:end-1),'\n','split');
    
    if any(strcmp(d,s_ID))
        [~,d2] = system(['dir /ad/b "' file_dir filesep 'data' filesep  s_ID '"']);
        d2 = regexp(d2(1:end-1),'\n','split');
        if any(strcmp(d2,sess_ID))
            sessOverwrite = questdlg(['Session ' sess_ID ' for subject ' s_ID ' already exists. Select Option.'], ...
                'NCLI: Session Overwrite?', ...
                'Overwrite','Continue Run','Abort','Continue Run');
            switch sessOverwrite
                case 'Overwrite'
                    fclose('all');
%                     rmdir([file_dir filesep 'data' filesep  s_ID filesep sess_ID],'s');
                    system(['rmdir /S ' file_dir filesep 'data' filesep  s_ID filesep sess_ID]);
                    % Remove previous run directory and contents
                    sess_Dir = [file_dir filesep 'data' filesep s_ID filesep sess_ID];
                    run_double = 1;
                    mkdir(sess_Dir); % Make session directory
                    fprintf('\n\n\nNCLI: Overwrite %s\n\n\n',sess_Dir);
                case 'Continue Run'
                    % Subj ID prompt
                    run_prompt={'Run number:'};
                    run_name='Enter run number (1-3):';
                    run_numlines=1;
                    run_defaultanswer={'1'};
                    run_options.Resize='on';
                    run_str = inputdlg(run_prompt,run_name,run_numlines,run_defaultanswer,run_options);
                    run_double = str2double(regexp(run_str{1},'\d','match'));
                    if isempty(find(1:3==run_double, 1))
                        error('Enter valid run number (1-3).');
                    end
                    sess_Dir = [file_dir filesep 'data' filesep s_ID filesep sess_ID];
                    fprintf('\n\n\nNCLI: Working directory %s\n\n\n',sess_Dir);
                otherwise
                    fprintf('\n\n\nNCLI: User Cancelled.\n\n\n');
                    %clear all
                    %close all
                    return;
            end
        else
            sess_Dir = [file_dir filesep 'data' filesep s_ID filesep sess_ID];
            mkdir(sess_Dir); % Make session directory
            run_double = 1;
            fprintf('\n\n\nNCLI: Created %s\n\n\n',sess_Dir)
        end
    else
        mkdir([file_dir filesep 'data' filesep s_ID]); % Make subject directory
        sess_Dir = [file_dir filesep 'data' filesep s_ID filesep sess_ID];
        mkdir(sess_Dir); % Make session directory
        run_double = 1;
        fprintf('\n\n\nNCLI: Created %s\n\n\n',sess_Dir)
    end
else
    %clear all
    %close all
    error('Invalid subject input.  Entry must be equal to 3 digits long.');
end

% Initiate diary
diary([sess_Dir filesep s_name{1} '_Diary_' datestr(now,30)]);
diary on

% Loading stimulus text
stim = load([file_dir filesep 'stim' filesep 'stim.mat']);
stim = stim.stim;
cond_cell = {'Spanish','English','Homograph'};
s_length(1) = length(find(cellfun(@(y)(~isempty(y)),stim(:,1))));
s_length(2) = length(find(cellfun(@(y)(~isempty(y)),stim(:,2))));
s_length(3) = length(find(cellfun(@(y)(~isempty(y)),stim(:,3))));
stim = stim(1:max(s_length),1:3); % Length is based on longest list
stim = [Shuffle(stim(:,1)),Shuffle(stim(:,2)),Shuffle(stim(:,3))]; % Randomize (leave empty cells)

pres_n = length(find(cellfun(@(y)(~isempty(y)),stim)));
pres_construct = cell([pres_n 2]); % Pre-allocate
count = [1 1 1];
skipflag = 0;

for i = 1:pres_n
    if skipflag
        skipflag = 0; % Turn off skip
        continue; % Skip iteration
    else
        r_i = randi(1:2); % Randomize between Spanish/English
        if count(r_i) > s_length(r_i) % If length reached
            r_i = find(1:2~=r_i); % Select alternative
        end
        pres_construct(i,1) = stim(count(r_i),r_i);
        pres_construct{i,2} = r_i;
        count(r_i) = count(r_i) + 1;
    end
    
    if r_i == 1 % If Spanish
        if count(3) > max(s_length) % If count(3) is reached
            %         elseif randi(0:1) % 50% chance to add homograph
        elseif ~isempty(stim{count(3),3}) % If value is not empty
            pres_construct(i+1,1) = stim(count(3),3); % Add to next
            pres_construct{i+1,2} = 3; % Add to next
            count(3) = count(3) + 1;
            skipflag = 1;
        else
            count(3) = count(3) + 1; % Add to count to bypass empty cell
        end
    end
end
prac_check = cell2mat(cellfun(@(y)([y==1 y==2 y==3]),pres_construct(trial_length*3 + 1:end,2),'UniformOutput',false)); % Spanish and english logicals
prac_check = [prac_check(:,2) sum([prac_check(:,1) prac_check(:,3)],2)];; % Considering Spanish and Homograph the same
% Making sure at least one Spanish word and one English word is present in
% practice
prac_check_i = 1;
while all(any(prac_check(prac_check_i:prac_check_i+4,:)))
    prac_check_i = prac_check_i + 1;
end
prac = pres_construct(trial_length*3 + prac_check_i:trial_length*3 + prac_check_i+4,:); % Taking 5 trials for practice
pres_construct = pres_construct(1:trial_length*3,:); % Clip according to trial length and 3 trials
pres = cell([trial_length,3,2]);
pres(:,:,1) = [pres_construct(1:trial_length,1),pres_construct(trial_length+1:trial_length*2,1),pres_construct(trial_length*2 + 1:trial_length*3,1)];
pres(:,:,2) = [pres_construct(1:trial_length,2),pres_construct(trial_length+1:trial_length*2,2),pres_construct(trial_length*2 + 1:trial_length*3,2)];

t = RandSample(3:.25:5,[size(pres,1) size(pres,2)]); % ISI
prac_isi = RandSample(3:.25:5,[size(prac,1) 1]); % Practice ISI

% Efficiency calculations
E(1) = efficiency(t(:,1),3);
E(2) = efficiency(t(:,2),3);
E(3) = efficiency(t(:,3),3);
save([sess_Dir filesep 'E.mat'],'E'); % Saving variable to session directory

[win_w,~] = Screen('WindowSize',max(Screen('Screens')));

% Practice prompt
prac_flag = questdlg(['Session ' sess_ID ' for subject ' s_ID '. Initiate Practice?'], ...
    'NCLI: Practice Prompt.');

close(gcf);

% Practice switch
switch prac_flag
    case 'Yes'
        fid = fopen([sess_Dir filesep s_name{1} '_Practice_' datestr(now,30) '.csv'],'a');
        fprintf(fid,'%s,%s,%s,%s,%s,%s,%s,%s\n','Subject','Trial','Onset','ISI','TrialType','Stimulus','Acc','RT');
        prac_t = zeros([length(prac_isi) 1]); % VBL recording
        prac_resp = zeros([length(prac_isi) 1]); % Pres recording
        prac_acc = zeros([length(prac_isi) 1]); % Accuracy recording
        prac_rt = zeros([length(prac_isi) 1]); % Reaction time recording
        
        % Screen lockdown
        ListenChar(2);
        ShowHideWinTaskbarMex(0);
        HideCursor;
        
        % Screen Capture
        wobj = WordDisp(prac);
        
        % Instruction text auto-formatting
        txt_i = 30; % Default
        itxt = WrapString('In this task you will be presented with Spanish words and non-Spanish words. If the word is in Spanish, push the top button on the trigger grip with your thumb. If it is an example of a word in another language, push the front button with your index finger. \n\nPlease answer as QUICKLY and ACCURATELY as possible while moving as LITTLE as possible. When you are ready to begin, please let the experimenter know.',txt_i);
        txt_r = Screen('TextBounds',wobj.w,itxt);
        while txt_r(3) <= (win_w - 100) % According to width
            txt_i = txt_i + 1; % Scale up
            itxt = WrapString('In this task you will be presented with Spanish words and non-Spanish words. If the word is in Spanish, push the top button on the trigger grip with your thumb. If it is an example of a word in another language, push the front button with your index finger. \n\nPlease answer as QUICKLY and ACCURATELY as possible while moving as LITTLE as possible. When you are ready to begin, please let the experimenter know.',txt_i);
            txt_r = Screen('TextBounds',wobj.w,itxt); % Check bounds
        end
        
        % Instructions text and waiting for experimenter
        wobj.text(itxt);
        RestrictKeysForKbCheck(spkey);
        fprintf('\n\n\nBeginning practice.\n\n\n');
        fprintf('\n\n\nPress spacebar to continue.\n\n\n');
        KbStrokeWait;
        
        RestrictKeysForKbCheck([akey bkey esckey]);
        wobj.fixate; % Fixate draw
        start_t = Screen('Flip',wobj.w); % Start Flip
        WaitSecs(RandSample(6:.0001:8)); % Initial fixation wait
        
        for prac_i = 1:size(prac,1)
            wobj.word; % Word draw
            vbl = Screen('Flip',wobj.w);
            prac_t(prac_i) = vbl - start_t; % Onset
            ITI = 1+prac_isi(prac_i); % Set Max Interval
            keyIsDown = 0; % Reset
            flip_flag = 0;
            %     wobj.fixate; % Fixate draw
            %     Screen('Flip',wobj.w,pres_t(pres_i)+1); % Execute screen flip in 1s
            while GetSecs - vbl <= ITI % While less than ITI
                if ~keyIsDown
                    [keyIsDown,secs,keyCode] = KbCheck;
                    if keyIsDown
                        if find(keyCode)==esckey
                            % Screen release
                            Screen('CloseAll');
                            ListenChar(0);
                            ShowHideWinTaskbarMex(1);
                            ShowCursor;
                            fclose(fid);
                            %clear all
                            %close all
                            return; % Exit function
                        end
                        if secs <= vbl+1 % If less than a second
                            wobj.fixate; % Fixate draw
                            fix_t = Screen('Flip',wobj.w); % Execute screen flip
                            prac_resp(prac_i) = find(keyCode);
%                             disp(KbName(prac_resp(prac_i))); % Temp
                            prac_rt(prac_i) = secs - vbl;
                            WaitSecs(prac_isi(prac_i)); % Wait out ITI
                            break; % Break while
                        else % Greater than a second and press
                            prac_resp(prac_i) = find(keyCode);
                            prac_rt(prac_i) = secs - vbl;
                        end
                    end
                    if secs > vbl+1 && ~flip_flag % If greater than a second and no press
                        wobj.fixate; % Fixate draw
                        fix_t = Screen('Flip',wobj.w); % Execute screen flip
                        flip_flag = 1;
                    end
%                     try
%                         disp(KbName(prac_resp(prac_i))); % Temp
%                     end
                end
            end
            % Accuracy check
            if any(prac{prac_i,2}==[1 3]) % Spanish condition
                if prac_resp(prac_i)==akey
                    prac_acc(prac_i) = 1;
                end
            else % English condition
                if prac_resp(prac_i)==bkey
                    prac_acc(prac_i) = 1;
                end
            end
            fprintf(fid,'%s,%d,%6.4f,%1.2f,%s,%s,%d,%6.4f\n',s_name{1},prac_i,prac_t(prac_i),prac_isi(prac_i),cond_cell{prac{prac_i,2}},prac{prac_i,1},prac_acc(prac_i),prac_rt(prac_i));
        end
        
        % Screen release
        Screen('CloseAll');
        ListenChar(0);
        ShowHideWinTaskbarMex(1);
        ShowCursor;
        fclose(fid);
        
    case 'No'
        fprintf('Practice skipped.');
    case 'Cancel'
        disp('User Aborted');
        %clear all
        %close all
        return;
end

% Trigger input
useMCC_Flag = questdlg('Use trigger from scanner?'); % Ask for auto-trigger

switch useMCC_Flag
    case 'Yes'
        useMCC_Flag = 1;
        
        if ispc
            % Starting MCC_dio
            if( useMCC_Flag )
                MCC_dio = digitalio( 'mcc' ,'0' );
                addline( MCC_dio, 0, 0, 'in' );
                start( MCC_dio );
            end % END - if( useMCC_Flag )
        elseif ismac
            DAQdeviceIndex = DaqFind;
        end
        
    case 'No'
        
        prompt={'Enter TR:'};
        name='TR for manual start';
        numlines=1;
        defaultanswer={'2'};
        answer=inputdlg(prompt,name,numlines,defaultanswer);
        TR = str2double(answer);
        
        if isempty(TR)
            %clear all
            %close all
            error('User cancelled.');
        end
        
        useMCC_Flag = 0;
    case 'Cancel'
        return;
end % End switch

close(gcf);

for trial_i = run_double:3 % Start from run_double
    
    % Screen lockdown
    ListenChar(2);
    ShowHideWinTaskbarMex(0);
    HideCursor;
    
    % Screen Capture and object initialize
    clear wobj
    wobj = WordDisp(pres(:,trial_i));
    if trial_i==run_double % Display if first run  
        txt_e = 30; % Default
        endptxt = WrapString('You are now about to begin the experiment. Remember, the top button is for Spanish words and the front button is for non-Spanish words. Please respond as quickly and accurately as you can to each item while moving as little as possible.\n\nWhen you are ready to begin, please let the experimenter know.',txt_e);
        txt_r = Screen('TextBounds',wobj.w,endptxt);
        while txt_r(3) <= (win_w - 100) % According to width
            txt_e = txt_e + 1; % Scale up
            endptxt = WrapString('You are now about to begin the experiment. Remember, the top button is for Spanish words and the front button is for non-Spanish words. Please respond as quickly and accurately as you can to each item while moving as little as possible.\n\nWhen you are ready to begin, please let the experimenter know.',txt_e);
            txt_r = Screen('TextBounds',wobj.w,endptxt); % Check bounds
        end
        wobj.text(endptxt);
    end
    
    % Wait for experimenter
    RestrictKeysForKbCheck(spkey);
    fprintf('\n\n\nBeginning run %d.\n\n\n',trial_i); % Display run number
    fprintf('\n\n\nPress spacebar to continue.\n\n\n');
    KbStrokeWait;
    
    % Trigger/Manual
    if( useMCC_Flag ) % If using auto-trigger
        
        Screen('FillRect', wobj.w, 127);
        DrawFormattedText( wobj.w,'Wait.','center', 'center', 0);
        Screen( 'Flip', wobj.w );
        
        if ispc
            while(  ~getvalue( MCC_dio )  ) % Wait for trigger
            end % END - while(  ~getvalue( MCC_dio )  )
        elseif ismac
            while DaqDIn(DAQdeviceIndex,1) == 254 % Wait for trigger
            end
        end
        
    else % Manual
        Screen('FillRect', wobj.w, 127);
        DrawFormattedText(wobj.w,WrapString('Waiting for scanner operator to press spacebar.',20),'center', 'center', 0);
        Screen( 'Flip', wobj.w  );
        
        RestrictKeysForKbCheck(spkey);
        KbStrokeWait;
        
        Screen('FillRect', wobj.w, 127);
        DrawFormattedText(wobj.w,'Wait.','center', 'center', 0);
        Screen( 'Flip', wobj.w  );
        
        WaitSecs(2*TR + .75); % 2 times TR pulse wait + .75 computer delay
        
    end % END - if( useMCC_Flag )
    
    fid = fopen([sess_Dir filesep s_name{1} '_Run' int2str(trial_i) '_' datestr(now,30) '.csv'],'a');
    fprintf(fid,'%s,%s,%s,%s,%s,%s,%s,%s\n','Subject','Trial','Onset','ISI','TrialType','Stimulus','Acc','RT');
    pres_t = zeros([length(t(:,trial_i)) 1]); % VBL recording
    resp = zeros([length(t(:,trial_i)) 1]); % Pres recording
    acc = zeros([length(t(:,trial_i)) 1]); % Accuracy recording
    rt = zeros([length(t(:,trial_i)) 1]); % Reaction time recording
    
    wobj.fixate; % Fixate draw
    start_t = Screen('Flip',wobj.w); % Start Flip
    RestrictKeysForKbCheck([akey bkey esckey]);
    WaitSecs(RandSample(6:.0001:8)); % Initial fixation wait
    
    for pres_i = 1:length(t(:,trial_i))
        wobj.word; % Word draw
        vbl = Screen('Flip',wobj.w);
        pres_t(pres_i) = vbl - start_t; % Onset
        ITI = 1+t(pres_i,trial_i); % Set Max Interval
        keyIsDown = 0; % Reset
        flip_flag = 0;
        while GetSecs - vbl <= ITI % While less than ITI
            if ~keyIsDown
                [keyIsDown,secs,keyCode] = KbCheck;
                if keyIsDown
                    if find(keyCode)==esckey
                        % Screen release
                        Screen('CloseAll');
                        ListenChar(0);
                        ShowHideWinTaskbarMex(1);
                        ShowCursor;
                        fclose(fid);
                        %clear all
                        %close all
                        return; % Exit function
                    end
                    if secs <= vbl+1 % If less than a second
                        wobj.fixate; % Fixate draw
                        fix_t = Screen('Flip',wobj.w); % Execute screen flip
                        resp(pres_i) = find(keyCode);
%                         disp(KbName(resp(pres_i))); % Temp
                        rt(pres_i) = secs - vbl;
                        WaitSecs(t(pres_i,trial_i)); % Wait out ITI
                        break; % Break while
                    else % Greater than a second and press
                        resp(pres_i) = find(keyCode);
                        rt(pres_i) = secs - vbl;
                    end
                end
                if secs > vbl+1 && ~flip_flag % If greater than a second and no press
                    wobj.fixate; % Fixate draw
                    fix_t = Screen('Flip',wobj.w); % Execute screen flip
                    flip_flag = 1;
                end
%                 try
%                     disp(KbName(resp(pres_i))); % Temp
%                 end
            end
        end
        % Accuracy check
        if any(pres{pres_i,trial_i,2}==[1 3]) % Spanish condition
            if resp(pres_i)==akey
                acc(pres_i) = 1;
            end
        else % English condition
            if resp(pres_i)==bkey
                acc(pres_i) = 1;
            end
        end
        fprintf(fid,'%s,%d,%6.4f,%1.2f,%s,%s,%d,%6.4f\n',s_ID,pres_i,pres_t(pres_i),t(pres_i,trial_i),cond_cell{pres{pres_i,trial_i,2}},pres{pres_i,trial_i,1},acc(pres_i),rt(pres_i));
    end
    
    wobj.text(WrapString('End of Run. Waiting for experimenter to press spacebar.',20));    
    RestrictKeysForKbCheck(spkey);
    KbStrokeWait;
    
    % Screen release
    Screen('CloseAll');
    ListenChar(0);
    ShowHideWinTaskbarMex(1);
    ShowCursor;
    fclose(fid);
    
end

% Close dio
if( useMCC_Flag )
    if ispc
        stop( MCC_dio );
        delete( MCC_dio )
        clear MCC_dio
    end
end % END - if( useMCC_Flag )

diary off
fclose('all');
%clear all
%close all
end % End primary