%get_todos
% Framework for running NWB conversion as a service
% Chris van der Togt, April 2024

global path_codebase

path_codebase = 'D:\Git\';
path_fydml = [path_codebase 'FYD_Matlab'];
path_ninwb =  [path_codebase 'NINwb'];
path_matnwb = [path_codebase 'matnwb'];

addpath( path_fydml ...
    ,fullfile(path_fydml, 'dj') ...
    ,fullfile(path_fydml, 'ophys') ...
    ,fullfile(path_fydml, 'ephys') ...
    ,fullfile(path_fydml, 'YAML') );

addpath( path_ninwb ...
    ,fullfile(path_ninwb, 'images') ...
    ,fullfile(path_ninwb, 'utility_functions') );

addpath(genpath(path_matnwb));

global dbpar
dbpar = initmysql(); % On vc-server/togt
query = bids.Nwblist;

while(1)
    records = fetch(query & 'status="todo"', '*');
    ln = length(records);
    
    if ln > 0        
        sessionid = records(1).sessionid;
        % set to correct database for this lab
        lab = records(1).lab;
        dbpar.Database = lab;
        
        [all_meta, Okay] = getMetadata(sessionid);
        if Okay
 %% RUN NWB COnversion
            nwblog(append('<br>', char(datetime), '  <b>Converting session: ', sessionid,  ' started. </b>'))
            
            key = ['sessionid="', sessionid, '"'];
            update(query & key, 'status', 'doing');
    
            conversion_status = convert2nwb(all_meta);
            
            nwblog(append('<br>', char(datetime), '  <b> Done. </b>'))
            nwblog(append('Status conversion ', sessionid, ' :', conversion_status )); 
            if strcmp(conversion_status, 'SUCCESS')
                update(query & key, 'status', 'done');
            else 
                update(query & key, 'status', 'failed');
            end

        else
            nwblog(append('ERROR: obtaining metadata for :', sessionid));
        end
    else
       % disp('All done')
        pause(60); % 5min: 5 * 60 = 300s
    end
end