# Data
Data are extracted from Santander Cycle Hire Scheme, Transport for London. Click [here](http://cycling.data.tfl.gov.uk/) to get those raw data.
## Journey Data
Cleaned journey data are stored in the following files:
* data1.csv with journeys made between 13/09/2017 and 19/09/2017
* data2.csv with journeys made between 06/09/2017 and 12/09/2017
* data3.csv with journeys made between 30/08/2017 and 05/09/2017
* data4.csv with journeys made between 23/08/2017 and 29/08/2017
* data5.csv with journeys made between 15/08/2017 and 22/08/2017
* data6.csv with journeys made between 08/08/2017 and 14/08/2017
* data7.csv with journeys made between 01/08/2017 and 07/08/2017

In each comma separated value file, each row represents a single journey made in London. The 1<sup>st</sup> column is the journey duration (in seconds), the 2<sup>nd</sup> is a unique rental ID which does not play a role in our algorithm. The 3<sup>rd</sup> to the 8<sup>th</sup> records the date, month, year, hour, minute, and station ID when the journey terminated. The rest 9<sup>th</sup> to the 14<sup>th</sup> column are the same entries recorded when the journey started.
