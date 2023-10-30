# FYD2BIDS
This is a set of matlab routines to help users convert their datasets to a BIDS compliant format.  
Converting a dataset to BIDS involves :  
. creating folders that are BIDS compliant  
. copying and changing the names of your data files  
. Generating metadata to accompany the data in the form of json sidecar files and tables in tab separated value format (.tsv)  

tsv files for BIDS ephys are for example: 
channels.tsv, contacts,tsv, probes.tsv, events.tsv, subjects.tsv  
To see what data gets saved in these files, see the accompanying jsonc template files.  
These jsonc files can be adapted to your needs, since some fields may not be applicable in your case.

The main routine that provides a starting point and example is dataset2bids.m. Since the metadata that needs
to be associated with ephys differs from that of fMRI or 2P imaging, there are different subroutines for these recording types.

PREREQUISITES  
Install the Datajoint toolbox for matlab :  
In matlab => APPs => Get More APPS => search for Datajoint => ADD Datajoint as Addon.
  
Obtain the neccessary Datajoint templates to access tables in the FYD database.  
Get a credentials mfile to access the database.  
You can get these from Chris van der Togt. 
