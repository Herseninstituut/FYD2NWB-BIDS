# FYD2BIDS  
This is a set of matlab routines to help users convert their datasets to a BIDS compliant format.  
Converting a dataset to BIDS involves: 
. creating folders that are BIDS compliant  
. copying and changing the names of your data files  
. generating metadata to accompany the data in the form of json sidecar files and tables in tab separated value format (.tsv) 
[See BIDS Specification](https://bids.neuroimaging.io/specification.html)   

For Electrophysiology BIDS specifies various tsv files: 
channels.tsv, contacts,tsv, probes.tsv, events.tsv, subjects.tsv  

To help users understand what needs to be stored in these files, jsonc template files are included with explanatory comments to show the required and recommended fields that need to be provided to comply with the official BIDS metadata schema.  
With __get_json_template__ the jsonc files can be converted to a matlab data structure and used to create structure arrays. Later these can be converted and exported to tsv spreadsheet files or json files. The jsonc files can easily be adapted by commenting out the fields you don't need or that are not be applicable to your data.

The routines developed here for converting your data rely heavily on the use of the Datajoint toolbox, which you can install as an addon in matlab (See below for instructions). The nice thing about Datajoint is that it makes it super easy to interact with a MSQL database server. This applies to both retrieving data, as well as adding and updating data in various tables.
[Datajoint Documentation](https://datajoint.github.io/datajoint-docs-original/matlab/)

The main routine that provides a starting point and example is __dataset2bids.m__. As you can see, basic metadata can be directly retrieved from the FYD database using Datajoint. Other metadata details that need to be included may either be generated from log files you save with your experiments or metadata that you have saved separately and which are specific for the methods you are using. This means you will have to do some scripting yourself, because only you understand how to retrieve this metadata from your experimental files.  

For example details about channels, contacts and probes for electrophysiology do not change on every experiment. Ideally you would like to save this metadata once and be able to retrieve it any time you need it. To accomodate this, tables for channels, contacts and probes have been defined in a new database called __bids__ on the MYSQL server. So now you can save the contents of tables with the details about every channel, contact and probe for later use. There is an __Examples_BIDS_Datajoint__ mfile that illustrates how you generate and store this metadata using Datajoint. The examples also show you how to create tsv files.

Different recording techniques require different metadata. This is supported in FYD. To register what type of recording technique you are using, select a BIDS type (ephys, multi_photon, fMRI) in the **setup tab** on the FYD Webapp's editing interface and then press `(EDIT BIDS INPUT)`. BIDS meta data for a particular recording type can be entered here. This entry can later be used to generate an __(ephys, multiphoton or fMRI).json__ file that needs to be saved with each session in your BIDS dataset. Since different users may use the same setup, the great thing is, they can all make use of this same entry when they generate their own BIDS dataset.

Based on their recording_type two example subroutines have been included; one for electrophysiology and one for 2photon data.

#### PREREQUISITES  
1.  **Every experiment in your dataset needs to have a _session.json file tag, to make it findable and machine readable.**  

2.  Install the Datajoint toolbox for matlab :  
In matlab => APPs => Get More APPS => search for Datajoint => ADD Datajoint as Addon.

Using Datajoint makes interacting with a MYSQL database a breeze. For example, we have a database named 'bids' with a table named 'Channels'. Simply displaying it's contents can be done by typing `bids.Channels` in your matlab workspace.  
To get info on the fields in the table, simply type `describe(bids.Channels)`. For further usage, see the example scripts.
  
3.  Adapt the Datajoint templates in the `DJ/+yourlab` folder to access tables in your labs FYD database.  
Get a credentials mfile to access the database and adapt the initDJ funtion. 
You can get these from Chris van der Togt. 
