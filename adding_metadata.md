## Adding Metadata
#### Intro  
The general procedure followed by the NINwb tool is done in three steps. It first starts by extracting metadata from the FYD database and local logfiles, and then uses this to fill matlab structures generated from YAML files. The YAML files comply with BIDS and NWB metadata standards. These two steps help to maintain flexibility under changing requirements for metadata standards. The matlab structures created this way are then used to create metadata for the converted output.

You can see examples of yaml files in the YAML folder of the FYD repository. YAML files are easy to write and contain comments to explain what the data fields mean. They can be viewed and edited both in the matlab and Visual Studio Code editor, read and converted in python and matlab. 

#### Metadata management
Metadata is not a single entity, a simple list of attributes to add to a dataset. Metadata constitutes a spectrum from general documentation that is valid over a whole dataset to details that are valid only within a single experiment. 

Much of the metadata that is needed for generating NWB files and formatting data in accordance with BIDS can be obtained from the FYD database and edited through the [FYD webapp](https://nhi-fyd.nin.nl/#/loginvw). The FYD database encapsulates as much metadata as possible, but general enough to be usefull for all researchers at the NIN. However, a substantial amount of metadata has to be extracted from log files associated with individual experiments. This is an additional reason why we need different implementations for different recording types, recording systems and preprocessing toolboxes.

#### FYDapp edit
Two examples from the FYD edit interface: Subject and Setup are essential metadata entries.

<img src="https://github.com/Herseninstituut/NINwb/blob/main/images/subject.png" >
<img src="https://github.com/Herseninstituut/NINwb/blob/main/images/setup.png" >

The lower image shows the interface in the FYD app to add metadata for a method or setup. Here the recording type should first be selected. Metadata can then be added specifically for that recording type. Since more than one investigator may be using a particular setup or method, this makes it possible to share and copy metadata.

#### EPHYS type
Ephys is directed at microelectrode recordings; Extracellular, Intracellular, Patchclamp.
To complete the ephys metadata, it is neccessary to include three tables that document the probes, electrodes and channel configuration that was used in an experiment to record neural activity. You can create and retrieve these tables using : 
```
prelch
```

This mlapp helps to create unique probe names, which are associated with electrode ids in the electrode table. The electrode ids can then be associated, in any configuration, with channel ids in the channel table. The first row in each table are default values. When you increase the number of rows these values will be automatically copied to the added rows. By changing the default fields, different sets of electrodes and channels can be created.

 In princple, you can also make these tables yourself directly in matlab or from a spreadsheet. See the YAML files; ephys_probes, ephys_electrodes, ephys_channels. Use these templates to construct matlab structure arrays that can be converted to tables and saved as tsv files. You can also export the channel table from prelch.mlapp, adapt it in Excel, import it again and save it to update the table in the database.
 
 Only a limited number of fields is actually required, so you can construct arrays that fit your needs. These should be uploaded to the bids database on FYD and can be reused over multiple experiments and datasets. The matlab mfile ```Examples_BIDS_Datajoint.m``` shows how this can be done.
