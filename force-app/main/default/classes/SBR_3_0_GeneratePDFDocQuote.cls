/**
 * @description       : Quote PDF Doc Gen
 * @last modified on  : 05-07-2024
 * @last modified by  : Shreenivas Adapur
**/
public with sharing class SBR_3_0_GeneratePDFDocQuote {
    private static final String APINAME = 'DocGen_V2';
    private static final String COMPANY_ID = '01';
    private static final String X_CORRELATION_ID = SBR_3_0_Generic.generateRandomString(10);
    private static final String SOURCE_SF = 'SF';
    private static final String QUOTE_TEMPLAT_TYPE = 'Quote';
    
    private static String allFields = ',SBQQ__Account__r.Name,SBQQ__Account__r.RecordType.DeveloperName,SBQQ__Account__r.BillingAddress,SBQQ__Account__r.Primary_Equipment_Used__c,SBQQ__Account__r.Credit_Code_Description__c,SBQQ__Account__r.phone,SBQQ__Account__r.email__c,SBQQ__Account__r.ShippingAddress,SBQQ__Account__r.ParentID,SBQQ__Account__r.personOtherPhone__c,SBQQ__Account__r.fax,SBQQ__Account__r.unique_preferences_hot_buttons__c,SBQQ__Account__r.rental_opportunity__c,SBQQ__Account__r.Specialty_opportunity__c,SBQQ__Account__r.other_opportunity__c,SBQQ__Account__r.strategy_last_updated__c,Jobsite__r.Branch__r.Name, Jobsite__r.Name__c, Jobsite__r.Job_Site_Id__c, Jobsite__r.Job_Number__c, Jobsite__r.Job_Reference_Number__c,Jobsite__r.latitude_longitude__c,Jobsite__r.ParentRecordId,Jobsite__r.ParentRecord.Name,Jobsite__r.Override_System_Address_Updates__c,Jobsite__r.Account_Number__c,Jobsite__r.Street_address__c,Jobsite__r.city__c,Jobsite__r.state__c,Jobsite__r.address_validation_status__c,Jobsite__r.zip_code__c,Jobsite__r.quote__r.name,SBQQ__PrimaryContact__r.Name,  SBQQ__PrimaryContact__r.Status__c, SBQQ__PrimaryContact__r.DoNotCall,SBQQ__PrimaryContact__r.mailingAddress,SBQQ__PrimaryContact__r.birthdate,SBQQ__PrimaryContact__r.leadsource,SBQQ__PrimaryContact__r.assistantName,SBQQ__PrimaryContact__r.assistantphone,SBQQ__PrimaryContact__r.HasOptedOutOfEmail,SBQQ__PrimaryContact__r.hasOptedOutOfFax,SBQQ__PrimaryContact__r.createdbyID,SBQQ__PrimaryContact__r.lastmodifiedByID,SBQQ__PrimaryContact__r.MobilePhone,SBQQ__PrimaryContact__r.phone,SBQQ__PrimaryContact__r.email,SBQQ__PrimaryContact__r.fax,SBQQ__PrimaryContact__r.Preferred_Contact_Method__c,SBQQ__PrimaryContact__r.Role__c,SBQQ__PrimaryContact__r.reportsToId,SBQQ__PrimaryContact__r.description,Branch__r.name,Branch__r.RecordType.DeveloperName,Branch__r.Street_address__c,Branch__r.city__c,Branch__r.state__c,Branch__r.zip_code__C,Branch__r.country__c,Branch__r.latitude_longitude__c,Branch__r.Delivery_instruction_1__c,Branch__r.Delivery_instruction_2__c,Branch__r.Delivery_instruction_3__c,Branch__r.Delivery_instruction_4__c,Branch__r.CreatedById,Branch__r.LastModifiedById,Branch__r.Branch_Location_Name__c,SBQQ__SalesRep__r.Name, SBQQ__SalesRep__r.Email,Ordered_by__r.Name, Ordered_by__r.FirstName, Ordered_by__r.LastName, Ordered_by__r.Email,SBQQ__Account__r.RM_Account_Number_Display__c,SBQQ__Account__r.RM_Account_Number__c';

    /**
    * @description : Get all the templates matching quote's Branch__r.Analysis_Region_Key__c
    * @author Shreenivas Adapur
    * @param String recordId 
    * @return List<Adobe_Quote_template__c> 
    **/
    @AuraEnabled
    public static List<Adobe_Quote_template__c> getTemplates(String recordId){
        String userid = UserInfo.getUserId(); 
    
        List<Adobe_Quote_template__c> adobeTemplateQuotes =  new List<Adobe_Quote_template__c>();
        SBQQ__Quote__c quoteFields = Database.query('SELECT Id, Branch__r.Name,Branch__r.Analysis_Region2__c,Branch__r.Analysis_Region_Key__c FROM SBQQ__Quote__c WHERE Id =:recordId LIMIT 1');
        String analysisRegion = quoteFields.Branch__r.Analysis_Region_Key__c;
        if(String.isNotEmpty(analysisRegion)){
            List<Adobe_Quote_template__c> adobeTemplates = Database.query('SELECT Id,Template__c,Analysis_Regions__c,Name FROM Adobe_Quote_Template__c WHERE Analysis_Regions__c INCLUDES (\'' + analysisRegion + '\')');
            for(Adobe_Quote_template__c adobeTemplate : adobeTemplates){
                if(adobeTemplate.Template__c != null && QUOTE_TEMPLAT_TYPE.equalsIgnoreCase(adobeTemplate.Template__c) ){
                    adobeTemplateQuotes.add(adobeTemplate);
                }
            }
            return adobeTemplateQuotes;
        }
        return adobeTemplateQuotes;
    }

    /**
    * @description: Load Quote Fields
    * @author Shreenivas Adapur
    * @param String recordId 
    * @return TemplateWrapper 
    **/
    @AuraEnabled
    public static TemplateWrapper loadQuoteFields(String recordId){
        //get quote fields
        List<SBQQ__Quote__c> quoteList = SBR_3_0_UtilityDA.getAllFieldsForSObject('SBQQ__Quote__c', recordId);
        SBQQ__Quote__c quoteFields = quoteList[0];

        String dateFormat = 'MM/dd/yyyy hh:mm:ss a';
        String timeZone = 'America/Los_Angeles'; // US Pacific time zone, use New_York for Eastern time zone
        DateTime startDateTime = Datetime.now();
        DateTime endDateTime = Datetime.now();

        if(quoteFields.Start_Date__c !=null){
            startDateTime = quoteFields.Start_Date__c;
        }
        if(quoteFields.End_Date__c !=null){
            endDateTime = quoteFields.End_Date__c;
        }
        
        String formattedStartDate = startDateTime.format(dateFormat,timeZone);
        String formattedEndDate = endDateTime.format(dateFormat,timeZone);

        //create wrapper class for teamplte and add template and quote fields. 
        TemplateWrapper templateWrapped = new TemplateWrapper();
        
        //remove leading attribute tag from salesforce object
        Map<String,Object> quoteMap = (Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(quotefields));
        removeAttributes(quoteMap);
        
        if(quoteMap.containsKey('Start_Date__c')){
            quoteMap.put('Start_Date__c', formattedStartDate);
        } 
        if(quoteMap.containsKey('End_Date__c')){
            quoteMap.put('End_Date__c', formattedEndDate);
        }

        templateWrapped.pdfTitle = quoteFields.Quote_Name__c+'_'+quoteFields.Name;
        templateWrapped.data = quoteMap;
        
        return templateWrapped;
    }

    /**
    * @description: Build request for 1st Document call
    * @param Object quoteMap 
    * @param String templateId 
    * @param String pdfName 
    * @return WrappedResponse 
    **/
    @AuraEnabled(cacheable=false)
    public static WrappedResponse buildRequest(Object quoteMap, String templateId, String pdfName){
        try {
            Map<String,Object> quoteFieldMaps = (Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(quoteMap));

            WrappedResponse response = new WrappedResponse();

            Adobe_Quote_template__c adobeTemplateRec = SBR_3_0_UtilityDA.getAdobeTemplateById(templateId);

            DocGenRequestWrapper docGenReqWrap = new DocGenRequestWrapper();
            docGenReqWrap.inputPayload = quoteFieldMaps;
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
        public String base64EncodedInputFile{get;set;}
        @AuraEnabled
        public String pdfTitle{get;set;}
    }

    public class WrappedResponse{
        @AuraEnabled
        public String body{get;set;}
        @AuraEnabled
        public String status{get;set;} 
        @AuraEnabled
        public list<String> headers{get;set;}
        @AuraEnabled
        public String base64Body{get;set;}
        @AuraEnabled
        public String pdfTitle{get;set;}
        @AuraEnabled
        public String contentDocumentId{get;set;}
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

    /**
    * @description: Make 2nd call to Retrieve PDF from repoId generated from 1st call
    * @param String repoId 
    * @param String endPoint 
    * @param String authToken 
    * @return WrappedResponse 
    **/
    @AuraEnabled
    public static WrappedResponse RetrieveFile(String repoId, String endPoint, String authToken){
        try {
            WrappedResponse response = new WrappedResponse();

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
                // if(response.body.contains('"completed":false')){
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
   
    /**
    * @description: Upsert PDF files in salesforce
    * @param String recordId 
    * @param String base64 
    * @param String filename 
    * @return Map<String, String> 
    **/
    private static Map<String, String> upsertPDFFiles(String recordId, String base64, String filename){
        List<ContentDocumentLink> contentDocumentLinkRecord = [
            Select Id,ContentDocument.title,LinkedEntityId,ContentDocumentId,ContentDocument.OwnerId, 
            ContentDocument.LastModifiedDate from ContentDocumentLink 
            where LinkedEntityId =:recordId AND ContentDocument.title =:filename 
            Order by ContentDocument.LastModifiedDate DESC LIMIT 1
        ];
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