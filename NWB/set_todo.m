%add a session to the todo list

%adding neccessary folders to your path, 

labs = {'roelfsemalab','leveltlab','heimellab', ...                   
        'lohmannlab','kolelab','willuhnlab', ...
        'socialbrainlab', 'dezeeuwlab', 'vansomerenlab', ...
        'siclarilab', 'saltalab', 'verhagenlab', ...
        'kalsbeeklab', 'huitingalab'};
[indx,tf] = listdlg('ListString', labs, 'SelectionMode','single');
lab = labs{indx};

initDJ(lab);

%% Select sessionids based on project, dataset, condition, subject, date, 
sessions = getSessions(project='', dataset='', subject='');

 
%% Select a sessionid and check if it contains all neccessary metadata
% Or simply go to the FYD webapp and select a single sessionid.
sessionid = 'Amarone_20221013_001';
all_md = getMetadata(sessionid);

%% If so add it to the todo list to automatically be converted to NWB format.
if ~isempty(all_md)
    query = bids.Nwblist;
    query.insert( struct('sessionid', sessionid, 'lab', lab ) )
end

%% Check status of conversion at https://nhi-fyd.nin.nl/nwblog.html

% [conversion_status, nwb, path_nwb] = convert2nwb(all_md);
% del(query & ['sessionid="' sessionid '"'])