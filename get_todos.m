%get_todos
% Framework for running NWB conversion as a service
% Chris van der Togt, April 2024
global dbpar

conn = initmysql();
NwbLog = nwblog();

query = bids.Nwblist;

while(1)
    records = fetch(query & 'status="todo"', '*');
    ln = length(records);
    
    if ln > 0 
       % disp([num2str(ln), ' session(s) can be converted to NWB format!'])
       % disp([records(:).sessionid])
        
        sessionid = records(1).sessionid;
        url = records(1).url;
        lab = records(1).lab;
        dbpar.User = 'dbuser';
        dbpar.Database = lab;
        

        try
            Okay = true;
            %% Get neccessary metadata, this contains references to other tables in FYD
            sess_meta = getSessions(sessionid=sessionid); % metadata in JSON files and in Sessions table
            project = sess_meta.project;
            dataset = sess_meta.dataset;
            subject = sess_meta.subject;
            setup = sess_meta.setup;
            stim = sess_meta.stimulus;
    
            % Other tables in FYD
            dataset_meta = getDataset( project, dataset );
            stim_metadata = getStimulus(stim);
            subject_meta = getSubjects(subject); % multiple subjects as cell array
    
            %% Meta data from the bids database
            setup_meta = getSetup(setup);
    
    
            %% Retreive probe, contact and channel metadata from the database, selecting by subject
            key = ['subject="', subject,'"'];
            probe_meta = fetch(bids.Probes & key, '*'); % '*' -> retrieve all fields
            contact_meta = fetch(bids.Contacts & key, '*');
            chan_meta  = fetch(bids.Channels & key, '*');

        catch err
            messg = ['<br><b>ERROR obtaining metadata</b>: ', err.identifier, '<br>' ];
            NwbLog.write(messg)
            Okay = false;
        end
        
        if Okay
            %% RUN NWB COnversion
            d = char(datetime);
            % Put </br> in your messages to create new lines
            messg = ['<br><b>Converting session</b>: ', sessionid ' : started at ', d, '<br>' ];
            NwbLog.write(messg)
            key = ['sessionid="', sessionid, '"'];
            update(query & key, 'status', 'doing')
    
    %...................................................
    
    %....................................................
    
    
            messg = ['Conversion done: ', sessionid, '<br>' ];
            NwbLog.write(messg)
    
        %% Finish by setting session to 'done' in ninwb database
    
            update(query & key, 'status', 'done')
            %finish by setting the record to 'done'
        end
    else
       % disp('All done')
        pause(300) % 5min: 5 * 60 = 300s
    end
end