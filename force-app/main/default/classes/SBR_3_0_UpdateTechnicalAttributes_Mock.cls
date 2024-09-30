/*********************************************************************************************************************
* Apex Class: SBR_3_0_UploadPSCItems_Controller_Mock
----------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* SERV-8180 - Mock Class for Test Class : SBR_3_0_UpdateTechnicalAttributes_Test
----------------------------------------------------------------------------------------------------------------------
* History:
* VERSION     DEVELOPER NAME        DATE            MOD LOG
    1.0       Ritesh Mohapatra      2023-Dec-8     Initial version (SERV-8180)
	
**********************************************************************************************************************/
@isTest
global class SBR_3_0_UpdateTechnicalAttributes_Mock implements HttpCalloutMock
{
	global HTTPResponse respond(HTTPRequest request) {
        
        String jsonBody = '{"success":true,"message":"Technical Attribute value(s) saved successfully.","data":{"targetObject":"SVMXA360__SM_TA_AssetTechnicalAttribute__c","source":"External System","objectName":"Asset","attributeList":[{"value":"21","unit":"","timeOfOccurence":"","recordName":"","recordId":"02i8D000002AJZDQA4","dataType":"Number","attributeKey":"Calendar_Days_Number","assetIdentifiers":[{"value":"","identifierName":""}]},{"value":"600","unit":"","timeOfOccurence":"","recordName":"","recordId":"02i8D000002AJZDQA4","dataType":"Number","attributeKey":"Rental_Days_Number","assetIdentifiers":[{"value":"","identifierName":""}]},{"value":"30","unit":"","timeOfOccurence":"","recordName":"","recordId":"02i8D000002AJZDQA4","dataType":"Number","attributeKey":"Meter_Number","assetIdentifiers":[{"value":"","identifierName":""}]}],"assetIdentifierFieldAPIName":"Name"}}';
        
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody(jsonBody);
        response.setStatusCode(200);
        return response; 
    }
}