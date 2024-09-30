/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_SyncAccount
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Send Account to Rentalman (via Mulesoft) when it is created in Salesforce
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
1.0         Pratiksha Kadam         2023-08-18             Initial version   
*********************************************************************************************************************/
public class SBR_3_0_API_SyncAccount {
    private static SyncAccountWrapper requestBody = new SyncAccountWrapper();
    private static final String APINAME_ACCOUNT_POST = 'API_Account_Insert';
    private static final String APINAME_ACCOUNT_PUT = 'API_Account_Update';
    private static final String X_CORRELATION_ID = SBR_3_0_Generic.generateRandomString(10);
	private static Boolean printException= false;
    
    public class SyncAccountWrapper{
        public UserWrapper data = new UserWrapper();       
    }
    
    public class parameterDetails{
        
        public string accountID;
       
        public String operation;
    }
    
   
    public static void SyncAccountRMCallout(List<parameterDetails> requestList) {
        String input = '';
        String operation = '';
        if (!requestList.isEmpty()) {
            input = requestList[0].accountID;
            operation = requestList[0].operation;            
            SyncAccount(input,operation);           
        }
    }
    
    @future(Callout = true)
    public static void SyncAccount(String accId,String operation) {
        String APINAME = '';
        Account acc = SBR_3_0_AccountDA.getAccountsForRM(accId);
        
        if(acc != null){
            generateWrapper(acc);
        }
        
        String payload = generateJSONPayload();
        if(operation == 'POST')
        {
           APINAME= APINAME_ACCOUNT_POST;
        }
        else
        {
         APINAME= APINAME_ACCOUNT_PUT;   
        }
        
        SBR_3_0_HttpCallout httpCallout = new SBR_3_0_HttpCallout(APINAME);
        HttpRequest req = httpCallout.getRequest();
        req.setMethod(Operation);
        req.setEndpoint(req.getEndpoint());
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('X-Correlation-ID', X_CORRELATION_ID);
        req.setHeader('companyId', acc.Company_Code__c);
        
        req.setTimeout(20000);
        req.setBody(payload);
        Http http = new Http();
        
        HTTPResponse res = http.send(req);
        
        String returnPayload = res.getBody();
        if (res.getStatusCode() == 201 || res.getStatus()== 'OK' || res.getStatusCode() == 200){
            

            SBR_3_0_SyncAccountJsonParser js=SBR_3_0_SyncAccountJsonParser.parse(res.getBody());
            acc.RM_Account_Number__c=js.data.rmAccountNumber;
            acc.Non_Credit_Integration_Status__c = true;
            update acc;
        }
        else{
            acc.Non_Credit_Integration_Status__c = false;
            update acc;
            insert new Exception_Log__c(Exception_Message__c = returnPayload, Class_Name__c = 'SBR_3_0_API_SyncAccount',
                                        Stack_Trace__c = 'Failed Payload : '+ payload);
        }
        if(printException==true){
            insert new Exception_Log__c(Exception_Message__c = label.SyncAccountExceptionMessage +UserInfo.getUserId()+'('+UserInfo.getName()+')', Class_Name__c = 'SBR_3_0_API_SyncAccount');
        }
    }
    
    public static void generateWrapper(Account acc) {
        //Added a Try-Catch block and a Null Check (PS-4457) - VS 
       	try{
            Id userId = UserInfo.getUserId();
            User_Location__c branch;
            List<User_Location__c> branchList= [SELECT Id, Branch__r.Branch_Location_Number__c FROM User_Location__c 
                                                WHERE User__C =: userId LIMIT 1];
            if(!branchList.isEmpty()){
                branch= branchList[0];
            }else{
                throw new SyncAccountException();
            }
        
            UserWrapper userObj = new UserWrapper();
            List<UserWrapper> userObjLst = new List<UserWrapper>();
            
            addressWrapper addressWrapperObj = new addressWrapper();
            List<addressWrapper> addressWrapperObjLst = new List<addressWrapper>();
            
            accDetailsClass accObj = new accDetailsClass();
            accObj.companyCode = acc.Company_Code__c;
            accObj.name = acc.Name;
            accObj.emailId = acc.E_mail_Address__c;
            accObj.driversLicenseState = acc.RM_Cash_State__c;
            accObj.driversLicenseNumber = acc.RM_Cash_Number__c;
            accObj.originalBranchNumber = branch.Branch__r.Branch_Location_Number__c;
            accObj.status = acc.Status__c;    
            accObj.comment = acc.Comments__c; 
            accObj.chargeForDW = acc.Charge_for_RPP__c; //SF-7116, FRONT-30431, FRONT-30569
            /*if(acc.Charge_for_RPP__c == true)    //Commenting as a part of SF-7116
                accObj.chargeForDW='Y';
            else{
                accObj.chargeForDW='N';
            }*/
            if(acc.BirthDate__c != null){
            accObj.dateOfBirth  = Integer.valueOf((String.valueOf(acc.BirthDate__c)).remove('-'));
            }
            if(String.isNotBlank(acc.Sales_Rep_Id__c)){
                accObj.salesRep = Integer.valueOf(acc.Sales_Rep_Id__c);
            }
            accObj.salesforceId = acc.SF_Account_Number__c;
            
            addressWrapperObj.line1 = acc.BillingStreet;
          
            addressWrapperObj.city = acc.BillingCity;
            addressWrapperObj.state = acc.BillingStateCode;
            addressWrapperObj.postalCode = acc.BillingPostalCode;
            addressWrapperObj.country = acc.BillingCountryCode;
            addressWrapperObj.phone = Long.valueOf(acc.Phone);
            addressWrapperObjLst.add(addressWrapperObj);
            accObj.address = addressWrapperObjLst;
            
            userObj.user = accObj;        
            requestBody.data = userObj;
        }
        catch(Exception e){
            //insert new Exception_Log__c(Exception_Message__c = label.SyncAccountExceptionMessage +UserInfo.getUserId()+'('+UserInfo.getName()+')', Class_Name__c = 'SBR_3_0_API_SyncAccount');
			printException= true;
        }
	}
    
    private static String generateJSONPayload() {
        String currentWrapper = JSON.serialize(requestBody,true);
         //String currentWrapper = JSON.serialize(requestBody).replace('null', '""');
        return currentWrapper;
    }
    
    public class UserWrapper{
        public accDetailsClass user;
    }
    public class accDetailsClass {
        public string companyCode;
        public string name;
        public string emailId ;
        public string driversLicenseState;
        public string driversLicenseNumber;
        public string originalBranchNumber;
        public string status;
        public string comment;
        public integer dateOfBirth;
        public integer salesRep;
        public string salesforceId;
        public List<addressWrapper> address;
        public string chargeForDW;
    }
    
    public class addressWrapper{
        public string line1; 
        
        public string city; 
        public string state;
        public string postalCode;
        public string country;
        public Long phone; 
    }
    
    public class SyncAccountException extends Exception {} 
}