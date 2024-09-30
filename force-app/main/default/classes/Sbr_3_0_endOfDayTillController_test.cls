@isTest
private class Sbr_3_0_endOfDayTillController_test {
    
    @testSetup
    static void setupTestData() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Sales'];
        Profile p1 = [SELECT Id FROM Profile WHERE Name='Chatter External User'];
        
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Payment_Access'];
        //create ers user clone
        String ersUserName = 'ersuser' + DateTime.now().getTime() + '@SBRtestorg.com';
        String ChatUserName = 'chatuser' + DateTime.now().getTime() + '@SBRtestorg.com';
        User ersu = new User(Alias = 'ers', Email='ersuser@testorg.com',
                             EmailEncodingKey='UTF-8', LastName='erstest', LanguageLocaleKey='en_US',
                             LocaleSidKey='en_US', ProfileId = p.Id,
                             TimeZoneSidKey='America/Los_Angeles',
                             UserName=ersUserName);
        ersu.RepID__c = '1028';
        insert ersu;
        
        User ersu1 = new User(Alias = 'chatuser', Email='chatter@testorg.com',
                             EmailEncodingKey='UTF-8', LastName='testchatuser', LanguageLocaleKey='en_US',
                             LocaleSidKey='en_US', ProfileId = p1.Id,
                             TimeZoneSidKey='America/Los_Angeles',
                             UserName=ChatUserName);
       
        insert ersu1;
        
        insert new PermissionSetAssignment(AssigneeId = ersu.Id, PermissionSetId = ps.Id);   
    }
    
    @IsTest
    static void myTestMethod1() {
        User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(ersu){
            try{
                End_of_Day_Till__c tilrec = new End_of_Day_Till__c();
                tilrec.Till_Date__c =  Date.valueof('2024-04-16');
                tilrec.Total_Currency__c = 12.00;
                tilrec.Total_Checks__c = 122.00;
                tilrec.Total_ROA_Checks__c = 112.00;
                tilrec.Total_Deposit_in_Bank__c = 312.00;
                tilrec.Status__c = 'Draft';
                Sbr_3_0_endOfDayTillController.upsertTillRecord(tilrec);
                Sbr_3_0_endOfDayTillController.getEndOfTillRecord(tilrec.Till_Date__c,'');
                Sbr_3_0_endOfDayTillController.getDraftEndOfTillRecord('');
                String response = Sbr_3_0_endOfDayTillController.getOAuthToken('testing','testclientid','testclientsecret');
                System.assertNotEquals(null, response, 'response cant be null');
                List<Till_Over_Short_Reason__c> reasonlist = new List<Till_Over_Short_Reason__c>();
                Till_Over_Short_Reason__c reasonrec = new Till_Over_Short_Reason__c();
                reasonrec.Amount__c = 100;
                reasonrec.Comment__c = 'Test reason rec';
                reasonrec.CurrencyIsoCode = 'USD';
                reasonrec.Reason__c = 'Short';
                reasonrec.End_of_Day_Till__c = tilrec.Id;
                reasonlist.add(reasonrec);
                String validReasonsJson = JSON.serialize(reasonlist);
                End_of_Day_Till__c tillRec = Sbr_3_0_endOfDayTillController.fetchCurrencies(tilrec.Id);
                System.assertNotEquals(null, tillRec, 'tillRec cant be null');
                String reasonsResponse = Sbr_3_0_endOfDayTillController.insertReasons(validReasonsJson);
                System.assertNotEquals(null, reasonsResponse, 'reasonsResponse cant be null');
                
            }catch(exception e){
                SBR_3_0_Log.logException(e);
            }
        }
    }
    
    @IsTest
    static void insertReasonsTest() {
        User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(ersu){
            try{
                End_of_Day_Till__c tilrec = new End_of_Day_Till__c();
                tilrec.Till_Date__c =  Date.valueof('2024-04-16');
                tilrec.Total_Currency__c = 12.00;
                tilrec.Total_Checks__c = 122.00;
                tilrec.Total_ROA_Checks__c = 112.00;
                tilrec.Total_Deposit_in_Bank__c = 312.00;
                tilrec.Status__c = 'Draft';
                
                Sbr_3_0_endOfDayTillController.upsertTillRecord(tilrec);
                List<Till_Over_Short_Reason__c> reasonlist = new List<Till_Over_Short_Reason__c>();
                Till_Over_Short_Reason__c reasonrec = new Till_Over_Short_Reason__c();
                reasonrec.Amount__c = 100;
                reasonrec.Comment__c = 'Test reason rec';
                reasonrec.CurrencyIsoCode = 'USD';
                reasonrec.Reason__c = 'Short';
                reasonrec.End_of_Day_Till__c = tilrec.Id;
                reasonlist.add(reasonrec);
                String validReasonsJson = JSON.serialize(reasonlist);
                String reasonsResponse = Sbr_3_0_endOfDayTillController.insertReasons(validReasonsJson);
                Sbr_3_0_endOfDayTillController.getEndOfTillRecord(tilrec.Till_Date__c,'');
                Sbr_3_0_endOfDayTillController.getDraftEndOfTillRecord('');
                String response = Sbr_3_0_endOfDayTillController.getOAuthToken('testing','testclientid','testclientsecret');
                
                System.assertNotEquals(null, response, 'response cant be null');
                
                System.assertNotEquals(null, reasonsResponse, 'reasonsResponse cant be null');
                
            }catch(exception e){
                
                SBR_3_0_Log.logException(e);
            }
        }
    }
    @IsTest
    static void getEndOfTillRecordTest() {
        User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(ersu){
            try{
                
                Sbr_3_0_endOfDayTillController.getEndOfTillRecord(date.today(),'');
                Sbr_3_0_endOfDayTillController.getEodTillRecord('test');
                End_of_Day_Till__c tilrec = new End_of_Day_Till__c();
                tilrec.Till_Date__c =  Date.valueof('2024-04-16');
                tilrec.Total_Currency__c = 12.00;
                tilrec.Total_Checks__c = 122.00;
                tilrec.Total_ROA_Checks__c = 112.00;
                tilrec.Total_Deposit_in_Bank__c = 312.00;
                tilrec.Status__c = 'Draft';
                
                Sbr_3_0_endOfDayTillController.upsertTillRecord(tilrec);
                List<Till_Over_Short_Reason__c> reasonlist = new List<Till_Over_Short_Reason__c>();
                Till_Over_Short_Reason__c reasonrec = new Till_Over_Short_Reason__c();
                reasonrec.Amount__c = 100;
                reasonrec.Comment__c = 'Test reason rec';
                reasonrec.CurrencyIsoCode = 'USD';
                reasonrec.Reason__c = 'Short';
                reasonrec.End_of_Day_Till__c = tilrec.Id;
                reasonlist.add(reasonrec);
                String validReasonsJson = JSON.serialize(reasonlist);
                String reasonsResponse = Sbr_3_0_endOfDayTillController.insertReasons(validReasonsJson);
                Sbr_3_0_endOfDayTillController.getEndOfTillRecord(tilrec.Till_Date__c,'');
                Sbr_3_0_endOfDayTillController.getDraftEndOfTillRecord('');
                String response = Sbr_3_0_endOfDayTillController.getOAuthToken('testing','testclientid','testclientsecret');
                
                System.assertNotEquals(null, response, 'response cant be null');
                
                System.assertNotEquals(null, reasonsResponse, 'reasonsResponse cant be null');
                
            }catch(exception e){
                
                SBR_3_0_Log.logException(e);
            }
        }
    }
    
    @IsTest
    static void getReasonRecordsByIdFailureTest() {
        User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(ersu){
            try{
                End_of_Day_Till__c tilrec = new End_of_Day_Till__c();
                tilrec.Till_Date__c =  Date.valueof('2024-04-16');
                tilrec.Total_Currency__c = 12.00;
                tilrec.Total_Checks__c = 122.00;
                tilrec.Total_ROA_Checks__c = 112.00;
                tilrec.Total_Deposit_in_Bank__c = 312.00;
                tilrec.Status__c = 'Draft';
                Sbr_3_0_endOfDayTillController.getReasonRecordsById('validReasonsJson');
                String response = Sbr_3_0_endOfDayTillController.getOAuthToken('testing','testclientid','testclientsecret');
                System.assertNotEquals(null, response, 'response cant be null');                
            }catch(exception e){
                
                SBR_3_0_Log.logException(e);
            }
        }
    }
    
    @IsTest
    static void fetchCurrenciesFailureTest() {
        User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(ersu){
            try{
                End_of_Day_Till__c tilrec = new End_of_Day_Till__c();
                tilrec.Till_Date__c =  Date.valueof('2024-04-16');
                tilrec.Total_Currency__c = 12.00;
                tilrec.Total_Checks__c = 122.00;
                tilrec.Total_ROA_Checks__c = 112.00;
                tilrec.Total_Deposit_in_Bank__c = 312.00;
                tilrec.Status__c = 'Draft';
                Sbr_3_0_endOfDayTillController.fetchCurrencies('validReasonsJson');
                String response = Sbr_3_0_endOfDayTillController.getOAuthToken('testing','testclientid','testclientsecret');
                System.assertNotEquals(null, response, 'response cant be null');                
            }catch(exception e){
                
                SBR_3_0_Log.logException(e);
            }
        }
    }
    
    @IsTest
    static void getDraftEndOfTillRecordFailureTest() {
        User ersu = [SELECT Id FROM User Where IsActive =true and Alias = 'chatuser' LIMIT 1];
        System.runAs(ersu){
            try{
                End_of_Day_Till__c tilrec = new End_of_Day_Till__c();
                tilrec.Till_Date__c =  Date.valueof('2024-04-16');
                tilrec.Total_Currency__c = 12.00;
                tilrec.Total_Checks__c = 122.00;
                tilrec.Total_ROA_Checks__c = 112.00;
                tilrec.Total_Deposit_in_Bank__c = 312.00;
                tilrec.Status__c = 'Draft';
                Sbr_3_0_endOfDayTillController.getDraftEndOfTillRecord('validReasonsJson');
                String response = Sbr_3_0_endOfDayTillController.getOAuthToken('testing','testclientid','testclientsecret');
                System.assertNotEquals(null, response, 'response cant be null');                
            }catch(exception e){
                
                SBR_3_0_Log.logException(e);
            }
        }
    }
    
       @IsTest
    static void getCashControlDetailsFailureTest() {
        User ersu = [SELECT Id FROM User Where IsActive =true and Alias = 'chatuser' LIMIT 1];
        System.runAs(ersu){
            try{
                Sbr_3_0_endOfDayTillController.getCashControlDetails('validReasonsJson');
                String response = Sbr_3_0_endOfDayTillController.getOAuthToken('testing','testclientid','testclientsecret');
                System.assertNotEquals(null, response, 'response cant be null');                
            }catch(exception e){
                SBR_3_0_Log.logException(e);
            }
        }
    }
    
     @IsTest
    static void getCashROAControlDetailsFailureTest() {
        User ersu = [SELECT Id FROM User Where IsActive =true and Alias = 'chatuser' LIMIT 1];
        System.runAs(ersu){
            try{
                Sbr_3_0_endOfDayTillController.getCashROAControlDetails('validReasonsJson');
                String response = Sbr_3_0_endOfDayTillController.getOAuthToken('testing','testclientid','testclientsecret');
                System.assertNotEquals(null, response, 'response cant be null');                
            }catch(exception e){
                SBR_3_0_Log.logException(e);
            }
        }
    }
    
     @IsTest
    static void getFilteredTillNewDepositDetailsFailureTest() {
        User ersu = [SELECT Id FROM User Where IsActive =true and Alias = 'chatuser' LIMIT 1];
        System.runAs(ersu){
            try{
                Sbr_3_0_endOfDayTillController.getFilteredTillNewDepositDetails('validReasonsJson','tillDetailId');
                String response = Sbr_3_0_endOfDayTillController.getOAuthToken('testing','testclientid','testclientsecret');
                System.assertNotEquals(null, response, 'response cant be null');                
            }catch(exception e){
                SBR_3_0_Log.logException(e);
            }
        }
    }
    
     @IsTest
    static void totalBusinessDetailsFailureTest() {
        User ersu = [SELECT Id FROM User Where IsActive =true and Alias = 'chatuser' LIMIT 1];
        	
        System.runAs(ersu){
            try{
                string year = '2008';
                string month = '10';
                string day = '5';
                string hour = '12';
                string minute = '20';
                string second = '20';
                string stringDate = year + '-' + month
                 + '-' + day + ' ' + hour + ':' + 
                minute + ':' + second;
                Sbr_3_0_endOfDayTillController.totalBusinessDetails(stringDate,'tillDetailId','profitCenter');
                String response = Sbr_3_0_endOfDayTillController.getOAuthToken('testing','testclientid','testclientsecret');
                System.assertNotEquals(null, response, 'response cant be null');                
            }catch(exception e){
                SBR_3_0_Log.logException(e);
            }
        }
    }
      @IsTest
    static void getcashInvoicesDetailsFailureTest() {
        User ersu = [SELECT Id FROM User Where IsActive =true and Alias = 'chatuser' LIMIT 1];
        System.runAs(ersu){
            try{
                Sbr_3_0_endOfDayTillController.getcashInvoicesDetails('recordTypeName','tillDetailId');
                String response = Sbr_3_0_endOfDayTillController.getOAuthToken('testing','testclientid','testclientsecret');
                System.assertNotEquals(null, response, 'response cant be null');                
            }catch(exception e){
                SBR_3_0_Log.logException(e);
            }
        }
    }
    
     @IsTest
    static void getotherLocationDetailsFailureTest() {
        User ersu = [SELECT Id FROM User Where IsActive =true and Alias = 'chatuser' LIMIT 1];
        System.runAs(ersu){
            try{
                Sbr_3_0_endOfDayTillController.getotherLocationDetails('recordTypeName','tillDetailId');
                String response = Sbr_3_0_endOfDayTillController.getOAuthToken('testing','testclientid','testclientsecret');
                System.assertNotEquals(null, response, 'response cant be null');                
            }catch(exception e){
                SBR_3_0_Log.logException(e);
            }
        }
    }
    
     @IsTest
    static void checkEODRecordPresentFailureTest() {
        User ersu = [SELECT Id FROM User Where IsActive =true and Alias = 'chatuser' LIMIT 1];
        System.runAs(ersu){
            try{
                Sbr_3_0_endOfDayTillController.checkEODRecordPresent('compoundKey');
                String response = Sbr_3_0_endOfDayTillController.getOAuthToken('testing','testclientid','testclientsecret');
                System.assertNotEquals(null, response, 'response cant be null');                
            }catch(exception e){
                SBR_3_0_Log.logException(e);
            }
        }
    }
    
    @IsTest
    static void getEODTillCompoundKeyFailureTest() {
        User ersu = [SELECT Id FROM User Where IsActive =true and Alias = 'chatuser' LIMIT 1];
        System.runAs(ersu){
            try{
                Sbr_3_0_endOfDayTillController.getEODTillCompoundKey('eodTillId');
                String response = Sbr_3_0_endOfDayTillController.getOAuthToken('testing','testclientid','testclientsecret');
                System.assertNotEquals(null, response, 'response cant be null');                
            }catch(exception e){
                SBR_3_0_Log.logException(e);
            }
        }
    }
    
    @IsTest
    static void getTillDetailCompoundKeyFailureTest() {
        User ersu = [SELECT Id FROM User Where IsActive =true and Alias = 'chatuser' LIMIT 1];
        System.runAs(ersu){
            try{
                Sbr_3_0_endOfDayTillController.getTillDetailCompoundKey('tillDetailId');
                String response = Sbr_3_0_endOfDayTillController.getOAuthToken('testing','testclientid','testclientsecret');
                System.assertNotEquals(null, response, 'response cant be null');                
            }catch(exception e){
                SBR_3_0_Log.logException(e);
            }
        }
    }
    
    @IsTest
    static void getEndOfTillRecordFailureTest() {
        User ersu = [SELECT Id FROM User Where IsActive =true and Alias = 'chatuser' LIMIT 1];
        System.runAs(ersu){
            try{
                Sbr_3_0_endOfDayTillController.getEndOfTillRecord(system.today(),'compoundKey');
                String response = Sbr_3_0_endOfDayTillController.getOAuthToken('testing','testclientid','testclientsecret');
                System.assertNotEquals(null, response, 'response cant be null');                
            }catch(exception e){
                SBR_3_0_Log.logException(e);
            }
        }
    }
    
     @IsTest
    static void upsertTillRecordFailureTest() {
        User ersu = [SELECT Id FROM User Where IsActive =true and Alias = 'chatuser' LIMIT 1];
        System.runAs(ersu){
            try{
                End_of_Day_Till__c tilrec = new End_of_Day_Till__c();
                tilrec.Till_Date__c =  Date.valueof('2024-04-16');
                tilrec.Total_Currency__c = 12.00;
                tilrec.Total_Checks__c = 122.00;
                tilrec.Total_ROA_Checks__c = 112.00;
                tilrec.Total_Deposit_in_Bank__c = 312.00;
                tilrec.Status__c = 'Draft';
                Sbr_3_0_endOfDayTillController.upsertTillRecord(tilrec);
                String response = Sbr_3_0_endOfDayTillController.getOAuthToken('testing','testclientid','testclientsecret');
                System.assertNotEquals(null, response, 'response cant be null');                
            }catch(exception e){
                
                SBR_3_0_Log.logException(e);
            }
        }
    }
    
    @IsTest
    static void insertReasonsFailureTest() {
        User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(ersu){
            try{
                End_of_Day_Till__c tilrec = new End_of_Day_Till__c();
                tilrec.Till_Date__c =  Date.valueof('2024-04-16');
                tilrec.Total_Currency__c = 12.00;
                tilrec.Total_Checks__c = 122.00;
                tilrec.Total_ROA_Checks__c = 112.00;
                tilrec.Total_Deposit_in_Bank__c = 312.00;
                tilrec.Status__c = 'Draft';
                Sbr_3_0_endOfDayTillController.insertReasons('validReasonsJson');
                Sbr_3_0_endOfDayTillController.upsertTillRecord(tilrec);
                
                Sbr_3_0_endOfDayTillController.getEndOfTillRecord(tilrec.Till_Date__c,'');
                Sbr_3_0_endOfDayTillController.getDraftEndOfTillRecord('');
                String response = Sbr_3_0_endOfDayTillController.getOAuthToken('testing','testclientid','testclientsecret');
                List<Till_Over_Short_Reason__c> reasonlist = new List<Till_Over_Short_Reason__c>();
                Till_Over_Short_Reason__c reasonrec = new Till_Over_Short_Reason__c();
                reasonrec.Amount__c = 100;
                reasonrec.Comment__c = 'Test reason rec';
                reasonrec.CurrencyIsoCode = 'USD';
                reasonrec.Reason__c = 'Short';
                reasonrec.End_of_Day_Till__c = tilrec.Id;
                reasonlist.add(reasonrec);
                System.assertNotEquals(null, response, 'response cant be null');                
            }catch(exception e){
                
                SBR_3_0_Log.logException(e);
            }
        }
    }
    
    
    @IsTest
    static void testGetCashControlDetails() {
        User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(ersu){
            End_of_Day_Till__c tilrec = new End_of_Day_Till__c();
            tilrec.Till_Date__c =  Date.valueof('2024-04-16');
            tilrec.Total_Currency__c = 12.00;
            tilrec.Total_Checks__c = 122.00;
            tilrec.Total_ROA_Checks__c = 112.00;
            tilrec.Total_Deposit_in_Bank__c = 312.00;
            tilrec.Status__c = 'Draft';
            Sbr_3_0_endOfDayTillController.upsertTillRecord(tilrec);
            
            Till_Detail__c tilldetail= new Till_Detail__c();
            tilldetail.End_of_Day_Till__c = tilrec.Id;
            insert tilldetail;
            // Create test data (you can customize this based on your requirements)
            List<Till_New_Deposit_Detail__c> testCashDetails = new List<Till_New_Deposit_Detail__c>();
            testCashDetails.add(new Till_New_Deposit_Detail__c(Name = 'Test Detail 1',  Amount__c = 100, Till_Detail__c=tilldetail.Id));
            testCashDetails.add(new Till_New_Deposit_Detail__c(Name = 'Test Detail 2',  Amount__c = 200, Till_Detail__c=tilldetail.Id));
            // Insert test data
            insert testCashDetails;
            
            // Call the method to be tested
            List<Till_New_Deposit_Detail__c> result = Sbr_3_0_endOfDayTillController.getCashControlDetails(tilldetail.Id);
            
            System.assertNotEquals(null, result,'result is null');
            System.assertEquals(2, result.size(),'size is 2'); // Adjust this based on your test data
            
            System.assertEquals('Test Detail 1', result[0].Name,'result found');
            System.assertEquals(100, result[0].Amount__c,'amount is 100'); 
        }
    }
    
    static void testGetCashControlDetails1() {
        User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(ersu){
            try{
                End_of_Day_Till__c tilrec = new End_of_Day_Till__c();
                tilrec.Till_Date__c =  Date.valueof('2024-04-16');
                tilrec.Total_Currency__c = 12.00;
                tilrec.Total_Checks__c = 122.00;
                tilrec.Total_ROA_Checks__c = 112.00;
                tilrec.Total_Deposit_in_Bank__c = 312.00;
                tilrec.Status__c = 'Draft';
                Sbr_3_0_endOfDayTillController.upsertTillRecord(tilrec);
                Sbr_3_0_endOfDayTillController.getEodTillRecord(tilrec.Id);
                Sbr_3_0_endOfDayTillController.fetchCurrencies(tilrec.Id);
            }catch(Exception e){
                SBR_3_0_Log.logException(e);
            }   
        }
    }
    
    @isTest
    static void testGetCashROAControlDetails() {
        // Create test data
        User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(ersu){
            End_of_Day_Till__c tilrec = new End_of_Day_Till__c();
            tilrec.Till_Date__c =  Date.valueof('2024-04-16');
            tilrec.Total_Currency__c = 12.00;
            tilrec.Total_Checks__c = 122.00;
            tilrec.Total_ROA_Checks__c = 112.00;
            tilrec.Total_Deposit_in_Bank__c = 312.00;
            tilrec.Status__c = 'Draft';
            Sbr_3_0_endOfDayTillController.upsertTillRecord(tilrec);
            
            Till_Detail__c tilldetail= new Till_Detail__c();
            tilldetail.End_of_Day_Till__c = tilrec.Id;
            insert tilldetail;
            
            List<Till_ROA_Detail__c> testROADetails = new List<Till_ROA_Detail__c>();
            testROADetails.add(new Till_ROA_Detail__c(
                Name = 'Test ROA Detail 1',
                Payment_ID__c = 67765,
                Location__c = 'Location1',
                Amount__c = 100.00,
                Wynne_User__c = 'User1',
                Invoice_or_Comment__c = '123456787',
                Till_Detail__c = tilldetail.Id
            ));
            testROADetails.add(new Till_ROA_Detail__c(
                Name = 'Test ROA Detail 2',
                Payment_ID__c = 67756,
                Location__c = 'Location2',
                Amount__c = 200.00,
                Wynne_User__c = 'User2',
                Invoice_or_Comment__c = '123456786',
                Till_Detail__c = tilldetail.Id
            ));
            
            // Insert test data
            insert testROADetails;
            
            // Call the method to be tested
            List<Till_ROA_Detail__c> result = Sbr_3_0_endOfDayTillController.getCashROAControlDetails(tilldetail.Id);
            
            // Verify the results
            System.assertNotEquals(null, result, 'Result should not be null');
            System.assertEquals(2, result.size(), 'Result size should be 2');
            
            // Verify the first record
            System.assertEquals('Test ROA Detail 1', result[0].Name,'Test ROA Detail 1');
            System.assertEquals('Location1', result[0].Location__c,'Location1');
            System.assertEquals(100, result[0].Amount__c,'amount is 100');
            System.assertEquals('User1', result[0].Wynne_User__c,'wynne user found');
            
            // Verify the second record
            System.assertEquals('Test ROA Detail 2', result[1].Name,'Test ROA Detail 2');
            System.assertEquals('Location2', result[1].Location__c,'Location2');
            System.assertEquals(200, result[1].Amount__c,'amount is 200');
            System.assertEquals('User2', result[1].Wynne_User__c,'User2');
        }
    } 
    
    @isTest
    static void testgetFilteredTillNewDepositDetails() {
        // Create test data
        User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(ersu){
            try{
                End_of_Day_Till__c tilrec = new End_of_Day_Till__c();
                tilrec.Till_Date__c =  Date.valueof('2024-04-16');
                tilrec.Total_Currency__c = 12.00;
                tilrec.Total_Checks__c = 122.00;
                tilrec.Total_ROA_Checks__c = 112.00;
                tilrec.Total_Deposit_in_Bank__c = 312.00;
                tilrec.Status__c = 'Draft';
                Sbr_3_0_endOfDayTillController.upsertTillRecord(tilrec);
                
                Till_Detail__c tilldetail= new Till_Detail__c();
                tilldetail.End_of_Day_Till__c = tilrec.Id;
                insert tilldetail;
                
                String recordTypeIdNewDeposit = Schema.SObjectType.Till_New_Deposit_Detail__c.getRecordTypeInfosByName().get('New Deposit').getRecordTypeId();
                List<Till_New_Deposit_Detail__c> testDepositDetails = new List<Till_New_Deposit_Detail__c>();
                testDepositDetails.add(new Till_New_Deposit_Detail__c(
                    Name = 'Test Deposit Detail 1',
                    Contract_Number__c = '121234565',
                    Invoice_Number__c = 567876685,
                    Detailed_Sequence_Number__c = 3453,
                    Amount__c = 100.00,
                    Drivers_License__c = 'CA 65765',
                    SR__c = 'R3',
                    Payment_Method__c = 'V',
                    Wynne_User__c = 'User1',
                    Till_Detail__c = tilldetail.Id,
                    RecordTypeId = recordTypeIdNewDeposit
                ));
                testDepositDetails.add(new Till_New_Deposit_Detail__c(
                    Name = 'Test Deposit Detail 2',
                    Contract_Number__c = '121234566',
                    Invoice_Number__c = 567876687,
                    Detailed_Sequence_Number__c = 3452,
                    Amount__c = 200.00,
                    Drivers_License__c = 'CA 78656',
                    SR__c = 'R3',
                    Payment_Method__c = 'A',
                    Wynne_User__c = 'User2',
                    Till_Detail__c = tilldetail.Id,
                    RecordTypeId = recordTypeIdNewDeposit
                ));
                
                // Insert test data
                insert testDepositDetails;
                
                // Call the method to be tested
                List<Till_New_Deposit_Detail__c> result = Sbr_3_0_endOfDayTillController.getFilteredTillNewDepositDetails('New Deposit',tilldetail.Id);
                
                // Verify the results
                System.assertNotEquals(null, result, 'Result should not be null');
                System.assertEquals(2, result.size(), 'Result size should be 2');
                
                // Verify the first record
                System.assertEquals('Test Deposit Detail 1', result[0].Name,'Test Deposit Detail 1');
                System.assertEquals('121234565', result[0].Contract_Number__c,'121234565');
                System.assertEquals(567876685, result[0].Invoice_Number__c,'567876685');
                System.assertEquals(3453, result[0].Detailed_Sequence_Number__c,'3453');
                System.assertEquals(100.00, result[0].Amount__c,'100.00');
                System.assertEquals('CA 65765', result[0].Drivers_License__c,'CA 65765');
                System.assertEquals('R3', result[0].SR__c,'R3');
                System.assertEquals('V', result[0].Payment_Method__c,'V');
                System.assertEquals('User1', result[0].Wynne_User__c,'User1');
                
                // Verify the second record
                System.assertEquals('Test Deposit Detail 2', result[1].Name,'Test Deposit Detail 2');
                System.assertEquals('121234566', result[1].Contract_Number__c,'121234566');
                System.assertEquals(567876687, result[1].Invoice_Number__c,'567876687');
                System.assertEquals(3452, result[1].Detailed_Sequence_Number__c,'3452');
                System.assertEquals(200.00, result[1].Amount__c,'200.00');
                System.assertEquals('CA 78656', result[1].Drivers_License__c,'CA 78656');
                System.assertEquals('R3', result[1].SR__c,'R3');
                System.assertEquals('A', result[1].Payment_Method__c,'A');
                System.assertEquals('User2', result[1].Wynne_User__c,'User2');
            }catch(Exception e){
                SBR_3_0_Log.logException(e);
            }
        }
    }
    
    @isTest
    static void testGetOtherLocationDetails() {
        // Create test data
        User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(ersu){
            End_of_Day_Till__c tilrec = new End_of_Day_Till__c();
            tilrec.Till_Date__c =  Date.valueof('2024-04-16');
            tilrec.Total_Currency__c = 12.00;
            tilrec.Total_Checks__c = 122.00;
            tilrec.Total_ROA_Checks__c = 112.00;
            tilrec.Total_Deposit_in_Bank__c = 312.00;
            tilrec.Status__c = 'Draft';
            Sbr_3_0_endOfDayTillController.upsertTillRecord(tilrec);
            
            Till_Detail__c tilldetail= new Till_Detail__c();
            tilldetail.End_of_Day_Till__c = tilrec.Id;
            insert tilldetail;
            
            List<Till_New_Payment_Detail__c> testOtherLocationDetails = new List<Till_New_Payment_Detail__c>();
            String recordTypeInvoice = Schema.SObjectType.Till_New_Payment_Detail__c.getRecordTypeInfosByName().get('Invoice').getRecordTypeId();
            String recordTypeInterCompany = Schema.SObjectType.Till_New_Payment_Detail__c.getRecordTypeInfosByName().get('InterCompany').getRecordTypeId();
            testOtherLocationDetails.add(new Till_New_Payment_Detail__c(
                Name = 'Test Payment Detail 1',
                Invoice_Number__c = '897548479',
                Location__c = 'Location1',
                SR__c = 'R1',
                Invoice_Amount__c = 150.00,
                Applied_Deposit__c = 50.00,
                Net_Cash_Received__c = 100.00,
                Other_Amount__c = 20.00,
                Till_Detail__c = tilldetail.Id,
                RecordTypeId = recordTypeInvoice
            ));
            testOtherLocationDetails.add(new Till_New_Payment_Detail__c(
                Name = 'Test Payment Detail 2',
                Invoice_Number__c = '897548478',
                Location__c = 'Location2',
                SR__c = 'R3',
                Invoice_Amount__c = 250.00,
                Applied_Deposit__c = 70.00,
                Net_Cash_Received__c = 180.00,
                Other_Amount__c = 30.00,
                Till_Detail__c = tilldetail.Id,
                RecordTypeId = recordTypeInterCompany
            ));
            
            // Insert test data
            insert testOtherLocationDetails;
            
            // Call the method to be tested
            List<Till_New_Payment_Detail__c> result = Sbr_3_0_endOfDayTillController.getotherLocationDetails('Invoice',tilldetail.Id);
            List<Till_New_Payment_Detail__c> result1 = Sbr_3_0_endOfDayTillController.getcashInvoicesDetails('InterCompany',tilldetail.Id);
            
            // Verify the results
            System.assertNotEquals(null, result, 'Result should not be null');
            System.assertNotEquals(null, result1, 'Result should not be null');
            System.assertEquals(1, result.size(), 'Result size should be 2');
            
            // Verify the first record
            System.assertEquals('Test Payment Detail 1', result[0].Name,'Test Payment Detail 1');
            System.assertEquals('Location1', result[0].Location__c,'Location1');
            System.assertEquals('R1', result[0].SR__c,'R1');
            System.assertEquals(150.00, result[0].Invoice_Amount__c,'150.00');
            System.assertEquals(50.00, result[0].Applied_Deposit__c,'50.00');
            System.assertEquals(100.00, result[0].Net_Cash_Received__c,'100.00');
            System.assertEquals(20.00, result[0].Other_Amount__c,'20.00');
        }
    }
    
    @isTest
    static void testupsertTillRecordException() {
        User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(ersu){
            try{
                End_of_Day_Till__c tilrec = new End_of_Day_Till__c();
                tilrec.Till_Date__c =  Date.valueof('2024-04-16');
                tilrec.Total_Currency__c = 12.00;
                tilrec.Total_Checks__c = 122.00;
                tilrec.Total_ROA_Checks__c = 112.00;
                tilrec.Total_Deposit_in_Bank__c = 312.00;
                Sbr_3_0_endOfDayTillController.upsertTillRecord(tilrec);
                System.assertNotEquals(null, tilrec, 'tilrec should not be null');
            }catch(exception e){
                SBR_3_0_Log.logException(e);
            }
        }
    }
    
    @isTest
    static void testTotalBusinessDetails() {
        User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(ersu){
            try{        
                Date invoiceDateValue = Date.valueOf('2024-04-16');
                Invoice__c invoiceDetail = new Invoice__c(
                    Invoice_number__c = 'INV001',
                    Invoice_Sequence_Number__c = 50.00,
                    Total_invoice_Amount__c = 500.00,
                    Damage_Waiver__c = 40.00,
                    Sales_Tax_Amount__c = 30.00,
                    Pickup_Amount__c = 380.00,
                    Delivery_Amount__c = 1000.00,
                    Contract_Number__c = 5555,
                    Invoice_Date__c = invoiceDateValue
                );
                
                // Insert test data
                insert invoiceDetail;
                
                // Call the method to be tested
                List<Invoice__c> result = Sbr_3_0_endOfDayTillController.totalBusinessDetails('2024-04-16','','');
                
                // Verify the results
                System.assertNotEquals(null, result, 'Result should not be null');
                System.assertEquals(1, result.size(), 'Result size should be 2');
                
                // Verify the first record
                System.assertEquals('INV001', result[0].Invoice_Number__c,'INV001');
                System.assertEquals(40.00, result[0].Damage_Waiver__c,'40.00');
                System.assertEquals(30.00, result[0].Sales_Tax_Amount__c,'30.00');
                System.assertEquals(380.00, result[0].Pickup_Amount__c,'380.00');
            }catch(exception e){
                SBR_3_0_Log.logException(e);
            }
        }
    }
    @SuppressWarnings('PMD.NcssMethodCount')
    @isTest
    static void testInsertEndOfDayTillRecords(){
        User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(ersu){
            string jsonString = '{"companyCode":"01","branchLocNumber":"0653","fromDate":"2024-06-10","fromTime":"23:59:59","toDate":"2024-06-10","toTime":"23:59:59","cashDrawerDetails":{"totalCurrencyAmount":239.69,"totalChecksAmount":0,"totalCreditCardAmount":0,"totalDrawerAmount":239.69,"startDrawerAmount":239.69,"totalTransactionsAmount":0,"nextDrawerAmount":239.69,"totalDepositAmount":0,"autoDepositAmount":0,"depositInBankAmount":0,"cashSalesAmount":46.87,"refundsDepositsAmount":-46.87,"uncollectedCashAmount":0,"netCashFromInvoices":0,"depositsTakenAmount":0,"refundsNotGivenAmount":0,"interLocCashAmount":0,"totalCashTranAmount":0,"depositCashToBank":0,"depositChecksToBank":0,"depositCreditCardSlipsToBank":0,"bankDepositDate":"2024-05-22","postedToGL":"Y","postedToGLDate":"2024-05-22","postedToGLTime":"23:59:59","drawerOverUnderAmount":0,"user":"CWLEZEN","systemDate":"2024-05-22","systemTime":"23:59:59","maintByUser":"CWLEZEN","invoiceNumber":"CDEP-925120","wireTransferAmount":0,"autoRoaDepositAmount":0,"roaAmount":0,"totalRoaChecksAmount":0,"depositRoaCashToBank":0,"depositRoaChecksToBank":0,"depositRoaCrdCardSlipsToBank":0,"totalRoaCurrencyAmount":0,"totalRoaCreditCardAmount":0},"currencyDenominationDetails":[{"denomination":100,"amount":0,"description":"Amount $100 Bills","currencyCode":"","exchangeRate":1},{"denomination":50,"amount":0,"description":"Amount $50 Bills","currencyCode":"","exchangeRate":1}],"creditCardDetails":[{"creditCard":"A","autoDeposit":"Y","amount":0,"GLAccountNumber":"0099990653005100","description":"*AMEX PAYMENT","currencyCode":"USD","exchangeRate":1},{"creditCard":"AR","autoDeposit":"Y","amount":0,"GLAccountNumber":"0099990653005100","description":"*ROA-AMEX PAYMENT","currencyCode":"USD","exchangeRate":1}]}';
            string jsonString1 = '{"companyCode":"01","branchLocNumber":"0653","fromDate":"2024-06-10","fromTime":"23:59:59","toDate":"2024-06-10","toTime":"23:59:59","cashDrawerDetails":{"totalCurrencyAmount":239.69,"totalChecksAmount":0,"totalCreditCardAmount":0,"totalDrawerAmount":239.69,"startDrawerAmount":239.69,"totalTransactionsAmount":0,"nextDrawerAmount":239.69,"totalDepositAmount":0,"autoDepositAmount":0,"depositInBankAmount":0,"cashSalesAmount":46.87,"refundsDepositsAmount":-46.87,"uncollectedCashAmount":0,"netCashFromInvoices":0,"depositsTakenAmount":0,"refundsNotGivenAmount":0,"interLocCashAmount":0,"totalCashTranAmount":0,"depositCashToBank":0,"depositChecksToBank":0,"depositCreditCardSlipsToBank":0,"bankDepositDate":"2024-05-22","postedToGL":"Y","postedToGLDate":"2024-05-22","postedToGLTime":"23:59:59","drawerOverUnderAmount":0,"user":"CWLEZEN","systemDate":"2024-05-22","systemTime":"23:59:59","maintByUser":"CWLEZEN","invoiceNumber":"CDEP-925120","wireTransferAmount":0,"autoRoaDepositAmount":0,"roaAmount":0,"totalRoaChecksAmount":0,"depositRoaCashToBank":0,"depositRoaChecksToBank":0,"depositRoaCrdCardSlipsToBank":0,"totalRoaCurrencyAmount":0,"totalRoaCreditCardAmount":0},"currencyDenominationDetails":[{"denomination":50,"amount":0,"description":"Amount $100 Bills","currencyCode":"","exchangeRate":1},{"denomination":50,"amount":0,"description":"Amount $50 Bills","currencyCode":"","exchangeRate":1}],"creditCardDetails":[{"creditCard":"A","autoDeposit":"Y","amount":0,"GLAccountNumber":"0099990653005100","description":"*AMEX PAYMENT","currencyCode":"USD","exchangeRate":1},{"creditCard":"AR","autoDeposit":"Y","amount":0,"GLAccountNumber":"0099990653005100","description":"*ROA-AMEX PAYMENT","currencyCode":"USD","exchangeRate":1}]}';
            string jsonString2 = '{"companyCode":"01","branchLocNumber":"0653","fromDate":"2024-06-10","fromTime":"23:59:59","toDate":"2024-06-10","toTime":"23:59:59","cashDrawerDetails":{"totalCurrencyAmount":239.69,"totalChecksAmount":0,"totalCreditCardAmount":0,"totalDrawerAmount":239.69,"startDrawerAmount":239.69,"totalTransactionsAmount":0,"nextDrawerAmount":239.69,"totalDepositAmount":0,"autoDepositAmount":0,"depositInBankAmount":0,"cashSalesAmount":46.87,"refundsDepositsAmount":-46.87,"uncollectedCashAmount":0,"netCashFromInvoices":0,"depositsTakenAmount":0,"refundsNotGivenAmount":0,"interLocCashAmount":0,"totalCashTranAmount":0,"depositCashToBank":0,"depositChecksToBank":0,"depositCreditCardSlipsToBank":0,"bankDepositDate":"2024-05-22","postedToGL":"Y","postedToGLDate":"2024-05-22","postedToGLTime":"23:59:59","drawerOverUnderAmount":0,"user":"CWLEZEN","systemDate":"2024-05-22","systemTime":"23:59:59","maintByUser":"CWLEZEN","invoiceNumber":"CDEP-925120","wireTransferAmount":0,"autoRoaDepositAmount":0,"roaAmount":0,"totalRoaChecksAmount":0,"depositRoaCashToBank":0,"depositRoaChecksToBank":0,"depositRoaCrdCardSlipsToBank":0,"totalRoaCurrencyAmount":0,"totalRoaCreditCardAmount":0},"currencyDenominationDetails":[{"denomination":20,"amount":0,"description":"Amount $100 Bills","currencyCode":"","exchangeRate":1},{"denomination":50,"amount":0,"description":"Amount $50 Bills","currencyCode":"","exchangeRate":1}],"creditCardDetails":[{"creditCard":"A","autoDeposit":"Y","amount":0,"GLAccountNumber":"0099990653005100","description":"*AMEX PAYMENT","currencyCode":"USD","exchangeRate":1},{"creditCard":"AR","autoDeposit":"Y","amount":0,"GLAccountNumber":"0099990653005100","description":"*ROA-AMEX PAYMENT","currencyCode":"USD","exchangeRate":1}]}';
            string jsonString3 = '{"companyCode":"01","branchLocNumber":"0653","fromDate":"2024-06-10","fromTime":"23:59:59","toDate":"2024-06-10","toTime":"23:59:59","cashDrawerDetails":{"totalCurrencyAmount":239.69,"totalChecksAmount":0,"totalCreditCardAmount":0,"totalDrawerAmount":239.69,"startDrawerAmount":239.69,"totalTransactionsAmount":0,"nextDrawerAmount":239.69,"totalDepositAmount":0,"autoDepositAmount":0,"depositInBankAmount":0,"cashSalesAmount":46.87,"refundsDepositsAmount":-46.87,"uncollectedCashAmount":0,"netCashFromInvoices":0,"depositsTakenAmount":0,"refundsNotGivenAmount":0,"interLocCashAmount":0,"totalCashTranAmount":0,"depositCashToBank":0,"depositChecksToBank":0,"depositCreditCardSlipsToBank":0,"bankDepositDate":"2024-05-22","postedToGL":"Y","postedToGLDate":"2024-05-22","postedToGLTime":"23:59:59","drawerOverUnderAmount":0,"user":"CWLEZEN","systemDate":"2024-05-22","systemTime":"23:59:59","maintByUser":"CWLEZEN","invoiceNumber":"CDEP-925120","wireTransferAmount":0,"autoRoaDepositAmount":0,"roaAmount":0,"totalRoaChecksAmount":0,"depositRoaCashToBank":0,"depositRoaChecksToBank":0,"depositRoaCrdCardSlipsToBank":0,"totalRoaCurrencyAmount":0,"totalRoaCreditCardAmount":0},"currencyDenominationDetails":[{"denomination":10,"amount":0,"description":"Amount $100 Bills","currencyCode":"","exchangeRate":1},{"denomination":50,"amount":0,"description":"Amount $50 Bills","currencyCode":"","exchangeRate":1}],"creditCardDetails":[{"creditCard":"A","autoDeposit":"Y","amount":0,"GLAccountNumber":"0099990653005100","description":"*AMEX PAYMENT","currencyCode":"USD","exchangeRate":1},{"creditCard":"AR","autoDeposit":"Y","amount":0,"GLAccountNumber":"0099990653005100","description":"*ROA-AMEX PAYMENT","currencyCode":"USD","exchangeRate":1}]}';
            string jsonString4 = '{"companyCode":"01","branchLocNumber":"0653","fromDate":"2024-06-10","fromTime":"23:59:59","toDate":"2024-06-10","toTime":"23:59:59","cashDrawerDetails":{"totalCurrencyAmount":239.69,"totalChecksAmount":0,"totalCreditCardAmount":0,"totalDrawerAmount":239.69,"startDrawerAmount":239.69,"totalTransactionsAmount":0,"nextDrawerAmount":239.69,"totalDepositAmount":0,"autoDepositAmount":0,"depositInBankAmount":0,"cashSalesAmount":46.87,"refundsDepositsAmount":-46.87,"uncollectedCashAmount":0,"netCashFromInvoices":0,"depositsTakenAmount":0,"refundsNotGivenAmount":0,"interLocCashAmount":0,"totalCashTranAmount":0,"depositCashToBank":0,"depositChecksToBank":0,"depositCreditCardSlipsToBank":0,"bankDepositDate":"2024-05-22","postedToGL":"Y","postedToGLDate":"2024-05-22","postedToGLTime":"23:59:59","drawerOverUnderAmount":0,"user":"CWLEZEN","systemDate":"2024-05-22","systemTime":"23:59:59","maintByUser":"CWLEZEN","invoiceNumber":"CDEP-925120","wireTransferAmount":0,"autoRoaDepositAmount":0,"roaAmount":0,"totalRoaChecksAmount":0,"depositRoaCashToBank":0,"depositRoaChecksToBank":0,"depositRoaCrdCardSlipsToBank":0,"totalRoaCurrencyAmount":0,"totalRoaCreditCardAmount":0},"currencyDenominationDetails":[{"denomination":5,"amount":0,"description":"Amount $100 Bills","currencyCode":"","exchangeRate":1},{"denomination":50,"amount":0,"description":"Amount $50 Bills","currencyCode":"","exchangeRate":1}],"creditCardDetails":[{"creditCard":"A","autoDeposit":"Y","amount":0,"GLAccountNumber":"0099990653005100","description":"*AMEX PAYMENT","currencyCode":"USD","exchangeRate":1},{"creditCard":"AR","autoDeposit":"Y","amount":0,"GLAccountNumber":"0099990653005100","description":"*ROA-AMEX PAYMENT","currencyCode":"USD","exchangeRate":1}]}';
            string jsonString5 = '{"companyCode":"01","branchLocNumber":"0653","fromDate":"2024-06-10","fromTime":"23:59:59","toDate":"2024-06-10","toTime":"23:59:59","cashDrawerDetails":{"totalCurrencyAmount":239.69,"totalChecksAmount":0,"totalCreditCardAmount":0,"totalDrawerAmount":239.69,"startDrawerAmount":239.69,"totalTransactionsAmount":0,"nextDrawerAmount":239.69,"totalDepositAmount":0,"autoDepositAmount":0,"depositInBankAmount":0,"cashSalesAmount":46.87,"refundsDepositsAmount":-46.87,"uncollectedCashAmount":0,"netCashFromInvoices":0,"depositsTakenAmount":0,"refundsNotGivenAmount":0,"interLocCashAmount":0,"totalCashTranAmount":0,"depositCashToBank":0,"depositChecksToBank":0,"depositCreditCardSlipsToBank":0,"bankDepositDate":"2024-05-22","postedToGL":"Y","postedToGLDate":"2024-05-22","postedToGLTime":"23:59:59","drawerOverUnderAmount":0,"user":"CWLEZEN","systemDate":"2024-05-22","systemTime":"23:59:59","maintByUser":"CWLEZEN","invoiceNumber":"CDEP-925120","wireTransferAmount":0,"autoRoaDepositAmount":0,"roaAmount":0,"totalRoaChecksAmount":0,"depositRoaCashToBank":0,"depositRoaChecksToBank":0,"depositRoaCrdCardSlipsToBank":0,"totalRoaCurrencyAmount":0,"totalRoaCreditCardAmount":0},"currencyDenominationDetails":[{"denomination":2,"amount":0,"description":"Amount $100 Bills","currencyCode":"","exchangeRate":1},{"denomination":50,"amount":0,"description":"Amount $50 Bills","currencyCode":"","exchangeRate":1}],"creditCardDetails":[{"creditCard":"A","autoDeposit":"Y","amount":0,"GLAccountNumber":"0099990653005100","description":"*AMEX PAYMENT","currencyCode":"USD","exchangeRate":1},{"creditCard":"AR","autoDeposit":"Y","amount":0,"GLAccountNumber":"0099990653005100","description":"*ROA-AMEX PAYMENT","currencyCode":"USD","exchangeRate":1}]}';
            string jsonString6 = '{"companyCode":"01","branchLocNumber":"0653","fromDate":"2024-06-10","fromTime":"23:59:59","toDate":"2024-06-10","toTime":"23:59:59","cashDrawerDetails":{"totalCurrencyAmount":239.69,"totalChecksAmount":0,"totalCreditCardAmount":0,"totalDrawerAmount":239.69,"startDrawerAmount":239.69,"totalTransactionsAmount":0,"nextDrawerAmount":239.69,"totalDepositAmount":0,"autoDepositAmount":0,"depositInBankAmount":0,"cashSalesAmount":46.87,"refundsDepositsAmount":-46.87,"uncollectedCashAmount":0,"netCashFromInvoices":0,"depositsTakenAmount":0,"refundsNotGivenAmount":0,"interLocCashAmount":0,"totalCashTranAmount":0,"depositCashToBank":0,"depositChecksToBank":0,"depositCreditCardSlipsToBank":0,"bankDepositDate":"2024-05-22","postedToGL":"Y","postedToGLDate":"2024-05-22","postedToGLTime":"23:59:59","drawerOverUnderAmount":0,"user":"CWLEZEN","systemDate":"2024-05-22","systemTime":"23:59:59","maintByUser":"CWLEZEN","invoiceNumber":"CDEP-925120","wireTransferAmount":0,"autoRoaDepositAmount":0,"roaAmount":0,"totalRoaChecksAmount":0,"depositRoaCashToBank":0,"depositRoaChecksToBank":0,"depositRoaCrdCardSlipsToBank":0,"totalRoaCurrencyAmount":0,"totalRoaCreditCardAmount":0},"currencyDenominationDetails":[{"denomination":1,"amount":0,"description":"Amount $100 Bills","currencyCode":"","exchangeRate":1},{"denomination":50,"amount":0,"description":"Amount $50 Bills","currencyCode":"","exchangeRate":1}],"creditCardDetails":[{"creditCard":"A","autoDeposit":"Y","amount":0,"GLAccountNumber":"0099990653005100","description":"*AMEX PAYMENT","currencyCode":"USD","exchangeRate":1},{"creditCard":"AR","autoDeposit":"Y","amount":0,"GLAccountNumber":"0099990653005100","description":"*ROA-AMEX PAYMENT","currencyCode":"USD","exchangeRate":1}]}';
            string jsonString7 = '{"companyCode":"01","branchLocNumber":"0653","fromDate":"2024-06-10","fromTime":"23:59:59","toDate":"2024-06-10","toTime":"23:59:59","cashDrawerDetails":{"totalCurrencyAmount":239.69,"totalChecksAmount":0,"totalCreditCardAmount":0,"totalDrawerAmount":239.69,"startDrawerAmount":239.69,"totalTransactionsAmount":0,"nextDrawerAmount":239.69,"totalDepositAmount":0,"autoDepositAmount":0,"depositInBankAmount":0,"cashSalesAmount":46.87,"refundsDepositsAmount":-46.87,"uncollectedCashAmount":0,"netCashFromInvoices":0,"depositsTakenAmount":0,"refundsNotGivenAmount":0,"interLocCashAmount":0,"totalCashTranAmount":0,"depositCashToBank":0,"depositChecksToBank":0,"depositCreditCardSlipsToBank":0,"bankDepositDate":"2024-05-22","postedToGL":"Y","postedToGLDate":"2024-05-22","postedToGLTime":"23:59:59","drawerOverUnderAmount":0,"user":"CWLEZEN","systemDate":"2024-05-22","systemTime":"23:59:59","maintByUser":"CWLEZEN","invoiceNumber":"CDEP-925120","wireTransferAmount":0,"autoRoaDepositAmount":0,"roaAmount":0,"totalRoaChecksAmount":0,"depositRoaCashToBank":0,"depositRoaChecksToBank":0,"depositRoaCrdCardSlipsToBank":0,"totalRoaCurrencyAmount":0,"totalRoaCreditCardAmount":0},"currencyDenominationDetails":[{"denomination":1,"amount":0,"description":"Amount 100 Bills","currencyCode":"","exchangeRate":1},{"denomination":50,"amount":0,"description":"Amount $50 Bills","currencyCode":"","exchangeRate":1}],"creditCardDetails":[{"creditCard":"A","autoDeposit":"Y","amount":0,"GLAccountNumber":"0099990653005100","description":"*AMEX PAYMENT","currencyCode":"USD","exchangeRate":1},{"creditCard":"AR","autoDeposit":"Y","amount":0,"GLAccountNumber":"0099990653005100","description":"*ROA-AMEX PAYMENT","currencyCode":"USD","exchangeRate":1}]}';
            string jsonString8 = '{"companyCode":"01","branchLocNumber":"0653","fromDate":"2024-06-10","fromTime":"23:59:59","toDate":"2024-06-10","toTime":"23:59:59","cashDrawerDetails":{"totalCurrencyAmount":239.69,"totalChecksAmount":0,"totalCreditCardAmount":0,"totalDrawerAmount":239.69,"startDrawerAmount":239.69,"totalTransactionsAmount":0,"nextDrawerAmount":239.69,"totalDepositAmount":0,"autoDepositAmount":0,"depositInBankAmount":0,"cashSalesAmount":46.87,"refundsDepositsAmount":-46.87,"uncollectedCashAmount":0,"netCashFromInvoices":0,"depositsTakenAmount":0,"refundsNotGivenAmount":0,"interLocCashAmount":0,"totalCashTranAmount":0,"depositCashToBank":0,"depositChecksToBank":0,"depositCreditCardSlipsToBank":0,"bankDepositDate":"2024-05-22","postedToGL":"Y","postedToGLDate":"2024-05-22","postedToGLTime":"23:59:59","drawerOverUnderAmount":0,"user":"CWLEZEN","systemDate":"2024-05-22","systemTime":"23:59:59","maintByUser":"CWLEZEN","invoiceNumber":"CDEP-925120","wireTransferAmount":0,"autoRoaDepositAmount":0,"roaAmount":0,"totalRoaChecksAmount":0,"depositRoaCashToBank":0,"depositRoaChecksToBank":0,"depositRoaCrdCardSlipsToBank":0,"totalRoaCurrencyAmount":0,"totalRoaCreditCardAmount":0},"currencyDenominationDetails":[{"denomination":0.5,"amount":0,"description":"Amount 100 Bills","currencyCode":"","exchangeRate":1},{"denomination":50,"amount":0,"description":"Amount $50 Bills","currencyCode":"","exchangeRate":1}],"creditCardDetails":[{"creditCard":"A","autoDeposit":"Y","amount":0,"GLAccountNumber":"0099990653005100","description":"*AMEX PAYMENT","currencyCode":"USD","exchangeRate":1},{"creditCard":"AR","autoDeposit":"Y","amount":0,"GLAccountNumber":"0099990653005100","description":"*ROA-AMEX PAYMENT","currencyCode":"USD","exchangeRate":1}]}';
            string jsonString9 = '{"companyCode":"01","branchLocNumber":"0653","fromDate":"2024-06-10","fromTime":"23:59:59","toDate":"2024-06-10","toTime":"23:59:59","cashDrawerDetails":{"totalCurrencyAmount":239.69,"totalChecksAmount":0,"totalCreditCardAmount":0,"totalDrawerAmount":239.69,"startDrawerAmount":239.69,"totalTransactionsAmount":0,"nextDrawerAmount":239.69,"totalDepositAmount":0,"autoDepositAmount":0,"depositInBankAmount":0,"cashSalesAmount":46.87,"refundsDepositsAmount":-46.87,"uncollectedCashAmount":0,"netCashFromInvoices":0,"depositsTakenAmount":0,"refundsNotGivenAmount":0,"interLocCashAmount":0,"totalCashTranAmount":0,"depositCashToBank":0,"depositChecksToBank":0,"depositCreditCardSlipsToBank":0,"bankDepositDate":"2024-05-22","postedToGL":"Y","postedToGLDate":"2024-05-22","postedToGLTime":"23:59:59","drawerOverUnderAmount":0,"user":"CWLEZEN","systemDate":"2024-05-22","systemTime":"23:59:59","maintByUser":"CWLEZEN","invoiceNumber":"CDEP-925120","wireTransferAmount":0,"autoRoaDepositAmount":0,"roaAmount":0,"totalRoaChecksAmount":0,"depositRoaCashToBank":0,"depositRoaChecksToBank":0,"depositRoaCrdCardSlipsToBank":0,"totalRoaCurrencyAmount":0,"totalRoaCreditCardAmount":0},"currencyDenominationDetails":[{"denomination":0.25,"amount":0,"description":"Amount 100 Bills","currencyCode":"","exchangeRate":1},{"denomination":50,"amount":0,"description":"Amount $50 Bills","currencyCode":"","exchangeRate":1}],"creditCardDetails":[{"creditCard":"A","autoDeposit":"Y","amount":0,"GLAccountNumber":"0099990653005100","description":"*AMEX PAYMENT","currencyCode":"USD","exchangeRate":1},{"creditCard":"AR","autoDeposit":"Y","amount":0,"GLAccountNumber":"0099990653005100","description":"*ROA-AMEX PAYMENT","currencyCode":"USD","exchangeRate":1}]}';
            string jsonString10 = '{"companyCode":"01","branchLocNumber":"0653","fromDate":"2024-06-10","fromTime":"23:59:59","toDate":"2024-06-10","toTime":"23:59:59","cashDrawerDetails":{"totalCurrencyAmount":239.69,"totalChecksAmount":0,"totalCreditCardAmount":0,"totalDrawerAmount":239.69,"startDrawerAmount":239.69,"totalTransactionsAmount":0,"nextDrawerAmount":239.69,"totalDepositAmount":0,"autoDepositAmount":0,"depositInBankAmount":0,"cashSalesAmount":46.87,"refundsDepositsAmount":-46.87,"uncollectedCashAmount":0,"netCashFromInvoices":0,"depositsTakenAmount":0,"refundsNotGivenAmount":0,"interLocCashAmount":0,"totalCashTranAmount":0,"depositCashToBank":0,"depositChecksToBank":0,"depositCreditCardSlipsToBank":0,"bankDepositDate":"2024-05-22","postedToGL":"Y","postedToGLDate":"2024-05-22","postedToGLTime":"23:59:59","drawerOverUnderAmount":0,"user":"CWLEZEN","systemDate":"2024-05-22","systemTime":"23:59:59","maintByUser":"CWLEZEN","invoiceNumber":"CDEP-925120","wireTransferAmount":0,"autoRoaDepositAmount":0,"roaAmount":0,"totalRoaChecksAmount":0,"depositRoaCashToBank":0,"depositRoaChecksToBank":0,"depositRoaCrdCardSlipsToBank":0,"totalRoaCurrencyAmount":0,"totalRoaCreditCardAmount":0},"currencyDenominationDetails":[{"denomination":0.10,"amount":0,"description":"Amount 100 Bills","currencyCode":"","exchangeRate":1},{"denomination":50,"amount":0,"description":"Amount $50 Bills","currencyCode":"","exchangeRate":1}],"creditCardDetails":[{"creditCard":"A","autoDeposit":"Y","amount":0,"GLAccountNumber":"0099990653005100","description":"*AMEX PAYMENT","currencyCode":"USD","exchangeRate":1},{"creditCard":"AR","autoDeposit":"Y","amount":0,"GLAccountNumber":"0099990653005100","description":"*ROA-AMEX PAYMENT","currencyCode":"USD","exchangeRate":1}]}';
            string jsonString11 = '{"companyCode":"01","branchLocNumber":"0653","fromDate":"2024-06-10","fromTime":"23:59:59","toDate":"2024-06-10","toTime":"23:59:59","cashDrawerDetails":{"totalCurrencyAmount":239.69,"totalChecksAmount":0,"totalCreditCardAmount":0,"totalDrawerAmount":239.69,"startDrawerAmount":239.69,"totalTransactionsAmount":0,"nextDrawerAmount":239.69,"totalDepositAmount":0,"autoDepositAmount":0,"depositInBankAmount":0,"cashSalesAmount":46.87,"refundsDepositsAmount":-46.87,"uncollectedCashAmount":0,"netCashFromInvoices":0,"depositsTakenAmount":0,"refundsNotGivenAmount":0,"interLocCashAmount":0,"totalCashTranAmount":0,"depositCashToBank":0,"depositChecksToBank":0,"depositCreditCardSlipsToBank":0,"bankDepositDate":"2024-05-22","postedToGL":"Y","postedToGLDate":"2024-05-22","postedToGLTime":"23:59:59","drawerOverUnderAmount":0,"user":"CWLEZEN","systemDate":"2024-05-22","systemTime":"23:59:59","maintByUser":"CWLEZEN","invoiceNumber":"CDEP-925120","wireTransferAmount":0,"autoRoaDepositAmount":0,"roaAmount":0,"totalRoaChecksAmount":0,"depositRoaCashToBank":0,"depositRoaChecksToBank":0,"depositRoaCrdCardSlipsToBank":0,"totalRoaCurrencyAmount":0,"totalRoaCreditCardAmount":0},"currencyDenominationDetails":[{"denomination":0.05,"amount":0,"description":"Amount 100 Bills","currencyCode":"","exchangeRate":1},{"denomination":50,"amount":0,"description":"Amount $50 Bills","currencyCode":"","exchangeRate":1}],"creditCardDetails":[{"creditCard":"A","autoDeposit":"Y","amount":0,"GLAccountNumber":"0099990653005100","description":"*AMEX PAYMENT","currencyCode":"USD","exchangeRate":1},{"creditCard":"AR","autoDeposit":"Y","amount":0,"GLAccountNumber":"0099990653005100","description":"*ROA-AMEX PAYMENT","currencyCode":"USD","exchangeRate":1}]}';
            string jsonString12 = '{"companyCode":"01","branchLocNumber":"0653","fromDate":"2024-06-10","fromTime":"23:59:59","toDate":"2024-06-10","toTime":"23:59:59","cashDrawerDetails":{"totalCurrencyAmount":239.69,"totalChecksAmount":0,"totalCreditCardAmount":0,"totalDrawerAmount":239.69,"startDrawerAmount":239.69,"totalTransactionsAmount":0,"nextDrawerAmount":239.69,"totalDepositAmount":0,"autoDepositAmount":0,"depositInBankAmount":0,"cashSalesAmount":46.87,"refundsDepositsAmount":-46.87,"uncollectedCashAmount":0,"netCashFromInvoices":0,"depositsTakenAmount":0,"refundsNotGivenAmount":0,"interLocCashAmount":0,"totalCashTranAmount":0,"depositCashToBank":0,"depositChecksToBank":0,"depositCreditCardSlipsToBank":0,"bankDepositDate":"2024-05-22","postedToGL":"Y","postedToGLDate":"2024-05-22","postedToGLTime":"23:59:59","drawerOverUnderAmount":0,"user":"CWLEZEN","systemDate":"2024-05-22","systemTime":"23:59:59","maintByUser":"CWLEZEN","invoiceNumber":"CDEP-925120","wireTransferAmount":0,"autoRoaDepositAmount":0,"roaAmount":0,"totalRoaChecksAmount":0,"depositRoaCashToBank":0,"depositRoaChecksToBank":0,"depositRoaCrdCardSlipsToBank":0,"totalRoaCurrencyAmount":0,"totalRoaCreditCardAmount":0},"currencyDenominationDetails":[{"denomination":0.01,"amount":0,"description":"Amount 100 Bills","currencyCode":"","exchangeRate":1},{"denomination":50,"amount":0,"description":"Amount $50 Bills","currencyCode":"","exchangeRate":1}],"creditCardDetails":[{"creditCard":"A","autoDeposit":"Y","amount":0,"GLAccountNumber":"0099990653005100","description":"*AMEX PAYMENT","currencyCode":"USD","exchangeRate":1},{"creditCard":"AR","autoDeposit":"Y","amount":0,"GLAccountNumber":"0099990653005100","description":"*ROA-AMEX PAYMENT","currencyCode":"USD","exchangeRate":1}]}';
            
            Id eodTillId = Sbr_3_0_endOfDayTillController.insertEndOfDayTillRecords(jsonString,'');
            Id eodTillId1 = Sbr_3_0_endOfDayTillController.insertEndOfDayTillRecords(jsonString1,'');
            Id eodTillId2 = Sbr_3_0_endOfDayTillController.insertEndOfDayTillRecords(jsonString2,'');
            Id eodTillId3 = Sbr_3_0_endOfDayTillController.insertEndOfDayTillRecords(jsonString3,'');
            Id eodTillId4 = Sbr_3_0_endOfDayTillController.insertEndOfDayTillRecords(jsonString4,'');
            Id eodTillId5 = Sbr_3_0_endOfDayTillController.insertEndOfDayTillRecords(jsonString5,''); 
            Id eodTillId6 = Sbr_3_0_endOfDayTillController.insertEndOfDayTillRecords(jsonString6,'');
            Id eodTillId7 = Sbr_3_0_endOfDayTillController.insertEndOfDayTillRecords(jsonString7,'');
            Id eodTillId8 = Sbr_3_0_endOfDayTillController.insertEndOfDayTillRecords(jsonString8,'');
            Id eodTillId9 = Sbr_3_0_endOfDayTillController.insertEndOfDayTillRecords(jsonString9,'');
            Id eodTillId10 = Sbr_3_0_endOfDayTillController.insertEndOfDayTillRecords(jsonString10,'');
            Id eodTillId11 = Sbr_3_0_endOfDayTillController.insertEndOfDayTillRecords(jsonString11,''); 
            Id eodTillId12 = Sbr_3_0_endOfDayTillController.insertEndOfDayTillRecords(jsonString12,'');
            System.assertNotEquals(null, eodTillId, 'eodTillId12 cant be null');
            System.assertNotEquals(null, eodTillId1, 'eodTillId12 cant be null');
            System.assertNotEquals(null, eodTillId2, 'eodTillId12 cant be null');
            System.assertNotEquals(null, eodTillId3, 'eodTillId12 cant be null');
            System.assertNotEquals(null, eodTillId4, 'eodTillId12 cant be null');
            System.assertNotEquals(null, eodTillId5, 'eodTillId12 cant be null');
            System.assertNotEquals(null, eodTillId6, 'eodTillId12 cant be null');
            System.assertNotEquals(null, eodTillId7, 'eodTillId12 cant be null');
            System.assertNotEquals(null, eodTillId8, 'eodTillId12 cant be null');
            System.assertNotEquals(null, eodTillId9, 'eodTillId12 cant be null');
            System.assertNotEquals(null, eodTillId10, 'eodTillId12 cant be null');
            System.assertNotEquals(null, eodTillId11, 'eodTillId12 cant be null');
            System.assertNotEquals(null, eodTillId12, 'eodTillId12 cant be null');
            Sbr_3_0_endOfDayTillController.getReasonRecordsById(eodTillId);
            Id tillDetailId = Sbr_3_0_endOfDayTillController.insertTillDetailRecords(eodTillId);
            String getNewDepositsResponseString = '[{"contractNumber":149101217,"invSeqNumber":1,"payType":"A","amountInContractCurrency":300,"user":"WEBTEMP","systemDate":"2024-05-24","systemTime":"23:00:00","dlSt":"PA","driversLicNumber":"30545916","sortType":"1","contractCurrency":"USD"},{"contractNumber":1401217,"invSeqNumber":1,"payType":"A","amountInContractCurrency":300,"user":"WEBTEMP","systemDate":"2024-05-24","systemTime":"23:00:00","dlSt":"PA","driversLicNumber":"30545916","sortType":"1","contractCurrency":"USD"}]';
            String getCashInvoiceResponseString = '[{"contractNumber":83912283,"invSeqNumber":1,"user":"JCOCKERILL","invoiceAmount":100,"appliedDeposit":80,"netCashReceived":100,"otherAmount":100},{"contractNumber":83912284,"invSeqNumber":2,"user":"JCOCKERILLI","invoiceAmount":150,"appliedDeposit":60,"netCashReceived":90,"otherAmount":10}]';
            
            End_of_Day_Till__c tilrec = new End_of_Day_Till__c();
            tilrec.Till_Date__c =  Date.valueof('2024-04-16');
            tilrec.Total_Currency__c = 12.00;
            tilrec.Total_Checks__c = 122.00;
            tilrec.Total_ROA_Checks__c = 112.00;
            tilrec.Total_Deposit_in_Bank__c = 312.00;
            tilrec.Status__c = 'Draft';
            tilrec.Compound_Key__c = 'test';
            Sbr_3_0_endOfDayTillController.upsertTillRecord(tilrec);
            
            Till_Detail__c tilldetail= new Till_Detail__c();
            tilldetail.End_of_Day_Till__c = tilrec.Id;
            tilldetail.Compound_Key__c = 'test';
            insert tilldetail;
            String recordTypeIdNewDeposit = Schema.SObjectType.Till_New_Deposit_Detail__c.getRecordTypeInfosByName().get('New Deposit').getRecordTypeId();
            List<Till_New_Deposit_Detail__c> testCashDetails = new List<Till_New_Deposit_Detail__c>();
            testCashDetails.add(new Till_New_Deposit_Detail__c(Name = 'Test Detail 1',  Amount__c = 100, Till_Detail__c=tilldetail.Id,Compound_Key__c = 'null-Rentalman-149101217-1',recordtypeid = recordTypeIdNewDeposit));
            insert testCashDetails;
            
            List<Till_New_Payment_Detail__c> testOtherLocationDetails = new List<Till_New_Payment_Detail__c>();
            String recordTypeInvoice = Schema.SObjectType.Till_New_Payment_Detail__c.getRecordTypeInfosByName().get('Invoice').getRecordTypeId();
            testOtherLocationDetails.add(new Till_New_Payment_Detail__c(
                Name = 'Test Payment Detail 1',
                Invoice_Number__c = '897548479',
                Location__c = 'Location1',
                SR__c = 'R1',
                Invoice_Amount__c = 150.00,
                Applied_Deposit__c = 50.00,
                Net_Cash_Received__c = 100.00,
                Other_Amount__c = 20.00,
                Till_Detail__c = tilldetail.Id,
                RecordTypeId = recordTypeInvoice,
                Compound_Key__c = 'null-Rentalman-83912284-2'
            ));
            testOtherLocationDetails.add(new Till_New_Payment_Detail__c(
                Name = 'Test Payment Detail 2',
                Invoice_Number__c = '897548478',
                Location__c = 'Location2',
                SR__c = 'R3',
                Invoice_Amount__c = 250.00,
                Applied_Deposit__c = 70.00,
                Net_Cash_Received__c = 180.00,
                Other_Amount__c = 30.00,
                Till_Detail__c = tilldetail.Id,
                RecordTypeId = recordTypeInvoice
            ));
            
            insert testOtherLocationDetails;
            
            List<Till_ROA_Detail__c> testROADetails = new List<Till_ROA_Detail__c>();
            testROADetails.add(new Till_ROA_Detail__c(
                Name = 'Test ROA Detail 1',
                Payment_ID__c = 67765,
                Location__c = 'Location1',
                Amount__c = 100.00,
                Wynne_User__c = 'User1',
                Invoice_or_Comment__c = '123456787',
                Till_Detail__c = tilldetail.Id,
                Compound_Key__c = 'null-Rentalman-8106149'
            ));
            insert testROADetails;
            
            // Insert test data
            
            Sbr_3_0_endOfDayTillController.insertcashInvoiceOrIntercompanyRecord(getCashInvoiceResponseString,tillDetailId,'Invoice');
            String getCashROAControlString = '[{"companyCode":"01","branchLocNumber":"0840","dateYyyymmdd":"2024-06-10","transactionNumber":114779,"timeHhmmss":"23:00:00","accountNumber":696567,"checkNumber":"M20201013","miscNotes":"CONCUR OVERPAYMENT","payType":"K","transactionAmount":3000,"createdBy":"MROCK","systemDate":"2024-05-24","systemTime":"23:00:00","postedToAR":"Y","lastMaintBy":"SBTEST","lastMaintDate":"2024-05-24","lastMaintTime":"23:00:00","transactionId":"8106149","cardHolder":"JOHN SMITH","referenceNumber":"XXXXXXXXXXXX0225","authorizeNumber":"159159","expDate":"2024-05-24","authorizedAmount":70228,"status":"T","depositCurrency":"USD","depositExchangeRate":1,"amountInDepositCurrency":3000,"creditedAmount":201.41},{"companyCode":"01","branchLocNumber":"0840","dateYyyymmdd":"2024-06-10","transactionNumber":114779,"timeHhmmss":"23:00:00","accountNumber":696567,"checkNumber":"M20201013","miscNotes":"CONCUR OVERPAYMENT","payType":"K","transactionAmount":3000,"createdBy":"MROCK","systemDate":"2024-05-24","systemTime":"23:00:00","postedToAR":"Y","lastMaintBy":"SBTEST","lastMaintDate":"2024-05-24","lastMaintTime":"23:00:00","transactionId":"810649","cardHolder":"JOHN SMITH","referenceNumber":"XXXXXXXXXXXX0225","authorizeNumber":"159159","expDate":"2024-05-24","authorizedAmount":70228,"status":"T","depositCurrency":"USD","depositExchangeRate":1,"amountInDepositCurrency":3000,"creditedAmount":201.41}]';        Sbr_3_0_endOfDayTillController.insertTillROADetailRecord(getCashROAControlString,tillDetailId);
            Sbr_3_0_endOfDayTillController.insertTillNewDepositRecord(getNewDepositsResponseString, tillDetailId,'New Deposit');
        }
    }
    
    @isTest
    static void testgetUserLocationInfo(){
        User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(ersu){
            try{
                // User user = new User(
                //     Username = 'testuser12@example.com',
                //     Alias = 'testus12',
                //     Email = 'testuser12@example.com',
                //     EmailEncodingKey = 'UTF-8',
                //     LastName = 'Test',
                //     LanguageLocaleKey = 'en_US',
                //     LocaleSidKey = 'en_US',
                //     ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
                //     TimeZoneSidKey = 'America/Los_Angeles',
                //     CompanyName = 'Test Company',
                //     Department = 'Test Department',
                //     Wynne_User_Name__c = 'TestWynneUser'
                // );
                // insert user;
                List<User_Location__c> userLocationList= Sbr_3_0_endOfDayTillController.getUserLocationInfo(ersu.Id);
                System.assertNotEquals(null, userLocationList , 'userLocationList cant be null');
            }catch(Exception e){
                SBR_3_0_Log.logException(e);
            }
        }
    }
    
    @isTest
    static void testgetEodTillRecord(){
        User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(ersu){
            End_of_Day_Till__c tilrec = new End_of_Day_Till__c();
            tilrec.Till_Date__c =  Date.valueof('2024-04-16');
            tilrec.Total_Currency__c = 12.00;
            tilrec.Total_Checks__c = 122.00;
            tilrec.Total_ROA_Checks__c = 112.00;
            tilrec.Total_Deposit_in_Bank__c = 312.00;
            tilrec.Status__c = 'Draft';
            insert tilrec;
            
            List<Till_Over_Short_Reason__c> reasonlist = new List<Till_Over_Short_Reason__c>();
            Till_Over_Short_Reason__c reasonrec = new Till_Over_Short_Reason__c();
            reasonrec.Amount__c = 100;
            reasonrec.Comment__c = 'Test reason rec';
            reasonrec.CurrencyIsoCode = 'USD';
            reasonrec.Reason__c = 'Short';
            reasonrec.End_of_Day_Till__c = tilrec.Id;
            reasonlist.add(reasonrec);
            String validReasonsJson = JSON.serialize(reasonlist);
            System.assertNotEquals(null,validReasonsJson, 'validReasonsJson cant be null');
            test.startTest();
            String ids = Sbr_3_0_endOfDayTillController.upsertTillRecord(tilrec);
            End_of_Day_Till__c tilrecords = Sbr_3_0_endOfDayTillController.getEodTillRecord(tilrec.Id);
            End_of_Day_Till__c tilrecord =  Sbr_3_0_endOfDayTillController.fetchCurrencies(tilrec.Id);
            test.stopTest();
            
            System.assertEquals(tilrec.Id, ids,'till record present');
            System.assertEquals(tilrecords.Id, tilrec.Id,'till record present');
            System.assertEquals(tilrecord.Id, tilrec.Id,'till record present');
        }
    }
    
    @isTest
    static void tesgetCustomSettingDays01(){
        User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(ersu) {
            test.startTest();
            EODT_Overdue_Dates__c setting = new EODT_Overdue_Dates__c();
            setting.Number_Of_Days__c = '5';
            insert setting;
            Integer Days = Sbr_3_0_endOfDayTillController.getCustomSettingDays();
            test.stopTest();
            Assert.areEqual(Integer.ValueOf(setting.Number_Of_Days__c), Days);
            
        }
    }
    @isTest
    static void tesgetCustomSettingDays02(){
        User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(ersu) {
            test.startTest();
            Date today = Date.today();
            Date sixMonthsAgo = today.addMonths(-6);
            // Calculate Last 6 Month days || the number of days between the two dates, inclusive
            Integer days = today.daysBetween(sixMonthsAgo) + 1;
            Integer numberOfDays = Integer.valueOf(String.valueOf(days).substring(1));
            Integer returnDays = Sbr_3_0_endOfDayTillController.getCustomSettingDays();
            test.stopTest();
			Assert.areEqual(numberOfDays, returnDays);
        }
    }
}