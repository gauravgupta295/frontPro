/*********************************************************************************************************************
* Apex Class: SBR_3_0_CustomLookupController
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to control CustomLookup LWC and MultiLookup LWC
* - SAL-78
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Kunal Patel           2022-02-23            Initial version  
    2.0         Shruti Gujarathi      2023-10-05            SAL-26649 Simplified lookup search logic for faster performance.  
*********************************************************************************************************************/
public without sharing class SBR_3_0_CustomLookupController {
  // Method to fetch lookup search result
  @AuraEnabled(cacheable=true)
  public static list<sObject> fetchLookupDataUsingParent(
    String searchKey,
    String sObjectApiName,
    String whereClause,
    String fieldsToInclude,
    Boolean hasCustomNameField,
    String parentName
  ) {
    system.debug(parentName + ' ###whereClause : ' + whereClause);
    String nameField = 'Name';
    String sWildCardText;
    String recordTypeName = 'RecordType.Name';
    // get Name custom field name
    if (hasCustomNameField) {
      if (sObjectApiName == 'SBQQ__Quote__c') {
        nameField = 'Quote_Name__c';
      } else if (sObjectApiName == 'Project__c') {
        nameField = 'Project_Name__c';
      } else if (sObjectApiName == 'User_Location__c') {
        nameField = 'Name';
      } else {
        nameField = 'Name__c';
      }
    }
    // Append Name field
    if (String.isNotBlank(fieldsToInclude)) {
      fieldsToInclude = nameField + ',' + fieldsToInclude;
    } else {
      fieldsToInclude = nameField;
    }
    if (
      sObjectApiName == 'Account' && !fieldsToInclude.contains(recordTypeName)
    ) {
      fieldsToInclude = fieldsToInclude + ',' + recordTypeName;
    }
    // Execute SOSL if search string is entered and object is not AssociatedLocation or User
    if (
      sObjectApiName != 'User_Location__c' &&
      sObjectApiName != 'AssociatedLocation' &&
      sObjectApiName != 'User' &&
      ((String.isNotBlank(searchKey) && searchKey.length() > 1) ||
      String.isNotBlank(parentName))
    ) {
      if (String.isBlank(searchKey) || searchKey.length() == 1) {
        searchKey = parentName;
      }
      if (String.isNotBlank(whereClause)) {
        whereClause = ' WHERE ' + whereClause;
      }
      searchKey = String.escapeSingleQuotes(searchKey);
      searchKey = searchKey.replaceAll('[\\-]', '\\\\-');
      searchKey = searchKey.replaceAll(
        '([\\&|!(){}\\[\\]^"~*?:\\\\\'+\\-])',
        '\\\\$1'
      );
      String soslQueryStr =
        'FIND {' +
        searchKey +
        '} IN ALL FIELDS Returning ' +
        sObjectApiName +
        '(Id,' +
        fieldsToInclude +
        whereClause +
        ' LIMIT 30)';

      system.debug('SOSL Query >> ' + soslQueryStr);
      return search.query(soslQueryStr)[0];
    }
    // Execute SOQL
    else {
      // create a search where condition using the search string entered by user
      if (String.isNotBlank(searchKey)) {
        sWildCardText = '%' + String.escapeSingleQuotes(searchKey) + '%';
        if (String.isNotBlank(whereClause))
          whereClause += ' AND ';
        whereClause += '(' + nameField + ' LIKE: sWildCardText';
        if (String.isNotBlank(fieldsToInclude)) {
          for (String s : fieldsToInclude.split(',')) {
            if(s != 'User__c'  ){ //Added this if block to avoid querying Userid field value for keyword search functionality
              whereClause += ' OR ' + s + ' LIKE: sWildCardText';
            }
          }
        }
        whereClause += ')';
      }
      if (String.isNotBlank(whereClause)) {
        whereClause = ' WHERE ' + whereClause;
      }
      String soqlQueryStr =
        'SELECT Id,' +
        fieldsToInclude +
        ' FROM ' +
        sObjectApiName +
        whereClause +
        ' LIMIT 30';

      system.debug('SOQL Query >> ' + soqlQueryStr);
      return Database.query(soqlQueryStr);
    }
  }

  // Method to fetch lookup search result
  @AuraEnabled(cacheable=true)
  public static list<sObject> fetchLookupData(
    String searchKey,
    String sObjectApiName,
    String whereClause,
    String fieldsToInclude,
    Boolean hasCustomNameField
  ) {
    system.debug('@@@whereClause : ' + whereClause);
    String nameField = 'Name';
    String sWildCardText;
    String recordTypeName = 'RecordType.Name';
    // get Name custom field name
    if (hasCustomNameField) {
      if (sObjectApiName == 'SBQQ__Quote__c') {
        nameField = 'Quote_Name__c';
      } else if (sObjectApiName == 'Project__c') {
        nameField = 'Project_Name__c';
      } else if (sObjectApiName == 'User_Location__c') {
          nameField = 'Name';
      } else {
        nameField = 'Name__c';
      }
    }
    // append Name fields
    if (String.isNotBlank(fieldsToInclude)) {
      fieldsToInclude = nameField + ',' + fieldsToInclude;
    } else {
      fieldsToInclude = nameField;
    }
    if (
      sObjectApiName == 'Account' && !fieldsToInclude.contains(recordTypeName)
    ) {
      fieldsToInclude = fieldsToInclude + ',' + recordTypeName;
    }
    // Execute SOSL if search string is entered and object is not AssociatedLocation or User
    if (
      sObjectApiName != 'AssociatedLocation' &&
      sObjectApiName != 'User' &&
      String.isNotBlank(searchKey) &&
      searchKey.length() > 1
    ) {
      if (String.isNotBlank(whereClause)) {
        whereClause = ' WHERE ' + whereClause;
      }
      searchKey = String.escapeSingleQuotes(searchKey);
      searchKey = searchKey.replaceAll('[\\-]', '\\\\-');
      searchKey = searchKey.replaceAll(
        '([\\&|!(){}\\[\\]^"~*?:\\\\\'+\\-])',
        '\\\\$1'
      );
      String soslQueryStr =
        'FIND {' +
        searchKey +
        '} IN ALL FIELDS Returning ' +
        sObjectApiName +
        '(Id,' +
        fieldsToInclude +
        whereClause +
        ' LIMIT 5)';

      system.debug('SOSL Query >> ' + soslQueryStr);
      return search.query(soslQueryStr)[0];
    }
    // Execute SOQL
    else {
      // create a search where condition using the search string entered by user
      if (String.isNotBlank(searchKey)) {
        sWildCardText = '%' + String.escapeSingleQuotes(searchKey) + '%';
        if (String.isNotBlank(whereClause))
          whereClause += ' AND ';
        whereClause += '(' + nameField + ' LIKE: sWildCardText';
        if (String.isNotBlank(fieldsToInclude)) {
          for (String s : fieldsToInclude.split(',')) {
            whereClause += ' OR ' + s + ' LIKE: sWildCardText';
          }
        }
        whereClause += ')';
      }
      if (String.isNotBlank(whereClause)) {
        whereClause = ' WHERE LastViewedDate != NULL AND ' + whereClause;
      } else {
        whereClause = ' WHERE LastViewedDate != NULL ';
      }
      String soqlQueryStr =
        'SELECT Id,' +
        fieldsToInclude +
        ' FROM ' +
        sObjectApiName +
        whereClause +
        ' ORDER BY LastViewedDate DESC LIMIT 5';

      system.debug('SOQL Query >> ' + soqlQueryStr);
      return Database.query(soqlQueryStr);
    }
    /* return fetchLookupDataWithoutCachable(searchKey, sObjectApiName, whereClause, fieldsToInclude, hasCustomNameField);*/
  }

  //FRONT-3033, FRONT-2621, FRONT- 3115, FRONT-3125 START
  /* @AuraEnabled
    public static list<sObject> fetchLookupDataWithoutCachable(String searchKey, String sObjectApiName, String whereClause, String fieldsToInclude, Boolean hasCustomNameField) {

    Set<sObject> returnSet = new Set<sObject>();
    String sWildCardText = '%' + String.escapeSingleQuotes(searchKey) + '%';
    String sQuery;
    String sQuery1;
    Boolean showExactMatch = false;

    String selectClause = '';
    String selectFields = '';
    String baseWhereClause = '';
    String exactMatchWhereClause = '';
    String fullWhereClause = '';
    String nameField = 'Name';
    String accountNumberField = 'RM_Account_Number_Display__c';
    String projectNameDisplayField = 'Project_Name__c';
    Integer remainingRows = (Limits.getLimitQueryRows() -
    Limits.getQueryRows());
    String orderByClause =
      ' ORDER BY LastModifiedDate DESC LIMIT ' + remainingRows;
    if (hasCustomNameField) {
      if (sObjectApiName == 'SBQQ__Quote__c') {
        nameField = 'Quote_Name__c';
      } else {
        nameField = 'Name__c';
      }
    }

    if (String.isNotBlank(fieldsToInclude)) {
      List<String> stringArray = fieldsToInclude.split(',');
      for (String s : stringArray) {
        fullWhereClause += ' OR ' + s + ' LIKE: sWildCardText';
        selectFields += ', ' + s;
      }

      //SAL-26124 Changes
      if (sObjectApiName == 'Account' && String.isNotBlank(searchKey)) {
        // Doing an exact match for Accounts first
        showExactMatch = true;
        exactMatchWhereClause +=
          ' WHERE ( RM_Account_Number_Display__c LIKE: sWildCardText OR Name LIKE: sWildCardText ) AND ' +
          whereClause +
          ' ';
      }
    }
    fullWhereClause += ')';

    selectClause = 'SELECT Id, ';
    selectClause += nameField;
    if (sObjectApiName == 'Project__c') {
      selectClause += ',' + projectNameDisplayField;
    }

    selectClause += selectFields;
    selectClause += ' FROM ' + sObjectApiName;

    baseWhereClause = ' WHERE (' + nameField + ' LIKE: sWildCardText ';

    //10572, SADAPUR
    String loggedInUserCompanyCode = '01';

    List<Schema.Location> userLocation = SBR_3_0_BranchDA.getLoggedInUserLocation();

    if (userLocation.size() > 0 && userLocation[0].Company_Code__c != null) {
      loggedInUserCompanyCode = userLocation[0].Company_Code__c;
    } else {
      User loggedInUser = SBR_3_0_UserDA.getUserById(UserInfo.getUserId());
      loggedInUserCompanyCode = loggedInUser.CompanyName;
    }

    String existingCompCodeClause = 'Company_Code__c = \'\'';
    String userCompanyCodeClause = 'Company_Code__c =: loggedInUserCompanyCode';
    String parentAccntCompCodeClause = 'Parent.Company_Code__c =: loggedInUserCompanyCode';

    if (!String.isBlank(whereClause)) {
      if (
        (sObjectApiName == 'Account' || sObjectApiName == 'Location') &&
        whereClause.contains(existingCompCodeClause)
      ) {
        whereClause = whereClause.replace(
          existingCompCodeClause,
          userCompanyCodeClause
        );
      } else if (
        (sObjectApiName == 'Account') &&
        (whereClause.startsWith('RecordTypeId') ||
        whereClause.startsWith('ParentId')) &&
        !whereClause.contains('Company_Code__c')
      ) {
        //14047
        whereClause += ' AND ' + parentAccntCompCodeClause;
      } else if (
        (sObjectApiName == 'Account' || sObjectApiName == 'Location') &&
        !whereClause.contains('Company_Code__c')
      ) {
        whereClause += ' AND ' + userCompanyCodeClause;
      }
      fullWhereClause = fullWhereClause + ' AND ' + whereClause;
      if (!exactMatchWhereClause.contains('WHERE')) {
        exactMatchWhereClause = ' WHERE ';
      }
      exactMatchWhereClause = exactMatchWhereClause + ' AND ' + whereClause;
    }

    sQuery = selectClause + baseWhereClause + fullWhereClause + orderByClause;
    sQuery1 = selectClause + exactMatchWhereClause + orderByClause;

    //SAL-19647
    String undefinedRTIdStr = 'RecordTypeId = \'undefined\'';
    String accountOfficeRT = SBR_3_0_Constants.ACCOUNT_OFFICE_RT_ID;

    String officeRTIdStr = 'RecordTypeId =:accountOfficeRT';

    if (sObjectApiName == 'Account' && sQuery.contains(undefinedRTIdStr)) {
      sQuery = sQuery.replace(undefinedRTIdStr, officeRTIdStr);
    }

    System.debug('sQuery : ' + sQuery);
    System.debug('sQuery1 : ' + sQuery1);

    // Only run exact match query when searchKey is not blank and sobject is account
    //SAL-26124 Changes
    if (showExactMatch) {
      for (sObject obj1 : Database.query(sQuery1)) {
        returnSet.add(obj1);
      }
    } else {
      for (sObject obj : Database.query(sQuery)) {
        returnSet.add(obj);
      }
    }

        return new list<sObject> (returnSet);
    }*/
  //FRONT-3033, FRONT-2621, FRONT- 3115, FRONT-3125 END

  // Method to fetch lookup default value
  @AuraEnabled
  public static sObject fetchDefaultRecord(
    String recordId,
    String sObjectApiName,
    Boolean hasCustomNameField
  ) {
    String sRecId = recordId;
    String nameField = 'Name';
    if (hasCustomNameField) {
      nameField = 'Name__c';
    }
    if (sObjectApiName == 'AssociatedLocation') {
      nameField = 'JobsiteName__c';
    }
    if (sObjectApiName == 'SBQQ__Quote__c') {
      nameField = 'Quote_Name__c';
    }
    if (sObjectApiName == 'User_Location__c') {
      nameField = 'Sales_Rep_Name__c';

    }

    //10572, SADAPUR
    String loggedInUserCompanyCode = '01';

    List<Schema.Location> userLocation = SBR_3_0_BranchDA.getLoggedInUserLocation();

    if (userLocation.size() > 0 && userLocation[0].Company_Code__c != null) {
      loggedInUserCompanyCode = userLocation[0].Company_Code__c;
    } else {
      User loggedInUser = SBR_3_0_UserDA.getUserById(UserInfo.getUserId());
      loggedInUserCompanyCode = loggedInUser.CompanyName;
    }

    String userCompanyCodeClause = 'Company_Code__c =:loggedInUserCompanyCode';
    String whereClause = ' WHERE Id =: sRecId ';

    //10572
    if ((sObjectApiName == 'Account' || sObjectApiName == 'Location')) {
      whereClause += ' AND ' + userCompanyCodeClause;
    }

    String sQuery =
      'SELECT Id, ' +
      nameField +
      ' FROM ' +
      sObjectApiName +
      whereClause +
      ' LIMIT 1';

    System.debug('default sQuery -> ' + sQuery);
    for (sObject obj : Database.query(sQuery)) {
      return obj;
    }
    return null;
  }
  // SAL-19640
  @AuraEnabled
  public static string getCompanyCode() {
    try {
      String loggedInUserCompanyCode = '';

      List<Schema.Location> userLocation = SBR_3_0_BranchDA.getLoggedInUserLocation();

      if (userLocation.size() > 0 && userLocation[0].Company_Code__c != null) {
        loggedInUserCompanyCode = userLocation[0].Company_Code__c;
      } else {
        User loggedInUser = SBR_3_0_UserDA.getUserById(UserInfo.getUserId());
        loggedInUserCompanyCode = loggedInUser.CompanyName;
      }
      return loggedInUserCompanyCode;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
  // Method to fetch lookup default value
  @AuraEnabled
  public static List<sObject> fetchDefaultRecordMultiple(
    String recordId,
    String sObjectApiName,
    Boolean hasCustomNameField
  ) {
    String sRecId = recordId;
    String nameField = 'Name';
    if (hasCustomNameField) {
      nameField = 'Name__c';
    }
    if (sObjectApiName == 'AssociatedLocation') {
      nameField = 'JobsiteName__c';
    }
    if (sObjectApiName == 'SBQQ__Quote__c') {
      nameField = 'Quote_Name__c';
    } 
    else if (sObjectApiName == 'User_Location__c') {
      nameField = 'Sales_Rep_Name__c';
    }
  

    //10572, SADAPUR
    String loggedInUserCompanyCode = '01';

    List<Schema.Location> userLocation = SBR_3_0_BranchDA.getLoggedInUserLocation();

    if (userLocation.size() > 0 && userLocation[0].Company_Code__c != null) {
      loggedInUserCompanyCode = userLocation[0].Company_Code__c;
    } else {
      User loggedInUser = SBR_3_0_UserDA.getUserById(UserInfo.getUserId());
      loggedInUserCompanyCode = loggedInUser.CompanyName;
    }

    String userCompanyCodeClause = 'Company_Code__c =:loggedInUserCompanyCode';

    Set<Id> idSet = new Set<Id>();
    if (String.isNotBlank(sRecId)) {
      if (sRecId.contains(',')) {
        for (String s : sRecId.split(',')) {
          idSet.add((Id) s.deleteWhitespace());
        }
      } else {
        idSet.add((Id) sRecId.deleteWhitespace());
      }
    }

    String whereClause = ' WHERE Id IN ' + inClausify(idSet);

    //10572
    if ((sObjectApiName == 'Account' || sObjectApiName == 'Location')) {
      whereClause += ' AND ' + userCompanyCodeClause;
    }

    String sQuery =
      'SELECT Id, ' +
      nameField +
      ' FROM ' +
      sObjectApiName +
      whereClause;

    System.debug('default sQuery -> ' + sQuery);
    List<sObject> result = Database.query(sQuery);
    System.debug('result size -> ' + result.size());
    return result;
  }

  @AuraEnabled(cacheable=true)
  public static List<SObJectResult> getResults(
    String ObjectName,
    String fieldName,
    String value,
    List<String> selectedRecId
  ) {
    List<SObJectResult> sObjectResultList = new List<SObJectResult>();

    if (selectedRecId == null) {
      selectedRecId = new List<String>();
    }

    if (String.isNotEmpty(value)) {
      String query =
        'Select Id,' +
        fieldName +
        ' FROM ' +
        ObjectName +
        ' WHERE ' +
        fieldName +
        ' LIKE \'%' +
        value.trim() +
        '%\' and ID NOT IN: selectedRecId';

      for (sObject so : Database.Query(query)) {
        String fieldvalue = (String) so.get(fieldName);
        sObjectResultList.add(new SObjectResult(fieldvalue, so.Id));
      }
    }
    return sObjectResultList;
  }

  public class SObjectResult {
    @AuraEnabled
    public String recName;
    @AuraEnabled
    public Id recId;

    public SObJectResult(String recNameTemp, Id recIdTemp) {
      recName = recNameTemp;
      recId = recIdTemp;
    }
    public SObJectResult() {
    }
  }

  // Method to fetch lookup search result
  @AuraEnabled(cacheable=true)
  public static String getAppName() {
    //FRONT-9907
    Boolean isFrontlineUser = FeatureManagement.checkPermission(
      'Frontline_User'
    );

    if (isFrontlineUser) {
      return 'RAE Frontline';
    } else {
      //below lines are added by frontline team if any changes required on the below kindly contact frontline team
      List<UserAppInfo> userAppInfo = [
        SELECT Id, AppDefinitionId
        FROM UserAppInfo
        WHERE UserId = :UserInfo.getUserId()
        LIMIT 1
      ];
      //SAL-27722
      if (!userAppInfo.isEmpty()) {
      //code to achieve test coverage
      AppDefinition appDefinition = [
        SELECT DurableId, Label
        FROM AppDefinition
          WHERE DurableId = :userAppInfo[0].AppDefinitionId
        LIMIT 1
      ];

      return appDefinition.Label;
      } else {
        return 'RAE Sales';
      }
    }
  }

  //Frontline code: to get a record type.
  @AuraEnabled(cacheable=true)
  public static list<sObject> getRecordTypeInfo(String sObjectApiName) {
    List<sObject> RecordTypeInfo = new List<SObject>();
    RecordTypeInfo = [
      SELECT ID, NAME, DESCRIPTION
      FROM RecordType
      WHERE SobjectType = :sObjectApiName
    ];

    return RecordTypeInfo;
  }

  public static String inClausify(Set<Id> ids) {
    if (ids == null || ids.isEmpty()) {
      return '(\'\')';
    }
    String inClause = String.format(
      '(\'\'{0}\'\')',
      new List<String>{ String.join(new List<Id>(ids), '\',\'') }
    );

    return inClause;
  }

  // SAL-26648 & SAL-26649: Get contacts associated with selected account. This method is invoked on load of the parent LWC cmp where lookup cmp is used.
  @AuraEnabled(cacheable=true)
  public static list<sObject> getRelatedContacts(
    String accountId,
    String officeAccountId
  ) {
    list<sObject> lstRecords = new List<sObject>();

    String strQuery;

    if (String.isNotBlank(accountId)) {
      if (String.isBlank(officeAccountId)) {
        strQuery = 'Select Id, Name, FirstName, LastName, Phone, MobilePhone from Contact where AccountId =: accountId';
      } else {
        strQuery = 'Select Id, Name, FirstName, LastName, Phone, MobilePhone from Contact where (AccountId =: accountId OR AccountId =: officeAccountId)';
      }
      lstRecords = Database.query(strQuery);
    }
    return lstRecords;
  }

  @AuraEnabled
  public static String getCurrentUserApplicationName() {
    try {
      return SBR_3_0_UtilityDA.getCurrentUserApplicationName();
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
}