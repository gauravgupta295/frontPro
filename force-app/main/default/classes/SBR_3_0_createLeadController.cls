/*********************************************************************************************************************
* Apex Class: SBR_3_0_createLeadController
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* @description       : Fetch lat/long from zip code
* @last modified on  : 03-04-2024
* @last modified by  : Aishwarya Bansal
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
1.0         	Aishwarya Bansal        03-04-2024          Initial version  
*********************************************************************************************************************/
public class SBR_3_0_createLeadController {
    
    // Constants for the keys used in the result map.
    private static final String LATITUDE = 'latitude';
    private static final String LONGITUDE = 'longitude';
    
/**
* @param 1: line1 The first line of the address (e.g., street address).
* @param 2:  line2 The second line of the address
* @param 3:  city The city of the address.
* @param 4:  state The state of the address.
* @param 5: zip The postal code of the address.
* @param 6: country The country of the address.
* @description : Fetches latitude and longitude for a given address.
* @return : A map containing latitude and longitude as keys and their respective values. 
*         In case of an error, the map might be empty or contain error information.
*/
    @AuraEnabled(cacheable = true)
    public static Map<String, String> getAddressLatLong(String line1, String line2, String city, String state, String zip, String country) {
        Map<String, String> result;
        try {
            // Create an instance of the API handler class
            SBR_3_0_API_FetchLatLong strLatLongApi = new SBR_3_0_API_FetchLatLong();
            
            // Call the external API to fetch latitude and longitude
            result = strLatLongApi.getAddressLatLong(line1, line2, city, state, zip, country);
            
            // Log the API response for debugging purposes
            SBR_3_0_Log.logInfo('\n Address_Geocode Response = ' + result);
            
        } catch (Exception ex) {
            SBR_3_0_Log.logException(ex);
        } finally {
            SBR_3_0_Log.saveLog();
        }
        
        return result;
    }
}