%% dataset2bids
% This is an example script that illustrates how you can retrieve metadata
% and generate a BIDS compliant dataset in the folder of your choice.
% 1. It first selects and retrieves all the urls to the sessions you want to
% incorporate in your dataset.
% 2. Then it creates global metadata files, creates folders with bids
% compliant names, copies and renames datafiles (in this example they are
% empty for test purposes) and adds metadata to each subfolder.

% Basic metadata can be retrieved from the FYD database. This depends on
% how well you have added documentation through the WebApp.
% Nevertheless, you will still need to retrieve extra metadata from the 
% log files you create with your data with custom scripts.

% Two subroutines were added in this repo as examples of custom subroutines 
% to retrieve metadata, one for ephys (gen_ephys_bids.m) and one for 2photon
% data (gen_2P_bids.m)
% This script will choose one or the other depending on the setup
% identifier ('Gaia' => 2P, 'MonkeyLab' => ephys)


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

%% Create dataset_description.json file

% Get the template
dd = get_json_template('template_dataset_description.jsonc');

% Fill some values using metadata from the FYD database: dset_meta
dd.name = dataset;
dd.license = 'CC BY-NC-SA 4.0';
dd.authors = dset_meta.author;
dd.institution_department_name = 'Vision and Cognition'; %'Molecular Visual Plasticity';
dd.institution_name = 'Netherlands Institute for Neuroscience';
dd.institution_address = 'Meibergdreef 47, 1105BA Amsterdam, The Netherlands';
dd.dataset_short_description = [ dataset ': '  dset_meta.shortdescr ', in project ' project ];
dd.dataset_description = dset_meta.longdescr;
dd.dataset_type="derived";

% Save the dataset descriptor to a json file          
txtO = jsonencode(dd);
fid = fopen(fullfile(dataset_folder, 'dataset_descriptor.json'), 'w');
fwrite(fid, txtO);
fclose(fid);

%% Create table for the _sessions.json file

% This will be filled when we go through each session
SessArray = struct('sessionid', [], 'session_quality', [], 'number_of_trials', [], 'comment', []);


%% Create the sub and sess folders, copy and rename files
%Create the basic session.json file to add to each subfolder
data_type = ''; % Recording type

for i = 1:length(sess_meta)
    if strcmp(sess_meta(i).setup, 'Gaia')
        data_type = 'multi_photon';
        % this conversion script is only for the 2photon data
        % for the neurolabware system, scanbox-YETI
        SessArray(i) = gen_2P_bids(sess_meta(i), dataset_folder);
        
    elseif contains(sess_meta(i).setup, 'MonkeyLab')
        data_type = 'ephys';
        % Conversion script for Blackrock data
        SessArray(i) = gen_Ephys_bids(sess_meta(i), dataset_folder);
    end
end

%% Write sessions table
    SessTbl = struct2table(SessArray);
    writetable(SessTbl, fullfile(dataset_folder, 'sessions.tsv'), ...
       'FileType', 'text', ...
       'Delimiter', '\t');

%% Create the Probes tsv file, retrieve data from bids.Probes table
if strcmp(data_type, 'ephys')
    probesArray = fetch(bids.Probes & ( 'subject="B01"' | 'subject="L01"'), '*');
    ProbeTbl = struct2table(probesArray);
    writetable(ProbeTbl, fullfile(dataset_folder, 'probes.tsv'), ...
           'FileType', 'text', ...
           'Delimiter', '\t');
end  
   