function [final_nev_event_codes, final_nev_event_times, reference_instance, ...
    lags_matrix, r_matrix] = func_blackrock_align_nev(nev_files)

instances_n     = numel(nev_files);

compiled_nev_event_codes = {};
compiled_nev_event_times = {};

for itt_instance = 1 : instances_n

    temp_evts                           = openNEV(nev_files{itt_instance}, 'nosave');

    compiled_nev_event_codes{itt_instance}  = temp_evts.Data.SerialDigitalIO.UnparsedData;
    compiled_nev_event_times{itt_instance}  = temp_evts.Data.SerialDigitalIO.TimeStamp';

    clear temp_evts
end

realigned_indices = {};

temp_events = [];
temp_times = [];
for itt_instance = 1 : numel(compiled_nev_event_codes)

    if ~isempty(compiled_nev_event_codes{itt_instance})

        if itt_instance == 1
            temp_events(:,itt_instance)     = double(compiled_nev_event_codes{itt_instance});
            temp_times(:,itt_instance)      = double(compiled_nev_event_times{itt_instance});

        elseif numel(compiled_nev_event_codes{itt_instance}) == size(temp_events, 1)
            temp_events(:,itt_instance)     = double(compiled_nev_event_codes{itt_instance});
            temp_times(:,itt_instance)      = double(compiled_nev_event_times{itt_instance});

        elseif numel(compiled_nev_event_codes{itt_instance}) < size(temp_events, 1)
            temp_events(:,itt_instance)     = [double(compiled_nev_event_codes{itt_instance}); ...
                nan(size(temp_events, 1) - numel(compiled_nev_event_codes{itt_instance}), 1)];
            temp_times(:,itt_instance)      = [double(compiled_nev_event_times{itt_instance}); ...
                nan(size(temp_times, 1) -  numel(compiled_nev_event_times{itt_instance}), 1)];

        else
            temp_events                     = [temp_events; nan(numel(compiled_nev_event_codes{itt_instance}) - ...
                size(temp_events, 1), size(temp_events, 2))];
            temp_events(:,itt_instance)     = double(compiled_nev_event_codes{itt_instance});
            temp_times                      = [temp_times; nan(numel(compiled_nev_event_times{itt_instance}) - ...
                size(temp_times, 1), size(temp_times, 2))];
            temp_times(:,itt_instance)      = double(compiled_nev_event_times{itt_instance});

        end

    else
        error("NEV FILES DO NOT CONTAIN SUFFICIENT INFORMATION TO COMPILE MULTIINSTANCE")
    end
end

events_matrix = zeros(max(max(temp_times)), instances_n);
for itt_instance = 1 : numel(compiled_nev_event_codes)
    events_matrix(temp_times(~isnan(temp_times(:,itt_instance)), itt_instance), itt_instance) = ...
        temp_events(~isnan(temp_times(:,itt_instance)), itt_instance);
end

r_matrix        = zeros(numel(compiled_nev_event_codes), numel(compiled_nev_event_codes));
lags_matrix     = zeros(numel(compiled_nev_event_codes), numel(compiled_nev_event_codes));

for itt_instance_1 = 1 : numel(compiled_nev_event_codes)
    for itt_instance_2 = 1 : numel(compiled_nev_event_codes)

            [temp_r, temp_lags] = xcorr(events_matrix(:,itt_instance_1), events_matrix(:, itt_instance_2), 'normalized');
            [   r_matrix(itt_instance_1, itt_instance_2), ...
                lags_matrix(itt_instance_1, itt_instance_2) ] = ...
                                max(temp_r);
            lags_matrix(itt_instance_1, itt_instance_2) = temp_lags(lags_matrix(itt_instance_1, itt_instance_2));

    end
end

reference_instance  = find(~any(lags_matrix<0, 2));
r_matrix            = r_matrix(reference_instance, :);
lags_matrix         = lags_matrix(reference_instance, :);

all_event_times     = [];
all_event_codes     = [];
all_event_instances = [];
for itt_instance = 1 : numel(compiled_nev_event_codes)
        compiled_nev_event_times{itt_instance} = compiled_nev_event_times{itt_instance} + lags_matrix(itt_instance);
        all_event_times         = [all_event_times; compiled_nev_event_times{itt_instance}];
        all_event_codes         = [all_event_codes; compiled_nev_event_codes{itt_instance}];
        all_event_instances     = [all_event_instances; repmat(itt_instance, numel(compiled_nev_event_codes{itt_instance}), 1)];
end

[all_event_times, all_event_indices]    = sort(all_event_times);
all_event_codes                         = all_event_codes(all_event_indices);
all_event_instances                     = all_event_instances(all_event_indices);

all_event_diffs                         = diff(all_event_times);
all_event_diffs(all_event_diffs < 30)   = 0;

final_nev_event_codes   = [];
final_nev_event_times   = [];
temp_codes              = [];
for itt_event = 1 : numel(all_event_codes)-1

    if ~all_event_diffs(itt_event)
        temp_codes = [temp_codes; all_event_codes(itt_event)];
    else
        for itt_simultaneous_codes = 1 : round(numel(temp_codes)/instances_n)

            temp_codes = [temp_codes; all_event_codes(itt_event)];

            temp_modal_code = mode(temp_codes);
            temp_modal_code = temp_modal_code(1);

            final_nev_event_codes = [final_nev_event_codes; temp_modal_code];
            final_nev_event_times = [final_nev_event_times; all_event_times(itt_event)];

            temp_codes(temp_codes == temp_modal_code) = [];

        end
        temp_codes = [];
    end

    if itt_event == numel(all_event_codes)-1
        for itt_simultaneous_codes = 1 : round(numel(temp_codes)/instances_n)

            temp_codes = [temp_codes; all_event_codes(itt_event)];

            temp_modal_code = mode(temp_codes);
            temp_modal_code = temp_modal_code(1);

            final_nev_event_codes = [final_nev_event_codes; temp_modal_code];
            final_nev_event_times = [final_nev_event_times; all_event_times(itt_event)];

            temp_codes(temp_codes == temp_modal_code) = [];

        end
        temp_codes = [];
    end

end

end