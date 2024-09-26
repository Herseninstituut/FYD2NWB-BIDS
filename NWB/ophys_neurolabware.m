function ophys_neurolabware(all_meta, nwb, path_nwb, path_nwbaq)


            % to obtain extra metadata for a recording we will need to retrieve the sbx file metadata
            % task = all_meta.task_meta;
            setup = all_meta.setup_meta;
            ophys = all_meta.ophys; % Collected metadata from source files and setup
            sess = all_meta.sess_meta;
            nwblog(append('Adding Neurolabware metadata for ', sess.sessionid));

            filepath = fullfile(sess.url, [sess.sessionid '_normcorr']); 
            if ~isfile([filepath '.sbx'])
                conversion_status = append('ABORTING: ', filepath, '.sbx cannot be found!'); 
                return
            end

            %DEFINE AND REGISTER DEVICES
            microscope = types.core.Device( 'description', setup.shortdescr, ...
                                          'manufacturer', setup.manufacturer );
            nwb.general_devices.set('Microscope', microscope);
            
            display = types.core.Device( 'description', '527x296mm 1920x1080px at 150mm distance', ...
                                         'manufacturer', 'DELL' );
            nwb.general_devices.set('Display', display); 
                       
            camera = types.core.Device( 'description', 'G-609 GigE Vision camera for epifluorescence', ...
                                         'manufacturer', 'Allied Vision' );
            nwb.general_devices.set('Camera', camera); 
 
            % Export a temporary copy to use for the sbx files later
            nwbExport(nwb, 'temp_aq.nwb');
            
            %NWB for optical physiology begins with defining an optical channel
            optical_channel = types.core.OpticalChannel( ...
            'description', 'Hamamatsu H10770B-40 GaAsP PMT', ...
            'emission_lambda', 600.);
        
            imaging_plane_name = 'imaging_plane'; % How to deal with splits ?!!!!
            imaging_plane = types.core.ImagingPlane( ...
                'optical_channel', optical_channel, ...
                'description', ophys.task_description, ...
                'device', types.untyped.SoftLink(microscope), ...
                'excitation_lambda', ophys.laser_excitation_wave_length, ...
                'imaging_rate', ophys.sampling_frequency, ...
                'indicator', ophys.indicator, ...
                'location', ophys.location);
            nwb.general_optophysiology.set(imaging_plane_name, imaging_plane);
                                      
            nwblog(append('Adding behavioural event data for  ', sess.sessionid)); 
            % POINT WHERE IT DEPENDS ON IMAGING TOOLBOX USED
            switch lower(ophys.image_processing_toolbox)
                case 'specseg'
                    
                    % BEHAVIOURAL DATA; running and eye poosition
                    % I've simply put them all in timeseries objects
                    behavioral_process_obj = types.core.ProcessingModule('description', 'Behavioral data store.');
                    behavioral_time_series = types.core.BehavioralTimeSeries();
                    
                    %Retrieve all behavioural events
                    events = all_meta.events;
                    if isfield(events, 'run_events')
                        speed_time_series = types.core.TimeSeries( ...
                            'data', events.run_events.speed, ...
                            'description', 'Velocity of the subject over time.', ...
                            'data_unit', 'cm/s', ...
                            'starting_time', events.run_events.time(1), ...
                            'starting_time_rate', ophys.sampling_frequency ...
                        );
                    
                        behavioral_time_series.timeseries.set('Run_speed', speed_time_series);
                    end
                    if isfield(events, 'pupil_events')
                        pupil_events = events.pupil_events; % This is a table
                        col_names = pupil_events.Properties.VariableNames;
                        if sum(contains(col_names, {'Pos', 'time'})) == 2
                            pupil_Pos_time_series = types.core.TimeSeries( ...
                                'data', events.pupil_events.Pos', ...      % Needs to be tgransposed
                                'description', 'Pupil recording 2-D; position(x,y)', ...
                                'data_unit', 'pixels', ...
                                'starting_time', events.pupil_events.time(1), ...
                                'starting_time_rate', ophys.sampling_frequency ...
                            );                  
                            behavioral_time_series.timeseries.set("Pupil_position", pupil_Pos_time_series);
                        end
                        if sum(contains(col_names, {'Area', 'time'})) == 2
                            pupil_Area_time_series = types.core.TimeSeries( ...
                                'data', events.pupil_events.Area, ...
                                'description', 'Pupil recording 1-D; Area', ...
                                'data_unit', 'pixels?', ...
                                'starting_time', events.pupil_events.time(1), ...
                                'starting_time_rate', ophys.sampling_frequency ...
                            );                  
                            behavioral_time_series.timeseries.set("Pupil_area", pupil_Area_time_series);
                        end                                                  
                    end
                    % if events.lick_events
                    behavioral_process_obj.nwbdatainterface.set('BehavioralTimeSeries', behavioral_time_series);
                    nwb.processing.set('behavior', behavioral_process_obj);
                    
                   % We also need to handle the stimulus/task event tables.
                   if isfield(events, 'task_events')
                        task_events = events.task_events;
                        col_names = task_events.Properties.VariableNames;
                        data = [];
                        if any(contains(col_names, 'texture'))
                           data = task_events.texture; % dimension has to be shifted to obtain column height as last dimension  
                            
                        elseif any(contains(col_names, 'log'))
%                            data = zeros(1,2,length(task_events.log));
                            data(1,:,:) = task_events.log';   %% needs to be transposed
                           % data = randi(255, [1, 2, 200]);
                        end
                        distance = 'n.a.';
                        field_of_view = 'n.a.';
                        if isfield(setup, 'display')
                            distance = setup.display.ScreenDistance;
                            field_of_view = [setup.display.Scrnwide, setup.display.Scrnhigh, 0];
                        end
                        optical_series = types.core.OpticalSeries( ...
                            'distance', distance, ...  %  (single) Distance from camera/monitor to target/eye.
                            'field_of_view', field_of_view, ...  %  (single) Width, height and depth of image, or imaged area, in meters.
                            'orientation', 'upper left', ...  % required
                            'device', types.untyped.SoftLink(display), ...
                            'data', data, ...
                            'data_continuity', 'step', ...
                            'data_unit', 'n.a.', ...
                            'timestamps', task_events.time(:), ...
                            'description', 'The images presented to the subject as stimuli' ...
                        );
                        nwb.stimulus_presentation.set('StimulusPresentation', optical_series);
                   end
 
                   %ROI DATA and metadata 
                   if isfield(all_meta, 'ROI_data')
                        % Gets all ROI related metadata from SPSIG.mat files
                        ROI_data = all_meta.ROI_data;
                        
                        %Create ophys module to store all roi related material
                        ophys_module = types.core.ProcessingModule('description', 'Contains 2P calcium imaging data');

                        nwblog(append('Adding Spectral component images', sess.sessionid));
%                         Spec_str = arrayfun(@(x) types.untyped.ObjectView(num2str(x)), ROI_data.Sax); %, 'UniformOutput', false
%                         
%                         ImageOrder = types.core.ImageReferences(...
%                             'data', Spec_str ...
%                         );
                        SpecImg = types.core.Images( ...
                            'description', 'Spectral component images');
                         %   'order_of_images', ImageOrder );
                                             
                        for i = 1:size(ROI_data.SPic,3)
                            Img = ROI_data.SPic(:,:,i)';
                            R = sort(Img(:));
                            p = round(0.999*size(R,1));
                            t = R(p);
                            Img(Img>t) = t; %CutOff
                            spec_image = types.core.GrayscaleImage( ...
                            'data', Img, ...  % required
                            'description', 'Spectral Component' ...
                            );
                            SpecImg.image.set(append('spectral_component_', num2str(ROI_data.Sax(i))), spec_image);
                        end
                        ophys_module.nwbdatainterface.set('SpectralImages', SpecImg);
                        
                        
                        %Supplementary images (Background max, average)
                        nwblog(append('Adding supplementary images ', sess.sessionid));

                        RefImg = types.core.Images( ...
                            'description', 'Reference Images: rois, average and max over time'...
                        );

                       % Mask pixel values denote rois
                        Mask = ROI_data.Mask;
                        pix_image = types.core.GrayscaleImage( ...
                            'data', Mask, ...  % required
                            'description', 'ROIS pixel image' ...
                        );
                        RefImg.image.set('pix_image', pix_image);

                      % Average image
                        Imavg = ROI_data.BImgAverage;
                        R = sort(Imavg(:));
                        p = round(0.999*size(R,1));
                        t = R(p);
                        Imavg(Imavg>t) = t;
                        avg_image = types.core.GrayscaleImage( ...
                            'data', Imavg, ...  % required
                            'description', 'Background image average over time' ...
                        );
                        RefImg.image.set('avg_image', avg_image);

                       % Back ground image max
                        Imax = ROI_data.BImgMax;
                        R = sort(Imax(:));
                        p = round(0.999*size(R,1));
                        t = R(p);
                        Imax(Imax>t) = t;
                        max_image = types.core.GrayscaleImage( ...
                            'data', Imax, ...  % required
                            'description', 'Background image max over time' ...
                        );
                        RefImg.image.set('max_image', max_image);
                        ophys_module.nwbdatainterface.set('SummaryImages', RefImg);


                       nwblog(append('Adding segmentation data for ', sess.sessionid));
                       % the number of ROIS are in the second dimension
                       %So the data needs to be transposed
                       nRois = size(ROI_data.sigCorrected,2);

                       line_mode = 1.0;
                       if strcmp(ophys.image_acquisition_protocol, 'bidirectional'), line_mode = 0.5;  end                     
                       scan_line_time = 1/ophys.scanning_frequency*1000*line_mode; %in ms
                       med_pos = uint16(zeros(nRois, 2)); %median position of roi in frame

                       [x, y] = deal([]);
                       num_pixels_per_roi = uint16(zeros(nRois, 1)); % Column vector
                       for i = 1:nRois               
                           [iy, ix] = find(ROI_data.Mask == i);
                            med_pos(i,:) = median([iy, ix]);
                            x = [x; ix(:)]; % Create a column vector
                            y = [y; iy(:)];
                            num_pixels_per_roi(i) = numel(ix);
                       end
                       % Create a struct
                        pixel_mask = struct;
                        pixel_mask.x = uint32(x);
                        pixel_mask.y = uint32(y);
                        pixel_mask.weigth = single(ones(size(x)));

                       if line_mode == 1.0 % unidirectional
                          delays = (med_pos(:,1) + med_pos(:,2)/796) * scan_line_time;
                       else
                          delays = med_pos(:,1) * scan_line_time; % bidirectional
                       end
                    %   img_mask = types.hdmf_common.VectorData('data', ROI_data.Mask', 'description', 'roi image mask');
                       pix_mask = types.hdmf_common.VectorData('data', pixel_mask, 'description', 'roi pixel position (x,y) and pixel weight');
                       vi_mask = types.hdmf_common.VectorIndex('data', cumsum(num_pixels_per_roi), ...
                                                               'target', types.untyped.ObjectView(pix_mask), ...
                                                               'description', 'Indices into pixel mask');
                       plane_segmentation = types.core.PlaneSegmentation( ...
                            'description', 'output from imaging plane', ...
                            'imaging_plane', types.untyped.SoftLink(imaging_plane), ...
                            'colnames', {'roi_area', 'roi_covariance', 'roi_delay'}, ...
                            'pixel_mask', pix_mask, ...
                            'pixel_mask_index', vi_mask, ...
                            'roi_area', types.hdmf_common.VectorData('data', ROI_data.PP.A(:), 'description', 'roi area in pixels'), ...
                            'roi_covariance', types.hdmf_common.VectorData('data', ROI_data.PP.Rvar(:), 'description', 'roi covariance (R^2)'), ...
                            'roi_delay', types.hdmf_common.VectorData('data', delays, 'description', 'roi delay in ms from frame onset') ...
                       );
                       img_seg = types.core.ImageSegmentation();
                       img_seg.planesegmentation.set('PlaneSegmentation', plane_segmentation);
                       ophys_module.nwbdatainterface.set('ImageSegmentation', img_seg);


             % Fluorescence traces   
                       Fluorescence = types.core.Fluorescence();
                       roi_table_region = types.hdmf_common.DynamicTableRegion( ...
                            'table', types.untyped.ObjectView(plane_segmentation), ...
                            'description', 'all_rois', ...
                            'data', (0:nRois-1)');

                       % sig corrected
                       roi_corrected = types.core.RoiResponseSeries( ...
                            'rois', roi_table_region, ...
                            'data', ROI_data.sigCorrected', ...  %Transposed  data!!!!
                            'description', 'DF/F for each roi corrected for background signal', ...
                            'data_unit', 'DF/F', ...
                            'starting_time_rate', ophys.sampling_frequency, ...
                            'starting_time', ROI_data.frameTimes(1) );

                       Fluorescence.roiresponseseries.set('Corrected', roi_corrected);

                        % sig background
                       roi_neuropil = types.core.RoiResponseSeries( ...
                            'rois', roi_table_region, ...
                            'data', ROI_data.sigBack', ...  %Transposed  data!!!!
                            'description', 'Background signal surrounding each roi', ...
                            'data_unit', 'lumens', ...
                            'starting_time_rate', ophys.sampling_frequency, ...
                            'starting_time', ROI_data.frameTimes(1) );

                       Fluorescence.roiresponseseries.set('Neuropil', roi_neuropil);

                        % sig raw
                       roi_raw = types.core.RoiResponseSeries( ...
                            'rois', roi_table_region, ...
                            'data', ROI_data.sigraw', ...  %Transposed  data!!!!
                            'description', 'Raw signal from each roi', ...
                            'data_unit', 'lumens', ...
                            'starting_time_rate', ophys.sampling_frequency, ...
                            'starting_time', ROI_data.frameTimes(1) );

                       Fluorescence.roiresponseseries.set('Raw', roi_raw);
                       ophys_module.nwbdatainterface.set('Fluorescence', Fluorescence);                       


                       nwb.processing.set('ophys', ophys_module);
                  end
            otherwise
                    nwblog('ERROR: Unknown imagaging toolbox');
            
            end
            
            % NWB EXPORT
            nwblog(append('NWB export to: ', path_nwb));          
            nwbExport(nwb, char(path_nwb));
           
            %% Finally add the registered image movie
            nwblog(append('Adding Normcorr image data for ', sess.sessionid)); 
            nwbaq = nwbRead('temp_aq.nwb');
            nwbaq.file_create_date = [];
            
            % compress the data
%             fData = squeeze(sbxread(filepath, 0, ophys.number_of_frames));
%             fData_compress = types.untyped.DataPipe( ...
%                 'data', fData, ... & sbxread(filepath, 0, ophys.number_of_frames), ...
%                 'compressionLevel', 3, ...
%                 'chunkSize', [1, size(fData,2), size(fData,3)], ...
%                 'axis', 1);
%             sbxread(filepath, 0,0);
%             Shape = info.Shape;
%             Shape(3) = max_idx; % ophys.number_of_frames;

            Shape = str2num(ophys.pixel_dimensions); %#ok<ST2NM> 
            Shape(3) = ophys.number_of_frames;
            m = memmapfile([filepath '.sbx'], 'Format',{'uint16', Shape, 'x'});
            fData = m.Data.x;

            InternalTwoPhoton = types.core.TwoPhotonSeries( ...
            'imaging_plane', types.untyped.SoftLink(imaging_plane), ...
            'data', fData, ... % squeeze(sbxread(filepath, 0, ophys.number_of_frames)), ... %fData_compress, ... 
            'scan_line_rate', ophys.scanning_frequency, ...
            'data_unit', 'lumens', ...
            'device', types.untyped.SoftLink(microscope), ...
            'pmt_gain', ophys.pmt_gain(1), ...
            'starting_time', 0.0, ...
            'starting_time_rate', ophys.sampling_frequency, ...
            'starting_time_unit', 'seconds' );

            nwbaq.acquisition.set('2pInternal', InternalTwoPhoton);
            
            % NWB EXPORT
            nwblog(append('NWB export to: ', path_nwbaq));  
            nwbExport(nwbaq, 'temp_aq.nwb');
            movefile('temp_aq.nwb', char(path_nwbaq))
            
%             ExternalTwoPhoton = types.core.TwoPhotonSeries( ...
%                 'external_file', 'images.tiff', ...
%                 'imaging_plane', types.untyped.SoftLink(imaging_plane), ...
%                 'external_file_starting_frame', 0, ...
%                 'format', 'tiff', ...
%                 'starting_time_rate', char(ophys.scanning_frequency), ...
%                 'starting_time', 0.0, ...
%                 'data_unit', 'lumens');
% 
%             nwb.acquisition.set('2pExternal', ExternalTwoPhoton);