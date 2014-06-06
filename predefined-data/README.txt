== Langs ==


== Scripts ==
Primary content: ISO 15924

Source: http://unicode.org/iso15924/iso15924-text.html, version 2012-10-16

Corrections made:
1. The following codes were excluded:
	Zinh  994  Code for inherited script
	Zmth  995  Mathematical notation
	Zsym  996  Symbols
	Zxxx  997  Code for unwritten documents
	Zyyy  998  Code for undetermined script
	Zzzz  999  Code for uncoded script


== Countries ==
Primary content: ISO 3166-1

Sources:
1. http://www.iso.org/iso/home/standards/country_codes/country_names_and_code_elements_txt.htm — corrected case
2. http://www.iso.org/iso/home/standards/country_codes/iso-3166-1_decoding_table.htm — added 'Exceptionally reserved code elements', ' 	Transitionally reserved code elements', 'Indeterminately reserved code elements'
3. http://opengeocode.org/ — added gov_website, stats_website fields

Notes:
1. ISO 3166-1 alpha-3 codes aren't included. They cover the same set of countries, and ISO states that they may be used in specific cases instead of alpha-2 codes. I don't know such cases in economic and finance areas.
2. There are a lot of other 'good' sources of information, including:
* https://www.cia.gov/library/publications/the-world-factbook/appendix/appendix-d.html
* http://www.geonames.org/
* http://opengeocode.org/
* Wikipedia
3. See README.countries.txt for additional info about included data.


== Markets ==
Primary content: ISO 10383

Source: http://www.iso15022.org/MIC/homepageMIC.htm

Corrections made:
1. Names of markets, names of countries and website urls were converted to proper case. I tried to do my best, but errors still can exist.
2. The following code was excluded:
	XXXX  XXXX  No market (e.g. unlisted)
3. Names of the following markets changed for uniqueness:
	CGMH  Citi Match  =>  Citi Match HK
	CITX  Citi Match  =>  Citi Match JP
	CGME  Citi Match  =>  Citi Match GB
	CGMU  Citi Match  =>  Citi Match US

Known issues:
1. Usefulness of acronym column is questionable. Acronyms in original file are non-unique, and the most of markets have no acronyms. May be this column should be dropped.


== Currencies ==


== Issuers ==


== Instruments ==


== Data Providers ==
Predefined data contains some data providers known to me. The list isn't complete.
Ideally predefined data should contain verified data providers for which we have workable import scripts (e.g. Yahoo Finance!). All other data providers should be added manually by users.


------------------------------------------------------------------------
Copyright © 2013, 2014  Basil Peace

This is part of FIDATA.

Copying and distribution of this file, with or without modification,
are permitted in any medium without royalty provided the copyright
notice and this notice are preserved.  This file is offered as-is,
without any warranty.
