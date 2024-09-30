/*********************************************************************************************************************
* Apex Class: SBR_3_0_GenerateFeedbackJson
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to Create the Json from the Data insert into the Product Recommendation Feedback Object
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Manish Taneja            26 Sep,2023          Initial version    
*********************************************************************************************************************/
public with sharing class SBR_3_0_GenerateFeedbackJson {
    public static String processRecords(List<Product_Recommendation_Feedback__c> records) {
        List<Map<String, Object>> feedbackList = new List<Map<String, Object>>();
        String FeedbackJson = '[';
        for (Product_Recommendation_Feedback__c record : records) {
            Map<String, Object> feedbackDataItem = new Map<String, Object>();
            feedbackDataItem.put('salesforceFeedbackId', record.Salesforce_Feedback_ID__c);
            if(record.Additional_comments__c != NULL){
            	feedbackDataItem.put('comments', record.Additional_comments__c);    
            }
            else{
                feedbackDataItem.put('comments', '');
            }
            feedbackDataItem.put('productFeedback', record.Feedback_Type__c);
            feedbackDataItem.put('catClass', record.Cat_Class_Key__c);
            feedbackDataItem.put('modelVersion', record.Model_Version__c);
        
            feedbackList.add(feedbackDataItem);
        }
        
        if (!feedbackList.isEmpty()) {
            Map<String, Object> outerJSON = new Map<String, Object>();
            outerJSON.put('feedbackData', feedbackList);
            outerJSON.put('accountNumber', records[0].Account_number__c); // Assuming all records have the same 'AccountNumber'
            outerJSON.put('salesRepID', records[0].Rep_ID__c); // Assuming all records have the same 'SalesRepID'
            outerJSON.put('companyCode', String.valueOf(records[0].Company_Code__c)); // Assuming all records have the same 'CompanyCode'
            
            // Convert the outer JSON object to a JSON string
            feedbackJSON = feedbackJSON + JSON.serialize(outerJSON);
            FeedbackJson = FeedbackJson + ']';
            System.debug('Generated JSON: ' + feedbackJSON);
        }
        return feedbackJSON;
    }
}