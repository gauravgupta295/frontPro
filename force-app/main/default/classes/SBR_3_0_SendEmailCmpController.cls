/*********************************************************************************************************************
* Apex Class: SBR_3_0_SendEmailCmpController
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Controller class for LWC component sbr_3_0_sendEmailCmp
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Piyush Jindal           2023-11-14          Initial version
    2.0         Piyush Jindal           2023-11-21          Changes made beacuse of new Request Payload
---------------------------------------------------------------------------------------------------------------------------------------
Note:-
* 
*********************************************************************************************************************/
public with sharing class SBR_3_0_SendEmailCmpController {

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Sends an email and returns the responseStatus (String)
    *********************************************************************************************************************/
    @AuraEnabled
    public static String sendEmail(String emailDetails) {
        User userObj = [SELECT Name, Branch__c, Phone, Fax from USER WHERE Id = :UserInfo.getUserId() LIMIT 1];

        String responsePayload = '';
        String requestBody = '';
        String responseStatus = '';
        SBR_3_0_SendgridEmailRequestWrapper.EmailWrapper emailWrapper = (SBR_3_0_SendgridEmailRequestWrapper.EmailWrapper) JSON.deserialize(emailDetails, SBR_3_0_SendgridEmailRequestWrapper.EmailWrapper.class);
        SBR_3_0_SendgridEmailRequestWrapper sendgridEmailRequestWrapper = new SBR_3_0_SendgridEmailRequestWrapper();
        sendgridEmailRequestWrapper.communicationData = new SBR_3_0_SendgridEmailRequestWrapper.communicationData();
        sendgridEmailRequestWrapper.emailDetails = new SBR_3_0_SendgridEmailRequestWrapper.EmailDetails();
        SBR_3_0_SendgridEmailRequestWrapper.EmailSenderWrapper senderWrapper = new SBR_3_0_SendgridEmailRequestWrapper.EmailSenderWrapper();
        SBR_3_0_SendgridEmailRequestWrapper.WorkOrderWrapper workOrderWrapper = new SBR_3_0_SendgridEmailRequestWrapper.WorkOrderWrapper();

        // assigning sender details to senderWrapper
        senderWrapper.senderName = userObj.Name;
        senderWrapper.senderBranchC = userObj.Branch__c;
        senderWrapper.senderPhone = userObj.Phone;
        senderWrapper.senderFax = userObj.Fax;

        // assigning work order details to workOrderWrapper
        workOrderWrapper.workOrderNumber = emailWrapper.workOrderDetails.workOrderNumber;
        workOrderWrapper.recordTypeC = emailWrapper.workOrderDetails.recordTypeC;
        workOrderWrapper.jobLocationC = emailWrapper.workOrderDetails.jobLocationC;
        workOrderWrapper.poNumberC = emailWrapper.workOrderDetails.poNumberC;
        
        // assigning senderWrapper and workOrderWrapper to 'communicationData' variable of sendgridEmailRequestWrapper
        sendgridEmailRequestWrapper.communicationData.workOrderData = workOrderWrapper;
        sendgridEmailRequestWrapper.communicationData.senderDetails = senderWrapper;

        // assigning email details to 'emailDetails' variable of sendgridEmailRequestWrapper
        sendgridEmailRequestWrapper.emailDetails.toEmailAddresses = new List<String>(emailWrapper.toAddresses);
        
        // assigning value of activityType to 'activityType' variable of sendgridEmailRequestWrapper
        sendgridEmailRequestWrapper.activityType = Integer.valueOf(SBR_3_0_SendgridEmailRequestUtility.WO_TEMPLATE_ACTIVITY_TYPE);

        // assigning all the uploaded attachments to 'attachments' variable of sendgridEmailRequestWrapper
        sendgridEmailRequestWrapper.attachments = new List<SBR_3_0_SendgridEmailRequestWrapper.AttachmentWrapper>(emailWrapper.attachmentData);

        requestBody = JSON.serialize(sendgridEmailRequestWrapper);

        // removing 'attachments' attribute from Request payload if no attachment is uploaded
        if((sendgridEmailRequestWrapper.attachments).isEmpty()){
            List<String> attachmentAttributes = new List<String>{'attachments'}; 
            requestBody = SBR_3_0_SendgridEmailRequestUtility.removeAttributeFromSerializedData(requestBody, attachmentAttributes);
        }

        // replacing attributes in Request payload so that the endpoint can process the Request payload
        requestBody = SBR_3_0_SendgridEmailRequestUtility.replaceAttributeInData(requestBody, SBR_3_0_SendgridEmailRequestUtility.oldToNewAttributeMap);

        // endpoint callout
        responsePayload = SBR_3_0_Generic_Callout.callEndpoint(requestBody, SBR_3_0_SendgridEmailRequestUtility.WO_EMAIL_API_NAME, SBR_3_0_SendgridEmailRequestUtility.COMPANY_CODE);
        
        if(responsePayload.containsIgnoreCase('success')) {
            responseStatus = 'success';
        } else {
            responseStatus = 'error';

            // Log exception if email is not sent.
            logException('sendEmail', responsePayload, responsePayload);
        }

        return responseStatus;
    }

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Creates a record of Exception Log.
    *********************************************************************************************************************/
    private static void logException(String methodName, String stackTrace, String errorMessage) {
        Map<String, String> exceptionParamsMap = new Map<String, String>{
            'ClassName'  => 'SBR_3_0_SendEmailCmpController',
            'MethodName' => methodName,
            'Type'       => '',
            'LineNumber' => '0',
            'StackTrace' => stackTrace,
            'Message'    => errorMessage
        };

        PPA_ExceptionLogHandler.createExceptionLog(exceptionParamsMap);
    }
}