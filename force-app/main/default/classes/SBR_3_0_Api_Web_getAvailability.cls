/**
 * 
 * @author Thomas E. Canter
 * @since 9/13/2022
 */
@RestResource(urlMapping = '/Availability/v1/getAvailability/*')
global with sharing class SBR_3_0_Api_Web_getAvailability {
    @HttpPost
    /**
     * 
     * @param levelName this is the level in the company heirarchy to get availability for, Branch, Region, District
     * @param levelId The id of the level, the query parameter in the correct field to return results
     * @param catClass The product name of the product to get availabilty for
     */    
    global static void getAvailabilityWeb(String levelName, String levelId, String catClass)
    {
        String uLevelName = levelName.toUpperCase();
        RestResponse restRes = RestContext.response;
        if (restRes == null) {
            restRes = new RestResponse();
            RestContext.response = restRes;
        }
        RestContext.response.addHeader('Content-Type', 'application/json');
        restRes.statusCode = 200;
        String response = '{"errorMessage":"no results found"}';
        List<AggregateResult> availabilityResults = getAvailability(levelName, levelId, catClass);
        if(availabilityResults != null && availabilityResults.size() != 0){
            restRes.responseBody = Blob.valueOf(JSON.serialize(availabilityResults));
        } 
    }
    global static List<AggregateResult> getAvailability(String levelName, String levelId, String catClass)
    {
        String uLevelName = levelName.toUpperCase();
        List<AggregateResult> availabilityResults = null;
        String[] queryParameters = new String[]{'Branch_Location_Number__c', 'Branch', 'Name', levelId, catClass};
        SBR_3_0_Api_Web_Availability ab = null;
        Boolean queryReady = false;
        switch on uLevelName {
            when 'BRANCH' {	
                queryParameters[2] = 'Name';
                queryReady = true;
            }	
            when 'DISTRICT' {
                queryParameters[2] = 'District__c';
                queryReady = true;
            }
            when 'REGION' {	
                queryParameters[2] = 'Region__c';
                queryReady = true;
            }
            when 'TERRITORY' {
                queryParameters[2] = 'Territory__c';
                queryReady = true;
            }
            when 'COMPANY' {
                queryParameters[2] = 'Company__c';
                queryReady = true;
            }
        }
        if(queryReady){
            ab = new SBR_3_0_Api_Web_Availability(queryParameters);
            if(ab?.availability != null && ab.availability.size() != 0){
                availabilityResults = ab.availability;
            }
            
        }
        return availabilityResults;
    }
}