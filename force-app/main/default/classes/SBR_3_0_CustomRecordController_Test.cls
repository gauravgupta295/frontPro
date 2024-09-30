@isTest
public class SBR_3_0_CustomRecordController_Test {
@testSetup
  static void setupTestData() {
    List<Account> accounts = SBR_3_0_TestDataFactory.createAccounts(2, false);
    accounts[0].Name = 'TestOne';
    accounts[1].Name = 'TestTwo';
    insert accounts;
    Id accId = accounts[0].Id;
    SBR_3_0_TestDataFactory.createContacts(5, accId, true);
    List<AppDefinition> app = [
      SELECT DurableId, Label
      FROM AppDefinition
      WHERE label = 'RAE Frontline'
    ];
    Schema.Location branch = SBR_3_0_TestDataFactory.createLocations(1, true, SBR_3_0_Constants.LOCATION_REC_TYPE_BRANCH)[0];
    Schema.Location loc = SBR_3_0_TestDataFactory.createLocations(1, true, SBR_3_0_Constants.LOCATION_REC_TYPE_JOB_LOC)[0];
    List<AssociatedLocation> jobsiteList=SBR_3_0_TestDataFactory.createAssociatedLocations(2, accounts[0].Id, branch.id, loc.id, false);
      jobsiteList[0].State__c='CA';
      jobsiteList[1].State__c='CA';
      insert jobsiteList;
      Map<String, Object> fldValByFldName = new Map<String, Object>{
      'AppDefinitionId' => app[0].DurableId,
      'FormFactor' => 'Large',
      'UserId' => UserInfo.getUserId()
    };
    List<UserAppInfo> info = new List<UserAppInfo>{
      (UserAppInfo) JSON.deserialize(
        JSON.serialize(fldValByFldName),
        UserAppInfo.class
      )
    };
    insert info;
  }

  @isTest
  private static void whenSearchKeyPresentThenReturnFilteredRecords() {
    String searchKey = '\'%AL%\'';
    List<String> fields = new List<String>{
      'Id',
      'AssociatedLocationNumber'
     };

    Test.startTest();
    SBR_3_0_CustomRecordController.SBR_3_0_CustomRecordResponse response = (SBR_3_0_CustomRecordController.SBR_3_0_CustomRecordResponse) SBR_3_0_CustomRecordController.getFilteredRecords(
      String.join(fields, ', '),
      Schema.SObjectType.AssociatedLocation.getName(),
      ' WHERE AssociatedLocationNumber LIKE ' + searchKey,
      ' ORDER BY LastViewedDate',
      ' LIMIT 10',
      true
    );
      set<string> fieldset=new set<string>();
      for(string field:fields){
          fieldset.add(field);
      }
      SBR_3_0_CustomRecordSelector.SBR_3_0_CustomRecordQueryBuilder builder = new SBR_3_0_CustomRecordSelector.SBR_3_0_CustomRecordQueryBuilder();
      builder.setFields(fieldset);
      builder.setCountClause('AssociatedLocationNumber');
      builder.setAdditionalClause('');
    
    Test.stopTest();
      
    List<AssociatedLocation> jobsites = (List<AssociatedLocation>) response.data;
    System.assertEquals(
      2,
      jobsites.size(),
      'Successfully retrieve filtered Records'
    );
    System.assertEquals(2, response.count, 'Count query ran successfully');
  }

  @isTest
  private static void whenIncorrectParamsProvidedThenThrowException() {
    AuraHandledException auraException;
    String searchKey = '\'%Test%\'';
    List<String> fields = new List<String>{ 'Id', 'Name', 'Phone', 'Email' };

    Test.startTest();
    try {
      SBR_3_0_CustomRecordController.SBR_3_0_CustomRecordResponse response = (SBR_3_0_CustomRecordController.SBR_3_0_CustomRecordResponse) SBR_3_0_CustomRecordController.getFilteredRecords(
        String.join(fields, ', '),
        Schema.SObjectType.Account.getName(),
        ' WHERE Name LIKE ' + searchKey,
        ' ORDER BY Name',
        ' LIMIT 10',
        true
      );
    } catch (AuraHandledException ex) {
      auraException = ex;
    }

    Test.stopTest();

    System.assertEquals(
      auraException.getMessage(),
      'Script-thrown exception',
      'Successfully thrown exception when incorrect field present'
    );
  }
}