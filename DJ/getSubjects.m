function  subjects = getSubjects( subnames )

global dbpar

subjects = [];
if nargin == 0
     return
else
    strSel = '';
    for i = 1: length(subnames)
        if i == 1
            strSel = ['subjectid="' subnames{i} '"' ]; 
        else
            strSel = [strSel ' OR subjectid="' subnames{i} '"' ];
        end
    end
end

if strSel == ""
    return
end


Database = dbpar.Database;  %= yourlab
query = eval([Database '.Subjects']);

subjects = fetch(query & strSel, 'species', 'genotype', 'sex', 'birthdate', 'shortdescr');



