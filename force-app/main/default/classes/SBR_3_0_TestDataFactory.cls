/*********************************************************************************************************************
* Apex Class: SBR_3_0_TestDataFactory
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* @description Class to create test data for unit testing
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Kunal Patel           2022-02-02            Initial version
    2.0         Hrishikesh Kanabar    2022-07-25            Added Phone field to method:  List<Contact> createContacts as it was required.
    3.0         Konrad Haight         2022-08-17            Added method to create appointments
    4.0         Viren Patel           2022-09-20            Fixed country, state errors and required Case.cost_center__c, Project__c.Project_Name__c errors
    5.0         Bhavesh Dhamecha      2023-01-23            Updated for Bug SAL-8356
**********************************************************************************************************************************************/
@SuppressWarnings('PMD.ExcessiveClassLength, PMD.CyclomaticComplexity, PMD.ExcessivePublicCount, PMD.CognitiveComplexity')
public without sharing class SBR_3_0_TestDataFactory {

    /**
     * @description Creates account records, with default record type, for unit testing.
     * @param count The number of account records to create
     * @param insertRecords Boolean value indicating whether or not to insert records.
     * @return A list of resulting account records.
     */
    public static List<Account> createAccounts(Integer count, Boolean insertRecords) {
        List<Account> accounts = createAccounts(count, insertRecords, null);
        return accounts;
    }

    /**
     * @description Creates a mulesoft credential record
     * @return The credential record that was created
     */
    public static Credential__c createCredential() {
        Credential__c oCredential = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        oCredential.Name = 'Mule_Token_Endpoint';
        oCredential.Key_Id__c = 'keyid';
        oCredential.Secret__c ='credSecret';

        if(!Schema.sObjectType.Credential__c.isCreateable()){
            throw new SBR_3_0_CustomException('Insufficient access for creating Credential__c!');
        }

        insert oCredential;
        return oCredential;
    }

    /**
     * @description Creates Single Account Record for unit testing.
     * @param insertRecords Boolean value indicating whether or not to insert records.
     * @param recordTypeId of the record type to use when creating accounts.
     * @param name of the Account to use when creating accounts.
     * @param rmAccountNumber of the Account to use when creating accounts.
     * @param companyCode Code of the Account to use when creating accounts.
     * @return Account Record.
     */
    public static Account createSingleAccount(Boolean insertRecords, Id recordTypeId, String name, String rmAccountNumber, String companyCode){
        Account oAccount = new Account(
            Name = Name,
            Company_Name__c = Name,
            Status__c = SBR_3_0_Constants.ACCOUNT_STATUS_ACTIVE,
            Phone = string.valueOf(Math.abs(Crypto.getRandomLong())).substring(0, 10),
            RecordTypeId = recordTypeId,
            RM_Account_Number__c = RMAccountNumber,
            Company_Code__c = CompanyCode
        );
        if (insertRecords) {

            if(!Schema.sObjectType.Account.isCreateable()){
                throw new SBR_3_0_CustomException('Insufficient access for creating Account!');
            }

           insert oAccount;
        }
        return oAccount;
    }

    /**
     * @description Creates account records for unit testing.
     * @param count The number of account records to create
     * @param insertRecords Boolean value indicating whether or not to insert records.
     * @param recordType Developer name of the record type to use when creating accounts.
     * @return A list of resulting account records.
     */
    public static List<Account> createAccounts(Integer count, Boolean insertRecords, String recordType) {
        List<Account> accounts = new List<Account>();

        // Updated for Bug SAL-8356
        String randomPhoneNumber = string.valueOf(Math.abs(Crypto.getRandomLong()));
        randomPhoneNumber= randomPhoneNumber.substring(0,10);

        Id recordTypeId = getAvailableRecordTypeId(
            Account.sObjectType.getDescribe(SObjectDescribeOptions.DEFERRED),
            recordType
        );

        for(Integer i = 0; i < count; i++) {
            String randomString = generateRandomString(15);
            String name = randomString + String.valueOf(i);

            Account acct = new Account(
                Name = name,
                Company_Name__c = name,
                Status__c = SBR_3_0_Constants.ACCOUNT_STATUS_ACTIVE,
                Phone = randomPhoneNumber, // Updated for Bug SAL-8356
                BillingStreet = name,
                BillingCity = randomString,
                BillingState = 'IN',
                BillingPostalCode = '20111',
                BillingCountry = 'US',
                ShippingStreet = name,
                ShippingCity = randomString,
                ShippingState = 'IN',
                ShippingPostalCode = randomString,
                ShippingCountry = 'US',
                RecordTypeId = recordTypeId,
                RM_Account_Number__c = name,
                Company_Code__c = '01'
            );

            if(recordType == 'Non_Credit'){
                acct.RM_Cash_State__c='GA';
                acct.RM_Cash_Number__c='7650009990';
            }else if (recordType == 'Credit') {
                acct.RM_Cash_State__c = 'KX9';
                acct.RM_Cash_Number__c = '1234';
            }

            accounts.add(acct);
        }

        insertRecords(accounts, insertRecords);

        return accounts;
    }

    /**
     * @description Creates contact records for unit testing.
     * @param count The number of contact records to create.
     * @param accountId The id of the parent account record.
     * @param insertRecords Boolean value indicating whether or not to insert the records.
     * @return A list of resulting contact records.
     */
    public static List<Contact> createContacts(Integer count, Id accountId, Boolean insertRecords) {
        List<Contact> contacts = new List<Contact>();

        for(Integer i = 0; i < count; i++) {
            String randomString = generateRandomString(15);
            String name = randomString + String.valueOf(i);
            Integer randomNumber = (Integer)Math.floor(Math.random() * 9000) + 1000000000;
            String randomPhoneNbr = String.valueOf(randomNumber);
            contacts.add(
                new Contact(
                    FirstName = name,
                    LastName = name,
                    AccountId = accountId,
                    Title = 'Test Title',
                    Email = name.deleteWhitespace() + '@salesforce.com',
                    MailingCity = name,
                    MailingStreet = randomString,
                    MailingState = 'CA',
                    MailingCountry = 'US',
                    Phone=randomPhoneNbr,
                    MailingPostalCode = randomString
                )
            );
        }

        insertRecords(contacts, insertRecords);

        return contacts;
    }

    /**
     * @description Creates lead records for unit testing
     * @param count The number of lead records to create.
     * @param insertRecords Boolean value indicating whether or not to insert records.
     * @return A list of resulting lead records.
     */
    public static List<Lead> createLeads(Integer count, Boolean insertRecords) {
        List<Lead> leads = new List<Lead>();

        for(Integer i = 0; i < count; i++) {
            String randomString = generateRandomString(15);
            String name = randomString + String.valueOf(i);

            leads.add(
                new Lead(
                    FirstName = name,
                    LastName = name,
                    Company = name + ' Company',
                    Email = name.deleteWhitespace() + '@salesforce.com',
                    Street = name,
                    City = randomString,
                    State = 'CA',
                    PostalCode = randomString,
                    Country = 'US'
                )
            );
        }

        insertRecords(leads, insertRecords);

        return leads;
    }

    /**
     * @description Creates credential records for unit testing.
     * @param count The number of credential records to create.
     * @param insertRecords Boolean value indicating whether or not to insert records.
     * @return A list of resulting credential records.
     */
    public static List<Credential__c> createCredentials(Integer count, Boolean insertRecords) {
        List<Credential__c> credentials = new List<Credential__c>();

        for(Integer i = 0; i < count; i++) {
            credentials.add(
                new Credential__c(
                    Name = generateRandomString(15) + String.valueOf(i),
                    Environment__c = SBR_3_0_Constants.SANDBOX,
                    Key_Id__c = generateRandomString(15) + String.valueOf(i)
                )
            );
        }

        insertRecords(credentials, insertRecords);

        return credentials;
    }

    /**
     * @description Creates case records for unit testing.
     * @param count The number of cases to create.
     * @param insertRecords Boolean value indicating whether or not to insert records.
     * @return A list of resulting case records.
     */
    public static List<Case> createCases(Integer count, Boolean insertRecords) {
        return createCases(count, null, insertRecords, 'Web', null, 'Random Subject', null);
    }

    /**
     * @description Creates asset records for unit tests.
     * @param count The number of asset records to create.
     * @param insertRecords Boolean value indicating whether or not to insert records.
     * @return A list of resulting asset records.
     */
    public static List<Asset> createAssets(Integer count, Boolean insertRecords) {
        return createAssets(count, insertRecords, null, null, null, null);
    }

    /**
     * @description Creates asset records for unit tests.
     * @param count The number of asset records to create.
     * @param insertRecords Boolean value indicating whether or not to insert records.
     * @param accountId The id of the parent account record.
     * @param contactId The id of the parent contact record.
     * @param locId The id of the parent location record.
     * @return A list of resulting asset records.
     */
    public static List<Asset> createAssets(Integer count, Boolean insertRecords, Id accountId, Id contactId, Id locId) {
        return createAssets(count, insertRecords, accountId, contactId, locId, 'Available');
    }

    /**
     * @description Creates non-inventory location records for unit tests.
     * @param count The number of records to create.
     * @param insertRecords Boolean value indicating whether or not to insert records.
     * @param recordType The developer name of the record type to use when creating the non-inventory location records.
     * @return A list of resulting location records.
     */
    public static List<Schema.Location> createLocations(Integer count, Boolean insertRecords, String recordType) {
        return createLocations(count, insertRecords, recordType, false);
    }

    /**
     * @description Creates inventory location records for unit tests.
     * @param count The number of records to create.
     * @param insertRecords Boolean value indicating whether or not to insert records.
     * @param recordType The developer name of the record type to use when creating the inventory location records.
     * @return A list of resulting location records.
     */
    public static List<Schema.Location> createInventoryLocations(Integer count, Boolean insertRecords, String recordType) {
        return createLocations(count, insertRecords, recordType, true);
    }

    /**
     * @description Creates associated location records for unit tests.
     * @param count The number of records to create
     * @param accountId - The Id of the parent account record.
     * @param branchId The Id of the parent branch record.
     * @param jobLocationId The Id of the parent job location record
     * @param insertRecords A boolean value indicating whether or not to insert records.
     * @return A list of associated location records.
     */
    public static List<AssociatedLocation> createAssociatedLocations(Integer count, Id accountId, Id branchId, Id jobLocationId, Boolean insertRecords) {
        List<AssociatedLocation> associatedLocations = new List<AssociatedLocation>();

        for(Integer i = 0; i < count; i++) {
            String randomString = generateRandomString(10);
            String name = randomString + String.valueOf(i);
            associatedLocations.add(
                new AssociatedLocation(
                    Job_Number__c = randomString,
                    ParentRecordId = accountId,
                    LocationId = jobLocationId,
                    Branch__c = branchId,
                    Street_Address__c = name,
                    City__c = randomString,
                    State__c = 'CA',
                    Zip_Code__c = randomString.length() > 6 ? randomString.LEFT(6) : randomString,
                    Job_Site_Id__c = randomString
                )
            );
        }

        insertRecords(associatedLocations, insertRecords);

        return associatedLocations;
    }

     /**
      * @description Create opportunity records for unit tests.
      * @param count - The number of records to create.
      * @param accountId - The Id of the parent account record.
      * @param insertRecords - Boolean value indicating whether or not to insert records.
      * @return A list of resulting opportunity records.
      */
     public static List<Opportunity> createOppts(Integer count, Id accountId, Boolean insertRecords) {
        List<Opportunity> oppts = new List<Opportunity>();

        Date today = Date.today();
        for(Integer i = 0; i < count; i++) {
            oppts.add(
                new Opportunity(
                    Name = generateRandomString(15) + String.valueOf(i),
                    AccountId = accountId,
                    Est_Start_Date__c = today,
                    Est_End_Date__c = today,
                    CloseDate = today,
                    StageName = 'Qualification',
                    Est_Duration_in_Weeks__c = 10,
                    City__c='Jersey City',
                    State__c='NJ'
                )
            );
        }

        insertRecords(oppts, insertRecords);

        return oppts;
    }

    /**
     * @description Creates case records for a given account, for unit testing.
     * @param count The number of cases to create.
     * @param accountId The Id of the parent account record.
     * @param insertRecords Boolean value indicating whether or not to insert records.
     * @param origin The case origin.
     * @param priority The case priority.
     * @return A list of resulting case records.
     */
    public static List<Case> createCaseForAnAccount(Integer count, Id accountId, Boolean insertRecords, String origin, String priority) {
        return createCases(count, accountId, insertRecords, origin, priority, 'Testing Resolved Fields', 'Sales Lead-Rental/Sales');
    }

    /**
     * @description Creates equipment on hold records for unit tests
     * @param count - The number of equipment on hold records to create.
     * @param insertRecords - Boolean value indicating whether or not to insert the records.
     * @param assetId - The Id of the parent asset record.
     * @param strAssetId - A second id of the asset record.
     * @return A list of resulting equipment on hold records.
     */
    public static List<Equipment_on_Hold__c> createEquipmentOnHold(Integer count, Boolean insertRecords, Id assetId, String strAssetId){
        List<Equipment_on_Hold__c> eqHoldList = new List<Equipment_on_Hold__c>();
        for(Integer i = 0; i < count; i++) {
            eqHoldList.add(
                new Equipment_on_Hold__c(
                    SM_PS_Equipment_Number__c = assetId,
                    Name = generateRandomString(15),
                    SM_PS_Asset_Id__c = strAssetId
                )
            );
        }

        insertRecords(eqHoldList, insertRecords);

        return eqHoldList;
    }

    /**
     * @description Creates account relationship records for unit tests.
     * @param count - The number of relationships to create.
     * @param accountId - The id fo the parent account record.
     * @param insertRecords - Boolean value indicating whether or not to insert the relationship records.
     * @return A list of resulting account relationship records.
     */
    public static List<Account_Relationship__c> createAccountRelationships(Integer count, Id accountId, Boolean insertRecords) {
        List<Account_Relationship__c> ars = new List<Account_Relationship__c>();
        for (Integer i = 0; i < count; i++) {
            ars.add(
                new Account_Relationship__c(
                    Account_ID__c = accountId
                )
            );
        }

        insertRecords(ars, insertRecords);

        return ars;
    }

    /**
     * @description Create products for unit tests.
     * @param count - The number of products to create.
     * @param insertRecords - Boolean value indicating whether or not to insert product records.
     * @return A list of resulting product records.
     */
    public static List<Product2> createProducts(Integer count, Boolean insertRecords){
        List<Product2> productList = new List<Product2>();
        for(Integer i = 0; i < count; i++) {
            productList.add(
                new Product2(
                    Name = 'Product'+ generateRandomString(15)
                )
            );
        }

        insertRecords(productList, insertRecords);

        return productList;
    }

    /**
     * @description Create stocked serial records for unit tests.
     * @param count - The nubmer of stocked serial records to create.
     * @param insertRecords - Boolean value indicating whether or not to insert records.
     * @param assetId - The id of the parent asset record.
     * @param productId - The id of the parent product record.
     * @param productItemId - The Id of the parent product item record.
     * @return A list of resulting stocked serial records.
     */
    public static List<Stocked_Serial__c> createStockedSerials(Integer count, Boolean insertRecords, Id assetId, Id productId, Id productItemId){
        List<Stocked_Serial__c> stockedSerials = new List<Stocked_Serial__c>();
        for(Integer i = 0; i < count; i++) {
            stockedSerials.add(
                new Stocked_Serial__c(
                    SM_PS_Asset__c = assetId,
                    SM_PS_Product__c = productId,
                    SM_PS_Product_Item__c = productItemId
                )
            );
        }

        insertRecords(stockedSerials, insertRecords);

        return stockedSerials;
    }

    /**
     * @description Creates product items for unit tests.
     * @param count - The number of product items to create.
     * @param insertRecords - Boolean value indicating whether or not to insert records.
     * @param productId - The id of the parent product record.
     * @param locationId - The id of the aprent location record.
     * @return A list of resulting product item records.
     */
    public static List<ProductItem> createProductItems(Integer count, Boolean insertRecords, Id productId, Id locationId){
        List<ProductItem> productItems = new List<ProductItem>();
        for(Integer i = 0; i < count; i++) {
            productItems.add(
                new ProductItem(
                    Product2Id = productId,
                    LocationId = locationId,
                    QuantityOnHand = 5,
                    SM_PS_Quantity_Available__c = 3,
                    SM_PS_Quantity_on_Rent__c = 2,
                    SM_PS_Quantity_Returned__c = 4,
                    SM_PS_Quantity_Reserved__c = 2,
                    SM_PS_ProductItem_Id__c = generateRandomString(10)
                )
            );
        }

        insertRecords(productItems, insertRecords);

        return productItems;
    }

    /**
     * @description Creates events / appointments for unit tests.
     * @param count - The number of event activities to create.
     * @param whatId - The record the events are related to.
     * @param whoId - The id of the attendee (can be a Contact, Lead, or User)
     * @param insertRecords - A boolean value indicating whether or not to insert the records.
     * @return A list of resulting event / appointment / activity records.
     */
    public static List<Event> createAppointments(Integer count, Id whatId, Id whoId, Boolean insertRecords) {
        List<Event> appointments = new List<Event>();

        Datetime startDateTime = Datetime.now();
        Datetime endDateTime = startDateTime.addHours(1);

        for(Integer i = 0; i < count; i++) {
            appointments.add(
                new Event(
                    Description = generateRandomString(15) + String.valueOf(i),
                    StartDateTime = startDateTime,
                    EndDateTime = endDateTime,
                    WhatId = whatId,
                    WhoId = whoId,
                    City__c ='Centreville',
                    State__c ='VA',
 					Country__c = 'US',
					Override_System_Address_Updates__c=true
                )
            );
        }

        insertRecords(appointments, insertRecords);

        return appointments;
    }

    /**
     * @description Creates user(s) for unit tests. DO NOT USE - Used for historical purpose.
     * @param count The number of users to create
     * @param insertRecords Boolean value indicating whether or not to insert the records.
     * @return A list of users created.
     */
    public static List<User> createUsers(Integer count, boolean insertRecords){
        return createUsersWithPermissions(1, insertRecords, 'Sales', new Set<String>(), new Set<String>());
    }

    /**
     * @description Creates a Sales user for unit tests.
     * @return A sales user with Id.
     */
    public static User createSalesUser(){
        return createUsersWithPermissions(1, true, 'Sales', new Set<String>{ 'SalesUserPsl' }, new Set<String>{ 'Sales_User '})[0];
    }

    /**
     * @description Creates a Service user for unit tests.
     * @return A service user with Id.
     */
    public static User createServiceUser(){
        return createUsersWithPermissions(1, true, 'Service', new Set<String>{ 'SalesUserPsl' }, new Set<String>{ 'Sales_User '})[0];
    }

    /**
     * @description Creates an admin users for unit tests.
     * @return An admin user with Id.
     */
    public static User createAdminUser(){
        return createUsersWithPermissions(1, true, 'System Administrator', new Set<String>{ 'SalesUserPsl', 'Integration API Access' }, new Set<String>{ 'Sales_User '})[0];
    }

    /**
     * @description Creates one or more Sales users for unit tests.
     * @param count - The number of users to create.
     * @param insertRecords - Boolean value indicating whether or not to insert the user records.
     * @param profile Name of the profile to use when creating the user
     * @param permissionSetLicenseNames A set of strings of permission set licenses to apply to the user.
     * @param permissionSetNames A set of strings of permission sets to apply to the user.
     * @return A list of sales users.
     */
    public static List<User> createUsersWithPermissions(Integer count, Boolean insertRecords, String profile, Set<String> permissionSetLicenseNames, Set<String> permissionSetNames){
        List<User> userList = new List<User>();

        Profile p = [SELECT Id FROM Profile WHERE Name = :profile WITH USER_MODE];

        for(Integer i = 0; i < count; i++){
            String email = profile.replace(' ','') + '_' + generateRandomString(15) +'@sunbeltrentals.com';
            User u = createUser(false, p);
            u.Username = email + '.unittest';
            u.Email = email;
            u.RepId__c = generateRandomNumber(15) + i;
            u.SF_PS_Mechanic_Id__c = '8888' + i;
            userList.add(u);
        }

        userList = (List<User>)insertRecords(userList, insertRecords);

        if(permissionSetLicenseNames != null){
            List<PermissionSetLicense> licenses = [Select Id,MasterLabel,DeveloperName From PermissionSetLicense Where DeveloperName = :permissionSetLicenseNames With USER_MODE];
            List<PermissionSetLicenseAssign> licenseAssignments = new List<PermissionSetLicenseAssign>();
            for(PermissionSetLicense psl : licenses){
                for(User u : userList){
                    licenseAssignments.add(
                        new PermissionSetLicenseAssign(
                            AssigneeId = u.Id,
                            PermissionSetLicenseId = psl.Id
                        )
                    );
                }
            }
            insertRecords(licenseAssignments,true);
        }

        if(permissionSetNames != null){
            List<PermissionSetAssignment> permissionSetAssignments = new List<PermissionSetAssignment>();
            for(PermissionSet ps : [Select Id From PermissionSet Where Name in :permissionSetNames With USER_MODE]){
                for(User u : userList){
                    permissionSetAssignments.add(
                        new PermissionSetAssignment(
                            AssigneeId = u.Id,
                            PermissionSetId = ps.Id
                        )
                    );
                }
            }
            insertRecords(permissionSetAssignments,true);
        }

        return userList;
    }

    /**
     * @description Creates a user record for unit testing.
     * @param insertRecord - Boolean value indicating whether or not to insert a record.
     * @param oProfile - The profile that the user will be created / assocaited with.
     * @return A user instance. If insertRecord is true, the instance will have an Id populated.
     */
    public static User createUser(Boolean insertRecord, Profile oProfile){
        User oUser = new User(
            Alias = 'batman',
            Email = 'bruce.wayne@sunbeltrentals.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Wayne',
            FirstName = 'Bruce',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = oProfile.Id,
            TimeZoneSidKey = 'America/Chicago',
            Username = generateRandomString(5) + DateTime.now().getTime() + '@SBRtestorg.com',
            IsActive = true,
            City = '',
            Country = 'CA',
            CountryCode = 'CA',
            PostalCode = 'V9B 3Y8',
            State = 'BC',
            StateCode = 'BC',
            Street = '2994 Jacklin Rd',
            UserPermissionsMarketingUser = true
        );

        insertRecords(oUser, insertRecord);

        return oUser;
    }

    /**
     * @description Create project records.
     * @param count - The number of projects to create.
     * @param insertRecords - Boolean value indicating whether or not to insert the records.
     * @return A list of resulting project records.
     */
    public static List<Project__c> createProjects(Integer count, Boolean insertRecords) {
        List<Project__c> projects = new List<Project__c>();

        for(Integer i = 0; i < count; i++) {
            projects.add(
                new Project__c(
                    City__c = 'Test City',
                    State__c = 'IN',
                    Project_Name__c = generateRandomString(15) + String.valueOf(i)
                )
            );
        }

        insertRecords(projects, insertRecords);

        return projects;
    }

    /**
     * @description Create project records.
     * @param count - The number of projects to create.
     * @param insertRecords - Boolean value indicating whether or not to insert the records.
     * @return A list of resulting project records.
     */
    public static List<Project__c> createProjectsNew(Integer count, Boolean insertRecords) {
        List<Project__c> projects = new List<Project__c>();

        for(Integer i = 0; i < count; i++) {
            projects.add(
                new Project__c(
                    City__c = 'Indianapolis',
                    State__c = 'IN',
                    Project_Name__c = generateRandomString(15) + String.valueOf(i)
                )
            );
        }

        insertRecords(projects, insertRecords);

        return projects;
    }

    /**
     * @description Creates contract records for unit tests.
     * @param count - The number of contract records to create.
     * @param accountId - Id of the parent account record.
     * @param contractTerm - The term of the contract.
     * @param status - The status of the contract(s).
     * @param insertRecords - Boolean value indicating whether or not to insert records.
     * @return A list of resulting contract records.
     */
    public static List<Contract> createContracts(Integer count, String accountId, Integer contractTerm, String status, Boolean insertRecords) {
        List<Contract> contracts = new List<Contract>();
        Date startDate = Date.today();

        for(Integer i = 0; i < count; i++) {
            contracts.add(
                new Contract(
                    AccountId = accountId,
                    Status = status,
                    ContractTerm = contractTerm,
                    StartDate = startDate
                )
            );
        }

        insertRecords(contracts, insertRecords);

        return contracts;
    }

    /**
     * @description Creates task records for unit tests.
     * @param count - The number of task records to create.
     * @param relatedToId - The record that the task is related to.
     * @param whoId - Who the task is associated with (e.g. a Contact, User, or Lead record)
     * @param assignedToId - The id of the user, group, or queue that the record is owned by / assigned to.
     * @param insertRecords - A boolean value indicating whether or not to insert the task records.
     * @return A list of resulting task / activity records.
     */
    public static List<Task> createTasks(Integer count, String relatedToId, String whoId, String assignedToId, Boolean insertRecords) {
        List<Task> tasks = new List<Task>();
        for(Integer i = 0; i < count; i++) {
            tasks.add(
                new Task(
                    OwnerId = assignedToId,
                    WhatId = relatedToId,
                    Priority = 'Normal',
                    Status = 'Open',
                    WhoId = whoId,
                    ActivityDate = Date.today()
                )
            );
        }

        insertRecords(tasks, insertRecords);

        return tasks;
    }

    /**
     * @description Creates campaign records for unit tests.
     * @param count - The number of campaigns to create.
     * @param insertRecords - The number of campaign records to insert.
     * @param recordType - A string containing the developer name of the campaign record type to use.
     * @return A list of resulting campaign records.
     */
    public static List<Campaign> createCampaigns(Integer count, Boolean insertRecords, String recordType) {
        Date startDate = Date.today();
        Date endDate = startDate.addDays(1);
        List<Campaign> campaigns = new List<Campaign>();
        Id recordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get(recordType)?.getRecordTypeId();

        for(Integer i = 0; i < count; i++) {
            campaigns.add(
                new Campaign(
                    Name = generateRandomString(15) + String.valueOf(i),
                    StartDate = startDate,
                    EndDate = endDate,
                    RecordTypeId = recordTypeId
                )
            );
        }

        insertRecords(campaigns, insertRecords);

        return campaigns;
    }

    /**
     * @description Creates equipment type records for unit tests.
     * @param count - The number of equipment type records to create.
     * @param insertRecords - Boolean value indicating whether or not to insert records.
     * @return A list of resulting equipment type records.
     */
    public static List<Equipment_Type__c> createEquipmentTypes(Integer count, Boolean insertRecords) {
        List<Equipment_Type__c> equipmentTypes = new List<Equipment_Type__c>();
        for(Integer i = 0; i < count; i++) {
            equipmentTypes.add(
                new Equipment_Type__c(
                    Name = generateRandomString(79) + String.valueOf(i)
                )
            );
        }

        insertRecords(equipmentTypes, insertRecords);

        return equipmentTypes;
    }

    /**
     * @description Create quote records for unit tests.
     * @param count - The number of quotes to create.
     * @param insertRecords - Boolean value that indicates whether or not to insert the quote records.
     * @param recordType - String containing the developer name of the record type of quotes to create.
     * @return A list of resulting CPQ quote records
     */
    public static List<SBQQ__Quote__c> createQuotes(Integer count, Boolean insertRecords, String recordType) {
        List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();

        Id recordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName().get(recordType)?.getRecordTypeId();
        List<Account> lAccounts = [Select Id from Account where recordtype.name =: SBR_3_0_Constants.ACCOUNT_REC_TYPE_CREDIT WITH SECURITY_ENFORCED];
        if(lAccounts.isEmpty()){
            lAccounts = createAccounts(1,true,SBR_3_0_Constants.ACCOUNT_REC_TYPE_CREDIT);
        }
        Account acct = lAccounts[0];

        for(Integer i = 0; i < count; i++) {
            quotes.add(
                new SBQQ__Quote__c(
                    Quote_Name__c = generateRandomString(15) + String.valueOf(i),
                    //Account_Record_Type_Txt__c = 'Credit'
                    SBQQ__Account__c = acct.Id
                )
            );

            if(!String.isBlank(recordTypeId)){
                quotes.get(i).RecordTypeId = recordTypeId;
            }
        }

        insertRecords(quotes, insertRecords);

        return quotes;
    }

    /**
     * @description create quote lines.
     * @param count - The number of quote lines to create.
     * @param insertRecords - Boolean value indicating whether or not to insert records.
     * @param quoteId - The id of the parent quote.
     * @return A list of resulting quote line items.
     */
    public static List<SBQQ__QuoteLine__c> createQuoteLines(Integer count, Boolean insertRecords, Id quoteId) {
        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();

        for(Integer i = 0; i < count; i++) {
            quoteLines.add(
                new SBQQ__QuoteLine__c(
                    Line_Name__c = generateRandomString(15) + String.valueOf(i),
                    SBQQ__Quote__c = quoteId
                )
            );
        }

        insertRecords(quoteLines, insertRecords);

        return quoteLines;
    }

    /**
     * @description Create crew records.
     * @param count - The number of crew records to create.
     * @param insertRecords - Boolean value indicating whether or not to insert the records.
     * @param taskType - The type of task the crew is associated with.
     * @param quoteId - Id of the relating quote.
     * @return a List of resulting crew records.
     */
    public static List<Crew__c> createCrew(Integer count, Boolean insertRecords, String taskType, Id quoteId) {
        List<Crew__c> crews = new List<Crew__c>();
        for(Integer i = 0; i < count; i++) {
            crews.add(
                new Crew__c(
                    Quote__c = quoteId,
                    Task__c = taskType,
                    Crew__c = 1,
                    Shift__c = 1,
                    Standard_Hours__c = 8,
                    Overtime_Hours__c = 8,
                    Rate_Overtime__c = 15,
                    Rate_Standard__c = 7.5
                )
            );
        }

        insertRecords(crews, insertRecords);
        return crews;
    }

    /**
     * @description Create engineering request(s).
     * @param count - The number of engineering requests to create.
     * @param insertRecords - Boolean value indicating whether or not to insert the records.
     * @return a List of the resulting engineering requests.
     */
    public static List<Engineering_Request__c> createEngineeringRequest(Integer count, Boolean insertRecords) {
        Account a = createAccounts(1, true, SBR_3_0_Constants.ACCOUNT_REC_TYPE_CREDIT)[0];
        Contact c = createContacts(1, a.Id, true)[0];
        Schema.Location b = createLocations(1, true, SBR_3_0_Constants.LOCATION_REC_TYPE_BRANCH)[0];
        Schema.Location l = createLocations(1, true, SBR_3_0_Constants.LOCATION_REC_TYPE_JOB_LOC)[0];
        AssociatedLocation al = createAssociatedLocations(1, a.Id, b.Id, l.Id, true)[0];
        SBQQ__Quote__c q = createQuotes(1, true, SBR_3_0_Constants.QUOTE_REC_TYPE_RENTAL_QUOTE)[0];

        List<Engineering_Request__c> ers = new List<Engineering_Request__c>();
        for(Integer i = 0; i < count; i++) {
            ers.add(
                new Engineering_Request__c(
                    Customer__c = a.Id,
                    Primary_Contact__c = c.Id,
                    Jobsite__c = al.Id,
                    Branch__c = b.Id,
                    Quotes__c = q.Id,
                    Requests_Type__c = 'Inquiry'
                )
            );
        }

        insertRecords(ers, insertRecords);

        return ers;
    }

    /**
     * @description create order
     * @param insertRecords - Boolean value indicating whether or not to create records.
     * @param name - The name of the order
     * @param recordTypeId - Id of the record type of the order to create.
     * @return The resulting order record.
     */
    public static Order createOrder(Boolean insertRecords, String name, Id recordTypeId){
        Account oAccount = createAccounts(1, true, SBR_3_0_Constants.ACCOUNT_REC_TYPE_CREDIT)[0];

        // Create Location
        Schema.Location jobLocation = new Schema.Location(
            Name = 'Test Job Location',
            Street_Address__c = '12 Main Street',
            City__c = 'Toronto',
            Zip_Code__c = 'M7N7B3',
            State__c = 'ON',
            Country__c = 'CA',
            RecordTypeId = SBR_3_0_Constants.LOCATION_JOB_RT_ID,
            OMS_Sourcing_Enabled__c = true,
            Distance_Multiplier__c = 50,
            Analysis_Region_Key__c = '001',
            Company_Code__c = '01'
        );
        insertRecords(jobLocation, true);

        // Create Branch
        Schema.Location branchLocation = new Schema.Location(
            Branch_Location_Number__c = '1234',
            Name = 'Test Branch Location',
            Street_Address__c = '12 Main Street',
            City__c = 'Toronto',
            Zip_Code__c = 'M7N7B3',
            State__c = 'ON',
            Country__c = 'CA',
            Job_Number__c = '332112',
            RecordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID,
            Company_Code__c = 'X',
            Time_Zone_Name__c = 'America/Chicago',
            Time_Zone__c = 3
        );
        insertRecords(branchLocation, true);

        String randomString = generateRandomString(10);
        AssociatedLocation jobSite = new AssociatedLocation(
            Name__c = 'Test Job Site',
            ParentRecordId = oAccount.Id,
            LocationId = jobLocation.Id,
            Branch__c = branchLocation.Id,
            Job_Number__c = '20221004A',
            Job_Site_Id__c = randomString
        );
        insertRecords(jobSite, true);

        Order oOrder = new Order(
            Quote_Name__c = 'Test Quote',
            AccountId = oAccount.Id,
            Jobsite__c = jobSite.Id,
            Deliverymethod__c = 'Delivery',
            Delivery_Charge__c = 10,
            Status = 'Draft',
            Pricebook2Id = Test.getStandardPricebookId(),
            Start_Date__c = date.valueOf('2022-12-12 12:00:00'),
            EffectiveDate = date.valueOf('2022-12-12 12:00:00'),
            EndDate = date.valueOf('2023-10-09 8:00:00'),
            Return_Date__c = date.valueOf('2023-10-09 8:00:00'),
            Earliest_Delivery_Date__c = date.valueOf('2022-10-08 12:00:00'),
            Opt_Out_RPP__c = false,
            Order_Initiating_Channel__c = 'SLSFRC',
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Duration__c = 'Custom',
            recordtypeId = RecordtypeId
        );

        insertRecords(oOrder, insertRecords);
        return oOrder;
    }

    /**
     * @description Creates product hierarchies
     * @param insertRecords - Boolean value indicating whether or not to insert records.
     * @param name - The name of the product hierarchy to create.
     * @return The product hierarchy instance.
     */
    public static Product_Hierarchy__c createProductHierarchies(Boolean insertRecords,String name){
        Product_Hierarchy__c oPH = new Product_Hierarchy__c(
            Name = name,
            Product_Hierarchy_Code__c = '1234'
        );

        insertRecords(oPH, insertRecords);

        return oPH;
    }

    /**
     * @description Create product features
     * @param insertRecords - Boolean value that indicates whether or not to insert records.
     * @param productId - Id of the associated product.
     * @return The resulting SBQQ_ProductFeature__c record.
     */
    public static SBQQ__ProductFeature__c createProductFeatures(Boolean insertRecords,Id productId){
        SBQQ__ProductFeature__c oPF = new SBQQ__ProductFeature__c(
            Name = 'Test',
            SBQQ__Number__c = 1234,
            SBQQ__ConfiguredSKU__c = ProductId
        );

        insertRecords(oPF, insertRecords);

        return oPF;
    }

    /**
     * @description Creates a message?
     * @param insertRecords - Boolean value indicating whether or not to insert the records.
     * @param productMessageId - Id of the associated Product Message record.
     * @return The resulting Message__c record.
     */
    public static Message__c createMessage(Boolean insertRecords, String productMessageId){
        Message__c oMessage = new Message__c(
            Name = 'Test',
            Product_Message_Id__c = productMessageId
        );

        insertRecords(oMessage, insertRecords);

        return oMessage;
    }

    /**
     * @description Creates a message?
     * @param insertRecords - Boolean value indicating whether or not to insert the records.
     * @param productId - Id of the associated Product2 record.
     * @return The resulting SBQ__ProductOption__c record.
     */
    public static SBQQ__ProductOption__c createMessage(Boolean insertRecords,Id productId){
        SBQQ__ProductOption__c oPO = new SBQQ__ProductOption__c(
            SBQQ__ConfiguredSKU__c = productId,
            SBQQ__Number__c = 1234
        );

        insertRecords(oPO, insertRecords);

        return oPO;
    }

    /**
     * @description Creates a product message.
     * @param insertRecords - Boolean value determining whether or not to insert the product message.
     * @param productId - Id of the associated product.
     * @return The resulting product message record.
     */
    public static Product_Message__c createProductMessage(Boolean insertRecords, Id productId){
        Product_Message__c oPM = new Product_Message__c(Product__c = ProductId);

        insertRecords(oPM, insertRecords);

        return oPM;
    }

    /**
     * @description Creates territory records.
     * @param insertRecords - A boolean determining whether or not to insert records.
     * @param territoryId Id of the territory?
     * @return the resulting territory__c record.
     */
    public static Territory__c createTerritory(Boolean insertRecords, Id territoryId){
        Territory__c oTerritory = new Territory__c(Territory_Id__c = territoryId);

        insertRecords(oTerritory, insertRecords);

        return oTerritory;
    }

    /**
     * @description Creates pricebook entries for each of the products passed in.
     * @param scope - A list of products to use when creating price book entries.
     * @return a list of pricebook entry records.
     */
    public static List<PricebookEntry> createPriceBookEntries(List<Product2> scope) {

        Map<String,String> ccToCurrency = getCompanyAndCurrencies();

        List<Pricebookentry> pbes = new List<Pricebookentry>();

        Id pricebookId = Test.getStandardPricebookId();

        update new Pricebook2(Id=pricebookId,IsActive=true); //NOPMD

        for(Product2 p2 : (List<Product2>)scope) {
            if(p2.Company_Code__c!=null){
                for (String cc : p2.Company_Code__c.split(';')) {
                    pbes.add(
                        new Pricebookentry (
                            Pricebook2Id = pricebookId,
                            IsActive = true,
                            UnitPrice = 0,
                            Product2Id = p2.Id,
                            CurrencyIsoCode = ccToCurrency.get(cc)
                        )
                    );
                }
            }
        }

        insertRecords(pbes,true);

        return pbes;
    }

    /**
     * @description Creates products and related pricebook entry
     * records for unit tests.
     * @return a list of newly created pricebook entry records,
     * related to the standard pricebook.
     */
    public static List<PricebookEntry> createProductsAndPricebookEntries(){
        // Create Product
        List<Product2> products = new List<Product2>{
            new Product2(
                Name = 'Test Product 0',
                Product_Type__c = 'Cat-Class',
                Product_SKU__c = '1234567',
                Category__c = '32134',
                Class__c = '2039',
                ToolFlex__c = 'N',
                Company_code__c ='01'
            ),
            new Product2(
                Name = 'Test Product 1',
                Product_Type__c = 'Merchandise',
                Item_Number__c = '1234GH',
                Stock_Class__c = 'AIMFV',
                Product_SKU__c ='01-PIPSA-817633',
                Company_code__c ='01'
            ),
            new Product2(
                Name = 'Test Product 2',
                Product_Type__c = '',
                Item_Number__c = '1285JC',
                Stock_Class__c = 'UJEKL',
                Company_code__c ='01'
            )
        };

        insertRecords(products, true);

        //Create PRICE BOOK ENTRIES
        return SBR_3_0_TestDataFactory.createPriceBookEntries(products);
    }

    /**
     * @description Creates asset records for unit tests.
     * @param count The number of asset records to create.
     * @param insertRecords Boolean value indicating whether or not to insert records.
     * @param accountId The id of the parent account record.
     * @param contactId The id of the parent contact record.
     * @param locationId The id of the parent location record.
     * @param status The status of the asset record.
     * @return A list of resulting asset records.
     */
    private static List<Asset> createAssets(Integer count, Boolean insertRecords, Id accountId, Id contactId, Id locationId, String status) {
        List<Asset> assets = new List<Asset>();

        for(Integer i = 0; i < count; i++) {
            assets.add(
                new Asset(
                    Name = generateRandomString(15) + String.valueOf(i),
                    AccountId = accountId,
                    ContactId = contactId,
                    SM_PS_Current_Location__c = locationId,
                    Status = status
                )
            );
        }

        insertRecords(assets, insertRecords);

        return assets;
    }

    /**
     * @description Creates case records for a given account, for unit testing.
     * @param count The number of cases to create.
     * @param accountId The Id of the parent account record.
     * @param insertRecords Boolean value indicating whether or not to insert records.
     * @param origin The case origin.
     * @param priority The case priority.
     * @param subject The subject of the case.
     * @param caseType The type of the case.
     * @return A list of resulting case records.
     */
    public static List<Case> createCases(Integer count, Id accountId, Boolean insertRecords, String origin, String priority, String subject, String caseType) {
        Schema.Location loc = SBR_3_0_TestDataFactory.createLocations(count, true, 'Branch')[0];
        List<Case> casList = new List<Case>();

        for(Integer i = 0; i < count; i++) {
            casList.add(
                new Case(
                    Status ='New',
                    Priority = priority,
                    Origin = origin,
                    Subject = subject,
                    Type = caseType,
                    Cost_Center__c= loc.Id,
                    AccountId = accountId
                )
            );
        }

        insertRecords(casList, insertRecords);

        return casList;
    }

    /**
     * @description Creates location records for unit tests.
     * @param count The number of records to create.
     * @param insertRecords Boolean value indicating whether or not to insert records.
     * @param recordType The developer name of the record type to use when creating the location records.
     * @param isInventoryLocation Boolean value indicating whether or not the location is an inventory location.
     * @return A list of resulting location records.
     */
    private static List<Schema.Location> createLocations(Integer count, Boolean insertRecords, String recordType, boolean isInventoryLocation) {
        List<Schema.Location> locations = new List<Schema.Location>();

        Id recordTypeId = Schema.SObjectType.Location.getRecordTypeInfosByName().get(recordType)?.getRecordTypeId();
        for(Integer i = 0; i < count; i++) {
            String randomString = generateRandomString(10);
            String name = randomString + String.valueOf(i);

            locations.add(
                new Schema.Location(
                    Name = name,
                    LocationType = SBR_3_0_Constants.LOCATION_TYPE_JOBLOCATION,
                    Street_Address__c = name,
                    City__c = randomString,
                    State__c = 'CA',
                    Zip_Code__c = randomString,
                    IsInventoryLocation = isInventoryLocation,
                    RecordTypeId = recordTypeId
                )
            );
        }

        insertRecords(locations, insertRecords);

        return locations;
    }

    /**
     * @description generates a random string
     * @param len Integer / length of string to generate
     * @return A random string with a lengtgh of len.
     */
    public static String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
           Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
           randStr += chars.substring(idx, idx+1);
        }
        return randStr;
    }

    private static Map<String,String> getCompanyAndCurrencies() {
        Map<String,String> ccToCurrency = new Map<String,String>();
        for (Company_Currency__mdt companyInfo :
            [SELECT
                Id,
                CurrencyIsoCode__c,
                Company_Code__c
             FROM
                Company_Currency__mdt
             WITH
                USER_MODE]) {
            ccToCurrency.put(companyInfo.Company_Code__c,companyInfo.CurrencyIsoCode__c);
        }
        return ccToCurrency;
    }

    private static List<sObject> insertRecords(List<sObject> records, boolean insertRecords){
        if(insertRecords) {
            String objApiName;
            if(records.size() > 0) {
                objApiName = String.valueOf(records[0].getSObjectType());
            }
            if(objApiName != 'Campaign') {
                SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE, records);
                List<sObject> tempRecords = decision.getRecords();
                insert tempRecords; //NOPMD
                for(Integer i=0; i < tempRecords.size(); i++){
                    records.get(i).Id = tempRecords.get(i).Id;
                }
            }
            else {
                insert records; //NOPMD
            }
        }
        return records;
    }

    private static void insertRecords(sObject record, boolean insertRecords){
        insertRecords(new List<sObject>{ record }, insertRecords);
    }

    /**
     * @description Gets the first record type that is available to the user if rtDeveloperName is blank (null or empty string).
     * Otherwise, if rtDeveloperName is populated, then the Id matching the sobject and the developer name is returned.
     * @param dsr The result of an sobject describe call, used for fetching applicable record types.
     * @param rtDeveloperName The developername of the record type to fetch.  If blank, then the Id of
     * the first avaialble recordtype is returned.
     * @return Id of the record type found. If rtDeveloperName is populated, then the record type matching that developer
     * name is returned.  Otherwise, the Id of the first available record type is returned.
     */
    public static Id getAvailableRecordTypeId(Schema.DescribeSObjectResult dsr, String rtDeveloperName){
        for(Schema.RecordTypeInfo rtInfo : dsr.getRecordTypeInfos()){
            if((String.isBlank(rtDeveloperName) || rtInfo.getDeveloperName() == rtDeveloperName) && rtInfo.isAvailable()){
                return rtInfo.getRecordTypeId();
            }
        }
        return null;
    }

    /**
     * @description Create a quote with a sourcing branching
     * @param insertRecords Boolean value indicating whether or not to insert records
     * @param name Name of the quote.
     * @param recordTypeId Id of the quote record type.
     * @return The instanciated (and potentially created) quote record.
     */
    public static SBQQ__Quote__c createQuoteWithSourcingBranch(Boolean insertRecords,String name,Id recordTypeId){
        SBR_3_0_TestDataFactory.createLocations(1, true, 'Branch');
        Account oAccount = createAccounts(1, true, SBR_3_0_Constants.ACCOUNT_REC_TYPE_CREDIT)[0];
        createContacts(1, oAccount.Id, true);
        // Create Location
        Schema.Location jobLocation = new Schema.Location(
            Name = 'Test Job Location' + Integer.valueof((Math.random() * 100)),
            Street_Address__c = '12 Main Street',
            City__c = 'Toronto',
            Zip_Code__c = 'M7N7B3',
            State__c = 'ON',
            Country__c = 'CA',
            RecordTypeId = SBR_3_0_Constants.LOCATION_JOB_RT_ID,
            OMS_Sourcing_Enabled__c = true,
            Distance_Multiplier__c = 50,
            Analysis_Region_Key__c = '001',
            Company_Code__c = '01'
        );

        insert jobLocation; //NOPMD

        // Create Branch
        Schema.Location branchLocation = new Schema.Location(
            Branch_Location_Number__c = '1234',
            Name = 'Test Branch Location',
            Street_Address__c = '12 Main Street',
            City__c = 'Toronto',
            Zip_Code__c = 'M7N7B3',
            State__c = 'ON',
            Country__c = 'CA',
            Job_Number__c='332112',
            RecordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID,
            Company_Code__c = 'X',
            Time_Zone_Name__c = 'America/Chicago',
            Time_Zone__c = 3,
            OMS_Sourcing_Enabled__c = true
        );
        insert branchLocation; //NOPMD

        String randomString = generateRandomString(10);
        AssociatedLocation jobSite = new AssociatedLocation(
            Name__c = 'Test Job Site',
            ParentRecordId = oAccount.Id,
            LocationId = jobLocation.Id,
            Branch__c = branchLocation.Id,
            Job_Number__c = '20221004A',
            Job_Site_Id__c = randomString
        );

        if(!Schema.sObjectType.AssociatedLocation.isCreateable()){
            throw new SBR_3_0_CustomException('Insufficient access for creating AssociatedLocation!');
        }
        insert jobSite;

        Pricebook2 priceBook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );

        if(!Schema.sObjectType.Pricebook2.isUpdateable()){
            throw new SBR_3_0_CustomException('Insufficient access for updating Pricebook2!');
        }

        update priceBook;
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            Quote_Name__c = 'Test Quote',
            SBQQ__Account__c = oAccount.Id,
            Sourcing_Branch__c = branchLocation.Id,
            Jobsite__c = jobSite.Id,
            SBQQ__DeliveryMethod__c = 'Delivery',
            Delivery_Charges__c = 10,
            SBQQ__Status__c = 'Draft',
            SBQQ__PriceBook__c = priceBook.Id,
            Start_Date__c = date.valueOf('2022-12-12 12:00:00'),
            SBQQ__EndDate__c = date.valueOf('2023-10-09 8:00:00'),
            End_Date__c = date.valueOf('2023-10-09 8:00:00'),
            Delivery_Date__c = date.valueOf('2022-10-08 12:00:00'),
            Opt_Out_RPP__c = false,
            Quote_Initiating_Channel__c = 'SLSFRC',
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Duration__c = 'Custom',
            RecordTypeId = recordTypeId
        );

        if (insertRecords) {
            if(!Schema.sObjectType.SBQQ__Quote__c.isCreateable()){
                throw new SBR_3_0_CustomException('Insufficient access for creating SBQQ__Quote__c!');
            }

            insert quote;
        }
        return quote;
    }

    /**
     * @description Creates Analysis region for unit test(s).
     * @param insertRecords Boolean value indicating whether or not to perform DML transaction.
     * @param analysisRegionKey - The key to use when creating the Analysis Region record.
     * @param accountId - The Id of the account to associate the analysis region record.
     * @return The instanciated (and potentially created) analysis region record.
     */
    public static Analysis_Region__c createAnalysisRegion(Boolean insertRecords,String analysisRegionKey,Id accountId){
        Analysis_Region__c oAnalysisRegion = new Analysis_Region__c(
            Analysis_Region_Key__c = AnalysisRegionKey,
            Company_Code__c = '1234'
        );
        insertRecords(oAnalysisRegion, insertRecords);
        return oAnalysisRegion;
    }

    /**
     * @description createCustomerSpend description
     * @param  insertRecords  insertRecords boolean determines whether DML is performed
     * @param  analysisRegionId analysisRegionId description
     * @param  accountId accountId description
     * @return                  return description
     */
    public static Customer_Spend__c createCustomerSpend(Boolean insertRecords, Id analysisRegionId, Id accountId){
        Customer_Spend__c oCustomerSpend = new Customer_Spend__c(
            Analysis_Region__c = AnalysisRegionId,
            Account__c = AccountId
        );

        if (insertRecords) {

            if(!Schema.sObjectType.Customer_Spend__c.isCreateable()){
                throw new SBR_3_0_CustomException('Insufficient access for creating Customer_Spend__c!');
            }

            insert oCustomerSpend;
        }

        return oCustomerSpend;
    }

    /**
     * @description Create Comment records
     * @param count - Number of comments to create
     * @param insertRecords - Boolean value indicating whether or not to perform DML
     * @param accountId - Id of account to associate with comments
     * @return A list of comments generated
     */
    public static List<Comment__c> createComments(Integer count, Boolean insertRecords, Id accountId) {
        List<Comment__c> comments = new List<Comment__c>();

        for(Integer i = 0; i < count; i++) {
            comments.add(
                new Comment__c(
                    Account_Name__c = accountId,
                    Comment__c = 'Test Comment - '+String.valueOf(i),
                    Company_Code__c = '01',
                    Date__c = Date.today()
                )
            );
        }
        insertRecords(comments, insertRecords);
        return comments;
    }

    /**
     * @description : Generates Random Number with given length
     * @author soomjeet.sahoo | 04-25-2024
     * @param len
     * @return String
     **/
    public static String generateRandomNumber(Integer len) {
        final String chars = '0123456789';
        String randStr = '';
        while (randStr.length() < len) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()),chars.length());
            randStr += chars.substring(idx, idx + 1);
        }
        return randStr;
    }
}