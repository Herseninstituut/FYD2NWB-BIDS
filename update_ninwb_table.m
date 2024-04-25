%update_ninwb_client

lab = 'roelfsemalab';

initDJ(lab)
sess_meta = getsessions(sessionid=sessionid);

query = ninwb.Nwblist;
query.insert( struct('sessionid', sessionid, 'url', sess_meta.url, 'lab', lab ) )