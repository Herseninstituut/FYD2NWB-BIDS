function Sess = gen_2P_bids(sess_meta, multiphoton, dataset_folder)
        global info %% header info from imaging files
       
        % create to add to sessions tsv output table
        Sess = struct('sessionid', sess_meta.sessionid, 'session_quality', [], 'number_of_trials', [], 'comment', []);
  
        %To create the bids compliant hierarchy of folders
        subject_folder = fullfile(dataset_folder, ['sub-' sess_meta.subject] );
        methods_folder = fullfile(subject_folder, 'ophys');
        session_folder = fullfile(methods_folder, ['sess-' sess_meta.sessionid] );
        mkdir(session_folder);

        %Create BIDS compliant name
        bids_prenom = fullfile(session_folder, ['sub-' sess_meta.subject '_sess-' sess_meta.sessionid '_task-' sess_meta.stimulus ]);
                
        %retrieve all files associated with this recording session
        %Here each file should contain the FYD sessionid or this will not work
        searchpath = [sess_meta.url '\' sess_meta.sessionid '*'];
        filesIn = dir(searchpath);
        for j = 1:length(filesIn)
            if ~contains(filesIn(j).name, '_session') % Ignore _session.json files, we have retrieved this metadata already
                %get remainder of filename + extention without sessionid
                ext = erase(filesIn(j).name, sess_meta.sessionid);
                %create the file and format the filename according to BIDS
                f = fopen([bids_prenom ext], 'w' );  
                fclose(f);
            end
        end

        %Create json file for this session with relevent metadata
        %read matadata from scanbox imaging file (.sbx)
        fpath = [sess_meta.url '\' sess_meta.sessionid];
        try
            info = [];
            sbxread(fpath, 0, 1);
            scanmode = info.scanmode;
            if scanmode == 1
                multiphoton.image_acquisition_protocol = 'unidirectional';
            else 
                multiphoton.image_acquisition_protocol = 'bidirectional';
                scanmode = 2; %Scanmode in info is 0, but I need it to be 2
            end
            multiphoton.sampling_frequency = info.resfreq * scanmode /(info.Shape(2) * info.Shape(3));
            multiphoton.pixel_dimensions = [info.Shape(1) info.Shape(2)];
            multiphoton.channels = info.Shape(3);
            multiphoton.recording_duration = ceil(info.max_idx / multiphoton.sampling_frequency);
            multiphoton.number_of_frames = info.max_idx;
            
            % Also retrieve the events and create an events.tsv file
            Events = array2table([info.frame info.line info.event_id], 'VariableNames', { 'frame', 'line', 'event_id' });
            writetable(Events, [ bids_prenom '_events.tsv'], ...
               'FileType', 'text', ...
               'Delimiter', '\t');
           
           multiphoton.number_of_trials = height(Events); %This may need to be validated
           Sess.number_of_trials = height(Events);
           Sess.comment = 'Okay';
           
        catch
            Sess.comment = 'No sbx info for this session';
            % disp(['no sbx info for session: ' sess_meta.sessionid])
        end

        %Read metadata related to the task from the FYD database
        Task_meta = getStimulus(sess_meta.stimulus);
        multiphoton.task_name = Task_meta.stimulusid;
        multiphoton.task_description = Task_meta.shortdescr;

        %Write to json file
        f = fopen([bids_prenom '_multiphoton.json'], 'w' ); 
        txtO = jsonencode(multiphoton);
        fwrite(f, txtO);
        fclose(f);
        