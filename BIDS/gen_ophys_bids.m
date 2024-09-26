function Sess = gen_ophys_bids(md, dataset_folder)
       
        sess_meta = md.sess_meta;
        ophys = md.ophys;
        % create to add to sessions tsv output table
        Sess = struct('sessionid', sess_meta.sessionid, 'session_quality', [], 'number_of_trials', [], 'comment', []);
  
        %To create the bids compliant hierarchy of folders
        subject_folder = fullfile(dataset_folder, ['sub-' sess_meta.subject] );
        methods_folder = fullfile(subject_folder, 'ophys');
        session_folder = fullfile(methods_folder, ['sess-' sess_meta.sessionid] );
        mkdir(session_folder);

        %Create BIDS compliant name
        bids_prenom = fullfile(session_folder, ['sub-' sess_meta.subject '_sess-' sess_meta.sessionid '_task-' sess_meta.stimulus ]);
                
        % Instead of copying the raw files, we will simply copy and rename 
        % the appropriate NWB files which should contain all data assciated with a session!!! 
         searchpath = [sess_meta.url '\' sess_meta.sessionid '*.nwb'];
         filesIn = dir(searchpath);
         if isempty(filesIn)
             warndlg('no NWB files for this session')
         else
             for j = 1:length(filesIn)
                % get remainder of filename + extention without sessionid
                ext = erase(filesIn(j).name, sess_meta.sessionid); 
                %create the file and format the filename according to BIDS with
                %nwb extension
                fbids = [bids_prenom ext];
              %  copyfile(fullfile(sess_meta.url,filesIn(j).name), fbids);
             end
         end
         
         events = md.events;
         EvntTbl = table;
         if isfield(events, 'run_events')
            EvntTbl.time = num2str(events.run_events.time, '%.3f');
            EvntTbl.run_speed = num2str(events.run_events.speed, '%.1f');
         end
         if isfield(events, 'pupil_events')
             EvntTbl.time = num2str(events.pupil_events.time, '%.3f');
             EvntTbl.eye_pos_x = num2str(events.pupil_events.Pos(:,1), '%.1f');
             EvntTbl.eye_pos_y = num2str(events.pupil_events.Pos(:,2), '%.1f');
             EvntTbl.eye_area = num2str(events.pupil_events.Area, '%.0f');
         end
        writetable(EvntTbl, [ bids_prenom '_events_behaviour.tsv'], ...
               'FileType', 'text', ...
               'Delimiter', '\t');
         
         if isfield(events, 'task_events')
             EvntStim = table;
             EvntStim.time = num2str(events.task_events.time, '%.3f');
             EvntStim.log = num2str(events.task_events.log);   
             writetable(EvntStim, [ bids_prenom '_events_stimulus.tsv'], ...
                   'FileType', 'text', ...
                   'Delimiter', '\t');
             Sess.number_of_trials = height(EvntStim);
         end
         
          Sess.comment = 'Okay';
           

        %Write to json file
        f = fopen([bids_prenom '_ophys.json'], 'w' ); 
        txtO = jsonencode(ophys);
        fwrite(f, txtO);
        fclose(f);
        