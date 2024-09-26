%% dataset2bids
% This is an example script that illustrates how you can 
% generate a BIDS compliant dataset.
% 1. It first selects and retrieves all the urls to the sessions you want to
% incorporate in your dataset.

% 2. Then it creates global metadata files, creates folders with bids
% compliant names, copies and renames datafiles (in this example they are
% empty for illustration purposes) and adds metadata to each subfolder.

% Basic metadata can be retrieved from the FYD database. This depends on
% how well you have added documentation through the WebApp.

% Two subroutines were added in this repo as examples of custom subroutines 
% to retrieve metadata, one for ephys (gen_ephys_bids.m) and one for 2photon
% data (gen_2P_bids.m)
% This script will choose one or the other depending on the setup
% identifier ('Gaia' => ophys, 'MonkeyLab' => ephys)


%% Initialize Datajoint for your lab and retrieve metadata from the FYD database
%Make sure to adapt this file to access the database of your lab

% dezeeuwlab, heimellab, huitingalab, kalsbeeklab, kolelab, leveltlab, 
% lohmannlab, roelfsemalab, saltalab, siclarilab, vansomerenlab, 
% socialbrainlab, willuhnlab

initDJ('leveltlab')
% This checks the datajoint template and whether you are using the right
% credentials


%% SELECT YOUR DATASET!!!
% getting metadata for all sessions from FYD, this returns a table with fields 
% url, subject, condition, stimulus, date, setup for each recording session

% Example multi_photon dataset 
myproject='GluA3_VR';
mydataset='KOinV1PV_2P';
mysubject='Pinot';

% Example ephys dataset from Paolo Papale, please try this with your own
% dataset
myproject='Thatcher_mk';
mydataset='Faces';
mysubject='monkeyN';


% gets urls to data folders, using DataJoint (See Examples_BIDS_Datajoint)
% With this function you can also select based on excond(condition), stimulus,
% setup, date
if isMATLABReleaseOlderThan("R2020a")
    sess_meta = getSessions('project', myproject, 'dataset',mydataset, 'subject', mysubject);
else
    sess_meta = getSessions(project=myproject, dataset=mydataset, subject=mysubject);
end

% gets metadata about the dataset, from Dataset and Project tables
dset_meta = getDataset( myproject, mydataset );

%% Create the dataset folder
% Choose where to store your dataset
my_savepath = uigetdir();

%Create dataset folder, in selected path, with name of dataset
dataset_folder = fullfile(my_savepath, mydataset);
mkdir(dataset_folder);


%% Create participants.json

subjects = unique({ sess_meta(:).subject });
%retrieve from FYD database, yourlab.Subjects
sub_meta = getSubjects(subjects); %gets id, species, sex, birthdate, age

%NOTE that we use jsonencode to convert a matlab structure array to json
%formatted string. The a json file is created and the string is saved.
%You can open the json file in a browser(mozilla) to verify it's contents
txtO = jsonencode(sub_meta);
fid = fopen(fullfile(dataset_folder, 'participants.json'), 'w');
fwrite(fid, txtO);
fclose(fid);


% We might also need to create a tsv table for the participants
% tbl = struct2cell(sub_metadata);
% writecell(tbl,fullfile(dataset_folder, 'participants.tsv'), 'filetype','text', 'delimiter','\t')

%% Create dataset_description.json file

% Get the template, comment the fields you don't use
dd = yaml.loadFile('template_dataset_description.yaml');

% Fill some values using metadata from the FYD database: dset_meta
dd.name = mydataset;
dd.license = 'CC BY-NC-SA 4.0';
dd.authors = dset_meta.author;
dd.institution_department_name =  dset_meta.institution_department_name; % 'Molecular Visual Plasticity'; %
dd.dataset_short_description = [ mydataset ': '  dset_meta.shortdescr ', in project ' myproject ];
dd.dataset_description = dset_meta.longdescr;
dd.dataset_type='raw';
dd.generated_by.name = 'FYD2BIDS';
dd.generated_by.version = 1.0;
dd.generated_by.container.name = 'NWB';

% Save the dataset descriptor to a json file          
txtO = jsonencode(dd);
fid = fopen(fullfile(dataset_folder, 'dataset_descriptor.json'), 'w');
fwrite(fid, txtO);
fclose(fid);


%% recording type determines the type of metadata that you will need to include
% Save recording type on the FYDS webApp, in the setup tab.

setupid = unique({ sess_meta(:).setup });
if length(setupid) > 1
    waitfor(warndlg(['More than one setup; ' strjoin(setupid)], 'Warning'))
end
%We retrieve the setup type from the lab.Setups table
setupid = setupid{1};
recording_type = getSetupType(setupid);
        
%retrieve info on setup, device and task
setup_meta = getSetup( setupid );



%% Ephys  Some metadata that will be constant over the whole dataset
if contains(recording_type, 'ephys')
    
        
        % ephys signal types
        types = yaml.loadFile('ephys_types.yaml');
                  
        % Template ephys metadata
        % Here also, you may need to comment out fields that are not
        % appropriate or unknown for your dataset
        ephys = yaml.loadFile('template_ephys.yaml');
        
        % Much of the metadata about the devices in a setup goes into the ephys.json file.
        % Retrieve this info from the bids.Ephys and .Setups table
        % The bids.Ephys table is BIDS compliant, and the field values can
        % be directly copied to our ephys output structure. 
        
        %copy values to corresponding fields
        flds = fields(ephys);
        for i = 1: length(flds)
            if isstring(ephys.(flds{i}) ) % character arrays
                ephys.(flds{i}) = char(ephys.(flds{i})); 
                if isfield(setup_meta, flds{i}), ephys.(flds{i}) = char(setup_meta.(flds{i})); end
                if isfield(dset_meta, flds{i}), ephys.(flds{i}) = char(dset_meta.(flds{i})); end
            else  % numbers
              if isfield(setup_meta, flds{i}), ephys.(flds{i}) = setup_meta.(flds{i}); end
              if isfield(dset_meta, flds{i}), ephys.(flds{i}) = dset_meta.(flds{i}); end              
            end
        end
   
       % ephys_json.body_part = 'Ventral stream (V1,V4,IT)'; % this should be retrieved from FYD!!!!
 
%% MULTIPHOTON metadata constant over dataset    
elseif strcmp(recording_type, 'ophys')
    
        %Predefined parameter fields for 2 photon imaging
        ophys = yaml.loadFile('template_ophys.yaml');

        %retrieve info on setup, device and task
        setup_meta = getSetup( setupid );
       
        %copy values to corresponding fields
        flds = fields(ophys);
        for i = 1:length(flds)
            if isstring(ophys.(flds{i}) )
                ophys.(flds{i}) = char(ophys.(flds{i})); 
                if isfield(setup_meta, flds{i}), ophys.(flds{i}) = char(setup_meta.(flds{i})); end
                if isfield(dset_meta, flds{i}), ophys.(flds{i}) = char(dset_meta.(flds{i})); end
            else
                if isfield(setup_meta, flds{i}), ophys.(flds{i}) = setup_meta.(flds{i}); end
                if isfield(dset_meta, flds{i}), ophys.(flds{i}) = dset_meta.(flds{i}); end                
            end

         %   if isfield(task_meta, flds{i}), ophys.(flds{i}) = char(task_meta.(flds{i})); end
        end

%% fMRI metadata valid over dataset
elseif strcmp(recording_type, 'fMRI')
    warndlg('Not yet implemented')
    return;
end
%% Create table for the _sessions.tsv file

% This will be filled when we go through each session, (no template because
% it only contains a few columns.
SessArray = struct('sessionid', [], 'session_quality', [], 'number_of_trials', [], 'comment', []);


%% Create the sub and sess folders, copy and rename files
% Since we have a list of urls, representing each individual session, we can
% now loop through them to create all the folders, copy and rename all the
% files, and create the neccessay metadata tsv and json files.
% Here either a multiphoton dataset or an ehpys subroutine is called for
% each session based on the recording_type we got from the setup info.
% You will need to write your own subroutine to access specific
% experimental data. The example subroutines give some idea.

% Two examples one for 2p data and one for ephys data
% to extract the correct data for each session;
% SessArray(i) = gen_2P_bids(sess_meta(i), multiphoton_json, dataset_folder);
% SessArray(i) = gen_Ephys_bids(sess_meta(i), ephys_json, dataset_folder);

if strcmp(stupid, 'Gaia')
    SessArray(i) = gen_2P_bids(sess_meta(i), ophys_json, dataset_folder);
    
elseif strcmp(setupid, 'monkey_setup_4')
    %Here is an example produced by Paolo
    mat_dimensions = {'trial_id' 'up_down' 'rot' 'metamer_intact' 'source'};
    for i = 1:length(sess_meta)   
        % Conversion script for Blackrock data
        SessArray(i) = gen_Ephys_bids_humanP(sess_meta(i), ephys, dataset_folder,0,mat_dimensions);

    end
end

%% Write sessions table
SessTbl = struct2table(SessArray);
writetable(SessTbl, fullfile(dataset_folder, 'sessions.tsv'), ...
    'FileType', 'text', ...
    'Delimiter', '\t');


% Add pre-processed MUA as a derivative folder
stimuli = unique({sess_meta.stimulus});
C = strsplit(sess_meta(1).url,sess_meta(1).subject);
for i = 1:length(stimuli)
    mua_sess.url = [C{1},sess_meta(1).subject];
    mua_sess.stimulus = stimuli{i};
    mua_sess.subject = sess_meta(1).subject;
    temp = gen_Ephys_bids_humanP(mua_sess, ephys, dataset_folder,1,[]);
end

   
   
 
   