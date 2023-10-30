function bids_struct = makebidscompliant(bids_struct, fyd_struct)

%In the FYD bids database the fields are in snake case
% For BIDS the fields are now in Pascal case
% This may change in the future!!

flds = fields(fyd_struct);
for i = 1: length(flds)
    [~, Pascalfield] = snake2camel(flds{i});
    
    bids_struct.(Pascalfield) = fyd_struct.(flds{i});   
end