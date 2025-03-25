## Adding and Validating Metadata
#### Intro  
The converion routines first extract metadata from the FYD database and local logfiles. Following this the extracted metadata is used to fill matlab structures to comply with BIDS and NWB metadata standards. The matlab structures are generated from YAML configuration files and will be adapted when the official metadata standards are updated.

You can see examples of yaml files in the YAML folder of the FYD repository. YAML files are easy to write and contain comments to explain what the data fields mean. They can be viewed and edited both in the matlab and Visual Studio Code editor, read and converted in python and matlab. 

#### Metadata management
Metadata constitutes a spectrum from general documentation that is valid over a whole dataset to details that are valid only within a single experiment. General metadata can be obtained from the FYD database and edited through the [FYD webapp](https://nhi-fyd.nin.nl/#/loginvw). This metadata should be general enough to be usefull for all researchers at the NIN. 
However, a substantial amount of metadata has to be extracted from log and configuration files associated with individual experiments. This is an additional reason why we need different implementations for different recording types, recording systems and preprocessing toolboxes.

#### FYDapp edit
Two properties from the FYD edit interface; Subject and Setup, are essential metadata entries.

<img src="/images/subject.png" >
<img src="/images/setup.png" >

The lower image shows the UI (user interface) in the FYD app to add metadata for a method or setup. Here the recording type should first be selected. Metadata can then be added specifically for that recording type. Since more than one investigator may be using a particular setup or method, this makes it possible to share and copy metadata.

#### EPHYS type
Ephys is for microelectrode recordings; Extracellular, Intracellular, Patchclamp.
Central to ephys metadata are three tables that document probes, electrodes and channels, and the mapping between them. You can create and retrieve these tables using : 
```
initDJ('yourlab')
% Probes-Electrodes-Channels
prelch
```

After selecting a project in the upper area of the UI, create a unique identifier for your probes in the probes tab. These will be associated with electrode Ids in the electrode table. 

The first row of this table functions as default input. When you increase the number of rows these values will be copied to the added rows. By changing the default fields, different sets of electrodes and channels can be created. 

After you enter values that will be applicable to all your probes, enter the number of probes (=rows) to generate probe info for all your probes.

Electrode Ids are created in a similar way. Enter the default metadata on the first line, then enter the total number of electrodes on a probe. This generates all the electrode metadata for a probe. Change the default values on the first line for the next probe, and increase the number of electrodes.
The electrode ids can be associated, in any configuration, with probe Ids.

When you're done creating and editing the channels, press save to save the tables in the BIDS database. When you select your project the next time you open **prelch** the metadata will be retrieved and the tables will be populated.


 In princple, you can also make these tables yourself directly in matlab or from a spreadsheet. See the YAML files; ephys_probes, ephys_electrodes, ephys_channels. Use these templates to construct matlab structure arrays that can be converted to tables and saved as tsv files. You can also export the channel table from prelch.mlapp, adapt it in Excel, import it again and save it to update the table in the database.
 
 Only a limited number of fields is actually required, so you can construct arrays that fit your needs. These should be uploaded to the bids database on FYD and can be reused over multiple experiments and datasets. The matlab mfile ```Examples_YAML_Datajoint.m``` shows how this can be done.
