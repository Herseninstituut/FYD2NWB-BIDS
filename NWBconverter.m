%% Calling nwbconverter on vc-server with urls seleced from the FYD database

% Open a connection with the database
initDJ('roelfsemalab')

% retrieve json file urls
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

udpconn = udpclient();

recording = {};
% make a cell array for the urls from the sess_meta table 
recording.urls = {sess_meta.url};

% Get participants
subjects = unique({ sess_meta(:).subject });
recording.sub_meta = getSubjects(subjects);

%metadata about the recording type
setupname = unique({sess_meta.setup});
setupid = setupname{1};
recording.setupid = setupid;
recording.recording_type = getSetupType(setupid);
recording.setup = getSetup(setupid);

% Get mapping probes, electrodes, channels

disp(recording)
%convert to a json string 
str_recording = jsonencode(recording);
% send to server to run NWB conversion
udpconn.write(str_recording)
