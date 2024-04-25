%get_todos
% Framework for running NWB conversion as a service
% Chris van der Togt, April 2024
global dbpar

conn = initmysql();
NwbLog = nwblog();

query = ninwb.Nwblist;


while(1)
    records = fetch(query & 'status="todo"', 'sessionid', 'lab', 'url');
    ln = length(records);
    
    if ln > 0 
       % disp([num2str(ln), ' session(s) can be converted to NWB format!'])
       % disp([records(:).sessionid])
        
        sessionid = records(1).sessionid;
        url = records(1).url;
        lab = records(1).lab;
        dbpar.User = 'dbuser';
        dbpar.Database = lab;
        

        %% Get neccessary metadata, this contains references to other tables in FYD
        sess_meta = getSessions(sessionid=sessionid);
        subject = sess_meta.subject;
        setup = sess_meta.setup;


        %% Meta data from the bids database
        setup_bids = getSetup(setup);


        %% Retreive probe, contact and channel metadata from the database, selecting by subject
        key = ['subject="', subject,'"'];
        probe_meta = fetch(bids.Probes & key, '*'); % '*' means retrieve all fields
        contact_meta = fetch(bids.Contacts & key, '*');
        chan_meta  = fetch(bids.Channels & key, '*');
        

        %% RUN NWB COnversion
        d = char(datetime);
        % Put </br> in your messages to create new lines
        messg = ['"</br><b>Converting session</b>: ', sessionid ' : started at ', d, '</br>"' ];
        NwbLog.write(messg)
        key = ['sessionid="', sessionid, '"'];
        update(query & key, 'status', 'doing')

%...................................................

%....................................................


        messg = ['"Conversion done: ', sessionid, '</br>"' ];
        NwbLog.write(messg)

    %% Finish by setting session to 'done' in ninwb database

        update(query & key, 'status', 'done')
        %finish by setting the record to 'done'
    else
       % disp('All done')
        pause(300) % 5min: 5 * 60 = 300s
    end
end