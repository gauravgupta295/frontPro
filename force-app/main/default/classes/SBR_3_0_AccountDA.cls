/**
 * @description       :  Concrete class for Account Data Access
---------------------------------------------------------------------------------------------------------------------------------------
* @author            : Avinash Rao
* @last modified on  : 05-07-2024
* @last modified by  : Kunal Patel
**/

@SuppressWarnings('PMD.CognitiveComplexity, PMD.ExcessivePublicCount')
public with sharing class SBR_3_0_AccountDA implements SBR_3_0_AccountDAInterface {
   
    /**
    * @description This method takes a set of account IDs as input and returns a map of account IDs and their corresponding account names.
    * @param ids - Set of account IDs
    * @return Map of account IDs and their corresponding account names
    */
    public static Map<Id, Account> getAccountsName(Set<Id> ids) {
        return new Map<Id, Account>([SELECT ID, Name, Company_Code__c, RM_Account_Number_Display__c FROM Account WHERE ID IN :ids]);
    }
    /*
        Method: getAccountWithLock
        Description: Queries the Account record with a FOR UPDATE clause to obtain a lock.
    */
    public static Account getAccountWithLock(Id accountId) {
        Account lockedAccount = new Account();
        
        // Check if accountId is not null
        if (accountId != null) {
            // Query for the Account record with FOR UPDATE clause to obtain a lock
            lockedAccount = [SELECT ID, Name, RM_Account_Number__c, RecordTypeId, ShippingCity, ShippingCountry, 
            ShippingPostalCode, ShippingState, ShippingStreet, ShippingLatitude, ShippingLongitude,
            BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, BillingLatitude, BillingLongitude, Override_Address__Street__s, Override_Address__City__s, Override_Address__StateCode__s, Override_Address__PostalCode__s,
            Override_Address__CountryCode__s, Override_Address__Latitude__s, Override_Address__Longitude__s
            FROM Account  WHERE Id = :accountId LIMIT 1 FOR UPDATE];
        } else {
            // Handle null case if necessary
        }
        
        return lockedAccount;
    }


    /**
     * @description - Retrieves a map of Account records based on a set of Account IDs.
     * @param ids A set of Account IDs.
     * @return  `Map<Id, Account>` - A map of Account records with the key as the Account ID and the value as the Account record.
     */
    public static Map<Id, Account> getAccounts(Set<Id> ids) {
        return new Map<Id, Account>(
            [
                SELECT ID, Name, RM_Account_Number__c, SF_Account_Number__c, RecordType.Name, Phone, Street_Address_LatLong__latitude__s, Street_Address_LatLong__longitude__s, TTM__c, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry, Status__c, Override_Address__Street__s, Override_Address__City__s, Override_Address__StateCode__s, Override_Address__PostalCode__s, Override_Address__CountryCode__s, Override_Address__Latitude__s, Override_Address__Longitude__s, BillingLatitude, BillingLongitude, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, Company_Code__c, ParentId, Managed_w_OSR_Fingerprint__c, Sales_Rep_commission__c, Sales_Activity_Status__c
                FROM Account
                WHERE ID IN :ids
            ]
        );
    }

    /**
     * @description - Retrieves a map of Account records based on a set of RM account numbers.
     * @param rmNumbers - A set of RM account numbers.
     * @return  `Map<Id, Account>` - A map of Account records with the key as the Account ID and the value as the Account record.
     */
    public static Map<Id, Account> getAccountsByRMNumbers(Set<String> rmNumbers) {
        return new Map<Id, Account>([SELECT ID, RM_Account_Number__c, Name FROM Account WHERE RM_Account_Number__c IN :rmNumbers]);
    }

    /**
     * @description - Retrieves a list of Account records based on a list of Account objects.
     * @param lAccounts - A list of Account objects.
     * @return  `list<Account>` - A list of Account records. 
     */
    public static list<Account> getAccountsFromLatLong(list<Account> lAccounts) {
        return new List<Account>(
            [
                SELECT Id, Street_Address_LatLong__Latitude__s, Street_Address_LatLong__Longitude__s, RecordtypeId, ParentId, RM_Account_Number_Display__c
                FROM Account
                WHERE Id IN :lAccounts AND (RecordtypeId = :SBR_3_0_Constants.ACCOUNT_PROSPECT_RT_ID OR RecordtypeId = :SBR_3_0_Constants.ACCOUNT_OFFICE_RT_ID)
            ]
        );
    }

    /**
     * @description - Retrieves a single Account record based on an Account ID.
     * @param id - An Account ID
     * @return  `Account` - An Account record. 
     */
    public static Account getAccount(Id id) {
        return [
            SELECT ID, Name, RM_Account_Number__c, Credit_Application_Link__c, SF_Account_Number__c,
            RecordType.Name, Phone, Street_Address_LatLong__latitude__s, Street_Address_LatLong__longitude__s, 
            TTM__c, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry, Status__c,
            Override_Address__Street__s, Override_Address__City__s, Override_Address__StateCode__s, Override_Address__PostalCode__s, Override_Address__CountryCode__s, 
            Override_Address__Latitude__s, Override_Address__Longitude__s, BillingLatitude, 
            BillingLongitude, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry
            FROM Account
            WHERE ID = :id
            WITH SECURITY_ENFORCED
        ];
    }

    /**
     * @description - Retrieves a single Account record based on an Account ID.
     * @param id - An Account ID.
     * @return  `Account` - An Account record. 
     */
    @AuraEnabled(cacheable=false)
    public static Account getContactAccount(Id id) {
        return [
            SELECT ID, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry,
            Override_Address__City__s, Override_Address__Street__s, Override_Address__StateCode__s, 
            Override_Address__PostalCode__s, Override_Address__CountryCode__s, BillingCity, BillingCountry, 
            BillingPostalCode, BillingState, BillingStreet, Phone
            FROM Account
            WHERE ID = :id
            WITH SECURITY_ENFORCED
        ];
    }

    /**
     * @description - Retrieves a single Account record based on an RM account number.
     * @param rmAccountNumber - An RM account number.
     * @return  `Account` - An Account record. 
     */
    public static Account getAccountByRmAccountNumber(String rmAccountNumber) {
        return [SELECT Id, RM_Account_Number__c, Company_Code__c, RecordType.DeveloperName FROM Account WHERE RM_Account_Number__c = :rmAccountNumber WITH SECURITY_ENFORCED LIMIT 1 ];
    }

    /**
     * @description - Retrieves a list of Account records that have a latitude and longitude value in their override address fields.
     * @return  `List<Account>` - A list of Account records.
     */
    public static List<Account> getAccounts() {
        List<Account> accts = new List<Account>();
        if(Schema.sObjectType.Account.fields.Id.isAccessible()){
            accts =  [
                SELECT Id, Name, RM_Account_Number__c, SF_Account_Number__c, RecordType.Name, Phone, Street_Address_LatLong__latitude__s, Street_Address_LatLong__longitude__s, TTM__c, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry, Status__c, Override_Address__Street__s, Override_Address__City__s, Override_Address__StateCode__s, Override_Address__PostalCode__s, Override_Address__CountryCode__s, Override_Address__Latitude__s, Override_Address__Longitude__s, BillingLatitude, BillingLongitude, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry
                    FROM Account
                    WHERE Override_Address__Latitude__s != NULL AND Override_Address__Longitude__s!= NULL
                    ORDER BY Name ASC
            ];
        }

        SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.READABLE, accts);
        List<Account> acctsFiltered = securityDecision.getRecords();
        return acctsFiltered;
    }

    /**
     * @description - Retrieves a list of Account records based on a record type name.
     * @param recordTypeName - A record type name.
     * @return  `List<Account>` - A list of Account records.
     */
    public static List<Account> getAccountsByRecordTypeName(String recordTypeName) {
        return [
            SELECT Id, Name, RM_Account_Number__c, SF_Account_Number__c, RecordType.Name, Phone, Street_Address_LatLong__latitude__s, Street_Address_LatLong__longitude__s, TTM__c, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry, Status__c, Override_Address__Street__s, Override_Address__City__s, Override_Address__StateCode__s, Override_Address__PostalCode__s, Override_Address__CountryCode__s, Override_Address__Latitude__s, Override_Address__Longitude__s, BillingLatitude, BillingLongitude, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry
            FROM Account
            WHERE RecordType.Name = :recordTypeName
            WITH SECURITY_ENFORCED
        ];
    }

    /**
     * @description - Retrieves a list of AccountWrapper objects based on a user ID.
     * @param userId - A user ID.
     * @return  `List<AccountWrapper>` - A list of AccountWrapper objects. 
     */
    public static List<AccountWrapper> getTopAccounts(Id userId) {
        Map<Id, Account_Relationship__c> ars = new Map<Id, Account_Relationship__c>(
            [
                SELECT Id, Account_ID__c, User_Account__c, Rank__c
                FROM Account_Relationship__c
                WHERE User_Account__c = :userId AND Rank__c != NULL AND Rank__c <= 50
                ORDER BY Rank__c ASC
            ]
        );

        Set<Id> accIds = new Set<Id>();
        for (Account_Relationship__c ar : ars.values()) {
            accIds.add(ar.Account_ID__c);
        }

        return getAccountRanks(accIds, userId);
    }

    /**
     * @description Retrieves account relationships for a set of account IDs and a user ID.
     * @param accIds - Set<Id> - A set of account IDs to retrieve account relationships for.
     * @param userId - Id - The user ID to retrieve account relationships for.
     * @return List<AccountWrapper> - A list of AccountWrapper objects containing account and account relationship information.
     */
    public static List<AccountWrapper> getAccountRanks(Set<Id> accIds, Id userId) {
        Map<Id, Account_Relationship__c> ars = new Map<Id, Account_Relationship__c>(
            [
                SELECT Id, Account_ID__c, User_Account__c, Rank__c
                FROM Account_Relationship__c
                WHERE User_Account__c = :userId AND Account_ID__c IN :accIds
                ORDER BY Rank__c ASC
            ]
        );

        Map<Id, Account> accs = new Map<Id, Account>(
            [
                SELECT Id, Name, RM_Account_Number__c, SF_Account_Number__c, RecordType.Name, Phone, Street_Address_LatLong__latitude__s, Street_Address_LatLong__longitude__s, TTM__c, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry, Sales_Activity_Status__c, Status__c, Override_Address__Street__s, Override_Address__City__s, Override_Address__StateCode__s, Override_Address__PostalCode__s, Override_Address__CountryCode__s, Override_Address__Latitude__s, Override_Address__Longitude__s, BillingLatitude, BillingLongitude, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry
                FROM Account
                WHERE ID IN :accIds
            ]
        );

        List<AccountWrapper> result = new List<AccountWrapper>();

        for (Account_Relationship__c ar : ars.values()) {
            Account a = accs.get(ar.Account_ID__c);
            if (a != null) {
                result.add(new AccountWrapper(a, ar));
            }
        }
        return result;
    }
    
    /**
     * @description Retrieves Account_Relationship__c records related to the given account IDs and user IDs.
     * @param accIds - Set<Id> - A set of account IDs to retrieve account relationships for.
     * @param userIds - Set<Id> - A set of user IDs to retrieve account relationships for.
     * @return Map<Id, Account_Relationship__c> - A map of account IDs to account relationship objects.
     */
    public static Map<Id, Account_Relationship__c> getAccountRelationShipAccountId(Set<Id> accIds, Set<Id> userIds) {
        Map<Id, Account_Relationship__c> accountRelationshipMap = new Map<Id, Account_Relationship__c>();
        List<Account_Relationship__c> relationshipRecords = [
            SELECT Id, Account_ID__c, User_Account__c, Rank__c
            FROM Account_Relationship__c
            WHERE User_Account__c IN :userIds AND Account_ID__c IN :accIds
            WITH SECURITY_ENFORCED
            ORDER BY Rank__c ASC
            
        ];

        for (Account_Relationship__c relationshipRecord : relationshipRecords) {
            if (!accountRelationshipMap.containsKey(relationshipRecord.Account_ID__c)) {
                accountRelationshipMap.put(relationshipRecord.Account_ID__c, relationshipRecord);
            }
        }
        return accountRelationshipMap;
    }

    /**
     * @description Retrieves Accountrelated to the given set of account IDs.
     * @param ids - Set<Id> - A set of account IDs to retrieve account.
     * @return Map<Id, Account> - A map of account IDs to account objects.
     */
    public static Map<Id, Account> getAccountReadinessFields(Set<Id> ids) {
        return new Map<Id, Account>(
            [
                SELECT ID, Plant_Ready_Required__c, Event_Ready_Required__c, Airport_Personnel_Badge_Required__c, Airport_Vehicle_Badge_Required__c, All_gauges_and_controls_must_work_proper__c, All_lights_and_alarms_must_work_properly__c, Annual_Inspection_must_be_up_to_date__c, Anti_Entrapment__c, Beacon_Light_Required__c, Carb_Registration_Required__c, Containment_Berms__c, Copy_of_Owner_Manual_and_AEM_Required__c, COVID_Negative_Result_Required__c, COVID_Vaccination_Required__c, Dashboards_must_be_wiped_clean__c, Decals_Stencils_Must_Be_Legible__c, Equipment_must_be_extremely_clean__c, Facial_Hair_Restrictions__c, Fire_Extinguisher_Required__c, Generators_must_be_hand_wiped__c, Glass_must_be_intact_and_wiped_clean__c, Hard_Hats_Required__c, Headlights_Required__c, Motion_Beacons__c, No_Photography__c, No_visible_damage_to_the_machine__c, No_visible_signs_of_leaks__c, Non_Marking_Tires__c, OSHA_10_Required__c, OSHA_30_Required__c, Paint_must_be_close_to_perfect__c, Prevailing_Wage__c, Proximity_Alarms__c, Safety_Cones__c, Safety_Flags__c, Safety_Glasses_Required__c, Site_Specific_Crane_Inspection_Required__c, Site_Specific_Training_Required__c, Special_Back_up_Alarm_Required__c, Special_Decals_Required__c, Special_Tire_Tread_Requirements__c, Spill_Kits__c, State_of_MA_Code_Compliance_for_Heaters__c, Tier_4_Engine_Required__c, Tire_Covers__c, Tire_Shine_Required__c, Tires_must_be_in_good_condition__c, TWIC_Card_Required__c, Union_Personnel_Required__c, Water_Barriers_Required__c, Wheel_Chalks__c, Personnel_Must_Be_US_Citizen__c, Drip_Diapers__c, Company_Code__c
                FROM Account
                WHERE ID IN :ids
            ]
        );
    }

    /**
     * @description returns list of account's longitude and latitudes
     * @param ids 
     * @return  `List<Account>`
     */
    public static List<Account> getAccountsLatLongStatus(Set<Id> ids) {
        return [SELECT ID, Street_Address_LatLong_Status__c, Override_Address_LatLong_Status__c FROM Account WHERE ID IN :ids WITH SECURITY_ENFORCED];
    }

    /**
    * @description Fetch Accounts by filter wrapper
    * @param wrapper
    * @return List<Account>
    **/
    public static List<AccountWrapper> getAccountsFiltered(SBR_3_0_GoogleMapCmpController.FilterWrapper wrapper) { // NOPMD


        Set<Id> ownerIds = new Set<Id>();

        String users = wrapper.userTerritories;
        if (String.isNotBlank(users)) {
            users = users.deleteWhitespace();
            for (String s : users.split(',')) {
                ownerIds.add(s);
            }
        }
        String userCompanyCode = SBR_3_0_UserDA.getUserById(UserInfo.getUserId()).CompanyName;


        String sQuery = 'SELECT Id, Account_ID__c, User_Account__c, Rank__c FROM Account_Relationship__c WHERE ';

        if (String.isNotBlank(wrapper.accountSearch) && wrapper.searchAccounts == false) {
            sQuery += '(Account_ID__r.Name LIKE \'%' + String.escapeSingleQuotes(wrapper.accountSearch) + '%\'' + ' OR Account_ID__r.AccountNumber LIKE \'%' + String.escapeSingleQuotes(wrapper.accountSearch) + '%\'' + ' OR Account_ID__r.RM_Account_Number__c LIKE \'%' + String.escapeSingleQuotes(wrapper.accountSearch) + '%\'' + ' OR Account_ID__r.SF_Account_Number__c LIKE \'%' + String.escapeSingleQuotes(wrapper.accountSearch) + '%\'' + ' OR Account_ID__r.ShippingCity LIKE \'%' + String.escapeSingleQuotes(wrapper.accountSearch) + '%\'' + ' OR Account_ID__r.Override_Address__City__s LIKE \'%' + String.escapeSingleQuotes(wrapper.accountSearch) + '%\') AND ';
        }
        else if(String.isNotBlank(wrapper.accountSearch) && wrapper.searchAccounts == true) {
            String searchText = '%' + String.escapeSingleQuotes(wrapper.accountSearch) + '%';
            List<List<sObject>> searchListName = [FIND: searchText IN ALL Fields
                RETURNING Account(Id, RM_Account_Number__c, Name, ShippingCity, Override_Address__City__s 
                                WHERE (Name LIKE: searchText) AND Company_Code__c =: userCompanyCode) ];

            List<Account> accList = (List<Account>) searchListName[0];

            List<List<sObject>> searchListRMNum = [FIND: searchText IN ALL Fields
                RETURNING Account(Id, RM_Account_Number__c, Name, ShippingCity, Override_Address__City__s 
                                WHERE (RM_Account_Number__c LIKE: searchText) AND Company_Code__c =: userCompanyCode) ];

            List<Account> accListRMNum = (List<Account>) searchListRMNum[0];

            List<List<sObject>> searchListAccNum = [FIND: searchText IN ALL Fields
                RETURNING Account(Id, RM_Account_Number__c, Name, ShippingCity, Override_Address__City__s 
                                WHERE (AccountNumber LIKE: searchText) AND Company_Code__c =: userCompanyCode) ];

            List<Account> accListAccNum = (List<Account>) searchListAccNum[0];

            List<List<sObject>> searchListSFNum = [FIND: searchText IN ALL Fields
                RETURNING Account(Id, RM_Account_Number__c, Name, ShippingCity, Override_Address__City__s 
                                WHERE (SF_Account_Number__c LIKE: searchText) AND Company_Code__c =: userCompanyCode) ];

            List<Account> accListSFNum = (List<Account>) searchListSFNum[0];

            List<List<sObject>> searchListShipCity = [FIND: searchText IN ALL Fields
                RETURNING Account(Id, RM_Account_Number__c, Name, ShippingCity, Override_Address__City__s 
                                WHERE (ShippingCity LIKE: searchText) AND Company_Code__c =: userCompanyCode) ];

            List<Account> accListShipCity = (List<Account>) searchListShipCity[0];

            List<List<sObject>> searchListOverCity = [FIND: searchText IN ALL Fields
                RETURNING Account(Id, RM_Account_Number__c, Name, ShippingCity, Override_Address__City__s 
                                WHERE (Override_Address__City__s LIKE: searchText) AND Company_Code__c =: userCompanyCode) ];

            List<Account> accListOverCity = (List<Account>) searchListOverCity[0];

            Set<Id> accIds = new Set<Id>();
            for(Account acc: accList) {
                accIds.add(acc.Id);
            }
            for(Account acc: accListRMNum) {
                accIds.add(acc.Id);
            }
            for(Account acc: accListAccNum) {
                accIds.add(acc.Id);
            }
            for(Account acc: accListSFNum) {
                accIds.add(acc.Id);
            }
            for(Account acc: accListShipCity) {
                accIds.add(acc.Id);
            }
            for(Account acc: accListOverCity) {
                accIds.add(acc.Id);
            }

            sQuery += 'Account_ID__c IN ' + SBR_3_0_AccountDA.inClausify(accIds) + ' AND ';
        }

        sQuery += '(';

        if (wrapper.top25Accounts == true) {
            sQuery += 'Rank__c <= 25 OR ';
        }

        if (wrapper.top50Accounts == true) {
            sQuery += 'Rank__c <= 50 OR ';
        }

        if (wrapper.topXAccounts == true && String.isNotBlank(wrapper.topXAccountsValue)) {
            sQuery += 'Rank__c <= ' + String.escapeSingleQuotes(wrapper.topXAccountsValue) + ' OR ';
        }

        if (wrapper.rankRangeAccounts == true && String.isNotBlank(wrapper.rankRangeAccountsStart) && String.isNotBlank(wrapper.rankRangeAccountsEnd)) {
            sQuery += '(Rank__c >= ' + String.escapeSingleQuotes(wrapper.rankRangeAccountsStart) + ' AND Rank__c <= ' + String.escapeSingleQuotes(wrapper.rankRangeAccountsEnd) + ') OR ';
        }

        sQuery += ') AND ';


        sQuery = sQuery.replaceAll('\\(\\) AND ', '');
        sQuery = sQuery.replaceAll('OR \\)', ')');

        sQuery += '(';

        if (wrapper.watchlistAccounts == true) {
            sQuery += 'Account_ID__r.Sales_Activity_Status__c = \'Watchlist\' OR ';
        }

        if (wrapper.dormantAccounts == true) {
            sQuery += 'Account_ID__r.Sales_Activity_Status__c = \'Dormant\' OR ';
        }

        sQuery += ') AND ';

        sQuery = sQuery.replaceAll('\\(\\) AND ', '');
        sQuery = sQuery.replaceAll('OR \\)', ')');

        if(String.isNotBlank(wrapper.accountRecordType)) {
            List<String> accRecList = (List<String>) JSON.deserialize(wrapper.accountRecordType, List<String>.class);
            Set<String> accountRecSet = new Set<String>(accRecList);
            if(!accountRecSet.isEmpty() && !accountRecSet.contains('All')) {
                sQuery += 'Account_ID__r.RecordType.DeveloperName IN ' + inClausify(accountRecSet) + ' AND ';
            }
        }

        sQuery = sQuery += 'Account_ID__r.Company_Code__c = \'' + userCompanyCode + '\' AND ';

        if (wrapper.assignedAccountsOnly == true) {
            sQuery += 'Type__c = \'Assigned\' AND ';
        }

        if(wrapper.searchAccounts == false) {
            sQuery += 'User_Account__c IN ' + inClausify(ownerIds) + ' AND ';
        }
        
        if(wrapper.includeTracked == false) {
            sQuery += 'RecordTypeId != \'' + SBR_3_0_Constants.ACCOUNT_RELATIONSHIP_TRACKING_RT_ID + '\' AND ';
        }
        else {
            sQuery = sQuery.removeEndIgnoreCase(' AND ');
            sQuery = sQuery.replace('WHERE ', 'WHERE (');
            sQuery += ') OR (RecordTypeId = \'' + SBR_3_0_Constants.ACCOUNT_RELATIONSHIP_TRACKING_RT_ID + '\' AND User_Account__c IN ' + inClausify(ownerIds) + ') AND ';
            sQuery = sQuery.replace('(User_Account__c IN ' + inClausify(ownerIds) + ') OR ', ''); // handles case where User only selected Tracking filter
        }

        sQuery = sQuery.removeEndIgnoreCase(' AND ');

        sQuery += ' ORDER BY Rank__c ASC';

        // PMD below applied to sQuery to troubleshoot 
        System.debug('sQuery -> ' + sQuery); // NOPMD

        // PMD below applied to sQuery as it is concatenated
        List<Account_Relationship__c> relationships = Database.query(sQuery); // NOPMD

        Set<Id> accIds = new Set<Id>();

        for (Account_Relationship__c ar : relationships) {
            accIds.add(ar.Account_ID__c);
        }

        Map<Id, Account> accs = new Map<Id, Account>(
            [
                SELECT Id, ParentId, Parent.Name, Name, RM_Account_Number__c, RM_Account_Number_Display__c, SF_Account_Number__c, RecordType.Name, Phone, Street_Address_LatLong__latitude__s, Street_Address_LatLong__longitude__s, TTM__c, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry, Sales_Activity_Status__c, Status__c, Override_Address__Street__s, Override_Address__City__s, Override_Address__StateCode__s, Override_Address__PostalCode__s, Override_Address__CountryCode__s, Override_Address__Latitude__s, Override_Address__Longitude__s, BillingLatitude, BillingLongitude, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, Managed_w_OSR_Fingerprint__c, Sales_Rep_commission__c
                FROM Account
                WHERE ID IN :accIds
            ]
        );

        // if show offices, query for office accounts
        Map<Id, List<Account>> parentIdToOfficeAccounts = new Map<Id, List<Account>>();
        Map<Id, Account> officeAccounts = new Map<Id, Account>();
        if (wrapper.showOffices) {
            officeAccounts = new Map<Id, Account>(
                [
                    SELECT Id, ParentId, Parent.Name, Name, RM_Account_Number__c, RM_Account_Number_Display__c, SF_Account_Number__c, RecordType.Name, Phone, Street_Address_LatLong__latitude__s, Street_Address_LatLong__longitude__s, TTM__c, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry, Sales_Activity_Status__c, Status__c, Override_Address__Street__s, Override_Address__City__s, Override_Address__StateCode__s, Override_Address__PostalCode__s, Override_Address__CountryCode__s, Override_Address__Latitude__s, Override_Address__Longitude__s, BillingLatitude, BillingLongitude, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, Managed_w_OSR_Fingerprint__c, Sales_Rep_commission__c
                    FROM Account
                    WHERE ParentId IN :accIds AND RecordTypeId = :SBR_3_0_Constants.ACCOUNT_OFFICE_RT_ID
                ]
            );

            // build map of parent acc id to office account list
            for (Account acc : officeAccounts.values()) {
                if (parentIdToOfficeAccounts.get(acc.ParentId) == null) {
                    parentIdToOfficeAccounts.put(acc.ParentId, new List<Account>());
                }
                List<Account> accList = parentIdToOfficeAccounts.get(acc.ParentId);
                accList.add(acc);
                parentIdToOfficeAccounts.put(acc.ParentId, accList);
            }
        }

        List<AccountWrapper> result = new List<AccountWrapper>();

        for (Account_Relationship__c ar : relationships) {
            Account a = accs.get(ar.Account_ID__c);
            if (a != null) {
                result.add(new AccountWrapper(a, ar));
                // fetch office accounts from parent id and add wrappers to list
                if (parentIdToOfficeAccounts.get(a.Id) != null) {
                    for (Account acc : parentIdToOfficeAccounts.get(a.Id)) {
                        result.add(new AccountWrapper(acc, ar));
                    }
                }
            }
        }


        return result;
    }

    /**
     * @description 
     * @param accountId returns the account's RM Number
     * @param useHierarchy 
     * @return  `String`
     */
    public static String getAccountRMNumber(Id accountId, Boolean useHierarchy) {
        Account acc = [
            SELECT Id, RM_Account_Number__c, Parent.RM_Account_Number__c, Parent.Parent.RM_Account_Number__c, Parent.Parent.Parent.RM_Account_Number__c, Parent.Parent.Parent.Parent.RM_Account_Number__c, Parent.Parent.Parent.Parent.Parent.RM_Account_Number__c
            FROM Account
            WHERE ID = :accountId
            WITH SECURITY_ENFORCED
        ];

        if (useHierarchy == false) {
            return acc.RM_Account_Number__c;
        }
        if (acc.RM_Account_Number__c != null) {
            return acc.RM_Account_Number__c;
        }
        if (acc.Parent.RM_Account_Number__c != null) {
            return acc.Parent.RM_Account_Number__c;
        }
        if (acc.Parent.Parent.RM_Account_Number__c != null) {
            return acc.Parent.Parent.RM_Account_Number__c;
        }
        if (acc.Parent.Parent.Parent.RM_Account_Number__c != null) {
            return acc.Parent.Parent.Parent.RM_Account_Number__c;
        }
        if (acc.Parent.Parent.Parent.Parent.RM_Account_Number__c != null) {
            return acc.Parent.Parent.Parent.Parent.RM_Account_Number__c;
        }
        if (acc.Parent.Parent.Parent.Parent.Parent.RM_Account_Number__c != null) {
            return acc.Parent.Parent.Parent.Parent.Parent.RM_Account_Number__c;
        }
        return null;
    }

    /**
     * @description 
     * @param accountId - returns accounts with RM number and Type
     * @param useHierarchy 
     * @return  `Account`
     */
    public static Account getAccountRMNumberAndType(Id accountId, Boolean useHierarchy) {
        Account acc = [
            SELECT Id, RM_Account_Number__c, Record_Type_Text__c, Parent.RM_Account_Number__c, Parent.Record_Type_Text__c, Parent.Parent.RM_Account_Number__c, Parent.Parent.Record_Type_Text__c, Parent.Parent.Parent.RM_Account_Number__c, Parent.Parent.Parent.Record_Type_Text__c, Parent.Parent.Parent.Parent.RM_Account_Number__c, Parent.Parent.Parent.Parent.Record_Type_Text__c, Parent.Parent.Parent.Parent.Parent.RM_Account_Number__c, Parent.Parent.Parent.Parent.Parent.Record_Type_Text__c
            FROM Account
            WHERE ID = :accountId
            WITH SECURITY_ENFORCED
        ];
        if (useHierarchy == false) {
            return acc;
        }
        if (acc.RM_Account_Number__c != null) {
            return acc;
        }
        if (acc.Parent.RM_Account_Number__c != null) {
            return acc.Parent;
        }
        if (acc.Parent.Parent.RM_Account_Number__c != null) {
            return acc.Parent.Parent;
        }
        if (acc.Parent.Parent.Parent.RM_Account_Number__c != null) {
            return acc.Parent.Parent.Parent;
        }
        if (acc.Parent.Parent.Parent.Parent.RM_Account_Number__c != null) {
            return acc.Parent.Parent.Parent.Parent;
        }
        if (acc.Parent.Parent.Parent.Parent.Parent.RM_Account_Number__c != null) {
            return acc.Parent.Parent.Parent.Parent.Parent;
        }
        return null;
    }

    /**
     * @description - return count of account relationships
     * @param userIds 
     * @return  `List<AggregateResult>`
     */
    public static List<AggregateResult> getAccountRelationshipsForUsers(Set<String> userIds) {
        List<AggregateResult> result = [
            SELECT count(ID), User_Account__c, Territory__r.Territory_Id__c tid
            FROM Account_Relationship__c
            WHERE User_Account__c IN :userIds
            WITH SECURITY_ENFORCED
            GROUP BY Territory__r.Territory_Id__c, User_Account__c
        ];

        return result;
    }

    /**
    * @description This method returns the lowest rank of the account relationships for the given user IDs.
    * @param filterWrapper - the filter wrapper object containing user territories
    * @return Decimal - the lowest rank of the account relationships
    */
    @AuraEnabled(cacheable=true)
    public static Decimal getAccountRelationshipsForUsersLowestRank(SBR_3_0_GoogleMapCmpController.FilterWrapper filterWrapper) {
        Decimal result = 1;

        String userIds;
        if (filterWrapper != null) {
            userIds = filterWrapper.userTerritories;
        }

        if (String.isBlank(userIds)) {
            userIds = UserInfo.getUserId();
        }

        userIds = userIds.deleteWhitespace();
        List<String> userIdList = userIds.split(',');

        List<Account_Relationship__c> relationships = [SELECT ID, Rank__c FROM Account_Relationship__c WHERE User_Account__c IN :userIdList AND Rank__c != NULL WITH SECURITY_ENFORCED ORDER BY Rank__c DESC  LIMIT 1];

        if (relationships.size() > 0) {
            result = relationships[0].Rank__c;
        }

        return result;
    }
    
    /**
     * @description This method takes a Set of Ids and returns a formatted string with an IN clause for SOQL queries.
     * @param ids - a Set of Ids to be included in the IN clause
     * @return - a formatted string with the IN clause
     */
    public static String inClausify(Set<Id> ids) {
        String inClause = String.format('(\'\'{0}\'\')', new List<String>{ String.join(new List<Id>(ids), '\',\'') });
        return inClause;
    }

   /**
    * @description Convert Set of Strings into String for SOQL
    * @param stringSet
    * @return String
    **/
    public static String inClausify(Set<String> stringSet) {
        String inClause = String.format( '(\'\'{0}\'\')', 
                             new List<String> { String.join( new List<String>(stringSet) , '\',\'') });
        return inClause;
    }

    /**
     * @description This class is a wrapper for the Account and Account_Relationship__c objects.
     * It contains public properties for both objects.
     * Constructor for the AccountWrapper class.
     */
    public class AccountWrapper { // NOPMD
        public Account account { get; set; } // NOPMD
        // NOPMD added as property is readable
        public Account_Relationship__c account_relationship { get; set; } // NOPMD

        /**
        * @description Set Default values for inner AccountWrapper object using Account and Account Relationship
        * @param a - Account object to be wrapped
        * @param ar - Account_Relationship__c object to be wrapped
        **/
        AccountWrapper(Account a, Account_Relationship__c ar) {
            this.account = a;
            this.account_relationship = ar;
        }
    }

    /**
    * @description Fetch Accounts with JobSites from Account Ids
    * @param accIds
    * @return String
    **/
    public static List<Account> getAccountDefaultLocationAndJobsite(Set<Id> accIds) {
        return [SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry,BillingLatitude, BillingLongitude, (SELECT Id, JobsiteName__c, Job_Number__c, Latitude_Longitude__c, Street_Address__c, City__c, State__c, Country__c, Zip_Code__c, ParentRecordId, LocationId 
        FROM AssociatedLocations ORDER BY CreatedDate ASC LIMIT 1) FROM Account WHERE Id IN :accIds WITH SECURITY_ENFORCED];
    }
    
    //FRONT-4951
    /**
     * @description This method retrieves account information for a given account ID.
     * @param accId - the ID of the account to retrieve
     * @return Account object containing account information
     */
    public static Account getAccountsForRM(String accId){
        List<Account> acc = [SELECT Id,Name,Company_Code__c,E_mail_Address__c,RM_Cash_State__c,Driver_s_License_State__c,
                       RM_Cash_Number__c,Branch_Location_Number__c,Status__c,Non_Credit_Integration_Status__c, 
                       Description_Comment_2__c,Comments__c,Date_of_Birth__c,BirthDate__c,Sales_Rep_Id__c,Drivers_License__c,BillingStreet,
                       SF_Account_Number__c,BillingCity,BillingStateCode,BillingPostalCode,DL_Expiration_Date__c,
                       BillingCountryCode,phone,LastModifiedDate,Charge_for_RPP__c,OwnerId FROM Account WHERE Id =: accId LIMIT 1];
        
        SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.READABLE, acc);
        Account accnt = (Account)securityDecision.getRecords()[0];
        return accnt;
    }
}