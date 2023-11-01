%% Example script to insert probe metadata in the bids.Probes table

initDJ % credentials to access the database

% This is a structure template to create BIDS probe columns
probeJson = get_json_template('ephys_probes.jsonc');

%Fields in the template to create a structure array
probeFields = fields(probeJson);


numberOfProbes = 2;
%This creates a cell array with some random metadata for multiple probes
probCell = cell(length(probeFields), numberOfProbes);
for i = 1:numberOfProbes  
    probCell(:,i) = {'L01', 'Neuronexis', '', '', '', ['L01_' num2str(i)], ...
        'neuronexis-probe', 'silicon', randn(1), randn(1), randn(1), ...
        100, 2000, 2000, 'um', 60, 'left', 'V1', 'Paxinos'};
end

%% Convert the cellarray to a structure array and insert in Probes table
probeMeta = cell2struct(probCell, probeFields, 1);
insert(bids.Probes, probeMeta)

%% Show contents of bids.Probes
bids.Probes %Show table contents
describe(bids.Probes) % Show table structure

% delete entries in table bids.Probes where subject is L01
del(bids.Probes & 'subject="L01"')