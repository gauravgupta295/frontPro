@isTest
public with sharing class SBR_3_0_Queueable_VerifyJobSite_Test {
  private static final String TOKENNAME = 'MuleJWT';
  private static final String ADDRRESULT = 'result';

  @TestSetup
  static void makeData(){
      Account testAccount = SBR_3_0_TestDataFactory.createAccounts(1, true, 'Credit')[0];
      Schema.Location branch = SBR_3_0_TestDataFactory.createLocations(1, false, SBR_3_0_Constants.LOCATION_REC_TYPE_BRANCH)[0];
      branch.Name = 'Branch';
      branch.Company_Code__c = 'X';
      branch.Analysis_Region_Key__c = 'X';
      insert branch;
      Schema.Location jobLocation = SBR_3_0_TestDataFactory.createLocations(1, false, SBR_3_0_Constants.LOCATION_REC_TYPE_JOB_LOC)[0];
      jobLocation.Name = 'Shared';
      jobLocation.City__c = 'Centreville';
      jobLocation.State__c = 'VA';
      jobLocation.Company_Code__c = 'X';
      jobLocation.Analysis_Region_Key__c = 'X';
      jobLocation.Country__c = 'US';
      insert jobLocation;
      List<Credential__c> creds = SBR_3_0_TestDataFactory.createCredentials(1, false);
      creds[0].Name = 'Mule_Token_Endpoint';
      creds[0].Key_Id__c = 'keyid';
      creds[0].Secret__c ='credSecret';
      insert creds;
  }
  @isTest
  static void testValidateAssociatedLocation() {
    String accountId = [SELECT Id FROM Account][0].Id;
    String branchId = [SELECT Id FROM Location WHERE Name= 'Branch'][0].Id;
    String sharedId = [SELECT Id FROM Location WHERE Name= 'Shared'][0].Id;
    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new SBR_3_0_AVS_CalloutMock(6));
    Cache.Org.put(TOKENNAME, 'testToken', 850);
    List<AssociatedLocation> als = SBR_3_0_TestDataFactory.createAssociatedLocations(1, accountId, branchId, sharedId, true);
    System.enqueueJob(new SBR_3_0_Queueable_VerifyJobSiteAddress(als, true));
    Test.stopTest();
    
    List<AssociatedLocation> alPostUpdate = [
      SELECT Id, Address_Validation_Status__c
      FROM AssociatedLocation
      WHERE Address_Validation_Status__c =: SBR_3_0_Constants.STATUS_VALID
    ];
    
    System.assertEquals(
      1,
      alPostUpdate.Size(),
      'Address validation field not updated'
    );
  }

  @isTest
  static void testValidateAssociatedLocationInvalid() {
    String accountId = [SELECT Id FROM Account][0].Id;
    String branchId = [SELECT Id FROM Location WHERE Name= 'Branch'][0].Id;
    String sharedId = [SELECT Id FROM Location WHERE Name= 'Shared'][0].Id;
    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new SBR_3_0_AVS_CalloutMock(7));
    Cache.Org.put(TOKENNAME, 'testToken', 850);
    List<AssociatedLocation> als = SBR_3_0_TestDataFactory.createAssociatedLocations(1, accountId, branchId, sharedId, true);
    System.enqueueJob(new SBR_3_0_Queueable_VerifyJobSiteAddress(als, true));
    Test.stopTest();
    List<AssociatedLocation> alPostUpdate = [
      SELECT Id, Address_Validation_Status__c
      FROM AssociatedLocation
      WHERE Address_Validation_Status__c =: SBR_3_0_Constants.STATUS_INVALID
    ];
    
    System.assertEquals(
      1,
      alPostUpdate.Size(),
      'Address validation field not updated'
    );
  }
}