public with sharing class SBR_3_0_ManageWebsiteUserController {
	@AuraEnabled(cacheable=true)
    public static Map<Integer,list<String>> getManageWebsiteUsersColumns(String Category){
        try{
            Map<Integer,list<String>> mManageWebsireUsersColumns =  new Map<Integer,list<String>>();
            Map<String, SBR_3_0_Manage_Website_Users_Columns__mdt> mManageWebsireUsers = SBR_3_0_Manage_Website_Users_Columns__mdt.getAll();
            System.debug('mManageWebsireUsers'+mManageWebsireUsers);
            for(String LabelString : mManageWebsireUsers.keySet()){
                list<String> lValue = new list<String>();
                SBR_3_0_Manage_Website_Users_Columns__mdt oManageWebsireUsers = mManageWebsireUsers.get(LabelString);
                if(oManageWebsireUsers.MWU_Columns_Category__c == Category){
                    lValue.add(oManageWebsireUsers.Label__c);
                    lValue.add(oManageWebsireUsers.API_Name__c);
                    lValue.add(oManageWebsireUsers.Data_Type__c);
                    mManageWebsireUsersColumns.put(Integer.valueOf(oManageWebsireUsers.Field_Order__c),lValue);
                }
            }
            System.debug('mManageWebsireUsersColumns'+mManageWebsireUsersColumns);
            return mManageWebsireUsersColumns;
        }
        Catch(Exception e){
            throw new AuraHandledException(System.label.SBR_3_0_Manage_Website_User_Columns_Error);
        }
    }
    @AuraEnabled
    public static SBR_3_0_ManageWebsiteUserController.AccountResults getManageWebsiteUsersRecords(String recordId,String randomNumber){
        System.debug('recordId'+recordId);
        try{
            Account oAccount = 	[	
                                    SELECT
                                    Id,
                                    Company_Code__c,
                                    RM_Account_Number_Display__c 
                                    FROM
                                    Account
                                    WHERE
                                    Id =: recordId
                                ];
            if(String.isNotEmpty(oAccount.RM_Account_Number_Display__c) && String.isNotEmpty(oAccount.Company_Code__c)){
                SBR_3_0_ManageWebsiteUserWrapper response = SBR_3_0_ManageWebsiteUserIntegration.UserSearch(oAccount.Company_Code__c,oAccount.RM_Account_Number_Display__c);
                System.debug('response'+response);
                SBR_3_0_ManageWebsiteUserWrapper.data oData = new SBR_3_0_ManageWebsiteUserWrapper.data();
                oData = response.data;
                System.debug('oData'+oData);
                System.debug('Account Number : '+oData.accountNumber);
                System.debug('Company Code : '+oData.companyCode);
                System.debug('Users List : '+oData.users);
                SBR_3_0_ManageWebsiteUserController.AccountResults oResult = new SBR_3_0_ManageWebsiteUserController.AccountResults();
                list<SBR_3_0_ManageWebsiteUserWrapper.Users> lUsers = oData.users;
                System.debug('lUsers'+lUsers);
                list<SBR_3_0_ManageWebsiteUserController.Users> lUserToSend = new list<SBR_3_0_ManageWebsiteUserController.Users>();
                for(SBR_3_0_ManageWebsiteUserWrapper.Users oUser : lUsers){
                        SBR_3_0_ManageWebsiteUserController.Users oUserToSend = new SBR_3_0_ManageWebsiteUserController.Users();
                        oUserToSend.name = oUser.firstName+' '+oUser.lastName;
                        oUserToSend.email = oUser.email;
                        oUserToSend.lastLoginDateTime = oUser.lastLoginDateTime;
                        lUserToSend.add(oUserToSend);
                }
                    
                System.debug('lUserToSend'+lUserToSend);
                oResult.AccountNumber = oData.accountNumber;
                oResult.CompanyCode = oData.companyCode;
                oResult.users = lUserToSend;
                return oResult;
            }
            else{
            	throw new AuraHandledException(System.label.SBR_3_0_Manage_Website_User_Account_Error);    
            }
        }
        Catch(Exception e){
            throw new AuraHandledException(System.label.SBR_3_0_Manage_Website_User_Results_Error);
        }
    } 
    @AuraEnabled
    public static Boolean CreateWebsiteUsersRecords(String recordId,String FirstName,String LastName,String Email,String AccountNumber,String CompanyCode,String UserType){
        System.debug('FirstName'+FirstName);
        System.debug('LastName'+LastName);
        System.debug('Email'+Email);
        System.debug('AccountNumber'+AccountNumber);
        System.debug('CompanyCode'+CompanyCode);
        System.debug('recordId'+recordId);
        System.debug('UserType'+UserType);
        Account oAccount = 	[	
                                SELECT
                                Id,
                                Name,
                                recordType.DeveloperName,
                                Company_Code__c,
                                RM_Account_Number_Display__c 
                                FROM
                                Account
                                WHERE
                                Id =: recordId
                             ];
       	SBR_3_0_ManageWebsiteUserWrapper response = SBR_3_0_ManageWebsiteUserIntegration.UserInvite(	FirstName,
                                                                                                        LastName,
                                                                                                        Email,
                                                                                                        oAccount.Company_Code__c,
                                                                                                        oAccount.RM_Account_Number_Display__c,
                                                                                                        oAccount.Name,
                                                                                                        UserType
                                                                                                    );
        System.debug('response'+response);
        if(response.error != NULL){
            if(response.error.errorKey == 'INVALID_QUERY'){
                return true;
            }     
            else{
                System.debug('response.error.errorKey : '+response.error.errorKey);
				throw new AuraHandledException(System.label.SBR_3_0_Manage_Website_User_User_Invite_Error+' '+Email);                
            }
        }
        else{
            return true;
        }
    }
    @AuraEnabled
    public static AccountSearchResults searchWebsiteUser(String SearchEmail){
        if(String.isNotEmpty(SearchEmail)){
        	System.debug('SearchEmail'+SearchEmail);
            list<String> lAccountNumbersFromResponse = new list<String>();
            Map<String,Account> mAccount = new Map<String,Account>();
            list<SBR_3_0_MWUAccountSearchWrapper.Accounts> lAccountsFromResponse = new list<SBR_3_0_MWUAccountSearchWrapper.Accounts>();
            SBR_3_0_MWUAccountSearchWrapper response = SBR_3_0_ManageWebsiteUserIntegration.AccountsSearch(SearchEmail);
            System.debug('response'+response);
            if(response.error != NULL){
                AccountSearchResults oAccountSearchResult = new AccountSearchResults();
                oAccountSearchResult.accountType = response.error.errorKey;
                return oAccountSearchResult;
            }
            else{
                lAccountsFromResponse = response.data.accounts;
                System.debug('lAccountsFromResponse'+lAccountsFromResponse);
                for(SBR_3_0_MWUAccountSearchWrapper.Accounts oAccountsFromResponse : lAccountsFromResponse){
                    lAccountNumbersFromResponse.add(oAccountsFromResponse.accountNumber);    
                }
                System.debug('lAccountNumbersFromResponse'+lAccountNumbersFromResponse);
                list<Account> lAccount = 	[	
                                        SELECT
                                        Id,
                                        Name,
                                        recordType.DeveloperName,
                                        Company_Code__c,
                                        Account_Type__c,
                                        BillingCity,
                                        BillingState,
                                        RM_Account_Number_Display__c 
                                        FROM
                                        Account
                                        WHERE
                                        RM_Account_Number_Display__c IN: lAccountNumbersFromResponse
                                    ];
                System.debug('lAccount'+lAccount);
                for(Account oAccount : lAccount){
                    mAccount.put(oAccount.RM_Account_Number_Display__c,oAccount);    
                }
                System.debug('mAccount'+mAccount);
                AccountSearchResults oAccountSearchResult = new AccountSearchResults();
                oAccountSearchResult.Name = response.Data.firstName +' '+ response.Data.lastName;
                oAccountSearchResult.Email = response.Data.email;
                oAccountSearchResult.Address =  response.Data.address.line1+' '+
                                                response.Data.address.line2+' '+
                                                response.Data.address.line3+' '+
                                                response.Data.address.city+' '+
                                                response.Data.address.state+' '+
                                                response.Data.address.postalCode;
                oAccountSearchResult.PhoneNumber = response.Data.address.phone;
                oAccountSearchResult.accountType = response.Data.accountType;
                oAccountSearchResult.driverlicenseNumber = response.Data.driverlicenseNumber;
                System.debug('Account Type: '+response.Data.accountType);
                list<SBR_3_0_ManageWebsiteUserController.CreditAccountSearchResults> lCreditAccountsToSend = new list<SBR_3_0_ManageWebsiteUserController.CreditAccountSearchResults>();
                list<SBR_3_0_ManageWebsiteUserController.CashAccountSearchResults> lCashAccountsToSend = new list<SBR_3_0_ManageWebsiteUserController.CashAccountSearchResults>();
                for(SBR_3_0_MWUAccountSearchWrapper.Accounts oAccountsFromResponse : lAccountsFromResponse){
                    Account oAccount = mAccount.get(oAccountsFromResponse.accountNumber);
                    if(mAccount.containsKey(oAccountsFromResponse.accountNumber)){
                        if(response.Data.accountType == 'credit'){
                            SBR_3_0_ManageWebsiteUserController.CreditAccountSearchResults oCreditAccountsToSend = new SBR_3_0_ManageWebsiteUserController.CreditAccountSearchResults();
                            oCreditAccountsToSend.Id = oAccount.id;
                            oCreditAccountsToSend.AccountName = oAccount.Name; 
                            oCreditAccountsToSend.AccountNumber = oAccount.RM_Account_Number_Display__c;
                            oCreditAccountsToSend.AccountType = 'Credit';
                            oCreditAccountsToSend.BillingCity = oAccount.BillingCity;
                            oCreditAccountsToSend.BillingState = oAccount.BillingState;
                            lCreditAccountsToSend.add(oCreditAccountsToSend);
                        }
                        else if(response.Data.accountType == 'cash'){
                            SBR_3_0_ManageWebsiteUserController.CashAccountSearchResults oCashAccountsToSend = new SBR_3_0_ManageWebsiteUserController.CashAccountSearchResults();
                            oCashAccountsToSend.Id = oAccount.id;
                            oCashAccountsToSend.AccountName = oAccount.Name; 
                            oCashAccountsToSend.BillingCity = oAccount.BillingCity;
                            oCashAccountsToSend.BillingState = oAccount.BillingState;
                            lCashAccountsToSend.add(oCashAccountsToSend);
                        }
                    }
                    else{
                        if(response.Data.accountType == 'credit'){
                            SBR_3_0_ManageWebsiteUserController.CreditAccountSearchResults oCreditAccountsToSend = new SBR_3_0_ManageWebsiteUserController.CreditAccountSearchResults();
                            oCreditAccountsToSend.AccountName = oAccountsFromResponse.accountName; 
                            oCreditAccountsToSend.AccountNumber = oAccountsFromResponse.accountNumber;
                            oCreditAccountsToSend.AccountType = 'Credit';
                            //oCreditAccountsToSend.BillingCity = oAccount.BillingCity;
                            //oCreditAccountsToSend.BillingState = oAccount.BillingState;
                            lCreditAccountsToSend.add(oCreditAccountsToSend);
                        }
                        else if(response.Data.accountType == 'cash'){
                            SBR_3_0_ManageWebsiteUserController.CashAccountSearchResults oCashAccountsToSend = new SBR_3_0_ManageWebsiteUserController.CashAccountSearchResults();
                            oCashAccountsToSend.AccountName = oAccountsFromResponse.accountName; 
                            //oCashAccountsToSend.BillingCity = oAccount.BillingCity;
                            //oCashAccountsToSend.BillingState = oAccount.BillingState;
                            lCashAccountsToSend.add(oCashAccountsToSend);
                        }
                    }
                }
                System.debug('lCreditAccountsToSend'+lCreditAccountsToSend);
                if(!lCreditAccountsToSend.isEmpty()){
                    oAccountSearchResult.CreditAccountSearchResults = lCreditAccountsToSend;    
                }
                System.debug('lCashAccountsToSend'+lCashAccountsToSend);
                if(!lCashAccountsToSend.isEmpty()){
                    oAccountSearchResult.CashAccountSearchResults = lCashAccountsToSend;    
                }
                return oAccountSearchResult;
        	}
       	}
        else{
        	throw new AuraHandledException(System.label.SBR_3_0_Manage_Website_User_Email_Empty_Error);
        }
    }
    @AuraEnabled
    public static list<SBR_3_0_MWUAccountEmailSearchWrapper.Users> searchUserEmail(String SearchString){
        if(String.isNotEmpty(SearchString)){
            list<SBR_3_0_MWUAccountEmailSearchWrapper.Users> lUserEmails = new list<SBR_3_0_MWUAccountEmailSearchWrapper.Users>();
            lUserEmails = SBR_3_0_ManageWebsiteUserIntegration.AccountsEmailSearch(SearchString);
            if(!lUserEmails.isEmpty()){
                return lUserEmails;
            }
            else{
                throw new AuraHandledException(System.label.SBR_3_0_Manage_Website_Empty_Search_Results);
            }
        }
        else{
            throw new AuraHandledException(System.label.SBR_3_0_Manage_Website_User_Global_Empty_String_Error);
        }
    }
    public class AccountResults {
        @AuraEnabled
		public String AccountNumber;
        @AuraEnabled
		public String CompanyCode;
        @AuraEnabled
		public Users[] users;
    }
    public class Users {
        @AuraEnabled
		public String name;
        @AuraEnabled
		public String email;
        @AuraEnabled
		public String lastLoginDateTime;
	}
    public class AccountSearchResults {
        @AuraEnabled
		public String Name;
        @AuraEnabled
		public String Email;
        @AuraEnabled
		public String Address;
        @AuraEnabled
		public String PhoneNumber;
        @AuraEnabled
		public String accountType;
        @AuraEnabled
		public String driverlicenseNumber; 
        @AuraEnabled
		public CreditAccountSearchResults[] CreditAccountSearchResults;
        @AuraEnabled
		public CashAccountSearchResults[] CashAccountSearchResults;
    }
    public class CreditAccountSearchResults {
        @AuraEnabled
		public String Id;
        @AuraEnabled
		public String AccountName;
        @AuraEnabled
		public String AccountNumber;
        @AuraEnabled
		public String AccountType;
        @AuraEnabled
		public String BillingCity;
        @AuraEnabled
		public String BillingState;
    }
    public class CashAccountSearchResults {
        @AuraEnabled
		public String Id;
        @AuraEnabled
		public String AccountName;
        @AuraEnabled
		public String BillingCity;
        @AuraEnabled
		public String BillingState;
	}
    public class UsersWithEmail {
        @AuraEnabled
		public String email;
    }
}