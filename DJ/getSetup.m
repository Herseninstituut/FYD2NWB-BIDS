function setup_bids = getSetup( setupname )

global dbpar

Database = dbpar.Database;  %= yourlab
query = eval([Database '.Setups']); % setups table in FYD database for particular lab
Sel = ['setupid= "' setupname '"'];
setup_meta = fetch(query & Sel, 'shortdescr', 'longdescr', 'type');

if strcmp(setup_meta.type, 'ephys')
    query = bids.Ephys;  %ephys table in bids general database
    Sel = ['recording_setup= "' setupname '"'];
    setup_bids = fetch(query & Sel, '*' );
    
elseif strcmp(setup_meta.type, '2photon')
    query = bids.MultiPhoton;  %ephys table in bids general database
    Sel = ['recording_setup= "' setupname '"'];
    setup_bids = fetch(query & Sel, '*' );
    
else 
    disp('No type information for this setup! Cannot retrieve bids data.')
end

setup_bids.shortdescr = setup_meta.shortdescr;
setup_bids.longdescr = setup_meta.longdescr;