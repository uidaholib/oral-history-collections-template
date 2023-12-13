# LCOH collection

This collection is highly customized!
The metadata is pulled together from harvesting existing data off of the old website (the old website was build from XML files, but we aren't sure where they are or how to use them anymore).

Main metadata file:

- "lcoh_people.csv" - this file contains a listing of 193 people plus 337 interview records.
    - 193 people represent the interviewees. These were harvested from the old "People" page table. Each interview itself may contain more than one interviewee. Most interviewees get their own listing (but not all!). The objectid matches the url stub of the old "person" page. The person's metadata is harvested from the old "People" table plus from their individual "person" page. These have display_template "person". 37 people have an image.
    - 337 interviews are given the parentid of their connected person record. These records were harvested from each individual "person" page which provided a list of interviews. Their metadata is extracted from the page. They link to the OHMS viewer page. These represent 322 unique interviews, since a few are listed under multiple people records. These have display_template "interview"

Extras:

- "lcoh_index.csv" - this file contains 337 interviews plus 37 person records.
    - This data was harvested from the old LCOH home page Isotope feature.
    - 337 interviews are the actual interviews that link to the OHMS viewer page. These match up with the interview records found in "lcoh_people.csv", however there are a few metadata anomalies different between them.
    - 37 people represent the most popular people (?) with lots of interviews and an image (or are they just people who have an image?). They link to a "person" page, not to an interview.
- "lcoh_export.csv" - this file contains a list of PDF transcripts and outlines, exported from CONTENTdm.
    - 317 pdf files. These have a "object_location" pointing to current file on libobjects server.
    - Each has a bunch of extra metadata that *mostly* lines up with the "lcoh_people.csv", but there are some anomalies, not sure which is correct.
    - These aren't represented or available on the old LCOH site--they are linked from within the XML file of each interview. The download appears only when you click the "transcript" button on OHMS viewer.

## OHMS viewer

The OHMS viewer is hosted on our Reclaim server.
The XML files for the viewer are managed in https://github.com/uidaholib/lcoh_viewer.
These XML files have to be on the Reclaim server.
