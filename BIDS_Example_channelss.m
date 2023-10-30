%% Example script to insert channels metadata in the bids.Channels table

initDJ % credentials to access the database

% This is a structure template to create BIDS probe columns
channels_json = get_json_template('ephys_channels.jsonc');

%Fields in the template to create a structure array
ChanFields = fields(channels_json);

numberOfChannels = 1024;
%This creates a cell array with metadata for multiple channels
Chancell = cell(length(ChanFields), numberOfChannels);
for i = 1:numberOfChannels  
    Chancell(:,i) = {'L01', ['L01_' num2str(i)], 'n/a', 'EXT', 'mV', 30, 'KHz',...
        '', 'MUAe', 'Multiunit Activity', 'none', 'High Pass, rectification, Low Pass', ...
        num2str(randi(10,1)), 'Qualty estimate between 1-10', 1.0, 0.0, ...
        0, -1, 'Chamber screw', ''};
end

%Convert the cellarray to a structure array and insert in Probes table
Channels = cell2struct(Chancell, ChanFields, 1);

%Save to database if neccessary 
insert(bids.Channels, Channels)

%Channels  = fetch(bids.Probes & 'subject="L01"', '*');
temp_folder = uigetdir();
ChannelTbl = struct2table(Channels);
writetable(ChannelTbl, fullfile(temp_folder, 'channels.tsv'), ...
       'FileType', 'text', ...
       'Delimiter', '\t');



%% Show contents of bids.Probes
bids.Channels %Show table contents
describe(bids.Channels) % Show table structure

% delete entries in table bids.Probes where subject is L01
del(bids.Channels & 'subject="L01"')