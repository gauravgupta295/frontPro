/********************************************************************************************************************
* Apex Class: SBR_3_0_API_CreateWarrantyClaim
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Send Warranty claim to Rentalman (via Mulesoft) when a work order is closed
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Meghna Vijay          2023-01-17            Initial version
    2.0         Piyush Jindal         2023-03-21            Added an Invocable method (createWarrantyClaimRMCallout)
*********************************************************************************************************************/
public with sharing class SBR_3_0_API_CreateWarrantyClaim {
    private static final String APINAME = 'API_Warranty_Claim_Insert';
    private static final String X_CORRELATION_ID = SBR_3_0_Generic.generateRandomString(10);
    public static WorkOrderClaimParentReqWrapper requestBody = new WorkOrderClaimParentReqWrapper();

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Method is exposed to flows to make the Warranty Claim RM callout
    * Params: workOrderRecIdList (List of Work Order Ids)
    *********************************************************************************************************************/
    @InvocableMethod(label='ClaimRMCallout' description='Send claim to Rentalman (via Mulesoft) when a work order is closed' callout=true)
    public static void createClaimRMCallout(List<String> workOrderRecIdList) {
        
        if (!workOrderRecIdList.isEmpty() && !System.isFuture() && !System.isBatch()) {
            createWarrantyClaim(workOrderRecIdList[0]);
        }
    }

    public static void createWarrantyClaim(String workOrderRecId) {
        try {
            WorkOrder woRec = SBR_3_0_WarrantyClaimSelective.getWOClaimFieldsById(workOrderRecId);
            if(woRec != null){
                generateWrapper(woRec);
            }
            String payload = generateJSONPayload();
            String rentalManUserName = [
                    SELECT Wynne_User_Name__c 
                    FROM User 
                    WHERE Id=:woRec.OwnerId
                ]?.Wynne_User_Name__c;

            Map<String, String> getHeadersMap = new Map<String, String> {
                'companyId'          => woRec.SF_PS_Company_Code__c,
                'Content-Type'       => 'application/json',
                'x-correlation-Id'   => X_CORRELATION_ID,
                'sourceSystemName'   => 'Salesforce',
                'rentalmanUserId'    => rentalManUserName,
                'requestTimestamp'   => String.valueOf(woRec.LastModifiedDate.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSSSS\'Z\'')),
                'pc'                 => woRec.ServiceTerritory.Branch_Location_Number__c,
                'sourceSystemUserId' => woRec.CreatedBy.alias
            };
            SBR_3_0_HttpCallout httpCallout = new SBR_3_0_HttpCallout(APINAME);
            httpCallout.setHeadersMap(getHeadersMap);
            httpCallout.setRequestBody(payload);
            System.debug('requestPayload====='+payload);
            HttpResponse res = httpCallout.sendRequest();    
            String returnPayload = res.getBody();
            System.debug('returnPayload====='+ returnPayload);
            if (res.getStatusCode() == 200 || res.getStatus()== 'OK' ) {   
                WorkOrderClaimSuccessResponseWrapper successResponseWrap = (WorkOrderClaimSuccessResponseWrapper)JSON.deserialize(returnPayload, WorkOrderClaimSuccessResponseWrapper.class);  
                woRec.SF_PS_Claim_Num__c = String.valueOf(successResponseWrap.data.warrantyClaimNumber);
                SObjectAccessDecision decision = Security.stripInaccessible(AccessType.UPDATABLE,new List<WorkOrder>{woRec});
                update (List<WorkOrder>)decision.getRecords();
            } else {
                WorkOrderClaimErrorResponseWrapper errorResponseWrap = (WorkOrderClaimErrorResponseWrapper)JSON.deserialize(returnPayload,WorkOrderClaimErrorResponseWrapper.class);
                Exception_Log__c exc = new Exception_Log__c();
                exc.Exception_Message__c = (
                    res.getStatusCode()+'-'+'errorCode: '+errorResponseWrap.error.errorCode+'-'+
                    'errorKey: '+ errorResponseWrap.error.errorKey+ '-'+
                    'message: '+ errorResponseWrap.error.message
                );
                exc.Exception_Type__c = 'SF to RM Outbound Response';
                exc.Method_Name__c    = 'createWarrantyClaim';
                exc.Class_Name__c     = 'SBR_3_0_API_CreateWarrantyClaim';

                SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE,new List<Exception_Log__c>{exc});
                insert (List<Exception_Log__c>)decision.getRecords();
            }
        }
        catch(Exception error){
            SBR_3_0_LogException.LogIt(error);
            System.debug('Error Line -> ' + error.getStackTraceString()); 	// do not remove this debug log
            System.debug('Error Message -> ' + error.getMessage());			// do not remove this debug log
            //return error.getMessage();
        }
        

    }
    

    private static void generateWrapper(WorkOrder workOrderRec) {
        WorkOrderClaimParentReqWrapper workOrderClaimParentReqWrap = new WorkOrderClaimParentReqWrapper();
        WorkOrderClaimRequestWrapper workOrderClaimReqWrap = new WorkOrderClaimRequestWrapper();
        ClaimDetailsWrapper claimDetailsWrap = new ClaimDetailsWrapper();
        List<ClaimDetailsWrapper> claimDetailsWrapList = new List<ClaimDetailsWrapper>();
        List<WorkOrderClaimRequestWrapper> workOrderClaimReqWrapList = new List<WorkOrderClaimRequestWrapper>();

        workOrderClaimReqWrap.workOrderNumber = Integer.valueOf(workOrderRec.SF_PS_RM_WO_Number__c.substringAfter('-'));
        workOrderClaimReqWrap.labourCode = Integer.valueOf(workOrderRec.SF_PS_Claim_Labor_Code__c);
        workOrderClaimReqWrap.primaryPartNumber = workOrderRec.SF_PS_Primary_Part_Number__c;

        claimDetailsWrap.comment1 = workOrderRec.SF_PS_Claim_Comments1__c;
        claimDetailsWrap.comment2 = workOrderRec.SF_PS_Claim_Comments2__c;
        claimDetailsWrap.comment3 = workOrderRec.SF_PS_Claim_Comments3__c;
        claimDetailsWrapList.add(claimDetailsWrap);

        workOrderClaimReqWrap.claimDetails = claimDetailsWrapList;
        workOrderClaimReqWrapList.add(workOrderClaimReqWrap);
        workOrderClaimParentReqWrap.workOrderClaim = workOrderClaimReqWrapList;

        requestBody = workOrderClaimParentReqWrap;
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
    * WorkOrder Claim Parent Request Wrapper
    * Params:
    *********************************************************************************************************************/
    public class WorkOrderClaimParentReqWrapper {
       public List<WorkOrderClaimRequestWrapper>  workOrderClaim;
    }
    /*********************************************************************************************************************
    * Purpose/Methods:
    * WorkOrder Claim Request Wrapper
    * Params:
    *********************************************************************************************************************/
    public class WorkOrderClaimRequestWrapper {
        public Integer workOrderNumber;
        public Integer labourCode;
        public String primaryPartNumber;
        public List<ClaimDetailsWrapper> claimDetails;
    }
    /*********************************************************************************************************************
    * Purpose/Methods:
    * Claim Details Wrapper List
    * Params:
    *********************************************************************************************************************/
    public class ClaimDetailsWrapper {
        
        @TestVisible String comment1;
        String comment2;
        String comment3;
    }

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Inner class for Success Response Wrapper
    * Params:
    *********************************************************************************************************************/
    public class WorkOrderClaimSuccessResponseWrapper{
        public WorkOrderClaimDataResponseWrapper data;
    }


    /*********************************************************************************************************************
    * Purpose/Methods:
    * Inner class for Success Response Wrapper
    * Params:
    *********************************************************************************************************************/
    public class WorkOrderClaimDataResponseWrapper{
        public Integer warrantyClaimNumber{get;set;} 
        public String message{get;set;}
    }

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Class for error response 
    * Params:
    *********************************************************************************************************************/
    public class WorkOrderClaimErrorResponseWrapper {
        public ErrorResponseWrapper error;
    }

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Inner class for error response wrapper
    * Params:
    *********************************************************************************************************************/
    public class ErrorResponseWrapper {
        public String errorCode{get;set;}
        public String errorKey{get;set;}
        public String message{get;set;}
    }

}