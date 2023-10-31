# FYD2BIDS
This is a set of matlab routines to help users convert their datasets to a BIDS compliant format.  
Converting a dataset to BIDS involves :  
. creating folders that are BIDS compliant  
. copying and changing the names of your data files  
. Generating metadata to accompany the data in the form of json sidecar files and tables in tab separated value format (.tsv)  

tsv files for BIDS ephys are for example: 
channels.tsv, contacts,tsv, probes.tsv, events.tsv, subjects.tsv  

To help users understand what needs to be stored, jsonc template files are included with explanatory comments to show what fields need to be filled for the official BIDS convention. With __get_json_template__ they can be converted to a matlab structure.  
These jsonc files can be adapted to your needs, since some fields may not be applicable in your case (simply comment out the fields you don't use).

The main routine that provides a starting point and example is __dataset2bids.m__. As can be seen, some important metadata can be directly generated from the FYD database. Other metadata with details about a dataset may either be generated from log files you save with your experiments or metadata that you have saved separately and is specific for the methods you are using.
For example channels, contacts and probes do not change on every ephys experiment, so you could save the contents of a table with details about every channel to the bids database on the FYD server. There is a __BIDS_example_probes__ and ___channels__ that illustrates how you may generate and store this using Datajoint. The examples also show that it is very easy to create tsv files.

Different recording techniques require different metadata. This is supported in FYD. To register this metadata, select a BIDS type (ephys, multi_photon, fMRI) in the setup tab on the Webapp's editing interface and then press (EDIT BIDS INPUT). BIDS meta data for a particular recording type can be entered here. This entry can later be used to generate a __recording_type.json__ file that needs to be saved with each session in your BIDS dataset. Since different users may use the same setup, the great thing is, they can all make use of this same entry when they generate their own BIDS dataset.

Based on their recording_type two example subroutines have been included for electrophysiology and 2photon data.

PREREQUISITES  
**Every experiment in your dataset has a _session.json file tag, to make it findable and machine readable.** 

Install the Datajoint toolbox for matlab :  
In matlab => APPs => Get More APPS => search for Datajoint => ADD Datajoint as Addon.
  
Obtain the neccessary Datajoint templates to access tables in the FYD database.  
Get a credentials mfile to access the database.  
You can get these from Chris van der Togt. 
