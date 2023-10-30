%% data_to_bids


%% Initialize Datajoint for my lab and retrieve metadata from the FYD database
initDJ

%%MAKE SELECTABLE where to store
my_savepath = 'I:\Users\togt\Documents\temp\BIDS';

%% SELECT YOUR DATASET!!!
% getting metadata for all sessions from FYD, this returns a table with fields 
% url, subject, condition, stimulus, date, setup for each recording session
project='Muckli_reboot';
dataset='Passive_fixation';
subject='Lick';
sess_meta = getSessions(project=project, dataset=dataset, subject=subject);
dset_meta = getDataset( project, dataset );


%% Create the dataset folder

%Create dataset folder
dataset_folder = fullfile(my_savepath, dataset);
mkdir(dataset_folder);


%% Create participants.json

subjects = unique({ sess_meta(:).subject });
%retrieve from FYD database
sub_meta = getSubjects(subjects); %gets id, species, sex, birthdate, age
txtO = jsonencode(sub_meta);
fid = fopen(fullfile(dataset_folder, 'participants.json'), 'w');
fwrite(fid, txtO);
fclose(fid);


% We might also need to create a tsv table for the participants
% tbl = struct2cell(sub_metadata);
% writecell(tbl,fullfile(dataset_folder, 'participants.tsv'), 'filetype','text', 'delimiter','\t')

%% Create the Probes tsv file
probesArray = fetch(bids.Probes & ( 'subject="B01"' | 'subject="L01"'), '*');
ProbeTbl = struct2table(probesArray);
writetable(ProbeTbl, fullfile(dataset_folder, 'probes.tsv'), ...
       'FileType', 'text', ...
       'Delimiter', '\t');

%% Create dataset_description.json file

% Get the template
dd = get_json_template('dataset_description_template.jsonc');

% Fill some values
dd.Name = dataset;
dd.License = 'CC BY-NC-SA 4.0';
dd.Authors = dset_meta.author;
dd.InstitutionDepartmentName = 'Vision and Cognition'; %'Molecular Visual Plasticity';
dd.InstitutionName = 'Netherlands Institute for Neuroscience';
dd.InstitutionAddress = 'Meibergdreef 47, 1105BA Amsterdam, The Netherlands';
dd.DatasetShortDescription = [ dataset ': '  dset_meta.shortdescr ', in project ' project ];
dd.DatasetDescription = dset_meta.longdescr;
dd.DatasetType="preprocessed";

% Save the dataset descriptor to a json file          
txtO = jsonencode(dd);
fid = fopen(fullfile(dataset_folder, 'dataset_descriptor.json'), 'w');
fwrite(fid, txtO);
fclose(fid);

%% Create table for the _sessions.json file

% This will be filled when we go through each session
SessStructArray = struct('sessionid', [], 'session_quality', [], 'number_of_trials', [], 'comment', []);


%% Create the sub and sess folders, copy and rename files
%Create the basic session.json file to add to each subfolder

for i = 1:length(sess_meta)
    if strcmp(sess_meta(i).setup, 'Gaia')
        % this conversion script is only for the 2photon data
        % for the neurolabware system, scanbox-YETI
        SessStructArray(i) = gen_2P_bids(sess_meta(i), dataset_folder);
        
    elseif contains(sess_meta(i).setup, 'MonkeyLab')
        % Conversion script for Blackrock data
        SessStructArray(i) = gen_Ephys_bids(sess_meta(i), dataset_folder);
    end
end

%% Write sessions table
    SessTbl = struct2table(SessStructArray);
    writetable(SessTbl, fullfile(dataset_folder, 'sessions.tsv'), ...
       'FileType', 'text', ...
       'Delimiter', '\t');

    