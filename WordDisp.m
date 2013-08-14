classdef WordDisp < handle
    % Created by Ken Hwang, M.S.
    % Last modified 10/15/12
    % Requested by Angela Chouinard
    % PSU, SLEIC, Dept. of Psychology
    %
    % Presentation functionality is handled by WordDisp object instance.
    % This includes word, fixation, and text presentation.  Initialization
    % of the object sets up screen parameters.  Word font is set to a
    % default of 40. Fixation cross distance from center is default to 30.
    % Fixation line width is default to 20.  These properties can be
    % changed in class definition properties.  Text display is
    % automatically wrapped according to screen width in caller script.
    properties (SetObservable)
        w
        width
        height
        center_w
        center_h
        fix_c = [0 0 0]; % Black Fixation
        fix_l = 30;
        fix_w = 20;
        trial_n
        pres
        pres_count = 1;
        tobj
    end
    
    methods
        % Object set-up
        function obj = WordDisp(pres)
            obj.w = Screen('OpenWindow',max(Screen('Screens')),127); % Gray
            Screen('TextSize',obj.w,40); % Default
            [obj.width,obj.height] = Screen('WindowSize',obj.w);
            obj.center_w = obj.width/2;
            obj.center_h = obj.height/2;
            obj.trial_n = length(pres);
            obj.pres = pres;
        end
        
        % Fixation draw
        function fixate(obj)
            Screen('DrawLine',obj.w,obj.fix_c,obj.center_w-obj.fix_l,obj.center_h,obj.center_w+obj.fix_l,obj.center_h,obj.fix_w);
            Screen('DrawLine',obj.w,obj.fix_c,obj.center_w,obj.center_h-obj.fix_l,obj.center_w,obj.center_h+obj.fix_l,obj.fix_w);
        end
        
        % Word Draw
        function word(obj)
            DrawFormattedText(obj.w,obj.pres{obj.pres_count,1},'center','center',0);
            obj.pres_count = obj.pres_count + 1;
        end
        
        % Text Draw
        function text(obj,txt)
            Screen('TextSize',obj.w,20); 
            DrawFormattedText(obj.w,txt,'center','center',0,[],[],[],1.3);
            Screen('Flip',obj.w);
            Screen('TextSize',obj.w,40); % Reset
        end
        
    end
    
end