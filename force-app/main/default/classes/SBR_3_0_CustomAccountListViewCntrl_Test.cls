@isTest
private class SBR_3_0_CustomAccountListViewCntrl_Test {
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
  private static void whenSearchKeyPresentThenReturnFilteredAccounts() {
    String searchKey = '\'%Test%\'';
    List<String> fields = new List<String>{
      'Id',
      'Name',
      'Phone',
      'Account_Type__c',
      'Record_Type_Text__c',
      'Driver_s_License_State__c',
      'Drivers_License__c',
      'E_mail_Address__c',
      'BillingStateCode',
      'BillingStreet',
      'BillingPostalCode',
      'BillingCountryCode'
    };

    Test.startTest();
    SBR_3_0_CustomAccountListViewController.SBR_3_0_CustomAccountListViewResponse response = (SBR_3_0_CustomAccountListViewController.SBR_3_0_CustomAccountListViewResponse) SBR_3_0_CustomAccountListViewController.getFilteredAccounts(
      '',  
      String.join(fields, ', '),
      Schema.SObjectType.Account.getName(),
      ' WHERE Name LIKE ' + searchKey,
      ' ORDER BY Name',
      ' LIMIT 10',
      true
    );
    Test.stopTest();
    List<Account> accounts = (List<Account>) response.data;
    System.assertEquals(
      2,
      accounts.size(),
      'Successfully retrieve filtered accounts'
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
      SBR_3_0_CustomAccountListViewController.SBR_3_0_CustomAccountListViewResponse response = (SBR_3_0_CustomAccountListViewController.SBR_3_0_CustomAccountListViewResponse) SBR_3_0_CustomAccountListViewController.getFilteredAccounts(
        '',  
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

  @isTest
  private static void customAccountListViewSelectorTest(){
    List<String> fields = new List<String>{
      'Id',
      'Name',
      'Phone',
      'Account_Type__c',
      'Record_Type_Text__c',
      'Driver_s_License_State__c',
      'Drivers_License__c',
      'E_mail_Address__c',
      'BillingStateCode',
      'BillingStreet',
      'BillingPostalCode',
      'BillingCountryCode'
    };

    Set<String> fieldsSet = new Set<String>{
      'Id',
      'Name',
      'Phone',
      'Account_Type__c',
      'Record_Type_Text__c',
      'Driver_s_License_State__c',
      'Drivers_License__c',
      'E_mail_Address__c',
      'BillingStateCode',
      'BillingStreet',
      'BillingPostalCode',
      'BillingCountryCode'
    };


    SBR_3_0_CustomAccountListViewSelector.SBR_3_0_CustomAccountListViewQueryBuilder builder = new SBR_3_0_CustomAccountListViewSelector.SBR_3_0_CustomAccountListViewQueryBuilder();
    builder.setSearchKey('Test');
    String searchKey = builder.getSearchKey();

    builder.setFields(fieldsSet);
    Set<String> fieldsSetSelector = builder.getFields();

    builder.setOrderClause(' ORDER BY Name');
    String orderClause = builder.getOrderClause();

    builder.setLimitClause(' LIMIT 10');
    String limitClause = builder.getLimitClause();

    builder.setObjectName('Account');
    String objectName = builder.getObjectName();

    String whereClauseSelector = ' WHERE Name LIKE ' + '\'' + searchKey + '\'';
    builder.setWhereClause(whereClauseSelector);
    String whereClause = builder.getWhereClause();

    Test.startTest();
      SBR_3_0_CustomAccountListViewSelector responseSelector = new SBR_3_0_CustomAccountListViewSelector(builder);
      responseSelector.getAccounts();
    Test.stopTest();

  }
}