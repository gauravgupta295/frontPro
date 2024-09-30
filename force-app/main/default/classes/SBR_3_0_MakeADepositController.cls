/*********************************************************************************************************************
* Apex Class: SBR_3_0_MakeADepositController
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:@description This code defines a Salesforce Apex controller class named SBR_3_0_MakeADepositController. It contains 
methods for retrieving deposit amount, contact information, payment methods, terminals, payment data, card details, and more. 
These methods are annotated with @AuraEnabled to make them accessible from Lightning components.
The code ensures security enforcement by utilizing WITH SECURITY_ENFORCED in SOQL queries and handles exceptions 
appropriately.
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
     1          Vivek Kumar Sharma     20-01-2024           
     2          Manu                   24-01-2024
     3          Prakash                29-01-2024
     4          Vatshal                10-02-2024
     5          Chethan                11-02-2024
     6          Kavita                 11-03-2024
     7          Vikas                  11-05-2024
*********************************************************************************************************************/
public with sharing class SBR_3_0_MakeADepositController {

    
    public static Id transcationID;
    /**
    * Author: Manu
    * Method Name : getDeposit
    * @description Calculates the total deposit amount for a given order ID.
    * @param orderId The ID of the order for which to calculate the deposit.
    * @return Decimal representing the total deposit amount.
    */
    @AuraEnabled(cacheable=false)
    public static decimal getDeposit(Id orderId) {
        try {
            SBR_3_0_Log.setRelatedRecordId(orderId);
            Decimal totalDeposit = 0.00;
            // Query Payments__c records related to the given orderId with security enforcement
            List<Payments__c> paymentList = [Select Id, Deposit_Amount__c From Payments__c where Order__c = :orderId WITH SECURITY_ENFORCED];
            for(Payments__c pay : paymentList) {
                totalDeposit = pay.Deposit_Amount__c + totalDeposit;
            }
            return totalDeposit;
        } catch(Exception ex){  
            SBR_3_0_Log.logException(ex);
            throw new AuraHandledException(ex.getMessage());
        } finally {
            SBR_3_0_Log.saveLog();
        }  
    }

    /**
    * Author: Manu
    * Method Name : getDepositforRefund
    * @description Calculates the total deposit amount eligible for refund for a given order ID.
    * @param orderId The ID of the order for which to calculate the refundable deposit.
    * @return Decimal representing the total refundable deposit amount.
    */
    @AuraEnabled(cacheable=false)
    public static decimal getDepositforRefund(Id orderId) {
        try {
            Decimal totalDeposit = 0.00;
            SBR_3_0_Log.setRelatedRecordId(orderId);
            // Query Payments__c records related to the given orderId with security enforcement
            List<Payments__c> paymentList = [Select Id, Deposit_Amount__c From Payments__c where Order__c = :orderId WITH SECURITY_ENFORCED];
            for(Payments__c pay : paymentList) {
                if(pay.Deposit_Amount__c > 0){
                    totalDeposit = pay.Deposit_Amount__c + totalDeposit;
                }
            }
            return totalDeposit;
        } catch(Exception ex){  
            SBR_3_0_Log.logException(ex);
            throw new AuraHandledException(ex.getMessage());
        } finally {
            SBR_3_0_Log.saveLog();
        } 
    }
    /**
    * Author: Vivek Kumar Sharma
    * Method Name : getContact
    * @description Retrieves contact records related to the given order ID.
    * @param orderId The ID of the order for which to fetch contacts.
    * @return List<Contact> containing contact records related to the order. Returns null if no contacts found.
    */
    @AuraEnabled(cacheable=true)
    public static List<Contact> getContact(Id orderId) {
        try { // Query Contact records related to the given orderId with security enforcement
            SBR_3_0_Log.setRelatedRecordId(orderId);
            List<Contact> conList =  [SELECT Id, Name, Email FROM Contact WHERE AccountId IN (SELECT AccountId  FROM Order WHERE Id = :orderId) AND Primary_Contact__c = true WITH SECURITY_ENFORCED];
            if(conList.size() > 0){
                return conList;
            }
            else{
                return null;
            } 
        } catch(Exception ex){  
            SBR_3_0_Log.logException(ex);
            throw new AuraHandledException(ex.getMessage());
        } finally {
            SBR_3_0_Log.saveLog();
        } 
    }
    
    /**
    * @description Retrieves the latest order record associated with a given account ID.
    * @param accountId The ID of the account for which to retrieve the latest order.
    * @return List<Order> containing the latest order record related to the account. Returns null if no order found.
    */
    @AuraEnabled(cacheable=true)
    public static List<Order> getOrder(Id accountId) {
        try {
            SBR_3_0_Log.setRelatedRecordId(accountId);
            // Query Order records related to the given accountId with security enforcement
            List<Order> orderList =  [SELECT Id,AccountId FROM Order WHERE AccountId =: accountId WITH SECURITY_ENFORCED order by createddate DESC  limit 1];
            if(orderList.size() > 0){
                return orderList;
            }
            else{
                return null;
            }
        } catch(Exception ex){  
            SBR_3_0_Log.logException(ex);
            throw new AuraHandledException(ex.getMessage());
        } finally {
            SBR_3_0_Log.saveLog();
        }    
    }
    
    /**
    * Author: Vivek Kumar Sharma
    * Method Name : getContactEmail
    * @description Retrieves the email address of a contact based on the contact ID.
    * @param contactId The ID of the contact for which to retrieve the email address.
    * @return Contact object containing the ID and Email of the contact. Returns null if no contact found.
    */
    @AuraEnabled(cacheable=true)
    public static Contact getContactEmail(String contactId) {
        try {
            SBR_3_0_Log.setRelatedRecordId(contactId);
            return [SELECT Id, Email FROM Contact WHERE Id = :contactId WITH SECURITY_ENFORCED Limit 1];
        } catch (Exception e) {
            SBR_3_0_Log.logException(e);
            throw new AuraHandledException('Error fetching contact email: ' + e.getMessage());
        } finally {
            SBR_3_0_Log.saveLog();
        }
    } 
    
    /**
    * Author: Vivek Kumar Sharma
    * Method Name : sendEmailWithAttachment
    * @description Sends an email with an attachment.
    * @param toAddress The email address of the recipient.
    * @param subject The subject of the email.
    * @param body The body (content) of the email.
    * @param attachmentName The name of the attachment file.
    * @param attachmentBody The content of the attachment file as a String.
    * @return 'Success' if the email was sent successfully, or an empty string if there was an error.
    */
    @AuraEnabled(cacheable=false)
    public static String sendEmailWithAttachment(String toAddress, String subject, String body, String attachmentName, String attachmentBody) {
        try {
            Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
            attach.setFileName(attachmentName);
            attach.setBody(Blob.valueOf(attachmentBody));
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{toAddress});
            email.setSubject(subject);
            email.setPlainTextBody(body);
            email.setFileAttachments(new List<Messaging.EmailFileAttachment>{attach});
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
            return 'Success';
        } catch (Exception e) {
            SBR_3_0_Log.logException(e);        
            return '';
        } finally {
            SBR_3_0_Log.saveLog();
        }
        
    }

    /**
    * Author: Manu
    * Method Name : createDeposit
    * @description Creates a new payment deposit record based on provided data.
    * @param paymentDepositData JSON string containing payment deposit data.
    * @param orderRecordId The ID of the order associated with the deposit.
    * @return 'Success' if the deposit record was successfully created, otherwise an error message.
    */
    @AuraEnabled(cacheable=false)
    public static string createDeposit(String paymentDepositData, Id orderRecordId) {
        String message;
        Map<String,Object> paymentDepositRecord = (Map<String,Object>)JSON.deserializeUntyped(paymentDepositData);
        List<Payments__c> paymentDepositToInsert = new List<Payments__c>();
    	Id paymentRecordId;
        try{
            SBR_3_0_Log.setRelatedRecordId(orderRecordId);
            Payments__c depositRecord = new Payments__c();
            Map<String,String> mapOfPaymentMenthodAnnotation 
            = new map<String,String>{'Visa' =>'V','Amex' => 'A','Cash Currency' => 'C', 'Discover' => 'D', 'Interac Debit' => 'G' , 'Check' => 'K' , 'Mastercard' => 'M','No Refund Given' => 'N', 'Pay On Return'=> 'P','Refund Request (Corporate)' => 'R','Uncollected' => 'U','Visa' => 'V','Diners Club'=> 'X' };     
            String pmSelected = String.valueOf(paymentDepositRecord.get('paymentMethod'));
            depositRecord.Payment_Method__c = mapOfPaymentMenthodAnnotation.get(pmSelected);
            depositRecord.Invoice_or_Comment__c = String.valueOf(paymentDepositRecord.get('invoiceOrComment'));
            if (String.valueOf(paymentDepositRecord.get('paymentMethod')) != 'Pay on Return'){
                depositRecord.Deposit_Amount__c = (Decimal)paymentDepositRecord.get('amountCollected');
            }
            else{
                depositRecord.Deposit_Amount__c = 0.00;
            }
            depositRecord.Terminal__c = String.valueOf(paymentDepositRecord.get('terminal'));
            depositRecord.Cash_Received__c = (Decimal)(paymentDepositRecord.get('cashReceived'));
            depositRecord.Check_Number__c = String.valueOf(paymentDepositRecord.get('checkNumber'));
            String changeDueStr = String.valueOf(paymentDepositRecord.get('changeDue'));
            depositRecord.Change_Due__c = Decimal.valueOf(changeDueStr);
            depositRecord.Reason__c = String.valueOf(paymentDepositRecord.get('reason'));
            depositRecord.Order__c = orderRecordId;
            depositRecord.Account__c =(Id)paymentDepositRecord.get('accountId');
            depositRecord.Tran_Type__c = String.valueOf(paymentDepositRecord.get('tranType'));
            paymentDepositToInsert.add(depositRecord);
 
            if(!paymentDepositToInsert.isEmpty()){
                Database.SaveResult[] insertPayments = Database.insert(paymentDepositToInsert, false);
                if (insertPayments[0].isSuccess()) {
                	paymentRecordId = insertPayments[0].getId();
            	}
            }
            
            if(!String.isEmpty(transcationID) && !String.isEmpty(paymentRecordId)){
                Transaction__c transactionRecord = new Transaction__c(
        		Id = transcationID,
        		Payment__c = paymentRecordId);
                if (Schema.sObjectType.Transaction__c.isUpdateable()) {
                    update transactionRecord;
                }
            }
        return message ='Success';
        } catch(Exception ex){
            SBR_3_0_Log.logException(ex);
            throw new AuraHandledException(ex.getMessage());
        } finally {
            SBR_3_0_Log.saveLog();
        }
    }

    /**
    * Author: Vivek Sharma
    * Method Name : createTransaction
    * @description Creates a new transaction record based on provided payment deposit data and associates it with an order.
    * @param orderRecordId The ID of the order associated with the transaction.
    * @param paymentDepositData JSON string containing payment deposit data.
    * @return Id of the newly created transaction record if successful, otherwise an error is thrown.
    */
    @AuraEnabled(cacheable=false)
    @SuppressWarnings('PMD.AvoidDebugStatements')
    public static Id createTansaction(Id orderRecordId, String paymentDepositData) {  
        Id transactionId;  
        try{
            SBR_3_0_Log.setRelatedRecordId(orderRecordId);
            Map<String,Object> paymentDepositRecord = (Map<String,Object>)JSON.deserializeUntyped(paymentDepositData);
            List<Transaction__c> newTransactionList = new List<Transaction__c>();
            Map<String,String> mapOfPaymentMenthodAnnotation = new map<String,String>{'Visa' =>'V','Amex' => 'A','Cash Currency' => 'C', 'Discover' => 'D', 'Interac Debit' => 'G' , 'Check' => 'K' , 'Mastercard' => 'M','No Refund Given' => 'N', 'Pay On Return'=> 'P','Refund Request (Corporate)' => 'R','Uncollected' => 'U','Visa' => 'V','Diners Club'=> 'X' };
            Transaction__c newTransaction = new Transaction__c();
            newTransaction.Order__c =orderRecordId;
            String pmSelected = String.valueOf(paymentDepositRecord.get('paymentMethod'));
            newTransaction.Payment_Method__c = mapOfPaymentMenthodAnnotation.get(pmSelected);
            newTransaction.Deposit_Amount__c = (Decimal)paymentDepositRecord.get('amountCollected');
            newTransaction.Terminal__c = String.valueOf(paymentDepositRecord.get('terminal'));
            newTransaction.Cash_Received__c = (Decimal)(paymentDepositRecord.get('cashReceived'));
            newTransaction.Check_Number__c = String.valueOf(paymentDepositRecord.get('checkNumber'));
            String changeDueStr = String.valueOf(paymentDepositRecord.get('changeDue'));
            newTransaction.Change_Due__c = Decimal.valueOf(changeDueStr);
            newTransaction.Tran_Type__c = String.valueOf(paymentDepositRecord.get('tranType'));
            newTransactionList.add(newTransaction);
            Database.SaveResult[] srList = Database.insert(newTransactionList,false);
            // Insert the record
            for (Database.SaveResult sr : srList) {     
                if (sr.isSuccess()) {
                    transactionId = sr.getId();
                }else {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                        System.debug(LoggingLevel.ERROR,'The following error has occurred while inserting transaction record.');                    
                        System.debug(LoggingLevel.ERROR,err.getStatusCode() + ': ' + err.getMessage());
                        System.debug(LoggingLevel.ERROR,'Transaction fields that affected this error: ' + err.getFields());
                    }
                }
            }
        return transactionId;
        } catch(Exception ex){
            SBR_3_0_Log.logException(ex);
            throw new AuraHandledException(ex.getMessage());
        } finally {
            SBR_3_0_Log.saveLog();
        }
    }

    /**
    * Author: Kavita Satale
    * Method Name : createTansactionFromAccount
    * @description Creates a new transaction record for an account based on provided payment deposit data.
    * @param accountRecordId The ID of the account associated with the transaction.
    * @param paymentDepositData JSON string containing payment deposit data.
    * @return Id of the newly created transaction record if successful, otherwise an error is thrown.
    */
    @AuraEnabled(cacheable=false)
    @SuppressWarnings('PMD.AvoidDebugStatements')
    public static Id createTansactionFromAccount(Id accountRecordId, String paymentDepositData) {  
        Id transactionId;  
        try{
            SBR_3_0_Log.setRelatedRecordId(accountRecordId);
            Map<String,Object> paymentDepositRecord = (Map<String,Object>)JSON.deserializeUntyped(paymentDepositData);
            List<Transaction__c> newTransactionList = new List<Transaction__c>();
            Map<String,String> mapOfPaymentMenthodAnnotation = new map<String,String>{'Visa' =>'V','Amex' => 'A','Cash Currency' => 'C', 'Discover' => 'D', 'Interac Debit' => 'G' , 'Check' => 'K' , 'Mastercard' => 'M','No Refund Given' => 'N', 'Pay On Return'=> 'P','Refund Request (Corporate)' => 'R','Uncollected' => 'U','Visa' => 'V','Diners Club'=> 'X' };
            Transaction__c newTransaction = new Transaction__c();
            String pmSelected = String.valueOf(paymentDepositRecord.get('paymentMethod'));
            newTransaction.Payment_Method__c = mapOfPaymentMenthodAnnotation.get(pmSelected);
            newTransaction.Deposit_Amount__c = (Decimal)paymentDepositRecord.get('amountCollected');
            newTransaction.Terminal__c = String.valueOf(paymentDepositRecord.get('terminal'));
            newTransaction.Cash_Received__c = (Decimal)(paymentDepositRecord.get('cashReceived'));
            newTransaction.Check_Number__c = String.valueOf(paymentDepositRecord.get('checkNumber'));
            String changeDueStr = String.valueOf(paymentDepositRecord.get('changeDue'));
            newTransaction.Change_Due__c = Decimal.valueOf(changeDueStr);
            newTransaction.Tran_Type__c = String.valueOf(paymentDepositRecord.get('tranType'));
            newTransaction.Account__c = accountRecordId;
            newTransaction.User__c = (UserInfo.getFirstName().substring(0,1)) + UserInfo.getLastName();
            newTransactionList.add(newTransaction);
            Database.SaveResult[] srList = Database.insert(newTransactionList,false);
            // Insert the record
            for (Database.SaveResult sr : srList) {     
                if (sr.isSuccess()) {
                    transactionId = sr.getId();
                }else {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                        System.debug(LoggingLevel.ERROR,'The following error has occurred while inserting transaction record.');                    
                        System.debug(LoggingLevel.ERROR,err.getStatusCode() + ': ' + err.getMessage());
                        System.debug(LoggingLevel.ERROR,'Transaction fields that affected this error: ' + err.getFields());
                    }
                }
            }
            return transactionId;
        } catch(Exception ex){
            SBR_3_0_Log.logException(ex);
            throw new AuraHandledException(ex.getMessage());
        } finally {
            SBR_3_0_Log.saveLog();
        }
    }

    /**
    * Author: Vivek Kumar Sharma
    * Method Name : getPaymentMethod
    * @description Retrieves payment methods associated with a specified component name.
    * @param componentName The name of the component to retrieve payment methods for.
    * @return Map<String, String> where keys are payment method types and values are corresponding modes of payment.
    */
    @AuraEnabled(cacheable=false)
    public static Map<String,String> getPaymentMethod(String componentName) {
        try{
            List<Payment_Method__c> paymentMethodList = new List<Payment_Method__c>();
            // Query Payment_Method__c records with security enforcement
            paymentMethodList = [Select Id, toLabel(Type__c),Mode_Of_Payment__c From Payment_Method__c where Component_Name__c = :componentName or Component_Name__c = '' WITH SECURITY_ENFORCED order by Type__c];
            Map<string,String> listofPaymentMethods= new Map<string,String> ();
            for(Payment_Method__c tempValue: paymentMethodList){
                listofPaymentMethods.put(String.valueOf(tempValue.Type__c), tempValue.Mode_Of_Payment__c);
            }
            return listofPaymentMethods;
        } catch(Exception ex){
            SBR_3_0_Log.logException(ex);
            throw new AuraHandledException(ex.getMessage());
        } finally {
            SBR_3_0_Log.saveLog();
        }
    }

    /**
    * Author: Vivek Kumar Sharma
    * Method Name : getTerminal
    * @description Retrieves terminal options associated with a specified department.
    * @param department The department identifier to retrieve terminal options for.
    * @return List<String> where each element represents a terminal option in the format "Lane: <Lane Number>, ID: <Terminal ID>".
    */
    @AuraEnabled(cacheable=false)
    public static List<String> getTerminal(String department) {
        try {
            List<Terminal_Lane__c> terminalList = new List<Terminal_Lane__c>();
            // Query Terminal_Lane__c records related to the given department with security enforcement
            terminalList = [Select Id, Terminal_ID__c, Lane__c From Terminal_Lane__c where RM_Branch_Number__c = :department WITH SECURITY_ENFORCED ORDER BY Lane__c ASC];
            List<String> listofTerminalOptions= new List<String> ();
            for(Terminal_Lane__c tempValue: terminalList){
                listofTerminalOptions.add('Lane: ' + String.valueOf(tempValue.Lane__c) + ',' + ' ID: ' +  String.valueOf(tempValue.Terminal_ID__c));
            }
            return listofTerminalOptions;
        } catch(Exception ex) {
            SBR_3_0_Log.logException(ex);
            throw new AuraHandledException(ex.getMessage());
        } finally {
            SBR_3_0_Log.saveLog();
        }
    }

    /**
    * Author: Prakash
    * Method Name : getPaymentTypeWithTerminal
    * @description Retrieves payment types and associated terminals for a given order ID.
    * @param orderId The ID of the order to retrieve payment information for.
    * @return List<Map<String, String>> where each map contains 'type' and 'terminal' keys representing payment type and terminal ID respectively.
    *         Returns null if no payment information is found for the order.
    */
    @AuraEnabled(cacheable=false)
    public static List<Map<String, String>> getPaymentTypeWithTerminal(Id orderId) {
        try {
            SBR_3_0_Log.setRelatedRecordId(orderId);
            List<Map<String, String>> paymentTypesWithTerminal = new List<Map<String, String>>();
            List<Payments__c> paymentList = [SELECT Id, type__c, terminal__c FROM Payments__c WHERE Order__c = :orderId WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC];
            for (Payments__c payment : paymentList) {
                Map<String, String> paymentTypeMap = new Map<String, String>();
                paymentTypeMap.put('type', payment.type__c);
                paymentTypeMap.put('terminal', payment.terminal__c);
                paymentTypesWithTerminal.add(paymentTypeMap);
            }
            return paymentTypesWithTerminal.isEmpty() ? null : paymentTypesWithTerminal;
        } catch(Exception ex) {
            SBR_3_0_Log.logException(ex);
            throw new AuraHandledException(ex.getMessage());
        } finally {
            SBR_3_0_Log.saveLog();
        }
    }
 
    /**
    * Author: Prakash
    * Method Name : getPaymentData
    * @description Retrieves payment data associated with a specified order ID.
    * @param orderId The ID of the order to retrieve payment data for.
    * @return List<Payments__c> List of Payments__c records related to the order.
    */
    @AuraEnabled(cacheable=false)
    public static List<Payments__c> getPaymentData(Id orderId) {
        try {
            SBR_3_0_Log.setRelatedRecordId(orderId);
            return [SELECT Id, Name, Tran__c, Date__c,Type__c,Tran_Type__c,Deposit_Amount__c,Authorization__c FROM Payments__c WHERE Order__c = :orderId WITH SECURITY_ENFORCED ORDER BY Date__c DESC];
        } catch(Exception ex) {
            SBR_3_0_Log.logException(ex);
            throw new AuraHandledException(ex.getMessage());
        } finally {
            SBR_3_0_Log.saveLog();
        }
    }

    /**
    * Author: Manu
    * Method Name : getPaymentTypeWithDepositAmount
    * @description Retrieves payment types with associated deposit amounts for a given order ID.
    * @param orderId The ID of the order to retrieve payment types and deposit amounts for.
    * @return Map<String, Decimal> Map where keys are payment types and values are total deposit amounts.
    */
    @AuraEnabled(cacheable=false)
    public static Map<String, Decimal> getPaymentTypeWithDepositAmount(Id orderId) {
        try {
            SBR_3_0_Log.setRelatedRecordId(orderId);
            List<AggregateResult> paymentMethodList = [SELECT Payment_Method__c, SUM(Deposit_Amount__c) totalDeposit, MAX(CreatedDate) FROM Payments__c WHERE order__c=: orderId WITH SECURITY_ENFORCED GROUP BY Payment_Method__c];
            Map<String,String> mapOfPaymentMenthodAnnotation 
            = new map<String,String>{'V' =>'Visa','A' => 'Amex','C' => 'Cash Currency', 'D' => 'Discover', 'G' => 'Interac Debit' , 'K' => 'Check' , 'M' => 'Mastercard','N' => 'No Refund Given', 'P'=> 'Pay On Return','R' => 'Refund Request (Corporate)','U' => 'Uncollected','V' => 'Visa','X'=> 'Diners Club' };
            Map<String, Decimal> paymentTypeMap = new Map<String, Decimal>();
            Map<String, Decimal> paymentMethodMap = new Map<String, Decimal>();
            for (AggregateResult aggregateResult : paymentMethodList) {
                String paymentMethod = (String)aggregateResult.get('Payment_Method__c');
                Decimal totalDeposit = (Decimal)aggregateResult.get('totalDeposit');
                paymentMethodMap.put(mapOfPaymentMenthodAnnotation.get(paymentMethod), totalDeposit);
            }           
            List<Payments__c> paymentTypeList = [SELECT type__c FROM Payments__c WHERE Order__c =: orderId WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC ];           
            for (Payments__c payment : paymentTypeList) {
                string paymentMethod = payment.type__c.substringBefore(' ****');
                if(paymentMethodMap.containsKey(paymentMethod)){
                    paymentTypeMap.put(payment.type__c, paymentMethodMap.get(paymentMethod));
                    paymentMethodMap.remove(paymentMethod);
                }
            }
        return paymentTypeMap;
        } catch(Exception ex) {
            SBR_3_0_Log.logException(ex);
            throw new AuraHandledException(ex.getMessage());
        } finally {
            SBR_3_0_Log.saveLog();
        }
    }
    /**
    * Author: Chethan
    * Method Name : orderWithOrderItemDetails
    * @description Checks if an order has associated order item details.
    * @param orderId The ID of the order to check.
    * @return Boolean Returns true if the order has order item details, false otherwise.
    */
    @AuraEnabled(cacheable=false)
    public static Boolean orderWithOrderItemDetails(Id orderId){
        try {
            SBR_3_0_Log.setRelatedRecordId(orderId);
            Order orderRec = [select id,(select id from OrderItems) from order where id = :orderId WITH SECURITY_ENFORCED];
            if(orderRec.OrderItems.size() > 0){
                return true;
            }else{
                return false;
            }
        } catch(Exception ex) {
            SBR_3_0_Log.logException(ex);
            throw new AuraHandledException(ex.getMessage());
        } finally {
            SBR_3_0_Log.saveLog();
        }
    }
    /**
    * Author: Kavita/Manu
    * Method Name : getLocationInfo
    * @description Retrieves location information related to the specified order ID.
    * @param orderId The ID of the order to retrieve location information for.
    * @return List<Schema.Location> List of Location records related to the order.
    */
    @AuraEnabled(cacheable=false)
    public static List<Schema.Location> getLocationInfo(Id orderId) {
        try{
            SBR_3_0_Log.setRelatedRecordId(orderId);
            List<Schema.Location> locationList = [select Id,Allow_Refund_Greater_Than_Amount__c, Allow_Refund_on_New_Card__c from Location where A360SPARK_AccountId__c IN (select AccountId from Order where id =: orderId) WITH SECURITY_ENFORCED limit 1];
            return locationList;
        }catch(Exception e){
            SBR_3_0_Log.logException(e);
            throw new AuraHandledException(e.getMessage());
        } finally {
            SBR_3_0_Log.saveLog();
        }
    }

    /**
    * Author: Sreekar
    * Method Name : updateLocationInfo
    * @description Updates location information with specified values.
    * @param locationId The ID of the location to update.
    * @param refundGreater Boolean value to update Allow_Refund_Greater_Than_Amount__c field.
    * @param newCard Boolean value to update Allow_Refund_on_New_Card__c field.
    */
    @AuraEnabled(cacheable=false)
    public static void updateLocationInfo(Id locationId,Boolean refundGreater, Boolean newCard) {
        try{
            SBR_3_0_Log.setRelatedRecordId(locationId);
            List<Schema.Location> locationRec = [select Allow_Refund_Greater_Than_Amount__c, Allow_Refund_on_New_Card__c from Location where Id =: locationId WITH SECURITY_ENFORCED limit 1 ];
            if(refundGreater != null){
                locationRec[0].Allow_Refund_Greater_Than_Amount__c = refundGreater;
            }
            if(newCard != null){
                locationRec[0].Allow_Refund_on_New_Card__c = newCard;
            }
            if (Schema.sObjectType.Location.isUpdateable()) {
                update locationRec;
            }       
        }catch(Exception e){
            SBR_3_0_Log.logException(e);
            throw new AuraHandledException(e.getMessage());
        }finally {
            SBR_3_0_Log.saveLog();
        }

    }
  
    /**
    * Author: Prakash
    * Method Name : getUncollectedReasons
    * @description Retrieves list of uncollected reasons from the Reason_for_Uncollected__c picklist field.
    * @return List<String> List of uncollected reasons.
    */
    @AuraEnabled(cacheable=false)
	public static List<String> getUncollectedReasons() {
        try {
            List<Schema.PicklistEntry> picklistValues = Schema.SObjectType.Payments__c.fields.Reason_for_Uncollected__c.getPicklistValues();
            List<String> uncollectedReasons = new List<String>();
            
            for(Schema.PicklistEntry entry : picklistValues) {
                uncollectedReasons.add(entry.getValue());
            }
        return uncollectedReasons;
        }catch(Exception e){
            SBR_3_0_Log.logException(e);
            throw new AuraHandledException(e.getMessage());
        } finally {
            SBR_3_0_Log.saveLog();
        }
    }

    /**
    * @description Retrieves total rental amount and total invoiced amount for a specific order.
    * @param recordId The ID of the order to retrieve amount details for.
    * @return Order The Order record containing Total_Rental_Amount__c and Total_Invoiced_Amount__c fields.
    */
    @AuraEnabled(cacheable=false)
    public static Order getOrderAmountDetails(Id recordId) {
        try {
            SBR_3_0_Log.setRelatedRecordId(recordId);
            return [SELECT Total_Rental_Amount__c, Total_Invoiced_Amount__c FROM Order WHERE Id = :recordId WITH SECURITY_ENFORCED];
        } catch (Exception e) {
            SBR_3_0_Log.logException(e);
            throw new AuraHandledException('Error retrieving order details: ' + e.getMessage());
        } finally {
            SBR_3_0_Log.saveLog();
        }
    }

    /**
    * Author: Kavita
    * Method Name : insertROADetailRecords
    * @description Inserts ROA Detail records based on the provided JSON data and account ID.
    * @param roaDetailRecords JSON string representing a list of ROA Detail records.
    * @param accountId The ID of the account associated with the ROA Detail records.
    * @return List<ROA_Detail_Mapping> List of ROA_Detail_Mapping objects representing the inserted records.
    * @throws AuraHandledException If an error occurs during record insertion.
    */
    @AuraEnabled(cacheable=false)
    @SuppressWarnings('PMD.AvoidDebugStatements')
	public static  List<ROA_Detail_Mapping> insertROADetailRecords(String roaDetailRecords, String accountId) {
        try {
            SBR_3_0_Log.setRelatedRecordId(accountId);
            List<ROADetail> paymentRecords = (List<ROADetail>) JSON.deserialize(roaDetailRecords, List<ROADetail>.class);
            List<ROA_Detail__c> roaDetailsToInsert = new List<ROA_Detail__c>();
            
            for (ROADetail record : paymentRecords) {
                String invoiceOrComment = record.comment;
                Decimal editedValue = record.paymentAmount;        
                ROA_Detail__c roaDetail = new ROA_Detail__c(
                    Invoice_or_Comment__c = invoiceOrComment,
                    Payment_Amount__c = editedValue,
                    Account__c = accountId
                );  
                roaDetailsToInsert.add(roaDetail);
            }
            List<ROA_Detail_Mapping> insertedRecords = new List<ROA_Detail_Mapping>();
            if (!roaDetailsToInsert.isEmpty()){
                Database.SaveResult[] insertResults = Database.insert(roaDetailsToInsert, false);    
                for (Integer i = 0; i < insertResults.size(); i++) {
                    if (insertResults[i].isSuccess()) {
                        ROA_Detail__c insertedROADetail = roaDetailsToInsert[i];
                        insertedRecords.add(new ROA_Detail_Mapping(
                            insertedROADetail.Payment_Amount__c,
                            insertedROADetail.Invoice_or_Comment__c,
                            insertedROADetail.Id
                        ));
                    }else {
                    for(Database.Error error : insertResults[i].getErrors()) {
                        System.debug(LoggingLevel.ERROR,'Error message: ' + error.getMessage());
                    }
                }
            }
        }
            return insertedRecords;
        } catch (Exception e) {
            SBR_3_0_Log.logException(e);
            throw new AuraHandledException('Error retrieving order details: ' + e.getMessage());
        } finally {
            SBR_3_0_Log.saveLog();
        }
    }
    
    /**
    * @description Private method to save ROADetail.
    */
    public class ROADetail {
        
        /**
         * @description public variable to save paymentAmount.
        */
        public Decimal paymentAmount { get; set; }
        /**
         * @description public variable to save comment.
        */
        public String comment { get; set; }
        /**
         * @description public variable to save sfReferenceNumber.
        */
        public String sfReferenceNumber { get; set; }
    }
    
    /**
    * @description Private method to save ROA_Detail_Mapping.
    */
    public class ROA_Detail_Mapping{
        @auraEnabled
        public  Decimal paymentAmount;
        @auraEnabled
        public String comment;
        @auraEnabled
        public Id sfReferenceNumber;
        
    /**
    * @description Private method to save ROA_Detail_Mapping.
    * @param paymentAmount The payment amount associated with this detail mapping.Should be a Decimal value.
    * @param comment The comment or note associated with this detail mapping.Should be a String.               
    * @param sfReferenceNumber The Salesforce reference number associated with this detail mapping. Should be an Id.
    */
        public ROA_Detail_Mapping(Decimal paymentAmount, String comment, Id sfReferenceNumber) {
            this.paymentAmount = paymentAmount;
            this.comment = comment;
            this.sfReferenceNumber = sfReferenceNumber;
        }
    }

    /**
    * Author: Kavita
    * Method Name : updateROADetailRecords
    * @description Updates ROA Detail records associated with a specific detail sequence number and JSON data.
    * @param detailSeqNumber The detail sequence number associated with the Payments__c records.
    * @param roaRecords JSON string representing a list of updated ROA Detail records.
    * @return List<ROA_Detail__c> List of updated ROA Detail records.
    */
    @AuraEnabled(cacheable=false)
    public static List<ROA_Detail__c> updateROADetailRecords(String detailSeqNumber, String roaRecords) {   
        List<Payments__c> paymentList = [SELECT Id FROM Payments__c WHERE RM_Detail_Sequence_Number__c = :detailSeqNumber WITH SECURITY_ENFORCED LIMIT 1 ];
        if(paymentList.isEmpty()){ 
            return new List<ROA_Detail__c>();
        }
        try{
            Id paymentId = paymentList[0].Id;
            List<ROADetail> roaDetailRecords = (List<ROADetail>) JSON.deserialize(roaRecords, List<ROADetail>.class);
            List<ROA_Detail__c> roaDetailsToUpdate = new List<ROA_Detail__c>();
            for (ROADetail record : roaDetailRecords) {
                Id roaId = record.sfReferenceNumber;
                ROA_Detail__c roaDetail = new ROA_Detail__c(
                    id = roaId,
                    payment__c = paymentId
                );
                roaDetailsToUpdate.add(roaDetail);
            }
            if(!roaDetailsToUpdate.isEmpty()) {
                if (Schema.sObjectType.ROA_Detail__c.isUpdateable()){
                    update roaDetailsToUpdate;
                }
            }
            return roaDetailsToUpdate;
        }catch(Exception ex){
            SBR_3_0_Log.logException(ex);
            return new List<ROA_Detail__c>();
        } finally {
            SBR_3_0_Log.saveLog();
        }
    }

    /**
    * Author: Kavita
    * Method Name : getROADetailRecords
    * @description Retrieves ROA Detail records associated with a specific payment ID.
    * @param paymentId The ID of the payment associated with the ROA Detail records.
    * @return List<ROA_Detail__c> List of ROA_Detail__c records related to the payment ID.
    * @throws AuraHandledException If an error occurs during record retrieval.
    */
    @AuraEnabled(cacheable=false)
	public static List<ROA_Detail__c> getROADetailRecords(String paymentId) {
        try {
            SBR_3_0_Log.setRelatedRecordId(paymentId);
            return [select Invoice_or_Comment__c,Payment_Amount__c from ROA_Detail__c where Payment__c =: paymentId WITH SECURITY_ENFORCED];
        } catch(Exception ex){
            SBR_3_0_Log.logException(ex);
            throw new AuraHandledException(ex.getMessage());
        } finally {
            SBR_3_0_Log.saveLog();
        }
    }
    
    /**
    * @description Retrieves specific details (Id, Status, Record_Type_Name__c) from an Order record based on the provided order ID.
    * @param orderId The ID of the order to retrieve details for.
    * @return List<Order> List of Order records containing the specified details.
    * @throws AuraHandledException If an error occurs during record retrieval.
    */
    @AuraEnabled(cacheable=false)
    public static List<Order> getrecordTypeDetailsFromOrder(Id orderId) {
       
        try {
            SBR_3_0_Log.setRelatedRecordId(orderId);
            List<Order> recordDetails = [SELECT Id, Status, Record_Type_Name__c FROM Order where Id=:orderId WITH SECURITY_ENFORCED]; 
            return recordDetails;
        } catch(Exception ex){
            SBR_3_0_Log.logException(ex);
            throw new AuraHandledException(ex.getMessage());
        } finally {
            SBR_3_0_Log.saveLog();
        }
    }
    
    /**
    * @description Retrieves the current Salesforce session ID of the user.
    * @return String The session ID of the current user.
    * @throws AuraHandledException If an error occurs during session ID retrieval.
    */
    @AuraEnabled( cacheable=true )
    public static String fetchSessionId() {
        try {
            return UserInfo.getSessionId();
        } catch(Exception ex){
            SBR_3_0_Log.logException(ex);
            throw new AuraHandledException(ex.getMessage());
        } finally {
            SBR_3_0_Log.saveLog();
        }  
    }
    
    /**
    * @description Retrieves a Transaction record based on the provided transaction ID.
    * @param transactionId The ID of the transaction to retrieve.
    * @return Transaction__c The Transaction record corresponding to the transaction ID.
    * @throws AuraHandledException If an error occurs during transaction retrieval.
    */
    @AuraEnabled(cacheable=false)
    public static Transaction__c getTransactionById(Id transactionId) {
        try {
            // Query the transaction record
            Transaction__c transactionRecord = [
                SELECT Id, Name,RM_Detail_Sequence_Number__c,Transaction_Error_Message__c
                FROM Transaction__c
                WHERE Id = :transactionId
                WITH SECURITY_ENFORCED
            ];
            return transactionRecord;
        } catch (Exception ex) {
            SBR_3_0_Log.logException(ex);
            throw new AuraHandledException('Error retrieving transaction: ' + ex.getMessage());
        }finally {
            SBR_3_0_Log.saveLog();
        } 
    }  
}