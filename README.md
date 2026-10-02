# NG-CIIM

A repository for the development of National Gallery-instigated configurations and plugins for its [CIIM](https://www.k-int.com/products/ciim/) middleware (as developed by [Knowledge Integration](https://www.k-int.com/)). Note that this repo does *not* include the Gallery's CIIM itself.

We're starting with [data transformations to plug in to Rosetta](https://github.com/national-gallery/NG-CIIM/tree/3a7b3059a03cb978b84ecaf3d7d344508c650001/Rosetta). After an abortive start with JOLT, and another using [XSLT](https://github.com/national-gallery/NG-CIIM/tree/3a7b3059a03cb978b84ecaf3d7d344508c650001/Rosetta/XSLT), we are now implementing the mappings using [Proteus](https://github.com/national-gallery/NG-CIIM/tree/3a7b3059a03cb978b84ecaf3d7d344508c650001/Rosetta/Proteus).

## Structure

- `_archive` contains working files generated during the development process, including for languages which have been tried and abandoned
- `eodem` is an anomaly: it contains Richard Light's Proteus file for transforming [Museum Data Service](https://museumdata.uk/) data into the [EODEM](https://icom-documentation.mini.icom.museum/working-groups/documentation-standards/eodem-home/) [LIDO](https://icom-documentation.mini.icom.museum/working-groups/lido/lido-overview/) profile
- `Rosetta` contains the working files:the Rosetta configuration file, and libraries for Proteus transformations of CIIM data into various data profiles in JSON and XML serialisations

## A note about branches

- **main** will be used for production tools that are incorporated into the Gallery's live infrastructure
- Once this has been set up, future development work that is *signed off for inclusion* in the production infrastructure will be developed in the **dev** branch
- *All other* development work will take place in **separate branches**
