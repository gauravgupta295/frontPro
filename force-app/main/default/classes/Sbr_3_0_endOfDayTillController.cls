/*********************************************************************************************************************
* Apex Class: Sbr_3_0_endOfDayTillController
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:@description This class is written to perform EOD Functionality
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
     1          Vivek Kumar Sharma     11-03-2024           
     2          Kavita                 11-03-2024
*********************************************************************************************************************/
@SuppressWarnings('PMD.CyclomaticComplexity,PMD.NcssMethodCount,PMD.ExcessiveClassLength,PMD.CognitiveComplexity,PMD.StdCyclomaticComplexity,PMD.ExcessivePublicCount')
public with sharing class Sbr_3_0_endOfDayTillController {

    /**
    * Author: Vivek/Kavita
    * Method Name: getEndOfTillRecord
    * @description Retrieves the End of Day Till record for the specified tillDate.
    * @param tillDate The date for which to retrieve the End of Day Till record.
    * @param compoundKey Unique compound key to identify the End_of_Day_Till__c record.
    * @return End_of_Day_Till__c object representing the End of Day Till record for the specified date, or null if none found.
    */
    @AuraEnabled(cacheable=false)
    public static End_of_Day_Till__c getEndOfTillRecord(Date tillDate,String compoundKey){
        List<End_of_Day_Till__c> records = new List<End_of_Day_Till__c>();
        try {
            records = [SELECT id, Total_Cash__c, Till_Date__c, Total_Currency__c, Total_Checks__c, Total_ROA_Checks__c, 
                Total_Deposit_in_Bank__c, Owner.name,Status__c,Till_Status__c,
                Submitted_Date__c,LastModifiedBy.Alias,Start_Drawer__c,Next_Day_Drawer__c,Submitted_User__r.Alias,Adjustments_Accounted_For__c,Total_ROA_Cash__c
                FROM End_of_Day_Till__c WHERE Till_Date__c =:tillDate and Compound_Key__c =:compoundKey WITH SECURITY_ENFORCED LIMIT 1];

        } catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        // In case of exception or no record found, records will remain empty
    
        if (records!=null && !records.isEmpty()) {
            return records[0];
        // If records is not empty, return the first record
        }
        // No records fetched or an error occurred, return null
        return null;
    }

    /**
    * Author: Vivek/Kavita
    * Method Name: getEodTillRecord
    * @description Retrieves the End of Day Till record for the specified recordId.
    * @param recordId The ID of the End of Day Till record to retrieve.
    * @return End_of_Day_Till__c object representing the End of Day Till record for the specified ID, or null if none found.
    */
    @AuraEnabled(cacheable=false)
    public static End_of_Day_Till__c getEodTillRecord(String recordId){
        List<End_of_Day_Till__c> records = new List<End_of_Day_Till__c>();
        try {
            SBR_3_0_Log.setRelatedRecordId(recordId);
            records = [SELECT id, Total_Cash__c,Till_Status__c, Till_Date__c, Total_Currency__c, Total_Checks__c, Total_ROA_Checks__c, 
                Total_Deposit_in_Bank__c, Owner.name,Total_Drawer__c,
                Submitted_Date__c,LastModifiedBy.Alias,Start_Drawer__c,Next_Day_Drawer__c,Submitted_User__r.Alias,Adjustments_Accounted_For__c,
                Drawer_Bills_Hundred__c,Drawer_Bills_Fifty__c,Drawer_Bills_Twenty__c,Drawer_Bills_Ten__c,Drawer_Bills_Five__c,
                Drawer_Bills_Two__c,Drawer_Bills_One__c,Drawer_Coins_One__c,Drawer_Coins_Fifty__c,Drawer_Coins_Quarter__c,Drawer_Coins_Dime__c,
                Drawer_Coins_Nickel__c,Drawer_Coins_Penny__c,Status__c,
                Total_Credit_Cards__c,Total_Transaction__c,Total_Deposit__c,Less_Auto_Deposit__c,Less_ROA__c,Received_on_Charge_Account__c,
                Cash_Sales__c,Deposits_Applied_Refunded__c,Uncollected__c,Wire_Transfer__c,Net_Cash_From_Invoice__c,Deposits_Taken__c,
                Refunds_Not_Given__c,Inter_Location_Cash__c,Total_Transactions_System__c, Total_Auto_Deposit_Amount__c, Total_ROA_Credit_Card_Amount__c, 
                Total_ROA_Auto_Deposit__c,Accounted_For__c
                FROM End_of_Day_Till__c WHERE Id =:recordId WITH SECURITY_ENFORCED LIMIT 1];

        } catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        // In case of exception or no record found, records will remain empty
    
        if (records!=null && !records.isEmpty()) {
            return records[0];
        // If records is not empty, return the first record
        }
        // No records fetched or an error occurred, return null
        return null;
    }
    
    /**
    * Author: Vivek/Kavita
    * Method Name: getReasonRecordsById
    * @description Retrieves Till Over Short Reason records associated with the specified End of Day Till record ID.
    * @param recordId The ID of the End of Day Till record for which to fetch Till Over Short Reason records.
    * @return List of Till_Over_Short_Reason__c records associated with the specified End of Day Till record ID, or null if none found.
    */
    @AuraEnabled(cacheable=false)
    public static List<Till_Over_Short_Reason__c> getReasonRecordsById(String recordId) {
        try {
            SBR_3_0_Log.setRelatedRecordId(recordId);
            // Query the records based on the provided ID
            List<Till_Over_Short_Reason__c> records = [SELECT Id, Amount__c, Comment__c, Reason__c, End_of_Day_Till__c
                                                      FROM Till_Over_Short_Reason__c
                                                      WHERE End_of_Day_Till__c = :recordId WITH SECURITY_ENFORCED];
            return records;
        } catch (Exception e) {
            SBR_3_0_Log.logException(e);
            return null; // Return an empty list on error
        } finally {
            SBR_3_0_Log.saveLog();
        } 
    }
    
    /**
    * Author: Vivek/Kavita
    * Method Name: fetchCurrencies
    * @description Retrieves currency details from the End of Day Till record corresponding to the specified tillId.
    * @param tillId The ID of the End of Day Till record for which to fetch currency details.
    * @return End_of_Day_Till__c object representing currency details for the specified End of Day Till record ID, or null if none found.
    */
    @AuraEnabled(cacheable=false)
    public static End_of_Day_Till__c fetchCurrencies(String tillId){
        End_of_Day_Till__c tillrec = new End_of_Day_Till__c();
        try {
            SBR_3_0_Log.setRelatedRecordId(tillId);
            tillrec = [SELECT Drawer_Bills_Hundred__c,Drawer_Bills_Fifty__c,Drawer_Bills_Twenty__c,Drawer_Bills_Ten__c,Drawer_Bills_Five__c,
            Drawer_Bills_Two__c,Drawer_Bills_One__c,Drawer_Coins_One__c,Drawer_Coins_Fifty__c,Drawer_Coins_Quarter__c,Drawer_Coins_Dime__c,
            Drawer_Coins_Nickel__c,Drawer_Coins_Penny__c
            FROM End_of_Day_Till__c WHERE Id =:tillId WITH SECURITY_ENFORCED];

        } catch(Exception e) {
            SBR_3_0_Log.logException(e);
            throw new AuraHandledException(e.getMessage());
        } finally {
            SBR_3_0_Log.saveLog();
        } 
        // In case of exception or no record found, records will remain empty
        if (tillrec != null) {
            return tillrec;
        // If records is not empty, return the first record
        }
        // No records fetched or an error occurred, return null
        return null;
    }
    
    /**
    * Author: Vivek/Kavita
    * Method Name: getDraftEndOfTillRecord
    * @description Retrieves End of Day Till records with 'Submitted' status and submitted within the last 30 days.
    * @return List of End_of_Day_Till__c records meeting the criteria, or an empty list if none found.
    * @param compoundKey Unique compound key to identify the End_of_Day_Till__c record.
    */
    @SuppressWarnings('PMD.ApexSOQLInjection')
    @AuraEnabled(cacheable=false)
    public static list<End_of_Day_Till__c> getDraftEndOfTillRecord(String compoundKey){
        List<End_of_Day_Till__c> tillRecords;
        try { 
             Integer numberOfDays = getCustomSettingDays();
             String queryString = 'SELECT Id, Till_Date__c ' +
                     'FROM End_of_Day_Till__c ' +
                     'WHERE Till_Date__c < TODAY ' +
                     'AND Till_Status__c = \'Submitted\' ' +
                     'AND Till_Date__c >= LAST_N_DAYS:' + numberOfDays + ' ' +
                     'AND Compound_Key__c LIKE \'' + compoundKey + '%\' ' +
                     'WITH SECURITY_ENFORCED';

            // Execute the dynamic query 
            tillRecords = Database.query(queryString); 
        }catch(Exception e){
            SBR_3_0_Log.logException(e);
            throw new AuraHandledException(e.getMessage());
        } finally {
            SBR_3_0_Log.saveLog();
        } 
        return tillRecords;
    }
       
    /**
    * Author: Vikas
    * Method Name: getCustomSettings
    * @description to get EODT value.
    * @return Custom Setting EODT Overdue Dates record.
    */
    @AuraEnabled(cacheable=true) 
    public static Integer getCustomSettingDays(){
        Integer numberOfDays = 0;
        try { 
            EODT_Overdue_Dates__c customSetting =  EODT_Overdue_Dates__c.getOrgDefaults();
            if(customSetting.Number_Of_Days__c  != null ){
                numberOfDays = Integer.valueOf(customSetting.Number_Of_Days__c);
            } else {
                Date today = Date.today();
                Date sixMonthsAgo = today.addMonths(-6);
                // Calculate Last 6 Month days || the number of days between the two dates, inclusive
                Integer days = today.daysBetween(sixMonthsAgo) + 1;
                numberOfDays = Integer.valueOf(String.valueOf(days).substring(1));
            }
        }catch(Exception e){
            SBR_3_0_Log.logException(e);
            throw new AuraHandledException(e.getMessage());
        } finally {
            SBR_3_0_Log.saveLog();
        } 
        return numberOfDays;
    }

    /**
    * Author: Vivek/Kavita
    * Method Name: upsertTillRecord
    * @description Upserts the provided End_of_Day_Till__c record.
    * @param tillrec The End_of_Day_Till__c record to upsert.
    * @return Id of the upserted End_of_Day_Till__c record.
    */
    @SuppressWarnings('PMD.ApexCRUDViolation')
    @AuraEnabled(cacheable=false)
    public static string upsertTillRecord(End_of_Day_Till__c tillrec){
        try {
            upsert tillrec;
            return tillrec.Id;
        } catch (Exception e) {
            Logger.error('The following error has occurred while inserting/updating record.',e.getMessage(),tillrec.Id);
            SBR_3_0_Log.logException(e);
            throw new AuraHandledException('Unable to save record. Please check your permissions and try again.');
        } finally {
            SBR_3_0_Log.saveLog();
        } 
    }
    
    /**
    * Author: Vivek/Kavita
    * Method Name: insertReasons
    * @description Inserts Till Over Short Reason records based on the provided JSON input.
    * @param reasonsInput JSON string representing a list of Till_Over_Short_Reason__c records to insert.
    * @return 'Success' if records are successfully inserted.
    */
    @SuppressWarnings('PMD.ApexCRUDViolation')
    @AuraEnabled(cacheable=false)
    public static string insertReasons(String reasonsInput){
        try {   
            List<Till_Over_Short_Reason__c> reasonList = (List<Till_Over_Short_Reason__c>) JSON.deserialize(
                reasonsInput,
                List<Till_Over_Short_Reason__c>.class
            );
            insert reasonList;
            return 'Success';
        } catch (Exception e) {
            SBR_3_0_Log.logException(e);
            throw new AuraHandledException(e.getMessage());
        } finally {
            SBR_3_0_Log.saveLog();
        } 
    }

    /**
    * Author: Vivek/Kavita
    * Method Name: getOAuthToken
    * @description Retrieves an OAuth2 access token for authentication.
    * @param password Salesforce user password.
    * @param clientId OAuth2 client ID.
    * @param clientSecret OAuth2 client secret.
    * @return String representation of the HTTP response status code.
    */
    @AuraEnabled
    public static String getOAuthToken(String password, String clientId, String clientSecret) {
        try { 
        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        String username = UserInfo.getUserName();
        String endpoint;
        if (baseUrl.contains('sandbox')) {
            endpoint = 'https://test.salesforce.com/services/oauth2/token';
        } else {
            // Production or other environments
            endpoint = 'https://login.salesforce.com/services/oauth2/token';
        }
        
        // Construct the request body
        String requestBody = 'grant_type=password&client_id=' + EncodingUtil.urlEncode(clientId, 'UTF-8') 
                            + '&client_secret=' + EncodingUtil.urlEncode(clientSecret, 'UTF-8')
                            + '&username=' + EncodingUtil.urlEncode(username, 'UTF-8') 
                            + '&password=' + EncodingUtil.urlEncode(password, 'UTF-8');
        
        // Make the HTTP request
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setBody(requestBody);
        
        Http http = new Http();
        HttpResponse res;
        try {
            res = http.send(req);
            SBR_3_0_Log.logAPIDetails(requestBody,res.getBody().toString(),endpoint);
        } catch (CalloutException ex) {
            // Log the error
            SBR_3_0_Log.logException(ex);
            return 'Error while processing:'+ex.getMessage();
        }
        return String.valueOf(res.getStatusCode());
        }catch(Exception e){
            SBR_3_0_Log.logException(e);
            throw new AuraHandledException(e.getMessage());
        } finally {
            SBR_3_0_Log.saveLog();
        } 
    }

    /**
    * Author: Vivek/Kavita
    * Method Name: getCashControlDetails
    * @description Retrieves Till New Deposit Detail records for all record types associated with the specified tillDetailId.
    * @param tillDetailId The ID of the Till_Detail__c record for which to retrieve Till New Deposit Detail records.
    * @return List of Till_New_Deposit_Detail__c records associated with the specified Till_Detail__c ID, or an empty list if none found.
    */
    @AuraEnabled(cacheable=false)
    public static List<Till_New_Deposit_Detail__c> getCashControlDetails(String tillDetailId) {
        try {
            List<Till_New_Deposit_Detail__c> cashDetails = [SELECT Id,Name, Type__c,Contract_Number__c,Invoice_Number__c,Detailed_Sequence_Number__c, Amount__c, Drivers_License__c,SR__c,toLabel(Payment_Method__c),Wynne_User__c 
                                        FROM Till_New_Deposit_Detail__c where Till_Detail__c =: tillDetailId WITH SECURITY_ENFORCED];
            return cashDetails;
        }catch(Exception e){
            SBR_3_0_Log.logException(e);
            throw new AuraHandledException(e.getMessage());
        } finally {
            SBR_3_0_Log.saveLog();
        } 
    }
    
    /**
    * Author: Vivek/Kavita
    * Method Name: getCashROAControlDetails
    * @description Retrieves Till ROA Detail records associated with the specified Till_Detail__c ID.
    * @param tillDetailId The ID of the Till_Detail__c record for which to retrieve Till ROA Detail records.
    * @return List of Till_ROA_Detail__c records associated with the specified Till_Detail__c ID, or an empty list if none found.
    */
    @AuraEnabled(cacheable=false)
    public static List<Till_ROA_Detail__c> getCashROAControlDetails(String tillDetailId) {    
        try {
            List<Till_ROA_Detail__c> cashROADetails = [SELECT Id,Name,Payment_ID__c, Type__c,Location__c,Amount__c,Wynne_User__c,Payment_Method__c,Invoice_or_Comment__c 
                                        FROM Till_ROA_Detail__c where Till_Detail__c =: tillDetailId WITH SECURITY_ENFORCED];
            return cashROADetails;
        }catch(Exception e){
            SBR_3_0_Log.logException(e);
            throw new AuraHandledException(e.getMessage());
        } finally {
            SBR_3_0_Log.saveLog();
        } 
    }

    /**
    * Author: Vivek/Kavita
    * Method Name: getFilteredTillNewDepositDetails
    * @description Retrieves Till New Deposit Detail records of a specific record type associated with the specified Till_Detail__c ID.
    * @param recordTypeName The name of the RecordType to filter Till New Deposit Detail records.
    * @param tillDetailId The ID of the Till_Detail__c record for which to retrieve Till New Deposit Detail records.
    * @return List of Till_New_Deposit_Detail__c records meeting the criteria, or an empty list if none found.
    */
    @AuraEnabled(cacheable=false)
    public static List<Till_New_Deposit_Detail__c> getFilteredTillNewDepositDetails(String recordTypeName, String tillDetailId) {     
        try {                
            List<Till_New_Deposit_Detail__c> depositDetails = [SELECT Id,Name, Invoice_Number__c,Type__c,Contract_Number__c,Detailed_Sequence_Number__c, Amount__c, Drivers_License__c,SR__c,Payment_Method__c,Wynne_User__c 
                                        FROM Till_New_Deposit_Detail__c where recordType.Name =: recordTypeName and  Till_Detail__c =: tillDetailId WITH SECURITY_ENFORCED];
            return depositDetails;
        }catch(Exception e){
            SBR_3_0_Log.logException(e);
            throw new AuraHandledException(e.getMessage());
        } finally {
            SBR_3_0_Log.saveLog();
        } 
    }

    /**
    * Author: Vivek/Kavita
    * Method Name: totalBusinessDetails
    * @description Retrieves Invoice records based on specified invoice date, company code, and profit center.
    * @param invoiceDate The invoice date in format 'yyyy-MM-dd'.
    * @param companyCode The company code associated with the invoices.
    * @param profitCenter The profit center associated with the invoices.
    * @return List of Invoice__c records matching the criteria, or null if an error occurs during query execution.
    */
    @AuraEnabled(cacheable=false)
    public static List<Invoice__c> totalBusinessDetails(String invoiceDate, String companyCode, String profitCenter) {   
        try {
            Date invoiceDateValue = Date.valueOf(invoiceDate);
            List<Invoice__c> invoiceRecords = [SELECT Id,Name,Invoice_number__c,Invoice_Sequence_Number__c,Total_invoice_Amount__c, 
            Damage_Waiver__c,Sales_Tax_Amount__c,Pickup_Amount__c,Delivery_Amount__c FROM Invoice__c 
            WHERE Invoice_Date__c = :invoiceDateValue AND Company_Code__c = :companyCode AND Profit_Center__c = :profitCenter WITH SECURITY_ENFORCED];
            return invoiceRecords;
        } catch (QueryException e) {
            SBR_3_0_Log.logException(e);
            return null;
        } finally {
            SBR_3_0_Log.saveLog();
        }
    }

    /**
    * Author: Vivek/Kavita
    * Method Name: getcashInvoicesDetails
    * @description Retrieves Till New Payment Detail records of a specific record type associated with the specified Till_Detail__c ID.
    * @param recordTypeName The name of the RecordType to filter Till New Payment Detail records.
    * @param tillDetailId The ID of the Till_Detail__c record for which to retrieve Till New Payment Detail records.
    * @return List of Till_New_Payment_Detail__c records meeting the criteria, or an empty list if none found.
    */
    @AuraEnabled(cacheable=false)
    public static List<Till_New_Payment_Detail__c> getcashInvoicesDetails(String recordTypeName, String tillDetailId) {    
        try {
            List<Till_New_Payment_Detail__c> cashInvoicesDetails = [SELECT Id,Name,Wynne_user__c,Invoice_Number__c,Location__c,SR__c,Invoice_Amount__c,Applied_Deposit__c,Net_Cash_Received__c,Other_Amount__c 
                                        FROM Till_New_Payment_Detail__c where recordType.Name =: recordTypeName and  Till_Detail__c =: tillDetailId WITH SECURITY_ENFORCED]; 
            return cashInvoicesDetails;
        }catch(Exception e){
            SBR_3_0_Log.logException(e);
            throw new AuraHandledException(e.getMessage());
        } finally {
            SBR_3_0_Log.saveLog();
        }
    }

    /**
    * Author: Vivek/Kavita
    * Method Name: getotherLocationDetails
    * @description Retrieves Till New Payment Detail records of a specific record type associated with the specified Till_Detail__c ID.
    * @param recordTypeName The name of the RecordType to filter Till New Payment Detail records.
    * @param tillDetailId The ID of the Till_Detail__c record for which to retrieve Till New Payment Detail records.
    * @return List of Till_New_Payment_Detail__c records meeting the criteria, or an empty list if none found.
    */
    @AuraEnabled(cacheable=false)
    public static List<Till_New_Payment_Detail__c> getotherLocationDetails(String recordTypeName, String tillDetailId) {     
        try {
            List<Till_New_Payment_Detail__c> otherLocationDetails = [SELECT Id,Name,Invoice_Number__c,Location__c,SR__c,Invoice_Amount__c,Applied_Deposit__c,Net_Cash_Received__c,Other_Amount__c 
                                        FROM Till_New_Payment_Detail__c where recordType.Name =: recordTypeName and  Till_Detail__c =: tillDetailId WITH SECURITY_ENFORCED]; 
            return otherLocationDetails; 
        }catch(Exception e){
            SBR_3_0_Log.logException(e);
            throw new AuraHandledException(e.getMessage());
        } finally {
            SBR_3_0_Log.saveLog();
        }
    }

    /**
    * Author: Vivek/Kavita
    * Method Name: getUserLocationInfo
    * @description Retrieves User Location records associated with the specified User ID.
    * @param userId The ID of the User for which to retrieve User Location records.
    * @return List of User_Location__c records associated with the specified User ID, or an empty list if none found.
    */
    @AuraEnabled(cacheable=false)
    public static List<User_Location__c> getUserLocationInfo(String userId) {  //FRONT-32190    
        try {
            List<User_Location__c> userInfoList = [SELECT Branch__r.Company_ID__c, Branch__r.Branch_Location_Number__c 
            FROM User_Location__c where User__c =: userId WITH SECURITY_ENFORCED];
            if (userInfoList.isEmpty()) {
                throw new AuraHandledException('No user locations found');
            }
            User_Location__c userLocation = userInfoList[0];
            if (userLocation.Branch__r.Company_ID__c == null || userLocation.Branch__r.Branch_Location_Number__c == null) {
                throw new AuraHandledException('Company Id or Branch Location Number is missing on user location');
            }
            return userInfoList;
        }catch(AuraHandledException e){
            SBR_3_0_Log.logException(e);
            throw e;
        } finally {
            SBR_3_0_Log.saveLog();
        }
    }

   /**
   * Author: Vivek/Kavita
   * Method Name: insertEndOfDayTillRecords
   * @description Inserts or updates an End_of_Day_Till__c record based on the provided eodString if no existing record with the same compound key is found.
   * @param eodString JSON string representing the details to insert or update the End_of_Day_Till__c record.
   * @param compoundKey Unique compound key to identify the End_of_Day_Till__c record.
   * @return Id of the inserted or updated End_of_Day_Till__c record, or an empty string if an error occurs.
   */
   @AuraEnabled(cacheable=false)
   public static Id insertEndOfDayTillRecords(String eodString, String compoundKey){
        try{
            Map<String, Object> parsedJson = (Map<String, Object>) JSON.deserializeUntyped(eodString);
            Map<String, Object> cashDrawerDetailsJson = (Map<String, Object>) parsedJson.get('cashDrawerDetails');
            List<Object> currencyDenominationDetails = (List<Object>) parsedJson.get('currencyDenominationDetails'); //FRONT-32190
            Id eodTillRecordId = checkEODRecordPresent(compoundKey); 
            End_of_Day_Till__c eodRecord = new End_of_Day_Till__c();
            if(eodTillRecordId != null){
                List<End_of_Day_Till__c> eodRecordsList =new List<End_of_Day_Till__c>(SBR_3_0_OrderDA.getEodTill(eodTillRecordId));
                eodRecord = eodRecordsList[0];
            }
            List<End_of_Day_Till__c> endOfDayTillList = new List<End_of_Day_Till__c>();
            
            // eodRecord. = branchLocNumber
            // eodRecord. = companyCode
            // eodRecord. = fromDate
            // eodRecord. = fromTime
            String toDateString = (String) parsedJson.get('toDate');
            eodRecord.Till_Date__c = Date.valueOf(toDateString);
            //eodRecord. = toTime
            eodRecord.Total_Currency__c = (Decimal) cashDrawerDetailsJson.get('totalCurrencyAmount');
            eodRecord.Total_Checks__c = (Decimal) cashDrawerDetailsJson.get('totalChecksAmount');
            eodRecord.Total_Drawer__c = (Decimal) cashDrawerDetailsJson.get('totalDrawerAmount');
            eodRecord.Start_Drawer__c = (Decimal) cashDrawerDetailsJson.get('startDrawerAmount');
            eodRecord.Total_Transaction__c = (Decimal) cashDrawerDetailsJson.get('totalTransactionsAmount');
            eodRecord.Next_Day_Drawer__c = (Decimal) cashDrawerDetailsJson.get('nextDrawerAmount');
            eodRecord.Total_Deposit__c = (Decimal) cashDrawerDetailsJson.get('totalDepositAmount');
            eodRecord.Total_Deposit_in_Bank__c = (Decimal) cashDrawerDetailsJson.get('depositInBankAmount');
            eodRecord.Cash_Sales__c = (Decimal) cashDrawerDetailsJson.get('cashSalesAmount');
            eodRecord.Deposits_Applied_Refunded__c = (Decimal) cashDrawerDetailsJson.get('refundsDepositsAmount');
            eodRecord.Uncollected__c = (Decimal) cashDrawerDetailsJson.get('uncollectedCashAmount');
            eodRecord.Net_Cash_From_Invoice__c = (Decimal) cashDrawerDetailsJson.get('netCashFromInvoices');
            eodRecord.Deposits_Taken__c = (Decimal) cashDrawerDetailsJson.get('depositsTakenAmount');
            eodRecord.Refunds_Not_Given__c = (Decimal) cashDrawerDetailsJson.get('refundsNotGivenAmount');
            eodRecord.Inter_Location_Cash__c = (Decimal) cashDrawerDetailsJson.get('interLocCashAmount');
            eodRecord.Total_Cash__c = (Decimal) cashDrawerDetailsJson.get('totalCashTranAmount');
            eodRecord.Total_Transactions_System__c = (Decimal) cashDrawerDetailsJson.get('totalCashTranAmount');
            //eodRecord.Cash_Deposited_To_Bank__c = (Decimal) cashDrawerDetailsJson.get('depositCashToBank');
            //eodRecord.Checks_Deposited_To_Bank__c = (Decimal) cashDrawerDetailsJson.get('depositChecksToBank');
            //eodRecord.Credit_Card_Slips_To_Bank__c = (Decimal) cashDrawerDetailsJson.get('depositCreditCardSlipsToBank');
            //eodRecord.Submitted_User__c.Wynne_User__c = (String) cashDrawerDetailsJson.get('user');
            String postedToGLString = (String) cashDrawerDetailsJson.get('postedToGL');
            eodRecord.Submitted__c = postedToGLString.equalsIgnoreCase('true') ? true : false;
            //String postedToGLDateString = (String) cashDrawerDetailsJson.get('postedToGLDate');
            //eodRecord.Submitted_Date__c = (Datetime.valueOf(postedToGLDateString)); //invalid datetime error
            eodRecord.Last_Edited_By_RM_User__c = (String) cashDrawerDetailsJson.get('maintByUser');
            eodRecord.Wire_Transfer__c = (Decimal) cashDrawerDetailsJson.get('wireTransferAmount');
            eodRecord.Total_ROA_Checks__c = (Decimal) cashDrawerDetailsJson.get('totalRoaChecksAmount');
            eodRecord.Total_ROA_Cash__c = (Decimal) cashDrawerDetailsJson.get('depositRoaCashToBank');
            //eodRecord.ROA_Checks_Deposit_To_Bank__c = (Decimal) cashDrawerDetailsJson.get('depositRoaChecksToBank');
            //eodRecord.ROA_Credit_Card_Slips_Deposit_To_Bank__c = (Decimal) cashDrawerDetailsJson.get('depositRoaCrdCardSlipsToBank');
            //eodRecord.Total_ROA_Currency_Amount__c = (Decimal) cashDrawerDetailsJson.get('totalRoaCurrencyAmount');
            eodRecord.Status__c = 'In Balance';
            eodRecord.Compound_Key__c = compoundKey;
            eodRecord.Total_Credit_Cards__c = (Decimal) cashDrawerDetailsJson.get('totalCreditCardAmount');
            eodRecord.Total_Auto_Deposit_Amount__c = (Decimal) cashDrawerDetailsJson.get('autoDepositAmount');
            eodRecord.Total_ROA_Credit_Card_Amount__c = (Decimal) cashDrawerDetailsJson.get('totalRoaCreditCardAmount');
            eodRecord.Total_ROA_Auto_Deposit__c = (Decimal) cashDrawerDetailsJson.get('autoRoaDepositAmount');
            eodRecord.Less_ROA__c =  (Decimal) cashDrawerDetailsJson.get('autoRoaDepositAmount');
            eodRecord.Less_Auto_Deposit__c = (Decimal) cashDrawerDetailsJson.get('autoDepositAmount');
            eodRecord.Received_on_Charge_Account__c = (Decimal) cashDrawerDetailsJson.get('roaAmount');
            for (Object currencyObj : currencyDenominationDetails) {
                Map<String, Object> currencyMap = (Map<String, Object>) currencyObj;
                Double denomination = (Double) currencyMap.get('denomination');
                Double amount = (Double) currencyMap.get('amount'); 
                String description = (String) currencyMap.get('description'); 
                if (denomination == 100) {
                    eodRecord.Drawer_Bills_Hundred__c = amount;
                } else if (denomination == 50) {
                    eodRecord.Drawer_Bills_Fifty__c = amount;
                } else if (denomination == 20) {
                    eodRecord.Drawer_Bills_Twenty__c = amount;
                } else if (denomination == 10) {
                    eodRecord.Drawer_Bills_Ten__c = amount;
                } else if (denomination == 5) {
                    eodRecord.Drawer_Bills_Five__c = amount;
                } else if (denomination == 2) {
                    eodRecord.Drawer_Bills_Two__c = amount;
                } else if (denomination == 1 && description.contains('Bills')) {
                    eodRecord.Drawer_Bills_One__c = amount;
                } else if (denomination == 1) {
                    eodRecord.Drawer_Coins_One__c = amount;
                } else if (denomination == 0.5) {
                    eodRecord.Drawer_Coins_Fifty__c = amount;
                } else if (denomination == 0.25) {
                    eodRecord.Drawer_Coins_Quarter__c = amount;
                } else if (denomination == 0.10) {
                    eodRecord.Drawer_Coins_Dime__c = amount;
                } else if (denomination == 0.05) {
                    eodRecord.Drawer_Coins_Nickel__c = amount;
                } else if (denomination == 0.01) {
                    eodRecord.Drawer_Coins_Penny__c = amount;
                }
            }

            endOfDayTillList.add(eodRecord);
            Database.SaveResult[] srList;
            if(eodTillRecordId != null){
                srList = Database.update(endOfDayTillList,false);
            }else{
            srList = Database.insert(endOfDayTillList,false);
            }
            for (Database.SaveResult sr : srList) {     
                if (sr.isSuccess()) {
                    eodTillRecordId = sr.getId();
                }else {
                    for(Database.Error err : sr.getErrors()) {
                        Logger.error('The following error has occurred while inserting/updating record.',err.getMessage()+ ': ' +err.getStatusCode() + ': ' + err.getMessage()+ ': ' +err.getFields(),eodTillRecordId);
                    }
                }
            }
            return eodTillRecordId;
        }catch(Exception ex){
            SBR_3_0_Log.logException(ex);
            return '';
        } finally {
            SBR_3_0_Log.saveLog();
        } 
   }

    /**
    * Author: Vivek/Kavita
    * Method Name: checkEODRecordPresent
    * @description Method to check whether an End of Day (EOD) record is present with the given compound key.
    * @param compoundKey The compound key to search for in the End_of_Day_Till__c records.
    * @return ID of the first End_of_Day_Till__c record found with the specified compound key, or null if none found.
    */
   @AuraEnabled(cacheable=false)
   public static Id checkEODRecordPresent(String compoundKey){
        try {
            List<End_of_Day_Till__c> eodList = [select Id from End_of_Day_Till__c where Compound_Key__c =: compoundKey WITH SECURITY_ENFORCED limit 1];
            return !eodList.isEmpty() ? eodList[0].Id : null;
        }catch(Exception ex){
            SBR_3_0_Log.logException(ex);
            throw new AuraHandledException(ex.getMessage());
        }
   }

    /**
    * Author: Vivek/Kavita
    * Method Name: insertTillDetailRecords
    * @description Inserts a till detail record based on the provided eodTillId if no existing record with the same compound key on the eod record is found; otherwise, it updates the record.
    * @param eodTillId The ID of the End_of_Day_Till__c record to associate the Till_Detail__c record with.
    * @return ID of the inserted or updated Till_Detail__c record, or empty string if an exception occurs.
    */
   @AuraEnabled(cacheable=false)
   public static Id insertTillDetailRecords(Id eodTillId){
    try{
        SBR_3_0_Log.setRelatedRecordId(eodTillId);
            Id tillDetailId;
            tillDetailId = checkTillDetailRecordPresent(eodTillId);
            if(tillDetailId != null){
                return tillDetailId;
            }
            List<Till_Detail__c> tillDetailList = new List<Till_Detail__c>();
            String eodTillRecordCompoundKey = getEODTillCompoundKey(eodTillId);
            Till_Detail__c tillDetailRec = new Till_Detail__c(End_of_Day_Till__c = eodTillId, Source__c ='Rentalman', Compound_Key__c =  eodTillRecordCompoundKey + '-' +  'Rentalman');
            tillDetailList.add(tillDetailRec);
            Database.SaveResult[] srList = Database.insert(tillDetailList,false);
            for (Database.SaveResult sr : srList) {     
                if (sr.isSuccess()) {
                    tillDetailId = sr.getId();
                }else {
                    for(Database.Error err : sr.getErrors()) {
                        Logger.error('The following error has occurred while inserting/updating record.',err.getStatusCode() + ': ' + err.getMessage()+':'+err.getFields(),sr.Id);
                    }
                }
            }
            return tillDetailId;
        }catch(Exception ex){
            SBR_3_0_Log.logException(ex);
            return '';
        } finally {
            SBR_3_0_Log.saveLog();
        } 
   }

    /**
    * Author: Vivek/Kavita
    * Method Name: checkTillDetailRecordPresent
    * @description Method to check whether a till detail record is present with the given End_of_Day_Till__c record ID (eodTillId).
    * @param eodTillId The ID of the End_of_Day_Till__c record for which to check the presence of a related Till_Detail__c record.
    * @return ID of the first Till_Detail__c record found with the specified eodTillId, or null if none found.
    */
    @AuraEnabled(cacheable=false)
    public static Id checkTillDetailRecordPresent(Id eodTillId) { //FRONT-32190
            List<Till_Detail__c> tillRecordList = [SELECT Id FROM Till_Detail__c WHERE End_of_Day_Till__c = :eodTillId WITH SECURITY_ENFORCED LIMIT 1];
            return !tillRecordList.isEmpty() ? tillRecordList[0].Id : null;
    }

    /**
    * Author: Vivek/Kavita
    * Method Name: getEODTillCompoundKey
    * @description Method to retrieve the compound key of the End_of_Day_Till__c record identified by eodTillId.
    * @param eodTillId The ID of the End_of_Day_Till__c record for which to retrieve the compound key.
    * @return Compound key of the specified End_of_Day_Till__c record, or null if none found.
    */
    public static String getEODTillCompoundKey(Id eodTillId) {
        try {
            List<End_of_Day_Till__c> eodList = [select Compound_Key__c from End_of_Day_Till__c where Id =: eodTillId WITH SECURITY_ENFORCED limit 1];
            return !eodList.isEmpty() ? eodList[0].Compound_Key__c : null;
        }catch(Exception ex){
            SBR_3_0_Log.logException(ex);
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
    * Author: Vivek/Kavita
    * Method Name: insertTillNewDepositRecord
    * @description Inserts new deposit records specified in the depositString. If a record with the same compound key exists and field values have changed, it updates the record accordingly.
    * @param depositString JSON string containing the new deposit records to be inserted or updated.
    * @param tillDetailId The ID of the Till_Detail__c record to associate the new deposit records with.
    * @param recordTypeName The name of the record type for new deposit records.
    */
    @AuraEnabled(cacheable=false)
    public static void insertTillNewDepositRecord(String depositString, Id tillDetailId, String recordTypeName) {
        try {
            SBR_3_0_Log.setRelatedRecordId(tillDetailId);
            String recordTypeIdNewDeposit = Schema.SObjectType.Till_New_Deposit_Detail__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
            List<TillNewDeposit> tillRecords = (List<TillNewDeposit>) JSON.deserialize(depositString, List<TillNewDeposit>.class);
            String tillDetailCompoundKey = getTillDetailCompoundKey(tillDetailId);
            Map<String, Till_New_Deposit_Detail__c> existingRecordsMap = checkExisitngTillNewDepositRecords(tillRecords, tillDetailId,tillDetailCompoundKey);
            List<Till_New_Deposit_Detail__c> tillNewDepositList = new List<Till_New_Deposit_Detail__c>();
    
            for (TillNewDeposit obj : tillRecords) {
                String compoundKey = tillDetailCompoundKey + '-' + obj.contractNumber + '-' + obj.invSeqNumber;
                if (existingRecordsMap.containsKey(compoundKey)) {
                    Till_New_Deposit_Detail__c existingRecord = existingRecordsMap.get(compoundKey);
                    Boolean isUpdated = false;
    
                    if (existingRecord.Contract_Number__c != obj.contractNumber) {
                        existingRecord.Contract_Number__c = obj.contractNumber;
                        isUpdated = true;
                    }
                    if (existingRecord.Amount__c != obj.amountInContractCurrency) {
                        existingRecord.Amount__c = obj.amountInContractCurrency;
                        isUpdated = true;
                    }
                    if (existingRecord.Payment_Method__c != obj.payType) {
                        existingRecord.Payment_Method__c = obj.payType;
                        isUpdated = true;
                    }
                    if (existingRecord.Drivers_License__c != obj.driversLicNumber) {
                        existingRecord.Drivers_License__c = obj.driversLicNumber;
                        isUpdated = true;
                    }
                    if (existingRecord.Wynne_User__c != obj.user) {
                        existingRecord.Wynne_User__c = obj.user;
                        isUpdated = true;
                    }
                    if (existingRecord.Detailed_Sequence_Number__c != obj.invSeqNumber) {
                        existingRecord.Detailed_Sequence_Number__c = obj.invSeqNumber;
                        isUpdated = true;
                    }
                    if (existingRecord.SR__c != obj.sourceOfRecord) {
                        existingRecord.SR__c = obj.sourceOfRecord;
                        isUpdated = true;
                    }
    
                    if (isUpdated) {
                        tillNewDepositList.add(existingRecord);
                    }
                } else {
                    Till_New_Deposit_Detail__c newRecord = new Till_New_Deposit_Detail__c();
                    newRecord.Contract_Number__c = obj.contractNumber;
                    newRecord.Amount__c = obj.amountInContractCurrency;
                    newRecord.Payment_Method__c = obj.payType;
                    newRecord.Drivers_License__c = obj.driversLicNumber;
                    newRecord.Wynne_User__c = obj.user;
                    newRecord.Till_Detail__c = tillDetailId;
                    newRecord.RecordTypeId = recordTypeIdNewDeposit;
                    newRecord.Compound_Key__c = compoundKey;
                    newRecord.Detailed_Sequence_Number__c = obj.invSeqNumber;
                    newRecord.SR__c = obj.sourceOfRecord;
                    tillNewDepositList.add(newRecord);
                }
            }
    
            Database.UpsertResult[] srList = Database.upsert(tillNewDepositList, false);
            for (Database.UpsertResult sr : srList) {
                if (!sr.isSuccess()) {
                    for (Database.Error err : sr.getErrors()) {
                        Logger.error('The following error has occurred while inserting/updating record.',err.getStatusCode() + ': ' + err.getMessage()+':'+err.getFields(),sr.Id);
                    }
                }
            }
        } catch (Exception ex) {
            SBR_3_0_Log.logException(ex);
            return;
        } finally {
            SBR_3_0_Log.saveLog();
        }
    }
    
   /**
    * Author: Vivek/Kavita
    * Method Name: checkExisitngTillNewDepositRecords
    * @description This method checks if there exists a new deposit record where the till detail lookup is tillDetailId and the compound key matches.
    * @param tillRecords List of tillNewDeposit objects.
    * @param tillDetailId The ID of the Till_Detail__c record to check against.
    * @param tillDetailCompoundKey The compound key of the Till_Detail__c record.
    * @return Map<String, Till_New_Deposit_Detail__c> Map of existing records with compound key as key and Till_New_Deposit_Detail__c as value.
    */
    public static Map<String, Till_New_Deposit_Detail__c> checkExisitngTillNewDepositRecords(List<tillNewDeposit> tillRecords, Id tillDetailId, String tillDetailCompoundKey) { //FRONT-32190
        Map<String, Till_New_Deposit_Detail__c> existingRecordsMap = new Map<String, Till_New_Deposit_Detail__c>();
        if (tillRecords.isEmpty()) {
            return existingRecordsMap;
        }
    
        List<String> compoundKeys = new List<String>();
        for (TillNewDeposit obj : tillRecords) {
            compoundKeys.add(tillDetailCompoundKey + '-' +obj.contractNumber + '-' + obj.invSeqNumber);
        }
    
        List<Till_New_Deposit_Detail__c> existingRecords = [
            SELECT Id, Contract_Number__c, Amount__c, Payment_Method__c, Drivers_License__c, Wynne_User__c, Compound_Key__c,Detailed_Sequence_Number__c,SR__c
            FROM Till_New_Deposit_Detail__c
            WHERE Compound_Key__c IN :compoundKeys WITH SECURITY_ENFORCED
        ];
    
        for (Till_New_Deposit_Detail__c record : existingRecords) {
            existingRecordsMap.put(record.Compound_Key__c, record);
        }
        return existingRecordsMap;
    }
    
    /**
    * Author: Vivek/Kavita
    * Method Name: getTillDetailCompoundKey
    * @description This method gets the compound key from a Till_Detail__c record.
    * @param tillDetailId The ID of the Till_Detail__c record.
    * @return String Compound key of the Till_Detail__c record.
    */
    public static String getTillDetailCompoundKey(Id tillDetailId) {
        try {
            List<Till_Detail__c> tillDetailList = [select Compound_Key__c from Till_Detail__c where Id =: tillDetailId WITH SECURITY_ENFORCED limit 1];
            return !tillDetailList.isEmpty() ? tillDetailList[0].Compound_Key__c : null;
        }catch(Exception ex){
            SBR_3_0_Log.logException(ex);
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
   
    /**
    * Author: Vivek/Kavita
    * Class Name: tillNewDeposit
    * @description Wrapper class for till new deposit records.
    */
    public class TillNewDeposit {
        /**
        * @description contractNumber.
        */
        public String contractNumber { get; set; } 
        /**
        * @description amountInContractCurrency.
        */
        public Decimal amountInContractCurrency { get; set; }
        /**
        * @description payType.
        */
        public String payType { get; set; }
        /**
        * @description user.
        */
        public String user { get; set; }
        /**
        * @description driversLicNumber.
        */
        public String driversLicNumber { get; set; }
        /**
        * @description invSeqNumber.
        */
        public Integer invSeqNumber { get; set; }
        /**
        * @description sourceOfRecord.
        */
        public String sourceOfRecord { get; set; }
   }

    /**
    * Author: Vivek/Kavita
    * Method Name: insertcashInvoiceOrIntercompanyRecord
    * @description Inserts till new payment records specified in tillRecordString. If a record with the same compound key exists and the field values have changed, it updates the record accordingly.
    * @param tillRecordString JSON string containing the new payment records to be inserted or updated.
    * @param tillDetailId The ID of the Till_Detail__c record to associate the new payment records with.
    * @param recordTypeName The name of the record type for new payment records.
    */
   @AuraEnabled(cacheable=false)
   public static void insertcashInvoiceOrIntercompanyRecord(String tillRecordString, Id tillDetailId, String recordTypeName) {
       try {
           SBR_3_0_Log.setRelatedRecordId(tillDetailId);
           String recordTypeIdNewPayment = Schema.SObjectType.Till_New_Payment_Detail__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
           List<CashInvoiceOrInterCompanyDetail> cashInvoiceOrInterCompanyRecords = (List<CashInvoiceOrInterCompanyDetail>) JSON.deserialize(tillRecordString, List<CashInvoiceOrInterCompanyDetail>.class);
           String tillDetailCompoundKey = getTillDetailCompoundKey(tillDetailId);
           Map<String, Till_New_Payment_Detail__c> existingRecordsMap = checkExistingTillNewPaymentRecords(cashInvoiceOrInterCompanyRecords, tillDetailId, tillDetailCompoundKey);
           List<Till_New_Payment_Detail__c> tillCashInvoiceOrIntercompanyList = new List<Till_New_Payment_Detail__c>();
   
           for (CashInvoiceOrInterCompanyDetail obj : cashInvoiceOrInterCompanyRecords) {
               String compoundKey = tillDetailCompoundKey + '-' +obj.contractNumber + '-' + obj.invSeqNumber;
               if (existingRecordsMap.containsKey(compoundKey)) {
                   Till_New_Payment_Detail__c existingRecord = existingRecordsMap.get(compoundKey);
                   Boolean isUpdated = false;
   
                   if (existingRecord.Invoice_Number__c != obj.contractNumber + '-' + obj.invSeqNumber) {
                       existingRecord.Invoice_Number__c = obj.contractNumber + '-' + obj.invSeqNumber;
                       isUpdated = true;
                   }
                   if (existingRecord.Invoice_Amount__c != obj.invoiceAmount) {
                       existingRecord.Invoice_Amount__c = obj.invoiceAmount;
                       isUpdated = true;
                   }
                   if (existingRecord.Applied_Deposit__c != obj.appliedDeposit) {
                       existingRecord.Applied_Deposit__c = obj.appliedDeposit;
                       isUpdated = true;
                   }
                   if (existingRecord.Net_Cash_Received__c != obj.netCashReceived) {
                       existingRecord.Net_Cash_Received__c = obj.netCashReceived;
                       isUpdated = true;
                   }
                   if (existingRecord.Wynne_user__c != obj.user) {
                       existingRecord.Wynne_user__c = obj.user;
                       isUpdated = true;
                   }
                   if (existingRecord.Other_Amount__c != obj.otherAmount) {
                       existingRecord.Other_Amount__c = obj.otherAmount;
                       isUpdated = true;
                   }
                   if (existingRecord.Detailed_Sequence_Number__c != obj.invSeqNumber) {
                        existingRecord.Detailed_Sequence_Number__c = obj.invSeqNumber;
                        isUpdated = true;
                   }
                   if (existingRecord.Location__c != obj.location) {
                        existingRecord.Location__c = obj.location;
                        isUpdated = true;
                   }
   
                   if (isUpdated) {
                       tillCashInvoiceOrIntercompanyList.add(existingRecord);
                   }
               } else {
                   Till_New_Payment_Detail__c newRecord = new Till_New_Payment_Detail__c();
                   newRecord.Invoice_Number__c = obj.contractNumber + '-' + obj.invSeqNumber;
                   newRecord.Invoice_Amount__c = obj.invoiceAmount;
                   newRecord.Applied_Deposit__c = obj.appliedDeposit;
                   newRecord.Net_Cash_Received__c = obj.netCashReceived;
                   newRecord.Wynne_user__c = obj.user;
                   newRecord.Other_Amount__c = obj.otherAmount;
                   newRecord.Till_Detail__c = tillDetailId;
                   newRecord.RecordTypeId = recordTypeIdNewPayment;
                   newRecord.Compound_Key__c = compoundKey;
                   newRecord.Detailed_Sequence_Number__c = obj.invSeqNumber;
                   newRecord.Location__c = obj.location;
                   tillCashInvoiceOrIntercompanyList.add(newRecord);
               }
           }
           Database.UpsertResult[] srList = Database.upsert(tillCashInvoiceOrIntercompanyList, false);
           for (Database.UpsertResult sr : srList) {
               if (!sr.isSuccess()) {
                   for (Database.Error err : sr.getErrors()) {
                    Logger.error('The following error has occurred while inserting/updating record.',err.getStatusCode() + ': ' + err.getMessage()+':'+err.getFields(),sr.Id);
                   }
               }
           }
       } catch (Exception ex) {
           SBR_3_0_Log.logException(ex);
           return;
       } finally {
           SBR_3_0_Log.saveLog();
       }
   }
   
    /**
    * Author: Vivek/Kavita
    * Method Name: checkExistingTillNewPaymentRecords
    * @description This method checks if there exists a till new payment record where the till detail lookup is tillDetailId and the compound key matches.
    * @param records List of CashInvoiceOrInterCompanyDetail objects.
    * @param tillDetailId The ID of the Till_Detail__c record to check against.
    * @param tillDetailCompoundKey The compound key of the Till_Detail__c record.
    * @return Map<String, Till_New_Payment_Detail__c> Map of existing records with compound key as key and Till_New_Payment_Detail__c as value.
    */
   public static Map<String, Till_New_Payment_Detail__c> checkExistingTillNewPaymentRecords(List<CashInvoiceOrInterCompanyDetail> records, Id tillDetailId, String tillDetailCompoundKey) {
       Map<String, Till_New_Payment_Detail__c> existingRecordsMap = new Map<String, Till_New_Payment_Detail__c>();
       if (records.isEmpty()) {
           return existingRecordsMap;
       }
   
       List<String> compoundKeys = new List<String>();
   
       for (CashInvoiceOrInterCompanyDetail obj : records) {
           compoundKeys.add(tillDetailCompoundKey + '-' +obj.contractNumber + '-' + obj.invSeqNumber);
       }
   
       List<Till_New_Payment_Detail__c> existingRecords = [
           SELECT Id, Invoice_Number__c, Invoice_Amount__c, Applied_Deposit__c, Net_Cash_Received__c, Wynne_user__c, Other_Amount__c, Compound_Key__c,Detailed_Sequence_Number__c,Location__c
           FROM Till_New_Payment_Detail__c
           WHERE Compound_Key__c IN :compoundKeys WITH SECURITY_ENFORCED
       ];
   
       for (Till_New_Payment_Detail__c record : existingRecords) {
           existingRecordsMap.put(record.Compound_Key__c, record);
       }
   
       return existingRecordsMap;
    }
   
    /**
    * Author: Vivek/Kavita
    * Class Name: CashInvoiceOrInterCompanyDetail
    * @description Wrapper class for till new payment records.
    */
    public class CashInvoiceOrInterCompanyDetail {
       /**
        * @description contractNumber.
        */
       public String contractNumber { get; set; }
        /**
        * @description invSeqNumber.
        */
       public Integer invSeqNumber { get; set; }
       /**
        * @description user.
       */
       public String user { get; set; }
       /**
        * @description invoiceAmount.
        */
       public Decimal invoiceAmount { get; set; }
        /**
        * @description appliedDeposit.
        */
       public Decimal appliedDeposit { get; set; }
       /**
        * @description netCashReceived.
        */
       public Decimal netCashReceived { get; set; }
       /**
        * @description otherAmount.
        */
       public Decimal otherAmount { get; set; }
        /**
        * @description location.
        */
        public String location { get; set; }
   }

    /**
    * Author: Vivek/Kavita
    * Method Name: insertTillROADetailRecord
    * @description Inserts till ROA detail records specified in tillROADetailString. If a record with the same compound key exists and the field values have changed, it updates the record accordingly.
    * @param tillROADetailString JSON string containing the new ROA detail records to be inserted or updated.
    * @param tillDetailId The ID of the Till_Detail__c record to associate the new ROA detail records with.
    */
    @AuraEnabled(cacheable=false)
    public static void insertTillROADetailRecord(String tillROADetailString, Id tillDetailId) {
        try {
            SBR_3_0_Log.setRelatedRecordId(tillDetailId);
            List<tillRoaDetail> tillROARecords = (List<tillRoaDetail>) JSON.deserialize(tillROADetailString, List<tillRoaDetail>.class);
            String tillDetailCompoundKey = getTillDetailCompoundKey(tillDetailId);
            Map<String, Till_ROA_Detail__c> existingRecordsMap = checkExistingTillROADetailRecords(tillROARecords, tillDetailCompoundKey);

            List<Till_ROA_Detail__c> tillROADetailList = new List<Till_ROA_Detail__c>();

            for (TillRoaDetail obj : tillROARecords) {
                String compoundKey = tillDetailCompoundKey + '-' + obj.transactionId;
                if (existingRecordsMap.containsKey(compoundKey)) {
                    Till_ROA_Detail__c existingRecord = existingRecordsMap.get(compoundKey);
                    Boolean isUpdated = false;

                    if (existingRecord.Payment_ID__c != obj.transactionId) {
                        existingRecord.Payment_ID__c = obj.transactionId;
                        isUpdated = true;
                    }
                    if (existingRecord.Payment_Method__c != obj.payType) {
                        existingRecord.Payment_Method__c = obj.payType;
                        isUpdated = true;
                    }
                    if (existingRecord.Payment_Last_4__c != obj.referenceNumber) {
                        existingRecord.Payment_Last_4__c = obj.referenceNumber;
                        isUpdated = true;
                    }
                    if (existingRecord.Location__c != obj.branchLocNumber) {
                        existingRecord.Location__c = obj.branchLocNumber;
                        isUpdated = true;
                    }
                    if (existingRecord.Amount__c != obj.amountInDepositCurrency) {
                        existingRecord.Amount__c = obj.amountInDepositCurrency;
                        isUpdated = true;
                    }
                    if (existingRecord.Wynne_User__c != obj.createdBy) {
                        existingRecord.Wynne_User__c = obj.createdBy;
                        isUpdated = true;
                    }
                    if (existingRecord.Invoice_or_Comment__c != obj.miscNotes) {
                        existingRecord.Invoice_or_Comment__c = obj.miscNotes;
                        isUpdated = true;
                    }

                    if (isUpdated) {
                        tillROADetailList.add(existingRecord);
                    }
                } else {
                    Till_ROA_Detail__c newRecord = new Till_ROA_Detail__c();
                    newRecord.Payment_ID__c = obj.transactionId;
                    newRecord.Payment_Method__c = obj.payType;
                    newRecord.Payment_Last_4__c = obj.referenceNumber;
                    newRecord.Location__c = obj.branchLocNumber;
                    newRecord.Amount__c = obj.amountInDepositCurrency;
                    newRecord.Wynne_User__c = obj.createdBy;
                    newRecord.Invoice_or_Comment__c = obj.miscNotes;
                    newRecord.Till_Detail__c = tillDetailId;
                    newRecord.Compound_Key__c = compoundKey;
                    tillROADetailList.add(newRecord);
                }
            }
            Database.UpsertResult[] srList = Database.upsert(tillROADetailList, false);
            for (Database.UpsertResult sr : srList) {
                if (!sr.isSuccess()) {
                    for (Database.Error err : sr.getErrors()) {
                        Logger.error('The following error has occurred while inserting/updating record.',err.getStatusCode() + ': ' + err.getMessage()+':'+err.getFields(),sr.Id);
                    }
                }
            }
        } catch (Exception ex) {
            SBR_3_0_Log.logException(ex);
            return;
        } finally {
            SBR_3_0_Log.saveLog();
        }
    }

    /**
    * Author: Vivek/Kavita
    * Method Name: checkExistingTillROADetailRecords
    * @description This method checks if there exists a till ROA detail record where the till detail lookup is tillDetailId and the compound key matches.
    * @param records List of TillRoaDetail objects.
    * @param tillDetailCompoundKey The compound key of the Till_Detail__c record.
    * @return Map<String, Till_ROA_Detail__c> Map of existing records with compound key as key and Till_ROA_Detail__c as value.
    */
    public static Map<String, Till_ROA_Detail__c> checkExistingTillROADetailRecords(List<tillRoaDetail> records, String tillDetailCompoundKey) { //FRONT-32190
        Map<String, Till_ROA_Detail__c> existingRecordsMap = new Map<String, Till_ROA_Detail__c>();
        if (records.isEmpty()) {
            return existingRecordsMap;
        }

        List<String> compoundKeys = new List<String>();

        for (TillRoaDetail obj : records) {
            compoundKeys.add(tillDetailCompoundKey + '-' + obj.transactionId);
        }

        List<Till_ROA_Detail__c> existingRecords = [
            SELECT Id, Payment_ID__c, Payment_Method__c, Payment_Last_4__c, Location__c, Amount__c, Wynne_User__c, Invoice_or_Comment__c, Compound_Key__c
            FROM Till_ROA_Detail__c
            WHERE Compound_Key__c IN :compoundKeys WITH SECURITY_ENFORCED
        ];

        for (Till_ROA_Detail__c record : existingRecords) {
            existingRecordsMap.put(record.Compound_Key__c, record);
        }

        return existingRecordsMap;
    }

    /**
    * Author: Vivek/Kavita
    * Class Name: tillRoaDetail
    * @description Wrapper class for till ROA detail records.
    */
    public class TillRoaDetail {
        /**
        * @description transactionId.
        */
        public Decimal transactionId { get; set; }
        /**
        * @description payType.
        */
        public String payType { get; set; }
        /**
        * @description referenceNumber.
        */
        public String referenceNumber { get; set; }
        /**
        * @description branchLocNumber.
        */
        public String branchLocNumber { get; set; }
        /**
        * @description amountInDepositCurrency.
        */
        public Decimal amountInDepositCurrency { get; set; }
        /**
        * @description createdBy.
        */
        public String createdBy { get; set; }
        /**
        * @description miscNotes.
        */
        public String miscNotes { get; set; }
    }
}