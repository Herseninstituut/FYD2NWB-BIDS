%update_ninwb


initDJ('roelfsemalab')

query = ninwb.Nwblist;

query.insert( struct('sessionid', sess_meta(1).sessionid, 'url', sess_meta(1).url) )