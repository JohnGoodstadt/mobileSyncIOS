# mobileSyncIOS
A Design Pattern for Mobile Co-Operation - Sample Code

mobileSync is a design Pattern for synchronisarion of Databases between multiple mobile devices.

This gitHub is an IOS Sample that proves the pattern with Unit Tests built to test all areas of the design.

see:
https://docs.google.com/document/d/1GeMxb9cgLpHkXJOmDvy90A3BQn-p774IRR40ng65Ki8/edit?usp=sharing

for full details.

This readme details how to run the sample and what to expect.

1. Download from GitHub and load in to XCode
2. Run the Unit Tests - Product/Test , (⌘U). If run on a simulator you can find 4 sqlite databases representing 3 remote devices and one central server device.db1, device2.db, device3.db and server.db in its document folder.
3. There is a simple GUI interface that writes/reads from 2 devices and a server.
4. Note the unit tests completely deletes and recreates the databases on each run. However, the GUI will keep the DBs on each run. Manually delete them to start again.
5. The code uses 2 helper libraries. One that holds all the local devices calls (mobileHelper) and another that represents the functions that would be on the backend server (serverHelper). serverHelper is in written objective-c but would be translated to PHP/JAVA etc when implemented on a server.
6. The app users a simple employee, manager structure where the manager table is a foreign key into the employee table. The holds simple data items of first name, Last Name and email_address.
7. The App users OpenUDID to create a unique device ID. Thso could be any otehr library as long as each call returns an identicle string.
8. The App use FMDatabase for sqlite DB calls. Any other provider could be used.
9. Timestamps in the App are sortable text e.g. '2016-01-31 10:11:12.123' but unix times could also be used. 
10. This code has been developed and tested against XCode 7.2 and IOS 9.2.
