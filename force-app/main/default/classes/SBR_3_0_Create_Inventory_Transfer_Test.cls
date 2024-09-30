@isTest
public class SBR_3_0_Create_Inventory_Transfer_Test {
    @TestSetup
  static void makeData() {
    Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];

    String uName = 'admin' + DateTime.now().getTime() + '@SBRtestorg.com';
    User admin = new User(
      Alias = 'admin',
      Email = 'adminuser1@testorg.com',
      RepId__c = '1092345',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Admin1',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = p.Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = uName
    );
    insert admin;

    Schema.Location loc = new Schema.Location();
    loc.recordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
    loc.Name = '1799 Innovation Point';
    loc.Street_Address__c = '1799 Innovation Point';
    loc.State__c = 'SC';
    loc.Zip_Code__c = '29715';
    loc.Branch_Location_Number__c = '0411';
    insert loc;

    User_Location__c ul = new User_Location__c(
      User__c = admin.Id,
      Branch__c = loc.Id,
      ProfileBranche__c = loc.Id    //Added by pankaj for FRONT-17954,FRONT-19128
    );
    insert ul;
  }
    @IsTest
    static void methodName(){
        user userObj  = [SELECT id from user where  Alias = 'admin' limit 1];
        User_Location__c userLocationObj = [SELECT id,user__c,branch__c FROM User_Location__c limit 1];
        system.debug('userLocationObj'+userLocationObj);
        system.debug('userObj'+userObj);
        Test.startTest();
        	SBR_3_0_Create_Inventory_Transfer_Cntr.getLoggedInUserLocation('test');
        	SBR_3_0_Create_Inventory_Transfer_Cntr.getLoggedInUserLocation(userObj.id);
        Test.stopTest();
        
    }
}