%% Example script to insert channels metadata in the bids.Channels table
%this script shows you how to use Datajoint to generate and retrieve metadata

initDJ % credentials to access the database and initialization of Datajoint

% This is a structure template to create BIDS channel columns
channelsJson = get_json_template('ephys_channels.jsonc');

%Fields in the template to create a structure array
chanFields = fields(channelsJson);

numberOfChannels = 1024;
%This creates a cell array with metadata for multiple channels
chanCell = cell(length(chanFields), numberOfChannels);
for i = 1:numberOfChannels  
    chanCell(:,i) = {'L01', ['L01_' num2str(i)], 'EXT', 'mV', 30, 'KHz',...
        'MUAe', 'Multiunit Activity', 'none', 'High Pass, rectification, Low Pass', ...
        num2str(randi(10,1)), 'Qualty estimate between 1-10', 1.0, 0.0, ...
        0, -1, 'Chamber screw'};
end

%Convert the cellarray to a structure array and insert in Probes table
channelMeta = cell2struct(chanCell, chanFields, 1);

%% Save to database if neccessary 
insert(bids.Channels, channelMeta)

%% Retreive channel metadata from the database, selecting by subject
channelMeta  = fetch(bids.Channels & 'subject="L01"', '*');

%this will get all columns which you might not want, to restrict the output
%to the fields you used to generate this metadata
channelMeta = removefields(channelMeta, chanFields);

%% saving metadata to a tsv file
temp_folder = uigetdir();
ChannelTbl = struct2table(channelMeta);
writetable(ChannelTbl, fullfile(temp_folder, 'channels.tsv'), ...
       'FileType', 'text', ...
       'Delimiter', '\t');



%% Show contents of bids.Channels
bids.Channels %Show table contents
describe(bids.Channels) % Show table structure

% delete entries in table bids.Probes where subject is L01
del(bids.Channels & 'subject="L01"')