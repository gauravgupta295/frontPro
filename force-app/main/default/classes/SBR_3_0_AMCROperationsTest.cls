/*********************************************************************************************************************
* Apex Class: SBR_3_0_AMCROperationsTest
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test Class to manage Account Management Change Request Automatic Approve Request
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME      DATE            DETAIL FEATURES
    1.0         Manish Taneja        2023-10-07      Initial version (SF-309)
*********************************************************************************************************************/

@isTest
public class SBR_3_0_AMCROperationsTest {
    @TestSetup
    static void makeData() {
        //Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        // cred.Name = 'Mule_Token_Endpoint';
        // cred.Key_Id__c = 'testKey123';
        // cred.Secret__c = 'secret';
        // insert cred;
        // Create User
        // This code runs as the system user
        List<Profile> profiles = [SELECT Id, Name FROM Profile WHERE Name IN ('Sales', 'System Administrator')];
        Id adminProfile;
        Id salesProfile;
        for (Profile mProfile : profiles) {
            if (mProfile.Name.equals('Sales')) {
                salesProfile = mProfile.Id;
            } else {
                adminProfile = mProfile.Id;
            }
        }

        List<User> users = new List<User>();

        User adminUser = new User(Alias = 'admUsr', Email = 'standarduser@sunbeltrentals.com', EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = adminProfile, TimeZoneSidKey = 'America/Los_Angeles', UserName = 'admin@acmTest.com');
        User commissionsTeamUser = new User(Alias = 'Usr1', Email = 'standarduser@sunbeltrentals.com', EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = salesProfile, TimeZoneSidKey = 'America/Los_Angeles', UserName = 'commissionsTeamUser@acmTest.com');
        User businessAdminUser = new User(Alias = 'Usr2', Email = 'standarduser@sunbeltrentals.com', EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = salesProfile, TimeZoneSidKey = 'America/Los_Angeles', UserName = 'businessAdminUser@acmTest.com');
        User branchManagerUser = new User(Alias = 'Usr3', Email = 'standarduser@sunbeltrentals.com', EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = salesProfile, TimeZoneSidKey = 'America/Los_Angeles', UserName = 'branchManagerUser@acmTest.com');
        User regionalSalesDirectorUser = new User(Alias = 'Usr3', Email = 'standarduser@sunbeltrentals.com', EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = salesProfile, TimeZoneSidKey = 'America/Los_Angeles', UserName = 'regionalSalesDirectorUser@acmTest.com');
        User salesManagerUser = new User(Alias = 'Usr5', Email = 'standarduser@sunbeltrentals.com', EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = salesProfile, TimeZoneSidKey = 'America/Los_Angeles', UserName = 'salesManagerUser@acmTest.com');

        users.add(adminUser);
        users.add(commissionsTeamUser);
        users.add(businessAdminUser);
        users.add(branchManagerUser);
        users.add(regionalSalesDirectorUser);
        users.add(salesManagerUser);
        insert users;

        Map<String, Id> permissionSetMap = new Map<String, Id>();

        List<PermissionSet> permissionSets = [SELECT Id, Name FROM PermissionSet WHERE Name IN ('Branch_Manager1', 'Regional_Sales_Director_Custom_Permission', 'Business_Admin1', 'Commissions_Team', 'Sales_Management')];
        for (PermissionSet ps : permissionSets) {
            permissionSetMap.put(ps.Name, ps.Id);
        }

        // PermissionSetLicense mPermissionSetLicense = [SELECT Id FROM PermissionSetLicense WHERE DeveloperName = 'SalesforceCPQ_CPQStandardPerm'];
        // PermissionSetLicense mPermissionSetLicense = [SELECT Id FROM PermissionSetLicense WHERE DeveloperName = 'SalesforceCPQ_CPQAAPerm'];
        // PermissionSetLicense mPermissionSetLicense = [SELECT Id FROM PermissionSetLicense WHERE DeveloperName = 'EinsteinAnalyticsPlusPsl'];
        // List<PermissionSetLicenseAssign> permissionSetLicenseAssignments = new List<PermissionSetLicenseAssign>();
        // permissionSetLicenseAssignments.add(new PermissionSetLicenseAssign(AssigneeId = commissionsTeamUser.Id, PermissionSetLicenseId = mPermissionSetLicense.Id));
        // permissionSetLicenseAssignments.add(new PermissionSetLicenseAssign(AssigneeId = businessAdminUser.Id, PermissionSetLicenseId = mPermissionSetLicense.Id));
        // permissionSetLicenseAssignments.add(new PermissionSetLicenseAssign(AssigneeId = branchManagerUser.Id, PermissionSetLicenseId = mPermissionSetLicense.Id));
        // permissionSetLicenseAssignments.add(new PermissionSetLicenseAssign(AssigneeId = regionalSalesDirectorUser.Id, PermissionSetLicenseId = mPermissionSetLicense.Id));
        // permissionSetLicenseAssignments.add(new PermissionSetLicenseAssign(AssigneeId = salesManagerUser.Id, PermissionSetLicenseId = mPermissionSetLicense.Id));

        // insert permissionSetLicenseAssignments;

        List<PermissionSetLicense> permissionSetLicenses = [
            SELECT Id, DeveloperName
            FROM PermissionSetLicense
            WHERE DeveloperName IN ('SalesforceCPQ_CPQStandardPerm', 'SalesforceCPQ_CPQAAPerm', 'EinsteinAnalyticsPlusPsl')
        ];

        Map<String, Id> licenseIdMap = new Map<String, Id>();
        for (PermissionSetLicense license : permissionSetLicenses) {
            licenseIdMap.put(license.DeveloperName, license.Id);
        }

        List<PermissionSetLicenseAssign> permissionSetLicenseAssignments = new List<PermissionSetLicenseAssign>();
        Map<Id, List<String>> userLicenses = new Map<Id, List<String>>{ commissionsTeamUser.Id => new List<String>{ 'SalesforceCPQ_CPQStandardPerm', 'SalesforceCPQ_CPQAAPerm', 'EinsteinAnalyticsPlusPsl' }, businessAdminUser.Id => new List<String>{ 'SalesforceCPQ_CPQStandardPerm', 'SalesforceCPQ_CPQAAPerm', 'EinsteinAnalyticsPlusPsl' }, branchManagerUser.Id => new List<String>{ 'SalesforceCPQ_CPQStandardPerm', 'SalesforceCPQ_CPQAAPerm', 'EinsteinAnalyticsPlusPsl' }, regionalSalesDirectorUser.Id => new List<String>{ 'SalesforceCPQ_CPQStandardPerm', 'SalesforceCPQ_CPQAAPerm', 'EinsteinAnalyticsPlusPsl' }, salesManagerUser.Id => new List<String>{ 'SalesforceCPQ_CPQStandardPerm', 'SalesforceCPQ_CPQAAPerm', 'EinsteinAnalyticsPlusPsl' } };

        for (Id userId : userLicenses.keySet()) {
            for (String licenseDeveloperName : userLicenses.get(userId)) {
                permissionSetLicenseAssignments.add(new PermissionSetLicenseAssign(AssigneeId = userId, PermissionSetLicenseId = licenseIdMap.get(licenseDeveloperName)));
            }
        }
        insert permissionSetLicenseAssignments;

        List<PermissionSetAssignment> permissionSetAssignments = new List<PermissionSetAssignment>();

        PermissionSetAssignment commissionsTeamUserPSAssignment = new PermissionSetAssignment(AssigneeId = commissionsTeamUser.Id, PermissionSetId = permissionSetMap.get('Commissions_Team'));
        PermissionSetAssignment businessAdminUserPSAssignment = new PermissionSetAssignment(AssigneeId = businessAdminUser.Id, PermissionSetId = permissionSetMap.get('Business_Admin1'));
        PermissionSetAssignment branchManagerUserPSAssignment = new PermissionSetAssignment(AssigneeId = branchManagerUser.Id, PermissionSetId = permissionSetMap.get('Branch_Manager1'));
        PermissionSetAssignment regionalSalesDirectorUserPSAssignment = new PermissionSetAssignment(AssigneeId = regionalSalesDirectorUser.Id, PermissionSetId = permissionSetMap.get('Regional_Sales_Director_Custom_Permission'));
        PermissionSetAssignment salesManagerUserPSAssignment = new PermissionSetAssignment(AssigneeId = salesManagerUser.Id, PermissionSetId = permissionSetMap.get('Sales_Management'));

        permissionSetAssignments.add(commissionsTeamUserPSAssignment);
        permissionSetAssignments.add(businessAdminUserPSAssignment);
        permissionSetAssignments.add(branchManagerUserPSAssignment);
        permissionSetAssignments.add(regionalSalesDirectorUserPSAssignment);
        permissionSetAssignments.add(salesManagerUserPSAssignment);

        insert permissionSetAssignments;
        // Create Account
        // Account acct = new Account();
        // acct.RM_Account_Number__c = '4';
        // acct.Company_Code__c = '01';
        // acct.Name = 'Test Account';
        // acct.Account_Type__c = 'Credit';
        // acct.E_mail_Address__c = '123@sunbeltrentals.com';
        // acct.Phone = '12345678';
        // acct.BillingStreet = '123 Main Street';
        // acct.BillingCity = 'Toronto';
        // acct.BillingPostalCode = 'M9N7V5';
        // acct.BillingState = 'ON';
        // acct.BillingCountry = 'CA';
        // acct.Drivers_License__c = 'AKF';
        // acct.Driver_s_License_State__c = 'AL';
        // acct.OwnerId = u4.Id;
        // insert acct;

        // User u = SBR_3_0_TestDataFactory.createUsers(1, false)[0];
        // u.FirstName = 'John';
        // u.LastName = 'Doe';
        // u.Rep_Type__c = 'General Tool';
        // insert u;
        // User u2 = SBR_3_0_TestDataFactory.createUsers(1, false)[0];
        // u2.FirstName = 'Wayne';
        // u2.LastName = 'Joseph';
        // u2.Rep_Type__c = 'General Tool';
        // u2.RepID__c = '12334';
        // insert u2;

        // Account_Relationship__c accRel = SBR_3_0_TestDataFactory.createAccountRelationships(1, acct.Id, false)[0];
        // accRel.User_Account__c = u.Id;
        // accRel.Sales_Rep_ID__c = 12345;
        // insert accRel;
    }

    @isTest
    public static void checkUserPermissionsForAMCCreationTest() {
        List<User> users = [SELECT Id FROM User];
        List<String> usersIds = new List<String>();
        for (User mUser : users) {
            usersIds.add(mUser.Id);
        }

        List<String> userCreationPermissionList = new List<String>();

        Test.startTest();
        userCreationPermissionList = SBR_3_0_AMCROperations.checkUserPermissionsForAMCCreation(usersIds);
        Test.stopTest();

        System.assert(true, userCreationPermissionList.size() > 0);
    }

    // @isTest
    // public Static void AMCROperationsTest() {
    //     Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
    //     User adminUser = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);

    //         List<User> uList =  [SELECT id, isActive,ProfileId FROM User where firstname = 'John' LIMIT 1];
    //         uList[0].Rep_Type__c = 'General Tool';
    //         uList[0].Country = 'US';
    //         update uList[0];

    //         List<User> uList2 =  [SELECT id, isActive,ProfileId FROM User where firstname = 'Wayne' LIMIT 1];
    //         uList2[0].Rep_Type__c = 'General Tool';
    //         uList2[0].Country = 'US';
    //         update uList2[0];

    //         List<Account> AccList =  [SELECT id FROM Account LIMIT 1];
    //         update AccList[0];

    //         List<Account_Relationship__c> ACCRelationShipList =  [SELECT id FROM Account_Relationship__c where Sales_Rep_ID__c = 12345 LIMIT 1];
    //         update ACCRelationShipList[0];

    //         Account_Management_Change_Request__c acmr = new Account_Management_Change_Request__c();
    //         acmr.Sales_Rep__c = uList2[0].Id;
    //         acmr.Account__c = AccList[0].Id;
    //         acmr.Account_Relationship__c = ACCRelationShipList[0].Id;
    //         acmr.Approval_Status__c = 'Submitted';
    //         System.debug('ACMR'+acmr);
    //         insert acmr;

    //         List<Account_Management_Change_Request__c> ACMRList= new List<Account_Management_Change_Request__c>();
    //         ACMRList.add(acmr);

    //         System.runas(adminUser){
    //         Test.startTest();
    //         SBR_3_0_AMCROperations.CheckAMCRUser(ACMRList);
    //         Test.stopTest();
    //     }
    // }
}