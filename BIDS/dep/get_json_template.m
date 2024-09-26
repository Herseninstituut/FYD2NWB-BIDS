function template = get_json_template(jsoncfile)

        fid = fopen(jsoncfile, 'r');
        txt = fread(fid, '*char')';
        fclose(fid);
        %get rid of comments in the template jsonc file
        txt = regexprep(txt, '//[^\n]*' , '');
        template = jsondecode(txt); % convert to data structure