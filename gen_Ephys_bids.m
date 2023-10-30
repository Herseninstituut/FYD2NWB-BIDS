 function Sess = gen_Ephys_bids(sess_meta, dataset_folder)
         
        % recording type
        types = get_json_template('ephys_types.jsonc');

        % Output for the sessions table in tsv format
        Sess = struct('sessionid', sess_meta.sessionid, 'session_quality', [], 'number_of_trials', [], 'comment', []);
        
        % Template for channels array
        % chan_templ = get_json_template('efys_channels.jsonc'); 
        
        % Template ephys events
        % events_templ = get_json_template('efys_events.jsonc');
           
        % Template ephys metadata
        ephys_json = get_json_template('ephys_metadata.jsonc');
        
        %retrieve info on setup and device
        setup_bids = getSetup( sess_meta.setup );
     
        % Convert from database fields to BIDS prescribed fields 
        % (These might change in the future)
        ephys_json = makebidscompliant(ephys_json, setup_bids);
        
        ephys_json.Type = types.ChannelType{1}; % Extracellular neuronal recording.
        ephys_json.TaskName = sess_meta.stimulus;      
        ephys_json.BodyPart = "Striate Cortex (V1)";
        
        % prepare the creation of folders 
        subject_folder = fullfile(dataset_folder, ['sub-' sess_meta.subject] );
        session_folder = fullfile(subject_folder, ['sess-' sess_meta.sessionid] );
        mkdir(session_folder);

        %Create BIDS compliant name
        bids_prenom = fullfile(session_folder, ['sub-' sess_meta.subject '_sess-' sess_meta.sessionid '_task-' sess_meta.stimulus ]);
                
        % retrieve all files associated with this recording session
        % Here each file should contain the FYD sessionid or this will not work
        % So this doesn't work for Paolos files we simply need to select all the files in teh folder!!
        searchpath = [sess_meta.url '\*'];
        filesIn = dir(searchpath);
        for j = 1:length(filesIn)
            if ~filesIn(j).isdir && ~contains(filesIn(j).name, '_session') % Ignore _session.json files, we have retrieved this metadata already
                %get remainder of filename + extention without sessionid
                ext = erase(filesIn(j).name, sess_meta.sessionid);
                %create the file and format the filename according to BIDS
                f = fopen([bids_prenom '_' ext], 'w' );  
                fclose(f);
            end
        end

        
        %% this is datset specific  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %Create json file for this session with relevent metadata
        StreamTypes = {'MUAe', 'LFP', 'SpikeTrain', 'Psth10'};
       
        %Data file url
        fpath = [sess_meta.url '\NeuralDataMatrix.mat' ];
        metadata = whos('-file', fpath);
        names = {metadata.name};
        
        S = find(matches( names, StreamTypes));
        Streams = names(S);
        
        for i = 1: numel(Streams)
            name = Streams{i};
            switch name
                case {'MUAe', 'LFP'}
                    ephys_json.(name) = struct();
                    ephys_json.(name).Size = metadata(S(i)).size;
                    ephys_json.(name).Type = metadata(S(i)).class;
                    ephys_json.(name).Dimensions = { 'samples', 'trials', 'conditions', 'channels', 'instances'};
                    timename = [metadata(S(i)).name 'Time'];     
                    T = load(fpath, timename);
                    times = T.(timename);
                    lngtime = numel(times);
                    ephys_json.(name).Onset = times(1);
                    ephys_json.(name).Duration = times(lngtime) - times(1);
                    ephys_json.(name).SamplingFrequency = 1/mean(diff(times));
                    ephys_json.(name).SamplingFrequencyUnit = 'Hz';
                    trials = metadata(S(i)).size(2) * metadata(S(i)).size(3);
            end      
        end
        
    %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %update record for sessions
        Sess.number_of_trials = trials;
        
        %Read metadata related to the task from the FYD database
        Task_meta = getStimulus(sess_meta.stimulus);
        ephys_json.TaskName = Task_meta.stimulusid;
        ephys_json.TaskDescription = Task_meta.shortdescr;

        %Write to json file
        f = fopen([bids_prenom '_ephys.json'], 'w' ); 
        txtO = jsonencode(ephys_json);
        fwrite(f, txtO);
        fclose(f);
        