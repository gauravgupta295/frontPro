@isTest
Private class SBR_3_0_ReadAccountManagementCSV_Test {

    @isTest
    static void convertTest()
    {
        String str = 'RM_Account_Number__c,BillingStreet,Company_Code__c,Phone,Charge_Tax__c,Application_Number__c,BirthDate__c,AnnualRevenue\n' +
        '12345,123 Main Street,01,1234567890,true,23432,1990-04-09,23000';
        Account relatedAccount = new Account();
        relatedAccount.RM_Account_Number__c = '12345';
        relatedAccount.Name = SBR_3_0_API_Web_Jobsite_DA.JOBSITEACCOUNTNAME;
        relatedAccount.BillingStreet = '123 Main Street';
        relatedAccount.BillingCity = 'Toronto';
        relatedAccount.BillingPostalCode = 'M9N7V5';
        relatedAccount.BillingState = 'ON';
        relatedAccount.BillingCountry = 'CA';
        relatedAccount.Company_Code__c = '01';
        relatedAccount.Phone  = '1234567890';
        insert relatedAccount;

        	ContentVersion contentVersion = new ContentVersion(
                    Title          = 'a picture',
                    PathOnClient   = 'Pic.csv',
                    VersionData    = Blob.valueOf(str),
                    IsMajorVersion = true);
            insert contentVersion;

            List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
			//create ContentDocumentLink  record
            ContentDocumentLink cdl = new ContentDocumentLink(); 
            cdl.LinkedEntityId = relatedAccount.Id;
            cdl.ContentDocumentId = documents[0].Id;
            cdl.ShareType = 'V';
            cdl.Visibility = 'AllUsers'; 
            insert cdl;
            SBR_3_0_ReadAccountManagementCSV.Request[] requestList = new SBR_3_0_ReadAccountManagementCSV.Request[]{};
                SBR_3_0_ReadAccountManagementCSV.Request request = new SBR_3_0_ReadAccountManagementCSV.Request();
        
            request.contentDocumentId = documents[0].Id;
        	requestList.add(request);
        	SBR_3_0_ReadAccountManagementCSV.convert(requestList);
        
        	//List<SBR_3_0_Invocable_ARAuthority.ARRequest> lst = new List<SBR_3_0_Invocable_ARAuthority.ARRequest>();
        	//lst.add(new SBR_3_0_Invocable_ARAuthority.ARRequest());
        	//SBR_3_0_Invocable_ARAuthority.authenticateUserHierarchy(lst);
        
    }
    
    @isTest
    static void convertTestFail()
    {
        String str = 'RM_Account_Number__c,BillingStreet,Company_Code__c,Phone\n' +
        '12345,MainStreet,01,1234567890';
        Account relatedAccount = new Account();
        relatedAccount.RM_Account_Number__c = '12345';
        relatedAccount.Name = SBR_3_0_API_Web_Jobsite_DA.JOBSITEACCOUNTNAME;
        relatedAccount.BillingStreet = '123 Main Street';
        relatedAccount.BillingCity = 'Toronto';
        relatedAccount.BillingPostalCode = 'M9N7V5';
        relatedAccount.BillingState = 'ON';
        relatedAccount.BillingCountry = 'CA';
        relatedAccount.Company_Code__c = '01';
        relatedAccount.Phone  = '1234567890';
        insert relatedAccount;

        	ContentVersion contentVersion = new ContentVersion(
                    Title          = 'a picture',
                    PathOnClient   = 'Pic.csv',
                    VersionData    = Blob.valueOf(str),
                    IsMajorVersion = true);
            insert contentVersion;

            List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
			//create ContentDocumentLink  record
            ContentDocumentLink cdl = new ContentDocumentLink(); 
            cdl.LinkedEntityId = relatedAccount.Id;
            cdl.ContentDocumentId = documents[0].Id;
            cdl.ShareType = 'V';
            cdl.Visibility = 'AllUsers'; 
            insert cdl;
            SBR_3_0_ReadAccountManagementCSV.Request[] requestList = new SBR_3_0_ReadAccountManagementCSV.Request[]{};
            SBR_3_0_ReadAccountManagementCSV.Request request = new SBR_3_0_ReadAccountManagementCSV.Request();
            SBR_3_0_ReadAccountManagementCSV.Response Response = new SBR_3_0_ReadAccountManagementCSV.Response();
            List<SObject> Result = Response.convertedCSVRows;
        
            //request.contentDocumentId = documents[0].Id;
            request.objectApiName = 'Account';
            request.contentDocumentIdList = null;
        	requestList.add(request);
            try
            {
        		SBR_3_0_ReadAccountManagementCSV.convert(requestList);
            }
           catch(Exception ex)
           {
               system.assert(ex.getMessage() == 'You need to provide either a single ContentDocument Id OR a list of ContentDocumentIds as inputs to this Flow action.');
           }
        
        	//List<SBR_3_0_Invocable_ARAuthority.ARRequest> lst = new List<SBR_3_0_Invocable_ARAuthority.ARRequest>();
        	//lst.add(new SBR_3_0_Invocable_ARAuthority.ARRequest());
        	//SBR_3_0_Invocable_ARAuthority.authenticateUserHierarchy(lst);
        
    }
    
    @isTest
    static void convertTestFailAPIName()
    {
        String str = 'RM_Account_Number__c,BillingStreet,Company_Code__c,Phone \n' +
        '12345,MainStreet,01,1234567890';
        Account relatedAccount = new Account();
        relatedAccount.RM_Account_Number__c = '12345';
        relatedAccount.Name = SBR_3_0_API_Web_Jobsite_DA.JOBSITEACCOUNTNAME;
        relatedAccount.BillingStreet = '123 Main Street';
        relatedAccount.BillingCity = 'Toronto';
        relatedAccount.BillingPostalCode = 'M9N7V5';
        relatedAccount.BillingState = 'ON';
        relatedAccount.BillingCountry = 'CA';
        relatedAccount.Company_Code__c = '01';
        relatedAccount.Phone  = '1234567890';
        insert relatedAccount;

        	ContentVersion contentVersion = new ContentVersion(
                    Title          = 'a picture',
                    PathOnClient   = 'Pic.csv',
                    VersionData    = Blob.valueOf(str),
                    IsMajorVersion = true);
            insert contentVersion;

            List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
			//create ContentDocumentLink  record
            ContentDocumentLink cdl = new ContentDocumentLink(); 
            cdl.LinkedEntityId = relatedAccount.Id;
            cdl.ContentDocumentId = documents[0].Id;
            cdl.ShareType = 'V';
            cdl.Visibility = 'AllUsers'; 
            insert cdl;
            SBR_3_0_ReadAccountManagementCSV.Request[] requestList = new SBR_3_0_ReadAccountManagementCSV.Request[]{};
            SBR_3_0_ReadAccountManagementCSV.Request request = new SBR_3_0_ReadAccountManagementCSV.Request();
            SBR_3_0_ReadAccountManagementCSV.Response Response = new SBR_3_0_ReadAccountManagementCSV.Response();
            List<SObject> Result = Response.convertedCSVRows;
        
            request.contentDocumentId = documents[0].Id;
            request.objectApiName = 'Account';
            request.contentDocumentIdList = new List<String>();
        	requestList.add(request);
            string fieldApiName = 'Phone ';
            try
            {
        		SBR_3_0_ReadAccountManagementCSV.convert(requestList);
            }
           catch(Exception ex)
           {
               system.assert(ex.getMessage() == 'Invalid Field Error: '+fieldApiName + '. Please double check the API name of the field.');
           }
        
        	//List<SBR_3_0_Invocable_ARAuthority.ARRequest> lst = new List<SBR_3_0_Invocable_ARAuthority.ARRequest>();
        	//lst.add(new SBR_3_0_Invocable_ARAuthority.ARRequest());
        	//SBR_3_0_Invocable_ARAuthority.authenticateUserHierarchy(lst);
        
    }
}