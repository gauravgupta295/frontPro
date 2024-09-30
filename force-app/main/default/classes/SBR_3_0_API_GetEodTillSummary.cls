/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_GetEodTillSummary
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - @description get EOD Details from Rentalman (via Mulesoft) and create in salesforce
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Vivek Sharma          2024-03-18            Initial version    
*********************************************************************************************************************/
public class SBR_3_0_API_GetEodTillSummary {
    private static final String API_EOD_GET_TILL_SUMMARY = 'GET_TILL_SUMMARY';
    private static final String API_EOD_GET_ROA_CASH_CONTROL = 'GET_ROA_CASH_CONTROL';
    private static final String API_EOD_GET_CASH_INVOICE = 'GET_CASH_INVOICE';
    private static final String API_EOD_GET_INTERCOMPANY_DETAILS = 'GET_INTERCOMPANY_DETAILS'; //contract open at other location
    private static final String API_EOD_GET_NEW_DEPOSITS = 'GET_NEW_DEPOSITS';
    private static final String API_EOD_GET_ADDITIONAL_DEPOSITS = 'GET_ADDITIONAL_DEPOSITS';
    private String companyId;
    private String pc;
    private String sourceName;
    @TestVisible
    private static Object response;
    /**
    * @description BadRequestException.
    */
    public class BadRequestException extends Exception{}
    
    /**
    * @description AuraEnabled method to create payments.
    * @param tillDate Date of the till
    * @param userId Id of the user creating the till.
    * @param sourceName from where it is called.
    * @return Object representing the response from the API call.
    * @throws BadRequestException If the API returns an error, it throws a BadRequestException with details.
    */
    @AuraEnabled
    public static object getTillSummary(String tillDate , Id userId ,String sourceName) {
        SBR_3_0_HttpCallout.dateSelected = tillDate;
        new SBR_3_0_API_GetEodTillSummary(userId, sourceName);
        Map<String, Object> responseMap = (Map<String, Object>) response;
        if(responseMap != null) {
            if(responseMap.containsKey('error')){
                String jsonExceptionString = JSON.serialize(responseMap);
                SBR_3_0_Log.logInfo(jsonExceptionString);
                throw new BadRequestException(jsonExceptionString);
            }      
        }
        return response;
    }
    
    /**
    * @description Utility class to retrieve End of Day (EOD) summary information based on different sources.
    * @param userId Id of the user creating the till.
    * @param sourceName from where it is called
    */
    public SBR_3_0_API_GetEodTillSummary(Id userId, String sourceName) {
        try{
            this.sourceName = sourceName;
            List<User> users =new List<User>(SBR_3_0_OrderDA.getUsers(userId));
            for (User use : users) {
                this.companyId = use.CompanyName;
                this.pc = use.Department;
            }
            callEODTillSummary();
        }catch(Exception ex){
            SBR_3_0_Log.logException(ex);
            throw new AuraHandledException(ex.getMessage());
        }finally {
            SBR_3_0_Log.saveLog();  
        } 
    }

    /**
    *@description Calls the appropriate API endpoint based on the specified source name to retrieve EOD summary data.
    */
    private void callEODTillSummary(){
        try{
            String returnPayload = '';
            If (sourceName == 'Next'){
                returnPayload = SBR_3_0_Generic_Callout.callEndpointEod(API_EOD_GET_TILL_SUMMARY, this.companyId,this.pc);
            }
            else if (sourceName == 'CashROA'){
                returnPayload = SBR_3_0_Generic_Callout.callEndpointEod(API_EOD_GET_ROA_CASH_CONTROL, this.companyId,this.pc);  
            }
            else if (sourceName == 'CashInvoice'){
                returnPayload = SBR_3_0_Generic_Callout.callEndpointEod(API_EOD_GET_CASH_INVOICE, this.companyId,this.pc);  
            }
            else if (sourceName == 'NewDeposits'){
                returnPayload = SBR_3_0_Generic_Callout.callEndpointEod(API_EOD_GET_NEW_DEPOSITS, this.companyId,this.pc);  
            }  
            else if (sourceName == 'InterCompanyDetails'){
                returnPayload = SBR_3_0_Generic_Callout.callEndpointEod(API_EOD_GET_INTERCOMPANY_DETAILS, this.companyId,this.pc);
            } else if (sourceName == 'AdditionalDeposits'){
                returnPayload = SBR_3_0_Generic_Callout.callEndpointEod(API_EOD_GET_ADDITIONAL_DEPOSITS, this.companyId,this.pc);
            }
            response = JSON.deserializeUntyped(returnPayload);
        }catch(Exception Ex){
            SBR_3_0_Log.logException(ex);
        }   
    }
}