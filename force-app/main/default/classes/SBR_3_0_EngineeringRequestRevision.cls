/*********************************************************************************************************************
* Apex Class: SBR_3_0_EngineeringRequestRevision
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Create a Revision for Engineering Request record if status is Canceled/Complete
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                        DATE                DETAIL FEATURES
    1.0         Aditee Churiwala                     2022-12-07              Initial version   
*********************************************************************************************************************/
public with sharing class SBR_3_0_EngineeringRequestRevision {    
    private static final String ORDER = 'Order';
    private static final String ONE = '1';
    private static final String DRAFT = 'Draft';
    private static final String ZERO = '0';
    @AuraEnabled
    public static String cloneEngineeringRequest(Id engRequestId, String originalRequestId) {
        List<Engineering_Request__c> listEngRequestDetails = new List<Engineering_Request__c>();
        List<String> response = new List<String>();
        try{
                System.debug('@@'+originalRequestId);
                System.debug('@@engRequestId'+engRequestId);
                List<Engineering_Request__c> engReq = SBR_3_0_EngineeringRequestDA.getEngineeringRequestDetails(engRequestId);
                Engineering_Request__c cloned = new Engineering_Request__c();
            	String sourceEngReqId = '';
                if (!engReq.isEmpty()) {
                    if(engReq[0].Source_Engineering_Request__c != null) {
                        sourceEngReqId = engReq[0].Source_Engineering_Request__c;
                    }
                }
                Schema.SObjectType objectTypeEngRequest = Engineering_Request__c.sObjectType;
                List<String> fieldNotToQuery = new List<String>{'OwnerId'};
                    List<sObject> cloneEngRequestList = SBR_3_0_CloneUtility.cloneObjects(engReq, objectTypeEngRequest, 'Id', fieldNotToQuery, true);
                    for(sObject cloneOi : cloneEngRequestList) {
                        cloned = (Engineering_Request__c)cloneOi;
                        //Id quoteCloneId = (Id)cloned.Id;
                        if (!engReq.isEmpty()) {
                            cloned.Eng_Job_Number__c = engReq[0].Eng_Job_Number__c;
                            cloned.Status__c = DRAFT;
                            if(engReq[0].Revision_Number__c != null || engReq[0].Revision_Number__c == ZERO) {
                                cloned.Revision_Number__c = String.valueOf(Integer.valueOf(engReq[0].Revision_Number__c) + 1);
                            }
                            else {
                                cloned.Revision_Number__c = ONE;
                            }
                        }
                        cloned.Requested_Due_Date__c = addBusinessDaysUpdated(System.NOW(), 3);
                        if(sourceEngReqId != '') {
                            cloned.Source_Engineering_Request__c = sourceEngReqId;
                        }
                        else {
                            cloned.Source_Engineering_Request__c = (Id)cloned.Id;
                        }
                        if(originalRequestId != null && originalRequestId != '') {
                            cloned.Original_Request__c = originalRequestId;
                            cloned.Requests_Type__c = ORDER;
                        }
                       else{
                            cloned.Original_Request__c = engRequestId;
                       }
                        cloned.Is_Submitted__c = false;
                        cloned.Id = null;
                        listEngRequestDetails.add(cloned);
                    } 
                    if(listEngRequestDetails.size()>0) {
                        insert listEngRequestDetails;
                    }
            System.debug('@@@listEngRequestDetails'+listEngRequestDetails);
             return listEngRequestDetails[0].Id;
            /*listQuoteDetails = SDS_SOQL_Quote.getQuoteDetails(quoteId);
            Id clonedQuoteId = cloneQuoteRecord(listQuoteDetails, quoteId, version, qName,delDate,oppId);
            cloneQuoteLineItemRecord(listQuoteDetails, clonedQuoteId, delDate);*/
        }
 		catch(Exception ex) {
            System.debug('@@@ex'+ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        }
    }   
    public static DateTime addBusinessDaysUpdated(DateTime startDate, Integer iDays) {
        Integer businessDaysAdded = 0;
        DateTime currentDate = startDate;
        
        while (businessDaysAdded < iDays) {
            // Add one day to the current date
            currentDate = currentDate.addDays(1);
            
            // Check if the current date is a weekend day
            if (currentDate.format('E') == 'Sat' || currentDate.format('E') == 'Sun') {
                // Skip the weekend day and continue adding the remaining days
                continue;
            }
            
            // Increment the number of business days added
            businessDaysAdded++;
        }
        currentDate = currentDate.addMinutes(1);
        System.debug('@@@1'+currentDate);
        return currentDate;
    }
    @AuraEnabled(cacheable = true)
    public static List<Engineering_Request__c> searchOriginalRequest(Id engRequestId) {
        List<Engineering_Request__c> relatedEngRequestList = new List<Engineering_Request__c>();
        try {
            List<Engineering_Request__c> engRequestList = SBR_3_0_EngineeringRequestDA.getEngineeringRequestDetails(engRequestId);
            if (!engRequestList.isEmpty()) {

                if(engRequestList[0].Source_Engineering_Request__c != null) {
                    relatedEngRequestList = SBR_3_0_EngineeringRequestDA.getSourceEngineeringRequest(engRequestList[0].Source_Engineering_Request__c);
                    //SAL-25986 - if source is not null we need get the , not just those that reference the source and put it in this list
                    List<Engineering_Request__c> source = new List<Engineering_Request__c>();
                    source = SBR_3_0_EngineeringRequestDA.getEngineeringRequestDetails(engRequestList[0].Source_Engineering_Request__c);
                    if(!source.isEmpty()) {
                        source[0].Revision_Number__c = ZERO;
                        relatedEngRequestList.addAll(source);
                    }
                }
                // SAL-25986 -  if the source is null we need to add the request to the list from which this action was initiated
                else {
                    engRequestList[0].Revision_Number__c = ZERO;
                    relatedEngRequestList.addAll(engRequestList);
                }
            }
            
        }
        catch(Exception e) {
            
        }
        System.debug('@@@relatedEngRequestList'+relatedEngRequestList);
        return relatedEngRequestList;
    } 
    
    
}