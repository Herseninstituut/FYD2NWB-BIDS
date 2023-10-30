function Out = remove_empty(In)

 flds = fieldnames(In);
  for i = 1:length(flds)
     fld = flds(i);
     if isempty(In.(fld))
         In = rmfield(In,fld);
     end
  end
 
  Out = In;