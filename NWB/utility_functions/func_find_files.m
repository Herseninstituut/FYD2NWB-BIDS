function dir_cont = func_find_files(dir_in, search_exp, recurse)

if isstring(dir_in)
    dir_in = char(dir_in);
end

if nargin < 3
    recurse = 1;
end

dir_str = dir(dir_in);
dir_cont = {};

for itt_str = 1 : length(dir_str)

    if ~dir_str(itt_str).isdir && ...
            ~isempty(regexp(dir_str(itt_str).name,search_exp,'match'))

        dir_cont{length(dir_cont) + 1} = [dir_in '/' dir_str(itt_str).name];

    elseif dir_str(itt_str).isdir && ~strcmp(dir_str(itt_str).name,'.') && ...
            ~strcmp(dir_str(itt_str).name,'..') && recurse

        file_name = fullfile(dir_in,dir_str(itt_str).name);
        temp_dir_cont = func_find_files(file_name,search_exp);

        if ~isempty(temp_dir_cont)

            dir_cont((length(dir_cont)+1):(length(dir_cont)+length(temp_dir_cont))) = ...
                temp_dir_cont;
        end
    end
end

if nargin > 2
    good_files = ones(numel(dir_cont), 1, 'logical');
    for ii = 1 : numel(dir_cont)
        if strfind(dir_cont{ii}, 'probe')
            good_files(ii) = 0;
        end
    end
    dir_cont = dir_cont(good_files);
end
end