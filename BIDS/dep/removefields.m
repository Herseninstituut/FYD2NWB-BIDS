function records = removefields(records, cols)

    flds = fields(records);
    ix = contains(flds, cols);
    records = rmfield(records, flds(ix));