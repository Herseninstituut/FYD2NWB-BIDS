 function Sess = gen_Ephys_bids(sess_meta, ephys_json, dataset_folder)
         
 % INPUT: sess_meta retrieved info from FYD database for this session;
 %        ephys_json BIDS metadata prefilled for this session  
 %        Main folder where dataset is going to be saved.
 
 % OUTPUT: This script creates folders with BIDS compliant names, renames
 % the data files to BIDS compliant names, ands adds metadata files
 % required by BIDS
 
        % Output for the sessions table in tsv format
        Sess = struct('sessionid', sess_meta.sessionid, 'session_quality', [], 'number_of_trials', [], 'comment', []);
         
        % Template for channels array (adapt efys_channels to your needs)
        % chan_templ = get_json_template('efys_channels.jsonc'); 
        
        % Template ephys events
        % events_templ = get_json_template('efys_events.jsonc');
    
        % prepare the creation of subject, ephys and session folders with BIDS compliant names
        subject_folder = fullfile(dataset_folder, ['sub-' sess_meta.subject] );
        methods_folder = fullfile(subject_folder, 'ephys');
        session_folder = fullfile(methods_folder, ['sess-' sess_meta.sessionid] );
             
        mkdir(session_folder);
         
        %Create BIDS compliant session name
        bids_prenom = fullfile(session_folder, ['sub-' sess_meta.subject '_sess-' sess_meta.sessionid '_task-' sess_meta.stimulus ]);
                
        % Retrieve all files associated with this recording session
        % Here each file should either contain the FYD sessionid in it's name 
        % or the folder should contain only files that are associated with
        % one session. This is what makes data machine readable!!!!
        
        % In this case we simply select all the files in a folder, 
        % rename them according to BIDS and copy them to their destination folder!!
        % (not a real copy here, simply created empty files with the correct name)
        searchpath = [sess_meta.url '\*'];
        filesIn = dir(searchpath);
        for j = 1:length(filesIn)
            % Ignore _session.json files, we have retrieved this metadata already
            if ~filesIn(j).isdir && ~contains(filesIn(j).name, '_session') 
                %get remainder of filename + extention without sessionid
                ext = erase(filesIn(j).name, sess_meta.sessionid);
                %create the file and format the filename according to BIDS
                f = fopen([bids_prenom '_' ext], 'w' );  
                fclose(f);
            end
        end

        
        %% this is datset specific so you will need to adapt this %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %Add relevant metadata for this session's ephys.json file
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
        
        
        %update record for sessions
        Sess.number_of_trials = trials;
        
        %Read metadata related to the task from the FYD database
        task_meta = getStimulus(sess_meta.stimulus);
        ephys_json.task_name = task_meta.stimulusid;
        ephys_json.task_description = task_meta.shortdescr;

        %Write to json file
        f = fopen([bids_prenom '_ephys.json'], 'w' ); 
        txtO = jsonencode(ephys_json);
        fwrite(f, txtO);
        fclose(f);
        
    %% A simple way to create the channels.tsv (or probes.tsv, contacts.tsv) 
    % if they where previously saved on tables within the bids database
    
    % This retrieves all fields, you could also use the template to retrieve a subset of the fields
    % Since they will be subject dependent, select the channels, probes
    % associated with a subject
    ChannArray = fetch(bids.Channels & 'subject="L01"', '*');
    % you might want to remove empty or redundant fields
    ChannArray = rmfield(ChannArray, {'subject', 'contact_id', 'channel_name', 'recording_mode'});
    
    ChannelTbl = struct2table(ChannArray);
    writetable(ChannelTbl, [bids_prenom '_channels.tsv'], ...
           'FileType', 'text', ...
           'Delimiter', '\t');  
       
   % Create the Probes tsv file, retrieve data from bids.Probes table
    probesArray = fetch(bids.Probes & 'subject="L01"', '*');
    ProbeTbl = struct2table(probesArray);
    writetable(ProbeTbl, [bids_prenom '_probes.tsv'], ...
           'FileType', 'text', ...
           'Delimiter', '\t');

       