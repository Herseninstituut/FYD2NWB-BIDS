# FYD2BIDS
This is a set of matlab routines to help users convert their datasets to a BIDS compliant format.  
Converting a dataset to BIDS involves :  
. creating folders that are BIDS compliant  
. copying and changing the names of your data files  
. generating metadata to accompany the data in the form of json sidecar files and tables in tab separated value format (.tsv)  

tsv files for BIDS ephys are for example: 
channels.tsv, contacts,tsv, probes.tsv, events.tsv, subjects.tsv  

To help users understand what needs to be stored, jsonc template files are included with explanatory comments to show what fields need to be filled for the official BIDS metadata schema.  
With __get_json_template__ the jsonc files can be converted to a matlab data structure and used to create structure arrays, that later can be converted and exported to tsv spreadsheet files. The jsonc files can further be adapted to your needs, since some fields may not be applicable to your data. Simply comment out the fields you don't use.

The main routine that provides a starting point and example is __dataset2bids.m__. As you can see, some important metadata can be directly generated from the FYD database. Other details that need to be included as metadata may either be generated from log files you save with your experiments or metadata that you have saved separately and which are specific for the methods you are using.
For example details about channels, contacts and probes do not change on every ephys experiment, so you could save the contents of a table with details about every channel to the **bids** database on the FYD server. There is a __BIDS_example_channels__ , ___contacts__ and __probes__ that illustrates how you may generate and store this metadata using Datajoint. The examples also show you how to create tsv files.

Different recording techniques require different metadata. This is supported in FYD. To register this metadata, select a BIDS type (ephys, multi_photon, fMRI) in the setup tab on the Webapp's editing interface and then press (EDIT BIDS INPUT). BIDS meta data for a particular recording type can be entered here. This entry can later be used to generate a __(ephys, multiphoton or fMRI).json__ file that needs to be saved with each session in your BIDS dataset. Since different users may use the same setup, the great thing is, they can all make use of this same entry when they generate their own BIDS dataset.

Based on their recording_type two example subroutines have been included for electrophysiology and 2photon data.

#### PREREQUISITES  
1.  **Every experiment in your dataset needs to have a _session.json file tag, to make it findable and machine readable.**  

2.  Install the Datajoint toolbox for matlab :  
In matlab => APPs => Get More APPS => search for Datajoint => ADD Datajoint as Addon.

Using Datajoint makes interacting with a MYSQL database a breeze. For example, we have a database named 'bids' with a table named 'Channels'. Simply displaying it's contents can be done by typing `bids.Channels` in your matlab workspace.  
To get info on the fields in the table, simply type `describe(bids.Channels)`. For further usage, see the example scripts.
  
3.  Adapt the Datajoint templates in the `DJ/+yourlab` folder to access tables in your labs FYD database.  
Get a credentials mfile to access the database and adapt the initDJ funtion. 
You can get these from Chris van der Togt. 
