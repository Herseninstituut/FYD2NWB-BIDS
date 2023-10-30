%% Example script to insert probe metadata in the bids.Probes table

initDJ % credentials to access the database

% This is a structure template to create BIDS probe columns
probes_json = get_json_template('ephys_probes.jsonc');

%Fields in the template to create a structure array
ProbFields = fields(probes_json);


numberOfProbes = 2;
%This creates a cell array with metadata for multiple probes
Probcell = cell(length(ProbFields), numberOfProbes);
for i = 1:numberOfProbes  
    Probcell(:,i) = {'L01', 'Neuronexis', '', '', '', ['L01_' num2str(i)], ...
        'neuronexis-probe', 'silicon', randn(1), randn(1), randn(1), ...
        100, 2000, 2000, 'um', 60, 'left', 'V1', 'Paxinos'};
end

%Convert the cellarray to a structure array and insert in Probes table
Probes = cell2struct(Probcell, ProbFields, 1);
insert(bids.Probes, Probes)

%% Show contents of bids.Probes
bids.Probes %Show table contents
describe(bids.Probes) % Show table structure

% delete entries in table bids.Probes where subject is L01
del(bids.Probes & 'subject="L01"')