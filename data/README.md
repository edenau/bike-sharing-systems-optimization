# Data
Data are extracted from Santander Cycle Hire Scheme, Transport for London. Click [here](http://cycling.data.tfl.gov.uk/) to get those raw, updated, unclean(?) data. 

## Journey Data
Cleaned journey data are stored in the following files:
* [data1.csv](./data1.csv) with journeys made between 13/09/2017 and 19/09/2017
* [data2.csv](./data2.csv) with journeys made between 06/09/2017 and 12/09/2017
* [data3.csv](./data3.csv) with journeys made between 30/08/2017 and 05/09/2017
* [data4.csv](./data4.csv) with journeys made between 23/08/2017 and 29/08/2017
* [data5.csv](./data5.csv) with journeys made between 15/08/2017 and 22/08/2017
* [data6.csv](./data6.csv) with journeys made between 08/08/2017 and 14/08/2017
* [data7.csv](./data7.csv) with journeys made between 01/08/2017 and 07/08/2017

In each comma separated value file, each row represents a single journey made in London. The 1<sup>st</sup> column is the journey duration (in seconds), the 2<sup>nd</sup> is a unique rental ID which does not play a role in our algorithm. The 3<sup>rd</sup> to the 8<sup>th</sup> records the date, month, year, hour, minute, and station ID when the journey terminated. The rest 9<sup>th</sup> to the 14<sup>th</sup> column are the same entries recorded when the journey started.

## Station Data

Note that data was extracted in October 2017, which might be outdated now. Cleaned station data are stored in [station_info.csv](./station_info.csv), with each row representing a station in the Cycle Hire Scheme. The 1<sup>st</sup> column is the unique station ID sorted in ascending order. Note that some stations are missing so we got 773 stations only although the largest station ID is 826. There is also another strange phenomenon that some stations are not recorded here but somehow appear in journey data where Londoners rented or returned bikes in those ghost stations (e.g. station ID 201). The 2<sup>nd</sup> column shows the capacity of the station, whereas the rest is the latitude-longitude position of the station.
