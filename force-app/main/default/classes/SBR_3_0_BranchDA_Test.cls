/*********************************************************************************************************************
* Apex Class: SBR_3_0_BranchDA_Test 
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to test SBR_3_0_BranchDA
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                  DATE                    DETAIL FEATURES
    1.0         Joelle Ramiandrisoa           2022-08-17                Initial version    
*********************************************************************************************************************/
@isTest
public class SBR_3_0_BranchDA_Test {
  @testSetup
  static void setupTestData() {
    List<Analysis_Region__c> regions = new List<Analysis_Region__c>();

    Analysis_Region__c regionA = new Analysis_Region__c();
    regionA.Analysis_Region_Key__c = '001';
    regionA.Name = 'RegionA';
    regionA.Company_Code__c = '01';
    regions.add(regionA);
    insert regions;

    List<Schema.Location> branchLocations = new List<Schema.Location>();

    Schema.Location branchLocationA = new Schema.Location();
    branchLocationA.Branch_Location_Number__c = '1234';
    branchLocationA.Name = 'Test Branch Location1 Austin';
    branchLocationA.Street_Address__c = '768 Tanglewood Lane Brooklyn';
    branchLocationA.City__c = 'New York';
    branchLocationA.Zip_Code__c = '11201';
    branchLocationA.State__c = 'ON';
    branchLocationA.Country__c = 'US';
    branchLocationA.Job_Number__c = '332112';
    branchLocationA.Time_Zone_Name__c = 'America/Chicago';
    branchLocationA.OMS_Sourcing_Enabled__c = true;
    branchLocationA.Time_Zone__c = 3;
    branchLocationA.Analysis_Region_Key__c = '001';
    branchLocationA.Analysis_Region2__c = regions[0].Id;
    branchLocationA.Operational_Status__c = 'A';
    insert branchLocationA;

    Schema.Location branchLocationB = new Schema.Location();
    branchLocationB.Branch_Location_Number__c = '4323';
    branchLocationB.Name = 'Test Branch LocationB';
    branchLocationB.Street_Address__c = '34 Goldfield Ave Brooklyn';
    branchLocationB.City__c = 'New York';
    branchLocationB.Zip_Code__c = '11224';
    branchLocationB.State__c = 'ON';
    branchLocationB.Country__c = 'US';
    branchLocationB.Job_Number__c = '331342';
    branchLocationB.RecordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
    branchLocationB.Company_Code__c = 'X';
    branchLocationB.Time_Zone_Name__c = 'America/Chicago';
    branchLocationB.OMS_Sourcing_Enabled__c = true;
    branchLocationB.Time_Zone__c = 3;
    branchLocationB.Analysis_Region_Key__c = '001';
    branchLocationB.Analysis_Region2__c = regions[0].Id;
    branchLocationB.Operational_Status__c = 'A';
    insert branchLocationB;

    Schema.Location branchLocationC = new Schema.Location();
    branchLocationC.Branch_Location_Number__c = '5443';
    branchLocationC.Name = 'Test Branch LocationC';
    branchLocationC.Street_Address__c = '12 Main Street';
    branchLocationC.City__c = 'Toronto';
    branchLocationC.Zip_Code__c = 'M7N7B3';
    branchLocationC.State__c = 'ON';
    branchLocationC.Country__c = 'CA';
    branchLocationC.Job_Number__c = '332112';
    branchLocationC.RecordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
    branchLocationC.Company_Code__c = 'X';
    branchLocationC.Time_Zone_Name__c = 'America/Chicago';
    branchLocationC.OMS_Sourcing_Enabled__c = true;
    branchLocationC.Time_Zone__c = 3;
    branchLocationC.Analysis_Region_Key__c = '001';
    branchLocationC.Analysis_Region2__c = regions[0].Id;
    branchLocationC.Operational_Status__c = 'A';
    insert branchLocationC;
  }
  static testMethod void testGetBranches() {
    Map<Id, Schema.Location> result = new Map<Id, Schema.Location>();

    Test.startTest();
    result = SBR_3_0_BranchDA.getBranches();
    Test.stopTest();

    System.assertEquals(3, result.size());
  }

  static testMethod void testGetLocationsByIds() {
    List<Schema.Location> branch = [SELECT Id FROM Location];
    Map<Id, Schema.Location> result = new Map<Id, Schema.Location>();
    Set<Id> setIds = new Set<Id>();

    setIds.add(branch[0].Id);

    Test.startTest();
    result = SBR_3_0_BranchDA.getLocationsByIds(setIds);
    Test.stopTest();

    System.assertEquals(1, result.size());
  }

  static testMethod void testGetLocationReadinessFields() {
    List<Schema.Location> branch = [SELECT Id FROM Location];
    Map<Id, Schema.Location> result = new Map<Id, Schema.Location>();
    Set<Id> setIds = new Set<Id>();

    setIds.add(branch[0].Id);

    Test.startTest();
    result = SBR_3_0_BranchDA.getLocationReadinessFields(setIds);
    Test.stopTest();

    System.assertEquals(1, result.size());
  }

  static testMethod void testGetLocationsFiltered() {
    List<Schema.Location> result = new List<Schema.Location>();
    SBR_3_0_GoogleMapCmpController.FilterWrapper wrapper = new SBR_3_0_GoogleMapCmpController.FilterWrapper();
    wrapper.branchSearch = 'New York';
    wrapper.country = 'US';
    wrapper.loadBranchData = true;
    Test.startTest();
    result = SBR_3_0_BranchDA.getBranchesFiltered(wrapper);
    Test.stopTest();

    System.assertEquals(1, result.size());
  }

  @isTest
  static void testGetLocation() {
    /*  Schema.Location loc = [SELECT ID FROM Location LIMIT 1];
     System.debug('loc::'+loc);*/
    List<Schema.Location> result = new List<Schema.Location>();

    List<Schema.Location> locList = [SELECT Id FROM Location];
    locList[0].Phone__c = '11231231234';
    locList[0].Branch_Location_Number__c = '0123';

    update locList;

    List<String> input = new List<String>();
    input.add(locList[0].Branch_Location_Number__c);

    Test.startTest();
    Schema.Location queryLoc = SBR_3_0_BranchDA.getLocation(locList[0].Id);
    Test.stopTest();

    System.assertEquals(locList[0].Id, queryLoc.Id);
  }
  @isTest
  static void getBranchPhones() {
    List<Schema.Location> branches = [SELECT Id FROM Location];
    List<Schema.Location> result = new List<Schema.Location>();

    branches[0].Phone__c = '11231231234';
    branches[0].Branch_Location_Number__c = '0123';
    update branches;

    List<String> input = new List<String>();
    input.add(branches[0].Branch_Location_Number__c);

    Test.startTest();
    result = SBR_3_0_BranchDA.getBranchPhones(input);
    Test.stopTest();

    System.assertEquals(1, result.size());
  }

  // method needs to be moved to SBR_3_0_SpotlightPanelCmpController_Test, but it's currently throwing an error
  @isTest
  static void getPhonesWithValidBranch() {
    List<Schema.Location> branches = [SELECT Id FROM Location];
    List<Schema.Location> result = new List<Schema.Location>();

    List<String> pcs = new List<String>();

    branches[0].Phone__c = '11231231234';
    branches[0].Branch_Location_Number__c = '0123';
    pcs.add(branches[0].Branch_Location_Number__c);
    update branches;

    Test.startTest();
    List<Schema.Location> testLocation = SBR_3_0_SpotlightPanelCmpController.getBranchPhones(
      pcs
    );
    Test.stopTest();

    System.assertEquals(branches[0].Phone__c, testLocation[0].Phone__c);
    //  System.assertEquals(branches[1].Phone__c,testLocation[1].Phone__c);
  }

  @isTest
  static void testGetLoggedInUserLocation() {
    Schema.Location branchLocation = buildLocation();
    User_Location__c userLoc = new User_Location__c();
    userLoc.User__c = UserInfo.getUserId();
    userLoc.Branch__c = branchLocation.Id;
    insert userLoc;

    Test.StartTest();

    List<Schema.Location> userLocations = SBR_3_0_BranchDA.getLoggedInUserLocation();

    Test.StopTest();
    System.AssertEquals(
      1,
      userLocations.size(),
      'No User Location was found !'
    );
  }

  @isTest
  static void testGetLoggedInUserProfileBranchLocation() {
    Schema.Location location = buildLocation();
    User_Location__c userLoc = new User_Location__c();
    userLoc.User__c = UserInfo.getUserId();
    userLoc.Branch__c = location.Id;
    userLoc.ProfileBranche__c = location.Id;
    insert userLoc;

    Test.StartTest();
    List<Schema.Location> userLocations = SBR_3_0_BranchDA.getLoggedInUserProfileBranchLocation();
    Test.StopTest();
    System.AssertEquals(
      1,
      userLocations.size(),
      'No User Location was found !'
    );
  }

  @isTest
  static void testGetSourcingBranchLocation() {
    Schema.Location location = buildLocation();
    Test.StartTest();
    List<Schema.Location> userLocations = SBR_3_0_BranchDA.getSourcingBranchLocation(
      location.id
    );
    Test.StopTest();
    System.AssertEquals(
      1,
      userLocations.size(),
      'No User Location was found !'
    );
  }

  @isTest
  static void testgetBranchByNumbers() {
    List<Schema.Location> branches = [
      SELECT Id, Branch_Location_Number__c
      FROM Location
    ];
    Set<String> branchNumbers = new Set<String>();
    branchNumbers.add(branches[0].Branch_Location_Number__c);
    Test.StartTest();
    Map<String, Schema.Location> resultMap = SBR_3_0_BranchDA.getBranchByNumbers(
      branchNumbers
    );
    Test.StopTest();
    System.AssertNotEquals(null, resultMap);
  }

  @isTest
  static void testGetBranchesLineOfBusinesses() {
    System.debug(
      'testGetBranchesLineOfBusinesses ->' +
      [
        SELECT Country__c, Analysis_Region2__r.Name
        FROM Location
      ]
    );

    Test.startTest();
    // Call the method to be tested
    String result = SBR_3_0_BranchDA.getBranchesLineOfBusinesses();
    Test.stopTest();

    // Deserialize the result
    List<Object> resultList = (List<Object>) JSON.deserializeUntyped(result);
    System.debug('===' + resultList);

    System.assertEquals(2, resultList.size());

    // Typecast each element in the resultList
    List<Map<String, Object>> resultMap = new List<Map<String, Object>>();
    for (Object obj : resultList) {
      resultMap.add((Map<String, Object>) obj);
    }

    // Assert the data in the result for US
    Map<String, Object> countryData = resultMap[0];
    System.assertEquals('US', countryData.get('country'));
    List<Object> lobsUSObjectList = (List<Object>) countryData.get('lobs');
    List<String> lobsUS = new List<String>();
    for (Object obj : lobsUSObjectList) {
      lobsUS.add(String.valueOf(obj));
    }
    System.assertEquals(2, lobsUS.size());
    System.assert(lobsUS.contains('RegionA'));
  }

  @isTest
  static void testGetBranchByBranchNumber() {
    Test.startTest();
    // Call the method to be tested
    List<Schema.Location> result = SBR_3_0_BranchDA.getBranchByBranchNumber(
      '1234'
    );
    Test.stopTest();
    System.assertEquals(1, result.size()); // todo
  }

    @isTest
    static void getBranchDetails(){
        Test.startTest();
    Map<String, Schema.Location> result = SBR_3_0_BranchDA.getBranchDetails(
      new List<String>{ '4323' }
    );
        Test.stopTest();
        System.assertEquals(1, result.size());  
    }
    
  private static Schema.Location buildLocation() {
    Schema.Location location = new Schema.Location();
    location.Branch_Location_Number__c = '1234';
    location.Name = 'Test Branch Location';
    location.Street_Address__c = '12 Main Street';
    location.City__c = 'Toronto';
    location.Zip_Code__c = 'M7N7B3';
    location.State__c = 'ON';
    location.Country__c = 'CA';
    location.Job_Number__c = '332112';
    location.RecordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
    location.Company_Code__c = 'X';
    location.Time_Zone_Name__c = 'America/Chicago';
    location.Time_Zone__c = 3;
    insert location;

    return location;
  }
}