function fld = field_if(item, fieldin, fieldout, condition)

if item.(fieldin) == condition
    fld = item.(fieldout);
else
    fld = [];
end
