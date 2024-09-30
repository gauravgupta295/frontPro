/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_CreateDamageEstimator
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Send Damage Estimator to Rentalman (via Mulesoft) when it is created in Salesforce
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
1.0         Meghna Vijay          2023-01-17             Initial version
2.0         Piyush Jindal         2024-01-30             Updating Damage Estimator record with SF_PS_Invoice_Number__c receieved from response
3.0         Piyush Jindal         2024-02-22             Removing SF_PS_Invoice_Number__c and updating the SF_PS_Invoice__c and SF_PS_Invoice_Sequence_Number__c fields on Damage Estimator record
4.0         Piyush Jindal         2024-02-27             Removed Test.isRunningTest after the creation of SBR_3_0_API_CreateDamageEstimatorMock class.
5.0         Piyush Jindal         2024-02-28             Added comments
*********************************************************************************************************************/

public with sharing class SBR_3_0_API_CreateDamageEstimator {
    private static final String APINAME = 'API_Damage_Estimator_Insert';
    private static final String X_CORRELATION_ID = SBR_3_0_Generic.generateRandomString(10);
    public static DamageEstimatorInvoiceParentReqWrapper requestBody = new DamageEstimatorInvoiceParentReqWrapper();
    /*********************************************************************************************************************
    * Purpose/Methods:
    * Method is used to make the callout and process the response.
    * Params: damageEstimatorIdSet (Set of Damage Estimator Id)
    *********************************************************************************************************************/
    @AuraEnabled
    public static DamageEstimatorSuccessErrorResponseWrapper createDamageEstimator(String damageEstimatorId) {
        try{
            DamageEstimatorSuccessErrorResponseWrapper damageEstimatorSuccessErrorResponseWrap = new DamageEstimatorSuccessErrorResponseWrapper();
            DamageEstimatorSuccessResponseWrapper successResponseWrap = new DamageEstimatorSuccessResponseWrapper();
            DamageEstimatorErrorResponseWrapper errorResponseWrap = new DamageEstimatorErrorResponseWrapper();
            SF_PS_Damage_Estimator__c damageEstimatorRec = SBR_3_0_DamageEstimatorSelective.getDamageEstimatorById(damageEstimatorId);
            if(damageEstimatorRec != null){
                generateWrapper(damageEstimatorRec);
            }

            String payload = generateJSONPayload();
            String rentalManUserName = [
                SELECT Wynne_User_Name__c 
                FROM User 
                WHERE Id=:damageEstimatorRec.SF_PS_Work_Order_Number__r.OwnerId
            ]?.Wynne_User_Name__c;
            
            Map<String, String> getHeadersMap = new Map<String, String> {
                'companyId'          => damageEstimatorRec.SF_PS_Work_Order_Number__r.SF_PS_Company_Code__c,
                'Content-Type'       => 'application/json',
                'x-correlation-Id'   => X_CORRELATION_ID,
                'sourceSystemName'   => 'Salesforce',
                'rentalmanUserId'    => rentalManUserName,
                'requestTimestamp'   => String.valueOf(damageEstimatorRec.SF_PS_Work_Order_Number__r.LastModifiedDate.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSSSS\'Z\'')),
                'pc'                 => damageEstimatorRec.SF_PS_Work_Order_Number__r.ServiceTerritory.Branch_Location_Number__c,
                'sourceSystemUserId' => damageEstimatorRec.SF_PS_Work_Order_Number__r.CreatedBy.alias
            };
                        
            SBR_3_0_HttpCallout httpCallout = new SBR_3_0_HttpCallout(APINAME);
            HttpRequest req = httpCallout.getRequest();
            req.setTimeout(30000);
            httpCallout.setHeadersMap(getHeadersMap);
            httpCallout.setRequestBody(payload);
            System.debug('payload====='+ payload);

            HttpResponse res = httpCallout.sendRequest();    
            String returnPayload = res.getBody();
            System.debug('returnPayload====='+ returnPayload);
            if (res.getStatusCode() == 200 || res.getStatus()== 'OK' ) {          
                successResponseWrap = (DamageEstimatorSuccessResponseWrapper)JSON.deserialize(returnPayload, DamageEstimatorSuccessResponseWrapper.class); 
                damageEstimatorSuccessErrorResponseWrap.damageEstimatorSuccessWrap = successResponseWrap;
                return damageEstimatorSuccessErrorResponseWrap;
            } else {
                errorResponseWrap = (DamageEstimatorErrorResponseWrapper)JSON.deserialize(returnPayload,DamageEstimatorErrorResponseWrapper.class);
                
                if(res.getStatusCode() == 400 && errorResponseWrap.error.errorCode.contains('009')) {
                    damageEstimatorSuccessErrorResponseWrap.damageEstimatorErrorWrap = errorResponseWrap;
                    return damageEstimatorSuccessErrorResponseWrap;
                }
                Exception_Log__c exc = new Exception_Log__c();
                exc.Exception_Message__c = (
                    res.getStatusCode()+'-'+'errorCode: '+errorResponseWrap.error.errorCode+'-'+
                    'errorKey: '+ errorResponseWrap.error.errorKey+ '-'+
                    'message: '+ errorResponseWrap.error.message
                );
                exc.Exception_Type__c = 'SF to RM Outbound Response';
                exc.Method_Name__c    = 'createDamageEstimator';
                exc.Class_Name__c     = 'SBR_3_0_API_CreateDamageEstimator';

                SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE,new List<Exception_Log__c>{exc});
                insert (List<Exception_Log__c>)decision.getRecords();
            }
        } catch(Exception error){
            SBR_3_0_LogException.LogIt(error);
            System.debug('Error Line -> ' + error.getStackTraceString()); 	// do not remove this debug log
            System.debug('Error Message -> ' + error.getMessage());			// do not remove this debug log
            
        }
        return null;
    }
    
    /*********************************************************************************************************************
    * Purpose/Methods:
    * Method is used to generate the Wrapper of Request payload
    * Params: damageEstimatorRec (Damage Estimator record)
    *********************************************************************************************************************/
    private static void generateWrapper(SF_PS_Damage_Estimator__c damageEstimatorRec) {
        DamageEstimatorInvoiceWrapper damageEstimatorInvoiceWrap = new DamageEstimatorInvoiceWrapper();
        DamageEstimatorInvoiceParentReqWrapper damageEstimatorReqWrap = new DamageEstimatorInvoiceParentReqWrapper();
        List<DamageEstimatorInvoiceWrapper> damageEstimatorInvoiceWrapperList = new  List<DamageEstimatorInvoiceWrapper>();
        damageEstimatorInvoiceWrap.workOrderNumber = damageEstimatorRec.SF_PS_Work_Order_Number__r.SF_PS_RM_WO_Number__c != null ? Integer.valueOf(damageEstimatorRec.SF_PS_Work_Order_Number__r.SF_PS_RM_WO_Number__c.substringAfter('-')) : null;
        damageEstimatorInvoiceWrap.contractNumber = damageEstimatorRec.SF_PS_Contract_Number__c != null ?Long.valueOf(damageEstimatorRec.SF_PS_Contract_Number__r.SM_PS_RM_Contract_Order_Number__c).intValue() : null;
        Integer completionDateDay = damageEstimatorRec.SF_PS_Estimated_Completion__c != null ? damageEstimatorRec.SF_PS_Estimated_Completion__c.day() : null;
        Integer completionDateMonth = damageEstimatorRec.SF_PS_Estimated_Completion__c != null ? damageEstimatorRec.SF_PS_Estimated_Completion__c.month() : null;
        Integer completionDateYear = damageEstimatorRec.SF_PS_Estimated_Completion__c != null ? damageEstimatorRec.SF_PS_Estimated_Completion__c.year() : null;
        String completionDateString = '';
        if(completionDateDay != null && completionDateMonth != null && completionDateYear != null) {
            String completingDateDayString = String.valueOf(completionDateDay).length() > 1 ? String.valueOf(completionDateDay) : '0'+String.valueOf(completionDateDay);
            String completingDateMonthString = String.valueOf(completionDateMonth).length() > 1 ? String.valueOf(completionDateMonth) : '0'+String.valueOf(completionDateMonth);
            completionDateString = String.valueOf(completionDateYear).removeStart('20')+completingDateMonthString+completingDateDayString;
        } 
        damageEstimatorInvoiceWrap.estimatedCostCompletionDate = completionDateString;
        System.debug('damageEstimatorInvoiceWrap.estimatedCostCompletionDate====='+ damageEstimatorInvoiceWrap.estimatedCostCompletionDate);
        damageEstimatorInvoiceWrap.estimatedCostLaborAmt = damageEstimatorRec.SF_PS_Estimated_Cost_Labor__c;
        damageEstimatorInvoiceWrap.estimatedCostLaborHrs = damageEstimatorRec.SF_PS_Estimated_Cost_Labor_Hours__c;
        damageEstimatorInvoiceWrap.estimatedCostMiscAmt = damageEstimatorRec.SF_PS_Estimated_Cost_Misc__c;
        damageEstimatorInvoiceWrap.estimatedCostPartsAmt = damageEstimatorRec.SF_PS_Estimated_Cost_Parts__c;
        damageEstimatorInvoiceWrap.equipmentNumber = damageEstimatorRec.SF_PS_WO_Equipment_Number__r.SM_PS_Equipment_Number__c;
        damageEstimatorInvoiceWrap.customerPoNumber = damageEstimatorRec.SF_PS_PO_Number__c;
        damageEstimatorInvoiceWrap.retailEstimateLaborAmt = damageEstimatorRec.SF_PS_Retail_Estimate_Cost_Labor__c;
        damageEstimatorInvoiceWrap.retailEstimateMiscAmt = damageEstimatorRec.SF_PS_Retail_Estimate_Cost_Misc__c;
        damageEstimatorInvoiceWrap.retailEstimatePartsAmt = damageEstimatorRec.SF_PS_Retail_Estimate_Cost_Parts__c;
        damageEstimatorInvoiceWrap.reasonCode = damageEstimatorRec.SF_PS_Estimator_Reason_Code__c;
        damageEstimatorInvoiceWrap.estimateComments = damageEstimatorRec.SF_PS_Estimate_Comment__c;
        damageEstimatorInvoiceWrap.invoiceComments1 = damageEstimatorRec.SF_PS_Invoice_Comment1__c;
        damageEstimatorInvoiceWrap.invoiceComments2 = damageEstimatorRec.SF_PS_Invoice_Comment2__c;
        damageEstimatorInvoiceWrap.invoiceComments3 = damageEstimatorRec.SF_PS_Invoice_Comment3__c;
        damageEstimatorInvoiceWrap.applyRppCoverage = damageEstimatorRec.SF_PS_Apply_RPP_Coverage__c;
        damageEstimatorInvoiceWrapperList.add(damageEstimatorInvoiceWrap);

        requestBody.damageEstimatorInvoice = damageEstimatorInvoiceWrapperList;
    }
    
    /*********************************************************************************************************************
    * Purpose/Methods:
    * Method is used to serailize the Request payload Wrapper.
    * Params:
    *********************************************************************************************************************/
    private static String generateJSONPayload() {
        String currentWrapper = '';
        if(!Test.isRunningTest()) {
            currentWrapper = JSON.serialize(requestBody).replace('null', '""');   
        } else {
            currentWrapper = JSON.serialize(requestBody);
        }
        return currentWrapper;
    }
    
    /*********************************************************************************************************************
    * Purpose/Methods:
    * Inner class for Success Error Response Wrapper
    * Params:
    *********************************************************************************************************************/
    public class DamageEstimatorSuccessErrorResponseWrapper {
        @AuraEnabled public DamageEstimatorSuccessResponseWrapper damageEstimatorSuccessWrap;
        @AuraEnabled public DamageEstimatorErrorResponseWrapper damageEstimatorErrorWrap;
    }
    /*********************************************************************************************************************
    * Purpose/Methods:
    * Inner class for Success Response Wrapper
    * Params:
    *********************************************************************************************************************/
    public class DamageEstimatorSuccessResponseWrapper{
        @AuraEnabled public Integer damageInvoiceNumber{get;set;}
        @AuraEnabled public Integer sequenceNumber{get;set;} 
        public String mode{get;set;}
        public string message;
        public string body{get;set;} 
        public list<String> headers{get;set;}
    }
    
    /*********************************************************************************************************************
    * Purpose/Methods:
    * Inner class for Parent Error Response Wrapper
    * Params:
    *********************************************************************************************************************/
    public class DamageEstimatorErrorResponseWrapper {
        public ErrorResponseWrapper error;
    }

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Inner class for Child1 Error Response Wrapper
    * Params:
    *********************************************************************************************************************/
    public class ErrorResponseWrapper {
        public String errorCode{get;set;}
        public String errorKey{get;set;}
        public String message{get;set;}
    }
    
    /*********************************************************************************************************************
    * Purpose/Methods:
    * Inner class for Parent Request Wrapper
    * Params:
    *********************************************************************************************************************/
    public class DamageEstimatorInvoiceParentReqWrapper {
        public List<DamageEstimatorInvoiceWrapper> damageEstimatorInvoice;
    }
    
    /*********************************************************************************************************************
    * Purpose/Methods:
    * Inner class for Child1 Request Wrapper
    * Params:
    *********************************************************************************************************************/
    public class DamageEstimatorInvoiceWrapper {
        public Integer contractNumber;
        public String estimatedCostCompletionDate;
        public Double estimatedCostLaborAmt;
        public Double estimatedCostLaborHrs;
        public Double estimatedCostMiscAmt;
        public Double estimatedCostPartsAmt;
        public String estimateComments;
        public String equipmentNumber;
        public String invoiceComments1;
        public String invoiceComments2;
        public String invoiceComments3;
        public String customerPoNumber;
        public Double retailEstimateLaborAmt;
        public Double retailEstimateMiscAmt;
        public Double retailEstimatePartsAmt;
        public String reasonCode;
        public Integer workOrderNumber;
        public String applyRppCoverage;
    }
}