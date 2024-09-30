/*********************************************************************************************************************
* Apex Class: SBR_3_0_UpdateTechnicalAttributes
----------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* Apex action to update technical attributes
----------------------------------------------------------------------------------------------------------------------
* History:
* VERSION     DEVELOPER NAME          DATE          DETAIL FEATURES
    1.0       Ritesh Mohapatra      2023-Dec-7      Initial version
**********************************************************************************************************************/

public class SBR_3_0_UpdateTechnicalAttributes {
    @InvocableMethod(label='Update Technical Attributes' 
                     description='Method to update technical attributes of Asset'
                     category='Technical Attributes')
    public static void updateTechAttributes(List<Requests> requestList)
    {
        String calendarDaysValue = requestList.get(0).calDays;
        String rentalDaysValue = requestList.get(0).renDays;
        String meterValue = requestList.get(0).meter;
        String assetRecordIdValue = requestList.get(0).assetRecordId;
        
        JSONGenerator updateJson = JSON.createGenerator(false);
        
        updateJson.writeStartObject();
        updateJson.writeStringField('source', 'External System');
        updateJson.writeStringField('objectName', 'Asset');
        updateJson.writeStringField('assetIdentifierFieldAPIName', 'Name');
        
        	updateJson.writeFieldName('attributeList');
            updateJson.writeStartArray();
        	if(calendarDaysValue!=null)
            {
                updateJson.writeStartObject();
                updateJson.writeStringField('value', calendarDaysValue);
                updateJson.writeStringField('unit', '');
                updateJson.writeStringField('attributeKey','Calendar_Days_Number');
                updateJson.writeStringField('dataType', 'Number');
                updateJson.writeStringField('timeOfOccurence', '');
                updateJson.writeStringField('recordName', '');
                updateJson.writeStringField('recordId', assetRecordIdValue);
                	updateJson.writeFieldName('assetIdentifiers');
                	updateJson.writeStartArray();
                    updateJson.writeStartObject();
                		updateJson.writeStringField('identifierName', '');
                		updateJson.writeStringField('value', '');
                	updateJson.writeEndObject();
                	updateJson.writeEndArray();
                updateJson.writeEndObject();
            }
        
        	if(rentalDaysValue!=null)
            {
                updateJson.writeStartObject();
                updateJson.writeStringField('value', rentalDaysValue);
                updateJson.writeStringField('unit', '');
                updateJson.writeStringField('attributeKey','Rental_Days_Number');
                updateJson.writeStringField('dataType', 'Number');
                updateJson.writeStringField('timeOfOccurence', '');
                updateJson.writeStringField('recordName', '');
                updateJson.writeStringField('recordId', assetRecordIdValue);
                	updateJson.writeFieldName('assetIdentifiers');
                	updateJson.writeStartArray();
                    updateJson.writeStartObject();
                		updateJson.writeStringField('identifierName', '');
                		updateJson.writeStringField('value', '');
                	updateJson.writeEndObject();
                	updateJson.writeEndArray();
                updateJson.writeEndObject();
            }
        
        	if(meterValue!=null)
            {
                updateJson.writeStartObject(); 
                updateJson.writeStringField('value', meterValue);
                updateJson.writeStringField('unit', '');
                updateJson.writeStringField('attributeKey','Meter_Number');
                updateJson.writeStringField('dataType', 'Number');
                updateJson.writeStringField('timeOfOccurence', '');
                updateJson.writeStringField('recordName', '');
                updateJson.writeStringField('recordId', assetRecordIdValue);
                	updateJson.writeFieldName('assetIdentifiers');
                	updateJson.writeStartArray();
                    updateJson.writeStartObject();
                		updateJson.writeStringField('identifierName', '');
                		updateJson.writeStringField('value', '');
                	updateJson.writeEndObject();
                	updateJson.writeEndArray();
                updateJson.writeEndObject();
            }
        
        updateJson.writeEndArray(); 
		updateJson.writeEndObject();
        
        System.debug('**UpdateJson BODY: '+updateJson.getAsString());
        
        updateCallout(updateJson.getAsString());
 
    }
    
    @future(callout = true)
    public static void updateCallout(string jsonString){
        // Instantiate a new Http object
        Http h = new Http();
    
        // Instantiate a new HTTP request, specify the method (GET) as well as the endpoint
        HttpRequest req = new HttpRequest();
        req.setEndpoint(URL.getOrgDomainURL().toExternalForm()+'/services/apexrest/SVMXA360/technicalAttribute/v1/saveTechnicalAttributes/');
        req.setMethod('POST');
        req.setHeader('Content-Type','application/json'); 
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId()); 
        req.setBody(jsonString);
    	
        try
        {
            // Send the request, and return a response
        	HttpResponse res = h.send(req);
            System.debug('RESPONSE BODY: '+res.getBody());
        }
        catch(Exception ex)
        {
            System.debug('Error: '+ex.getMessage());
        }
    }
    public class Requests {
        @InvocableVariable(label = 'Calendar Days' 
                           description = 'Maps Days since Date Commissioned (SM_PS_Days_Since_Date_Commissioned__c) from Asset'
                           required = false)
        public String calDays;
        
        @InvocableVariable(label = 'Rental Days' 
                           description = 'Maps Days on Rent Life to Date field on Asset (SM_PS_Life_to_Date_Days_Rent__c) from Asset'
                           required = false)
        public String renDays;
        
        @InvocableVariable(label = 'Meter' 
                           description = 'Maps Current Mi/Hr field on Asset (SM_PS_Current_MiHr__c) from Asset'
                           required = false)
        public String meter;
        
         @InvocableVariable(label = 'Asset Id' 
                           description = 'Stores RecordId of Asset'
                           required = true)
        public String assetRecordId;

    }
}