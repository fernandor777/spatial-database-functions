In order to protect the package from netnannies in corporations rejecting the zip because it 
contains executable cmd tools, I have renamed all the CMD scripts by replacing the "." with an "_".

So, once you have downloaded and unzipped the archive, rename the following:

install_cmd to install.cmd 
install_sh to install.sh; chmod u+x install.sh for Linux/Unix users.
(The install.sh script is not as up to date as the Windows command shell. 
 Please update and return to me.)

Then run the install.cmd to create the schema and load the packages.

All the code in these packages should (but may not) conform to Oracle's Locator vs Spatial licensing. 

While difficult, I now support 9i vs 10g+ installations but some functions in 10g cannot be supported 
in 9i so I have implemented a form of conditional compilation that is based on the Windows "findstr" 
utility (cf Unix/Linux "grep/sed"). There are many reasons for this, but mainly the lack of the matrix algebra
packages that the Affine() function uses, and the lack of the MDSYS.ST_* functions introduced at 10g. 
The lack of SDO_UTIL.APPEND() and SDO_UTIL.CONCAT_LINES() functions have been hacked around through 
(illegal for Locator uses) use of SDO_GEOM.SDO_UNION(): but this will be fixed soon as I code a replacement 
for both of these in PL/SQL. 

Another painful thing for 9i/10g support is mdsys.vertex_type with in 9i only has 4 members, but at 10g has 
5: this makes initialisation a pain. So, I have had to rely on my own VERTEX_TYPE and the fuller ST_Point() 
type. The former is "light weight" but the latter is "heavy weight" and was original coded as an exercise 
in writing a proper object in PL/SQL (it is not intendend to replace the ST_* functions introduced at 10g).

Finally, I have tried to detect when only Locator is installed and when Spatial is installed so that the packages
do not infringe licensing when used in Locator (SE/XE) situations. If anyone finds an illegal use please let me
know and I will fix it immediated.

(I am slowly removing dependence on the GF package with a goal to its removal.)

If you find errors on install please email me IMMEDIATELY. Also, if you have problems running the code
also email me (particularly including Oracle ERROR messages). 

If you find the code useful and embed it in your data management processes consider making
a small donation via my website as a lot of work went in to these packages and a little thank you would
be appreciated. If you don't want to throw money, please email me with a thank you or recommendation I
can include on my testimonials page.

Happy Oracling
regards
Simon
