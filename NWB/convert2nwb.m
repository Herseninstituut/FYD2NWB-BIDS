function [conversion_status, nwb, path_nwb] = convert2nwb(all_md)

% debug or production

% default values
flag_skip_completed         = true;

global path_codebase        %'D:\Git\'
if isempty(path_codebase)
     % Add your own local path if the global value is empty
    path_codebase = 'I:\Users\togt\Documents\GitHub\';
end

cd(path_codebase);
path_blackrock              = fullfile(cd, 'NPMK');                    % cd(path_codebase);
path_tuckerdavis            = fullfile(cd, 'TDTMatlabSDK');            % cd(path_codebase);
path_intan                  = fullfile(cd, 'Intan-RHX');               % cd(path_codebase);
path_openephys              = fullfile(cd, 'open-ephys-matlab-tools');  %cd(path_codebase);


func_version       = '0.1.0';
nwb               = [];

% store path information
% this contains the basic json file input
sess = all_md.sess_meta;
path_directory = sess.url;

path_nwb = fullfile(path_directory, [sess.sessionid '.nwb']);      %For preprocessed data
path_nwbaq = fullfile(path_directory, [sess.sessionid '_aq.nwb']); %For raw acquisition data

% store information regarding files in raw data source directory
struct_directory = all_md.sess_meta.url;

%% RUN PRECURSORY CHECKS
conversion_status = 'Precursory checks';

% check to see if we need to skip a completed file
if exist(append(path_directory,'\', sess.sessionid, '.nwb'), 'file') && flag_skip_completed
    conversion_status = 'ABORTED - nwb file already present and flag_skip_completed == true';
    nwblog(conversion_status); 
    return
end



%% INITIALIZE NWB
conversion_status = "NWB initialization";

nwb_out = append('Initializing the nwb file for ', sess.sessionid);
nwblog(nwb_out);

% Dataset metadata
dataset = all_md.dataset_meta;
% Task metadata
task = all_md.task_meta;
% incorporate basic metadata
nwb                                 = NwbFile;
nwb.session_description             = char(dataset.shortdescr);
nwb.timestamps_reference_time       = char(datetime('now', 'TimeZone', 'local'));
nwb.general_source_script_file_name = ['convert2nwb.m' ' version ' func_version];                         
%nwb.file_create_date                = char(datetime('today'));
nwb.general_source_script           = fileread(which("convert2nwb"));
nwb.general_experimenter            = char(dataset.author);
nwb.general_institution             = append(dataset.institution_name, ', ',  dataset.institution_adress); % Netherlands Institute For Neuroscience
nwb.general_lab                     = dataset.institution_department_name;
nwb.general_experiment_description  = char(task.task_description);
nwb.session_start_time              = sess.date;
nwb.general_session_id              = sess.sessionid;
nwb.general_stimulus                = sess.stimulus;
nwb.identifier                      = append('sub-', char(sess.subject), '_ses-', char(sess.date), '_exp-', char(sess.stimulus));


%% GRAB SUBJECT INFORMATION
conversion_status = "Subject information processing";

nwblog(append('Adding subject metadata for ', sess.sessionid)); 

subject = all_md.subject_meta;
if strcmp(subject.age, '') && ~strcmp(subject.birthdate, '')
    daynm = days(nwb.session_start_time-datetime(subject.birthdate));
    if strcmp(subject.species, 'Mus musculus') || strcmp(subject.species, 'Rattus norvegicus')
        subject.age = append('P', num2str(round(daynm/7)), 'W');
    else
        subject.age = append('P', num2str(round(daynm/365)), 'Y');
    end
else
    subject.age = 'unknown';
end

general_subject = types.core.Subject( ...
    'age',              subject.age,  ...
    'age_reference',    char(subject.age_reference), ...
    'date_of_birth',    subject.birthdate, ...
    'genotype',         char(subject.genotype), ...
    'sex',              char(subject.sex), ...
    'species',          char(subject.species), ...
    'strain',           char(subject.strain), ...
    'subject_id',       char(subject.subjectid), ...
    'weight',           char(subject.weight)   );                                   

nwb.general_subject = general_subject;

clear subject general_subject


%% RESOLVE RECORDING SAMPLING RATE

setup = all_md.setup_meta;

% Only for electroPHysiology datasets with probes
if strcmp(setup.type, 'ephys')  
    
    nwblog('Identifying sampling rate');

    switch lower(setup.sampling_frequency_unit)
        case "khz" 
            probes_fs = setup.sampling_frequency * 1000;
        case "hz"
            probes_fs = setup.sampling_frequency;
    end


    %% LOAD AND CONVERT ELECTRODE ARRAY INFORMATION

    conversion_status = 'Building electrode table';
    
    map_probes  = all_md.probe_meta;
    map_electrodes = all_md.electrode_meta;
    map_channels = all_md.channel_meta;
    
    % initialize probe table
    electrode_variables     = {'x', 'y', 'z', 'impedance', 'group', 'label' ,'probe', 'subject'};
    electrode_table         = cell2table(cell(0, length(electrode_variables)), ...
                                            'VariableNames', electrode_variables);
    
    % find number of probes in session
    probes_n = size(map_probes, 1);
    
    % itterate through probes
    for probes_itt = 1:probes_n
    
        % subselect the relevant channels/electrodes
        %temp_probe_electrodes = map_electrodes(map_electrodes.probe_id == num2str(probes_itt), :);
        %temp_probe_channels = map_channels(any(temp_probe_electrodes.electrode_id == map_channels.electrode_id'), :);
    
    
        %electrode_idx = arrayfun(@(item) strcmp(item.probe_id, num2str(probes_itt)), map_electrodes);
        electrode_idx = arrayfun(@(item) strcmp(item.probe_id, map_probes(probes_itt).probe_id), map_electrodes);

        temp_probe_array = { map_electrodes(electrode_idx).electrode_id };
        channel_idx = arrayfun( @(item) find(strcmp({map_channels(:).electrode_id}, item)), temp_probe_array);
    
        temp_probe_electrodes = map_electrodes(electrode_idx);
        temp_probe_channels = map_channels(channel_idx);
    
        % create probe device
        temp_device = types.core.Device( ...
            'description',      map_probes(probes_itt).probe_type, ...
            'manufacturer',     map_probes(probes_itt).manufacturer );    
        nwb.general_devices.set(['probe' num2str(probes_itt)], temp_device);
    
        % create electrode group for probe
        temp_electrode_group = types.core.ElectrodeGroup( ...
            'description',      ['electrode group for probe' num2str(probes_itt)], ...
            'device',           types.untyped.SoftLink(temp_device), ...
            'location',         map_probes(probes_itt).location );
        nwb.general_extracellular_ephys.set(['probe' num2str(probes_itt)], temp_electrode_group);
    
        % create reference to table object
        info_probe{probes_itt}.group_object_view = types.untyped.ObjectView(temp_electrode_group);
    
        % store number of electrodes information for each probe for later
        info_probe{probes_itt}.channels_n = length(temp_probe_channels);
    
        % itterate through channels to pull channel-wise data
        for channel_itt = 1:info_probe{probes_itt}.channels_n
    
            % include information that may or may not be available in tsv
            try    temp_x          = temp_probe_electrodes(channel_itt).x;           catch;      temp_x    = 0;            end
            try    temp_y          = temp_probe_electrodes(channel_itt).y;           catch;      temp_y    = 0;            end
            try    temp_z          = temp_probe_electrodes(channel_itt).z;           catch;      temp_z    = 0;            end
            try    temp_impedance  = temp_probe_electrodes(channel_itt).impedance;   catch;      temp_impedance  = -1;     end
    
            % create reference labels
            temp_label_probe    = ['probe' num2str(probes_itt)];
            temp_label_channel  = ['probe' num2str(probes_itt) '_e' num2str(channel_itt)];
            temp_label_subject  = map_probes(probes_itt).subject;
    
            % build electrode information table
            electrode_table = [ electrode_table; {...
                temp_x, temp_y, temp_z, ...
                temp_impedance, ...
                info_probe{probes_itt}.group_object_view, ...
                temp_label_channel, temp_label_probe, temp_label_subject}];
    
        end
    
        clear temp_*
    end
    
    % create the nwb electrode table
    nwb.general_extracellular_ephys_electrodes = util.table2nwb(electrode_table);
    
    % create probe-wise references to the table for pointing to the correct
    % electrodes when neural data is added
    temp_channels_ctr = 0;
    for probes_itt = 1:probes_n
    
        info_probe{probes_itt}.electrode_table_region = ...
            ...
            types.hdmf_common.DynamicTableRegion( ...
            'table',        types.untyped.ObjectView(nwb.general_extracellular_ephys_electrodes),           ...
            'description',  ['probe' num2str(probes_itt)],                                                  ...
            'data',         (1+temp_channels_ctr:info_probe{probes_itt}.channels_n+temp_channels_ctr-1)'    );
    
        temp_channels_ctr = temp_channels_ctr + info_probe{probes_itt}.channels_n;
    
    end
    
    clear temp_*
    nwblog(append('Finished  ', conversion_status, ' for ', sess.sessionid))

    %% PULL AND STORE DATA
    conversion_status = "Data load";
    
    % switch between raw data types
    switch lower(setup.manufacturer)
    
        case "blackrock"
    
            %%%%%%%%%% WARNING TO USER %%%%%%%%%%
            % So this is more challenging that what it appears. Because
            % there are multiple recording systems with different clocks
            % and starting times, but the electrode array mapping files are
            % not parsed by recording system 'instance', we need to align
            % the datafiles. I have made this decision because I think it
            % is far more user friendly, even if it zero pads data. If
            % something looks strange in data stemming from a Blackrock
            % multi-acquisition system recording, it is likely coming from
            % this compilation step. Perhaps we should try to setup up online
            % synchronization of the Blackrock systems...they have a synch port
    
            % add the path to the relevant SDK
            addpath(genpath(path_blackrock))
    
            % find the relevant data files
            ns6_files       = sort(func_find_files(path_directory, '.ns6'))';
            nev_files       = sort(func_find_files(path_directory, '.nev'))';
    
            if numel(ns6_files) ~= numel(nev_files)
                conversion_status = "FAILED - blackrock data is missing nev ~= ns6 counts";
                return
            end
    
            instances_n     = numel(ns6_files);
    
            % find the correct indices to pull from each instance
            if instances_n > 1
                [nev_event_codes, nev_event_times, reference_instance, nev_lags] = ...
                    func_blackrock_align_nev(nev_files);
            end
    
            % begin the data compilation and itterate through
            data_compiled       = [];
            data_analog_units   = [];
            data_resolution     = [];
            instances_itt_formatSpec = 'Reading data from file %d of %d. \n';
            for instances_itt = 1 : instances_n
    
                fprintf(instances_itt_formatSpec, instances_itt, instances_n);
    
                % open the nsX file
                temp_data           = openNSx(ns6_files{instances_itt});
    
                % find the electrode channels
                temp_is_electrode_channel = lower(cat(1,temp_data.ElectrodesInfo.Label));
                temp_is_electrode_channel = find( ...
                                                    sum(temp_is_electrode_channel(:,1:4) == ...
                                                    repmat('chan', size(temp_is_electrode_channel, 1), 1), 2) == 4 | ...
                                                    ...
                                                    sum(temp_is_electrode_channel(:,1:4) == ...
                                                    repmat('elec', size(temp_is_electrode_channel, 1), 1), 2) == 4);
    
                % extract some useful recording metadata
                data_analog_units       = cat(1, data_analog_units, ...
                                                cat(1,temp_data.ElectrodesInfo(temp_is_electrode_channel).AnalogUnits));
                data_resolution         = cat(1, data_resolution, ...
                                                cat(1,temp_data.ElectrodesInfo(temp_is_electrode_channel).Resolution));
    
                % add to the compiled data, taking into account the necessary
                % zero padding
                temp_data_to_add        = [ zeros(numel(temp_is_electrode_channel), nev_lags(instances_itt)), ...
                                            temp_data.Data(temp_is_electrode_channel, :) ];
    
                % add zero pad to end of earlier data if it is now shorter than
                % the data to add
                if size(temp_data_to_add, 2) > size(data_compiled, 2) & ~isempty(data_compiled)
                    data_compiled       = [ data_compiled, zeros(size(data_compiled, 1), ...
                                            size(temp_data_to_add, 2) - size(data_compiled, 2)) ];
                end
    
                % if to-be-added data is shorter than the compiled data after
                % the offset, zero pad. This would be because the order in
                % turning off the systems might be difference than the order
                % turning on
                if size(temp_data_to_add, 2) < size(data_compiled, 2)
                    temp_data_to_add    = [ temp_data_to_add, zeros(size(temp_data_to_add, 1), ...
                                            size(data_compiled, 2) - size(temp_data_to_add, 2)) ];
                end
    
                % do the concatenation
                data_compiled           = [ data_compiled; temp_data_to_add(temp_is_electrode_channel, :) ];
    
                clear temp_*
            end
    
            % check if the number of electrodes in the map matches the loaded
            % data
            if size(data_compiled, 1) ~= size(map_electrodes, 1)
                conversion_status = "FAILED - number of electrode channels in map does not match the data matrix size";
                return
            end
    
            % create general timestamps
            blackrock_timestamps    = double((1:size(data_compiled, 2)) ./ probes_fs)';
            
            % add digital events to the nwb
            digital_events = types.core.TimeIntervals( ...
                ...
                'description',          'digital codes from Blackrock Recording system',    ...
                'colnames',             {'start_time', 'stop_time', 'digital_code'},        ...
                'start_time',           types.hdmf_common.VectorData('data', double(nev_event_times) ./ probes_fs),                       ...
                'stop_time',            types.hdmf_common.VectorData('data', double(nev_event_times) ./ probes_fs),                       ...
                'digital_code',         types.hdmf_common.VectorData('data', double(nev_event_codes))                                     ); 
            nwb.intervals.set('digital_events', digital_events);
    
            % itterate through the probes to add the data to the nwb also need
            % to consider how many probes are on a given recording system. for
            % this, I will assume that a probe is never split across systems
            for probes_itt = 1 : probes_n
    
                % find the local electrodes and remap them
                temp_electrodes       = find(map_electrodes.probe_id == probes_itt);
                temp_channels       = map_channels.channel_id(temp_electrodes);
                [~, temp_indices]   = sort(temp_channels);
    
                % check the resolution (bit2volt) for the system
                temp_bit2volt = unique(data_resolution(temp_electrodes(temp_indices)));
                if numel(temp_bit2volt) > 1
                    conversion_status = "FAILED - resolution of data is not consistent within a probe - not possible";
                    return
                end
    
                % check the units for the probe
                temp_analog_units = unique(data_analog_units(temp_electrodes(temp_indices), 1));
                if strcmpi(temp_analog_units, 'u')
                    temp_bit2volt = temp_bit2volt ./ 1000000;
                else
                    conversion_status = "FAILED - expected Blackrock data as uV";
                    return
                end
                
                % compress the raw data to save some space
                probe_data = types.untyped.DataPipe( ...
                    'data',                 data_compiled(temp_electrodes(temp_indices), :)',           ...
                    'chunkSize',            [probes_fs, 1],                                             ...
                    'compressionLevel',     5,                                                          ...
                    'axis',                 1                                                           ); 
    
                % build the data field
                temp_raw_electrical_series = types.core.ElectricalSeries(                               ...
                    ...
                    'electrodes',           info_probe{probes_itt}.electrode_table_region,              ...
                    'starting_time',        0.0,                                                        ...
                    'starting_time_rate',   probes_fs,                                                  ...
                    'data',                 probe_data,                                                 ...
                    'data_continuity',      'continuous',                                               ...
                    'data_conversion',      single(temp_bit2volt),                                      ...
                    'data_unit',            'volts',                                                    ...
                    'description',          'raw data from single probe recorded with Blackrock',       ...
                    'filtering',            'default filters for ns6 recording on Blackrock',           ...
                    'timestamps',           blackrock_timestamps                                        );
    
                % add to the nwb
                nwb.acquisition.set(['probe_' num2str(probes_itt)], temp_raw_electrical_series);

                nwblog(append('Finished ', conversion_status, ' for ', sess.sessionid));
                clear temp_*
            end
    
    
        case "tucker-davis"
            addpath(genpath(path_tuckerdavis))
            conversion_status = "ABORTED - Tucker-Davis data type not yet supported";
            return
    
        case "intan"
            addpath(genpath(path_intan))
            conversion_status = "ABORTED - Intan data type not yet supported";
            return
    
        case "openephys"
            addpath(genpath(path_openephys))
            conversion_status = "ABORTED - Open Ephys data type not yet supported";
            return
    
        case "neuraviper"
            conversion_status = "ABORTED - NeuraViper data type not yet supported";
            return
    
        otherwise
            return
    end
    
    % NWB EXPORT
    nwblog(append('NWB export to: ', path_nwb));
    nwbExport(nwb, char(path_nwb));

elseif strcmp(setup.type, 'ophys')
 % switch between raw data types
    switch lower(setup.manufacturer)
        
        case 'neurolabware'
          ophys_neurolabware(all_md, nwb, path_nwb, path_nwbaq);
                
        otherwise
           nwblog('Unknown optical physiology setup');
    end
      
end

%% CLEANUP
conversion_status = 'SUCCESS';

end