 function Sess = gen_Ephys_bids_humanP(sess_meta, ephys_json, dataset_folder, deriv, mat_dimensions)
         
 % INPUT: sess_meta retrieved info from FYD database for this session;
 %        ephys_json BIDS metadata prefilled for this session  
 %        Main folder where dataset is going to be saved.
 
 % OUTPUT: This script creates folders with BIDS compliant names, renames
 % the data files to BIDS compliant names, ands adds metadata files
 % required by BIDS
 % requires: https://github.com/BlackrockNeurotech/NPMK/blob/master/NPMK/openNSx.m
 % requires: https://github.com/BlackrockNeurotech/NPMK/blob/master/NPMK/openNEV.m
 
         % Output for the sessions table in tsv format


         % Template for channels array (adapt efys_channels to your needs)
        % chan_templ = get_json_template('efys_channels.jsonc'); 
        
        % Template ephys events
        % events_templ = get_json_template('efys_events.jsonc');
    
        % prepare the creation of subject, ephys and session folders with BIDS compliant names
        subject_folder = fullfile(dataset_folder, ['sub-' sess_meta.subject] );
        if deriv
            Sess = struct('session_quality', [], 'number_of_trials', [], 'comment', []);
            methods_folder = fullfile(subject_folder, 'derivatives');
            session_folder = fullfile(methods_folder, 'MUA' );
            bids_prenom = fullfile(session_folder, ['sub-' sess_meta.subject '_task-' sess_meta.stimulus ]);
        else
            Sess = struct('sessionid', sess_meta.sessionid, 'session_quality', [], 'number_of_trials', [], 'comment', []);
            methods_folder = fullfile(subject_folder, 'ephys');
            session_folder = fullfile(methods_folder, ['sess-' sess_meta.sessionid] );
            bids_prenom = fullfile(session_folder, ['sub-' sess_meta.subject '_sess-' sess_meta.sessionid '_task-' sess_meta.stimulus ]);
        end
        
        mkdir(session_folder);
         
        %Create BIDS compliant session name
                
        % Retrieve all files associated with this recording session
        % Here each file should either contain the FYD sessionid in it's name 
        % or the folder should contain only files that are associated with
        % one session. This is what makes data machine readable!!!!
        
        % In this case we simply select all the files in a folder, 
        % rename them according to BIDS and copy them to their destination folder!!
        % (not a real copy here, simply created empty files with the correct name)
        if deriv ~= 1
            searchpath = [sess_meta.url '\*'];
            filesIn = dir(searchpath);
            for j = 1:length(filesIn)
                % Ignore _session.json files, we have retrieved this metadata already
                if ~filesIn(j).isdir && ~contains(filesIn(j).name, '_session')
                    %get remainder of filename + extention without sessionid
                    ext = erase(filesIn(j).name, sess_meta.sessionid);
                    %create the file and format the filename according to BIDS
                    f = fopen([bids_prenom '_' ext], 'w' );
                    % FOR NOW IT"S EMPTY!!
                    fclose(f);
                end
            end
            
            
            %% this is datset specific so you will need to adapt this %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %Add relevant metadata for this session's ephys.json file
            
            %Data file url
            json_name = dir(fullfile(sess_meta.url,'*.json'));
            newStr = erase(json_name.name,'_session.json');
            C = strsplit(sess_meta.url,sess_meta.subject);
            
            fpath = [C{1},sess_meta.subject,'\_logs\',newStr,'.mat'];
            f = fopen([bids_prenom '_logs.mat'], 'w' );
            logs = whos('-file', fpath);
            fclose(f); % FOR NOW IT"S EMPTY!!
            
            StreamTypes = {'NS6','CCF','NEV','LOG'};
            which_ns6 = find(contains({filesIn.name},'.ns6')==1,1);
            which_nev = find(contains({filesIn.name},'.nev')==1,1);
            temp_ns6 = openNSx([filesIn(which_ns6).folder,'\',filesIn(which_ns6).name],'skipfactor',100000);
            temp_nev = openNEV([filesIn(which_nev).folder,'\',filesIn(which_nev).name],'noread','nosave');
            Streams = StreamTypes;
        else
            StreamTypes = {'normMUA','ALLMAT','ALLMUA'};
            %Data file url
            temp = dir([sess_meta.url,'\*',sess_meta.stimulus,'*MUA_trials*']);
            fpath = [sess_meta.url,'\', temp.name];
            metadata = whos('-file', fpath);
            tb = load(fpath, 'tb');
            if ismember('meaning_of_rows_in_ALLMAT', {metadata.name})
                meaning_of_rows_in_ALLMAT = load(fpath, 'meaning_of_rows_in_ALLMAT');
                mat_dimensions = meaning_of_rows_in_ALLMAT;
            end
            
            f = fopen([bids_prenom '_' 'preproc_MUA.mat'], 'w' );
            % FOR NOW IT"S EMPTY!!
            fclose(f);
            
            temp = dir([sess_meta.url,'\*',sess_meta.stimulus,'*normMUA*']);
            fpath = [sess_meta.url,'\', temp.name];
            metadata2 = whos('-file', fpath);
            metadata = [metadata; metadata2];
            SNR = load(fpath, 'SNR');

            f = fopen([bids_prenom '_' 'norm_MUA.mat'], 'w' );
            % FOR NOW IT"S EMPTY!!
            fclose(f)
            
            names = {metadata.name};
            S = find(matches( names, StreamTypes));
            Streams = names(S);
        end

        
        for i = 1: numel(Streams)
            name = Streams{i};
            switch name
                    
                  case {'NS6'}
                    ephys_json.(name) = struct();
                    ephys_json.(name).Type = temp_ns6.MetaTags.FileExt;
                    ephys_json.(name).Dimensions = fieldnames(temp_ns6);
                    ephys_json.(name).SamplingFrequency = temp_ns6.MetaTags.SamplingFreq;
                    ephys_json.(name).SamplingFrequencyUnit = 'Hz';
                    idx = find(strcmp({logs.name}, 'MAT')==1);
                    trials = logs(idx).size(1);
                    
                 case {'NEV'}
                    ephys_json.(name) = struct();
                    ephys_json.(name).Type = temp_nev.MetaTags.FileExt;
                    ephys_json.(name).Dimensions = fieldnames(temp_nev);
                    ephys_json.(name).SamplingFrequency = temp_nev.MetaTags.TimeRes;
                    ephys_json.(name).SamplingFrequencyUnit = 'Hz';
                    idx = find(strcmp({logs.name}, 'MAT')==1);
                    trials = logs(idx).size(1);
                    
                case {'CCF'}
                    ephys_json.(name) = struct();
                    ephys_json.(name).Type = '.ccf';
%                     ephys_json.(name).Description = 'Configuration file';
                    
                case {'LOG'}
                    idx = find(strcmp({logs.name}, 'MAT')==1);
                    ephys_json.(name) = struct();
                    ephys_json.(name).Size = logs(idx).size;
                    ephys_json.(name).Type = logs(idx).class;
                    ephys_json.(name).Dimensions = mat_dimensions;
                    trials = logs(idx).size(1);
                    
                case {'ALLMAT'}
                    ephys_json.(name) = struct();
                    ephys_json.(name).Size = metadata(S(i)).size;
                    ephys_json.(name).Type = metadata(S(i)).class;
                    ephys_json.(name).Dimensions = mat_dimensions;
                    trials = metadata(S(i)).size(1);
                    
                case {'ALLMUA','normMUA'}
                    ephys_json.(name) = struct();
                    ephys_json.(name).Size = metadata(S(i)).size;
                    ephys_json.(name).Type = metadata(S(i)).class;
                    ephys_json.(name).Dimensions = { 'channels', 'trials', 'samples'};
                    ephys_json.(name).SNR = SNR.SNR;
                    times = tb.tb;
                    lngtime = numel(times);
                    ephys_json.(name).Onset = find(times==0);
                    ephys_json.(name).Duration = lngtime;
                    ephys_json.(name).SamplingFrequency = 1000;
                    ephys_json.(name).SamplingFrequencyUnit = 'Hz';
                    trials = metadata(S(i)).size(2);
            end      
        end
        
        
        %update record for sessions
        Sess.number_of_trials = trials;
        
        % Read metadata related to the task/stimulus for this session
        % from the FYD database
        task_meta = getStimulus(sess_meta.stimulus);
        ephys_json.task_name = task_meta.stimulusid;
        ephys_json.task_description = task_meta.shortdescr;

        %Write to json file
        f = fopen([bids_prenom '_ephys.json'], 'w' ); 
        txtO = jsonencode(ephys_json);
        fwrite(f, txtO);
        fclose(f);
        
        if sess_meta.subject(end) == 'N'
            rois = {'V1','V1','V1','V1','V1','V1','V1','V1','V4','V4','V4','V4','IT','IT','IT','IT'};
        elseif sess_meta.subject(end) == 'F'
            rois = {'V1','V1','V1','V1','V1','V1','V1','V1','IT','IT','IT','IT','IT','V4','V4','V4'};
        end
        
        probes = struct();
        for i = 1:16
            probes(i).subject = sess_meta.subject;
            probes(i).manufacturer = 'Blackrock';
            probes(i).manufacturers_model_name = 'Utah Array';
            probes(i).probe_id = i;
            probes(i).hemisphere = 'L';
            probes(i).AssociatedBrainRegion = rois{i};
        end
        
        ProbesTbl = struct2table(probes);
        writetable(ProbesTbl, [bids_prenom '_probes.tsv'], ...
           'FileType', 'text', ...
           'Delimiter', '\t');

        ContactArray = struct();
        for i = 1:1024
            ContactArray(i).contact_id = i;
            ContactArray(i).z = 1.5;
            ContactArray(i).probe_id = ceil(i/64);
        end
        
        ContactTbl = struct2table(ContactArray);
        writetable(ContactTbl, [bids_prenom '_contacts.tsv'], ...
               'FileType', 'text', ...
               'Delimiter', '\t');  
           
        ChannelArray = struct();
        for i = 1:1024
            ChannelArray(i).channel_id = i;
            ChannelArray(i).contact_id = i;
            ChannelArray(i).type = 'EXT';
            ChannelArray(i).unit = 'uV';
            ChannelArray(i).sampling_frequency = 30000;
            ChannelArray(i).sampling_frequency_unit = 'Hz';
            ChannelArray(i).ground = 'Pedestal';
        end
        
        ChannelTbl = struct2table(ChannelArray);
        writetable(ChannelTbl, [bids_prenom '_channels.tsv'], ...
               'FileType', 'text', ...
               'Delimiter', '\t');
 end

       