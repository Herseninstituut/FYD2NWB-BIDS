# FYD2NWB-BIDS  
The scripts presented here, help users to convert data from proprietry formats to NWB files per single recording session and following this to organize whole datasets in compliance with the BIDS schema.

**NWB** (Neurodata Without Borders) aims to package data in a standard format that can be accessed with open source tools. This file format has become an international standard for sharing neuroscientific data and is also used by the Allen Brain institute.

**BIDS** (Brain Imaging Data Structure) aims to introduce a standard schema for folder naming and data organisation (The data itself which may have been recorded in proprietry formats is not converted). The BIDS format is a well-known and universally accepted format, that is already the gold-standard for data sharing in human neuroimaging

Since these two operations require the addition of relevant metadata, the tool relies heavily on metadata stored in the FYD (Follow Your Data) system.
FYD_matlab scripts extract metadata from the FYD database thus requiring minimal input from users. Thanks to these routines you have all the flexibility on the user side, in terms of data management - while the once painful process of reformatting the entire data in order to release it after publication, is accounted for.  

### Converting to NWB
Converting session data to NWB files is performed by a service routine that contains various subroutines to convert data from Blackrock, neuropixel, and 2photon imaging files to NWB files. Other propriety formats will follow on your request and with your help.
#### How it works
The service _get_todos.m_ runs on a server, automatically checks a todo list for new conversion requests and if one has been added creates an NWB file.  You need not be concerned with the amount of data that needs to be converted or the time that it takes because it runs independent of your local machine.
##### Validate your metadata
The service routine can only run successfully if it can retrieve all the data and metadata which are neccessary to create an NWB file. To make sure this is possible, you can run the script ```getMetadata('sessionid')``` shown in _set_todo.m_ with the sessionid of your choice to validate your data and metadata. Once you have verified that your metadata sufficiently complies with our metadata standards, you simply register a sessionid to the online conversion todo list and an nwb file automatically appears in the source folder.  
A basic requirement for this service is that each experimental session in a dataset is associated with a ```_session.json``` file in accordance with the principles set out in Follow Your Data ([FYD](https://herseninstituut.sharepoint.com/sites/fyd-doc)).
#### Set_todo.m and how to get started
This script interfaces with the FYD database. For this you will need to install the [Datajoint](https://www.datajoint.com/) toolbox for matlab. See below under requirements how to install Datajoint.

To connect with the FYD database you will also require a credentials file, which contains a username, a password and the name of your lab's database. You can obtain this mfile from the NIN data manager. These files have a comman format; __nhi_fyd_LABparms.m__ (LAB is the abbreviation of your lab like MVP, VandC, etc.).

Download FYD-Matlab and FYD2NWB-BIDS from [github.com/Herseninstituut](https://github.com/Herseninstituut) and save to folders that you can add to your matlab path. 


Try to run _set_todo.m_ in steps in matlab.
This script adds additional paths and makes a connection using Datajoint to the FYD database. Once a valid connection is established with your lab's database you can start retrieving metadata.

Validate your metadata by calling _getMetadata_ with a sessionid. This will collect all metadata associated with a particular session and provide feedback about missing metadata that needs to be added before the data conversion can take place.  

Importantly you will need to provide metadata about the recording system used which is associated with a setup where the data was recorded. Enter this metadata in the setup tab on the FYD webapp. See further instructions for adding metadata [HERE](https://github.com/Herseninstituut/FYD2NWB-BIDS/blob/main/adding_metadata.md).  

At the time of writing, only two types of recording systems are supported: electrophysiology (ephys) and optical physiology (ophys), and we are looking for enthusiasts who would like to extend our service to other disciplines.

Once the metadata is validated, you can register the sessionid for data conversion, by inserting it in a NWB conversion todo list, as shown at the end of the _set_todo.m_ script.

To view the status of the session conversion open the [nwblog](https://nhi-fyd.nin.nl/nwblog.html). This shows whether the conversion has started, at what stage it is, and whether it has successfully finished.

To check whether your NWB file is valid, try to open it and retrieve data. Here is an example script for optical physiology: _read_ophys_nwb.mlx_

You may also like to do the conversion yourself. You can test whether it works by running convert2nwb with the sessionid of your choice. 

##### Basic requirements for NWB conversion;
1.  These routines exploit FYD, so every experiment in your dataset requires a _session.json file tag, to make it findable and machine readable.

2.  Install the Datajoint toolbox for matlab :  In matlab => APPs => Get More APPS => search for Datajoint => ADD Datajoint as Addon.
3. Get a credentials mfile to access the database (You can get these from Chris van der Togt).

Using Datajoint makes interacting with a MYSQL database very easy. For example, we have a database named 'bids' with a table named 'Channels'. Simply displaying it's contents can be done by typing `bids.Channels` in your matlab workspace.  
To get info on the fields in the table, simply type `describe(bids.Channels)`.  
For further usage, see the example scripts.

*In princple the conversion service will do the actual conversion to nwb files, so you will not need extra software. However, if you plan to run the converiosn scripts yourself the following is also required.*

4. Have a current version of matnwb (https://github.com/NeurodataWithoutBorders/matnwb) available on your Matlab path. Also ensure that you have correctly initialized the matnwb library (see the matnwb page for details).

5. Have the SDK's for whichever data format types you wish to convert from. Have them in the same directory as the path for this repo for greatest convenience. e.g., if ~\Github\nin_nwb_converter, then have ~\Github\NPMK)

### Converting to BIDS
The routine to convert a dataset into BIDS involves: 

1. Creating folders that are BIDS compliant (automatically)
2. copying and changing the names of your data files (automatically)
3. generating metadata to accompany the data in the form of json sidecar files and tables in tab separated value format (.tsv) (both automatically and with minimal input from users) [See BIDS Specification](https://bids.neuroimaging.io/specification.html)   


Below, you can find a short description of the requirments.

The only input required by NIN users concerns some of the BIDS metadata related to the recording equipment. For Electrophysiology, BIDS specifies various tsv files: 
channels.tsv, electrodes,tsv, probes.tsv, events.tsv, subjects.tsv
When you validate your metadata (see above) these files have to be present!!

To help users understand what needs to be stored in these files, we provide "yaml" template files, with explanatory comments to show the required and recommended fields that need to be provided to succesfully meet the requirments of the official BIDS metadata schema.
With `` yaml.loadFile(filename) `` the yaml files can be converted to a matlab data structure and used to create structure arrays. Later these can be converted and exported to tsv spreadsheet files or json files. The yaml files can easily be adapted by commenting out the fields you don't need or that are not applicable to your data. *(See FYD_Matlab\YAML)*

The routines developed here for converting your data rely heavily on the use of the Datajoint toolbox, which you can install as an addon in matlab (See above for instructions). The nice thing about Datajoint is that it makes it super easy to interact with a MSQL database server. This applies to both retrieving data, as well as adding and updating data in various tables.
[Datajoint Documentation](https://datajoint.github.io/datajoint-docs-original/matlab/)

The main routine that provides a starting point and example is `` dataset2bids.m ``. As you can see, basic metadata can be directly retrieved from the FYD database using Datajoint. Other metadata details that need to be included may either be generated from log files you save with your experiments or metadata that you have saved (or created) separately. These concern specific features related to the methods you are using. If you have first converted your data to NWB files this metadata should already have been generated and the NWB files will be simply copied to the BIDS dataset and renamed. 
In other cases where you might want to keep the original files you will have to do some scripting yourself, because only you understand how to retrieve this metadata from your experimental files (e.g., things are different for a Blackrock than for an Intan recording system). However, we do hope that as soon as people cover a particular setup, or data format, these variant scripts can be integrated in this tool (in that case, please get in touch with Chris van der Togt!)

For example: in chronic experiments, details about channels, contacts and probes for electrophysiology do not change on every session. Ideally you would like to save this metadata once and be able to retrieve it any time you need it. To accomodate this, tables for channels, contacts and probes have been defined in a new database called __bids__ on the FYD MYSQL server. So now you can save the contents of tables with the details about every channel, contact and probe for later use. 
There is an __Examples_BIDS_Datajoint__ mfile that illustrates how you generate and store this metadata using Datajoint. The examples also show you how to create tsv files. As before, as soon as people populate a table in the database, other users will also be able to use this information when the same animal, or configuration is used, for their analyses and data publications!

Different recording techniques require different metadata. This is now supported in FYD! To register what type of recording technique you are using, select a BIDS type (ephys, ophys, fMRI) in the **setup tab** on the FYD Webapp's editing interface and then press `(EDIT BIDS INPUT)`. BIDS meta data for a particular recording type can be entered here. This entry can later be used to generate an __(ephys, ophys or fMRI).json__ file that needs to be saved with each session in your BIDS dataset. Since different users may use the same setup, the great thing is, they can all make use of this same entry when they generate their own BIDS dataset.

Based on their recording_type two example subroutines have been included; one for electrophysiology and one for 2photon data.

#### TO-DO

1. Check-list: We will provide soon a simple checklist with step-by-step explanations on how to get the conversion done in no time and with minimal input on your side.


Please, if you have any suggestion, get in touch!
