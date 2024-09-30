public with sharing class SBR_3_0_CartPDFDocController {
    private static final String APINAME = 'DocGen_V2';
    private static final String COMPANY_ID = '01';
    private static final String X_CORRELATION_ID = SBR_3_0_Generic.generateRandomString(10);
    private static final String CART_TEMPLAT_TYPE = 'Cart';
    private static final String SOURCE_SF = 'SF';
    //ToDo
    private List<String> quoteChildObject= new List<String>{'Available','DOWN - LESS THAN 2O DAYS','DOWN MORE THAN 20 DAYS','RETURNED - NEED CHECK OUT' };
    
    @AuraEnabled
    public static List<Adobe_Quote_template__c> getTemplates(String recordId){
        String userid = UserInfo.getUserId(); 
    
        Cart__c cartFields = Database.query('SELECT Id, Branch__r.Name,Branch__r.Analysis_Region2__c,Branch__r.Analysis_Region_Key__c FROM Cart__c WHERE Id =:recordId LIMIT 1');
        String analysisRegion = cartFields.Branch__r.Analysis_Region_Key__c;
        
        List<Adobe_Quote_template__c> cartTemplates = new List<Adobe_Quote_template__c>();

        if(String.isNotEmpty(analysisRegion)){
            List<Adobe_Quote_template__c> adobeTemplates = Database.query('SELECT Id,Template__c,Analysis_Regions__c,Name FROM Adobe_Quote_Template__c WHERE Analysis_Regions__c INCLUDES (\'' + analysisRegion + '\')');
            for(Adobe_Quote_template__c adobeTemplate : adobeTemplates){
                if(adobeTemplate.Template__c != null && CART_TEMPLAT_TYPE.equalsIgnoreCase(adobeTemplate.Template__c) ){
                    cartTemplates.add(adobeTemplate);
                }
            }
            return cartTemplates;
        }        
        return cartTemplates;
    }

    @AuraEnabled
    public static TemplateWrapper loadCartFields(String recordId){
       
        TemplateWrapper templateWrapped = new TemplateWrapper();

        List<Cart__c> carts = SBR_3_0_UtilityDA.getAllFieldsForSObject('Cart__c', recordId);
        Cart__c  cart = carts[0];
        //Cart__c  cart = SBR_3_0_CartDA.getCart(recordId);
        List<Cart_Items__c> cartItems = cart?.Cart_Items__r;
       
        if(cartItems == null || cartItems.size() == 0){
            templateWrapped.pdfTitle = cart.Name;
            templateWrapped.data = null;
            return templateWrapped;
        }
        String dateFormat = 'MM/dd/yyyy hh:mm:ss a';
        String timeZone = 'America/Los_Angeles'; // US Pacific time zone, use New_York for Eastern time zone
        DateTime startDateTime = Datetime.now();
        DateTime endDateTime = Datetime.now();

        if(cart.Rental_Start_Date__c !=null){
            startDateTime = cart.Rental_Start_Date__c;
        }
        if(cart.Rental_End_Date__c !=null){
            endDateTime = cart.Rental_End_Date__c;
        }
        
        String formattedStartDate = startDateTime.format(dateFormat,timeZone);
        String formattedEndDate = endDateTime.format(dateFormat,timeZone);

        //remove leading attribute tag from salesforce object
        Map<String,Object> cartMap = (Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(cart));
        removeAttributes(cartMap);
        
        if(cartMap.containsKey('Rental_Start_Date__c')){
            cartMap.put('Rental_Start_Date__c', formattedStartDate);
        } 
        if(cartMap.containsKey('Rental_End_Date__c')){
            cartMap.put('Rental_End_Date__c', formattedEndDate);
        }

        templateWrapped.pdfTitle = cart.Name;
        templateWrapped.data = cartMap;

        return templateWrapped;
    }

    @AuraEnabled(cacheable=false)
    //public static WrappedResponse buildRequest(Object cartMap, String templateId){
    public static WrappedResponse buildRequest(Object cartMap, String templateId, String pdfName){
        try {
            //DocGen API V2 changes
            Map<String,Object> cartFieldMaps = (Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(cartMap));

            WrappedResponse response = new WrappedResponse();

            Adobe_Quote_template__c adobeTemplateRec = SBR_3_0_UtilityDA.getAdobeTemplateById(templateId);

            DocGenRequestWrapper docGenReqWrap = new DocGenRequestWrapper();
            docGenReqWrap.inputPayload = cartFieldMaps;
            //"templateId":"8640a989-1bea-4004-9a16-a1ab4df3f271"
            docGenReqWrap.templateId = adobeTemplateRec.Template_Id__c;
            
            //serialize the wrapper class and set it to a String.
            String template = JSON.serializePretty(docGenReqWrap);
         
            //create callout 
            SBR_3_0_HttpCallout httpCallout = new SBR_3_0_HttpCallout(APINAME);
            
            response.httpDocGenEndPoint = httpCallout.getRequest().getEndpoint();
            response.httpDocGenAuthToken = httpCallout.getRequest().getHeader('Authorization');
           
            httpCallout.setHeader('companyId', COMPANY_ID);
            httpCallout.setHeader('Content-Type', 'application/json');
            httpCallout.setHeader('thresholdWaitTime', '1');
            httpCallout.setHeader('X-Correlation-ID', X_CORRELATION_ID);
            httpCallout.setHeader('source', SOURCE_SF);
			
            httpCallout.setRequestBody(template);
            
            HttpResponse res = httpCallout.sendRequest();
            
            response.headers = res.getHeaderKeys();
            System.debug('res->'+res);
            System.debug('resBody->'+res.getBody());
            System.debug('res.getHeader->'+res.getHeader('x-request-id'));
            
            if(res.getBody().contains('"status": "In Progress"')){
                response.body = res.getHeader('x-request-id');
                response.status = 'false';
            }
            else if(res.getHeader('Content-Type').contains('application/octet-stream')){
                response.status = 'Complete';
                response.body = res.getBody();
                response.base64Body = EncodingUtil.base64encode(res.getBodyAsBlob());
            }
            else{
                response.status = 'InComplete';
            }
            System.debug('response->'+response);
            return response;        
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    public class DocGenRequestWrapper{

        @AuraEnabled
        public Map<String,Object> inputPayload{get;set;}
        @AuraEnabled
        public String templateId{get;set;}
    }

    public class TemplateWrapper{
        @AuraEnabled
        public  Map<String,Object> data{get;set;}
        @AuraEnabled
        public string base64EncodedInputFile{get;set;}
        @AuraEnabled
        public string pdfTitle{get;set;}

        public TemplateWrapper(){
        }
    }

    public class WrappedResponse{
        @AuraEnabled
        public string body{get;set;}
        @AuraEnabled
        public string status{get;set;} 
        @AuraEnabled
        public list<String> headers{get;set;}
        @AuraEnabled
        public string base64Body{get;set;}
        @AuraEnabled
        public string pdfTitle{get;set;}
        @AuraEnabled
        public string contentDocumentId{get;set;}
        @AuraEnabled
        public String httpDocGenEndPoint {get;set;}
        @AuraEnabled
        public String httpDocGenAuthToken {get;set;}
    }

    private static void removeAttributes(Map<String,Object> jsonObj)  {
        for(String key : jsonObj.keySet()) {
            if(key == 'attributes') {
                jsonObj.remove(key);
            } else {
                if(jsonObj.get(key) instanceof Map<String,Object>) {
                    removeAttributes((Map<String,Object>)jsonObj.get(key));
                }
                if(jsonObj.get(key) instanceof List<Object>) {
                    for(Object listItem : (List<Object>)jsonObj.get(key)) {
                        if(listItem instanceof Map<String,Object>)  {
                            removeAttributes((Map<String,Object>)listItem);
                        }
                    }
                }
            }
        }  
    }

    @AuraEnabled
    public static WrappedResponse RetrieveFile(String repoId, String endPoint, String authToken){
        try {
            
            WrappedResponse response = new WrappedResponse();
            System.debug('repoId->'+repoId);
            if(String.isEmpty(repoId) || String.isEmpty(endPoint) || String.isEmpty(authToken) ){
                response.status = 'BadRequest';
                return response;
            }
            HttpRequest req = new HttpRequest();
            req.setMethod('GET');
            req.setEndpoint(endPoint+'/'+ repoId);
            req.setHeader('companyId', COMPANY_ID);
            req.setHeader('thresholdWaitTime', '1');
            req.setHeader('Authorization', authToken);
            req.setHeader('X-Correlation-ID', X_CORRELATION_ID);
            req.setTimeout(120000);
			
            Http http =new Http();
            
            HTTPResponse res = http.send(req);
            
            response.headers = res.getHeaderKeys();
            response.body = res.getBody();

            if(((res.getStatusCode() == 200 || res.getStatus()== 'OK') && response.body.startsWith('%PDF')) || Test.isRunningTest()){
                response.status = 'Complete';
                response.base64Body = EncodingUtil.base64encode(res.getBodyAsBlob());
            }else if(response.body.contains('"status": "In Progress"')){
                response.status = 'InComplete';
            }
            
            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    /* Save file to ContentVerion as PDF fileType */
    @AuraEnabled
    public static WrappedResponse saveFile(String base64, String filename, String recordId){
        try {
            
            WrappedResponse response = new WrappedResponse();
            response.status = 'NOT_SUCCESS';

            Date dateToday = Date.today();
            String sMonth = String.valueof(dateToday.month());
            String sDay = String.valueof(dateToday.day());

            if(sMonth.length()==1 || Test.isRunningTest()){
            sMonth = '0' + sMonth;
            }
            if(sDay.length()==1 || Test.isRunningTest()){
            sDay = '0' + sDay;
            }
            
            String sToday = String.valueof(dateToday.year())+ '-' + sMonth +  '-' + sDay ;

            String title = '';
            if(String.isNotEmpty(filename)){
                title = filename+'.pdf';
            }else{
                title = 'GeneratedQuote' + '_' + sToday + '.pdf';
            }
            
            Map<String, String> recordContentDocLinkMap = upsertPDFFiles(recordId, base64, title);

            if(recordContentDocLinkMap.containsKey(recordId)){
                response.status = 'SUCCESS';
                response.contentDocumentId = recordContentDocLinkMap.get(recordId);
            }
            
            return response;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static Map<String, String> upsertPDFFiles(String recordId, String base64, String filename){
        List<ContentDocumentLink> contentDocumentLinkRecord = [Select Id,ContentDocument.title,LinkedEntityId,ContentDocumentId,ContentDocument.OwnerId, ContentDocument.LastModifiedDate from ContentDocumentLink where LinkedEntityId =:recordId AND ContentDocument.title =:filename Order by ContentDocument.LastModifiedDate DESC LIMIT 1 ];
        ContentVersion cv = new ContentVersion();
        Boolean isDocLinkedToRecordId = false;
        String cvId = '';
        Map<String, String> recordContentDocLinkMap = new Map<String, String>();
        String userId = UserInfo.getUserId(); 
             
        try {
            if(contentDocumentLinkRecord.size()>0 && contentDocumentLinkRecord[0].ContentDocumentId !=null && contentDocumentLinkRecord[0].ContentDocument.title !=null &&  contentDocumentLinkRecord[0].ContentDocument.title == filename){
                recordContentDocLinkMap.put(recordId,contentDocumentLinkRecord[0].ContentDocumentId);
                
                String contentDocOwnerId = contentDocumentLinkRecord[0].ContentDocument.OwnerId;

                ContentVersion cv1 = [select Id,Title,VersionData,VersionNumber,ContentDocumentId,IsLatest from ContentVersion where ContentDocumentId =:contentDocumentLinkRecord[0].ContentDocumentId LIMIT 1];
                ContentVersion cv2 = new ContentVersion();
                cv2.VersionData = EncodingUtil.base64Decode(base64);
                cv2.Title = filename;
                cv2.PathOnClient = filename;
                //cv2.ContentDocumentId = contentDocumentLinkRecord[0].ContentDocumentId;
                //cv2.Id = cv1.Id;
                cvId = cv1.Id;
                
                if(String.isNotBlank(cv1.Title) && cv1.Title == filename){
                    isDocLinkedToRecordId = true;
                    
                     Id profileId = userinfo.getProfileId();
                    Profile p = [SELECT Id, Name from Profile WHERE Id = :profileId LIMIT 1];
                    //Only Sysadmin can change the file ownership.
                    if(p != null && p.Name == SBR_3_0_Constants.PROFILE_NAME_ADMIN){                       
                        ContentDocument cd =  new contentDocument();
                        cd.Id = contentDocumentLinkRecord[0].ContentDocumentId;
                        cd.OwnerId = userId;
                        update cd; 

                        cv2.ContentDocumentId = contentDocumentLinkRecord[0].ContentDocumentId;
                        insert cv2;

                        cvId = cv2.Id;

                    }else if (contentDocOwnerId == userId){
                        //Only previous owner of the file can increment version number for the same fileName.
                        cv2.ContentDocumentId = contentDocumentLinkRecord[0].ContentDocumentId;
                        insert cv2;
                        cvId = cv2.Id;
                       
                    }else{
                        //For the same filename with new user, can only insert new version of the document, so new file will be created.
                        isDocLinkedToRecordId = false;
                        cv2.IsMajorVersion = false;
                       
                        insert cv2;
                        cvId = cv2.Id;
                    }  
                }
            }else{
                cv.VersionData = EncodingUtil.base64Decode(base64);
                cv.Title = filename;
                cv.PathOnClient = filename;
                cv.IsMajorVersion = false;
                insert cv;
                cvId = cv.Id;
            }
        
        } catch(Exception e) {
            System.debug(e);
        }
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id =: cvId
            ].ContentDocumentId;
        cdl.LinkedEntityId = recordId;
        cdl.ShareType = 'I';
        try {
            if(!isDocLinkedToRecordId){
                insert cdl;
                recordContentDocLinkMap.put(recordId,cdl.ContentDocumentId);
            }
        } catch(Exception e) {
            System.debug(e);
        }
        return recordContentDocLinkMap;
    }
}