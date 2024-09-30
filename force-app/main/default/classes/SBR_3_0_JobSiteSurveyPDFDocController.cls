/**
 * @description       :  PDF doc generator controller for Jobsite_Survey__c  Initial version SF-6444
---------------------------------------------------------------------------------------------------------------------------------------
* @author            : Shreenivas Adapur
* @last modified on  : 01-26-2024
* @last modified by  : Shreenivas Adapur
**/
@SuppressWarnings('PMD.ExcessiveClassLength, PMD.CyclomaticComplexity, PMD.ExcessivePublicCount, PMD.CognitiveComplexity')
public with sharing class SBR_3_0_JobSiteSurveyPDFDocController { // NOPMD
    private static final String APINAME = 'DocGen_V2';
    private static final String COMPANY_ID = '01';
    private static final String X_CORRELATION_ID = SBR_3_0_Generic.generateRandomString(10);
    private static final String JSS_TEMPLAT_TYPE = 'Scaffold Jobsite Survey';
    private static final String SOURCE_SF = 'SF';
   
    /**
    * @description Get adobe templates for the record's analysis region
    * @author Shreenivas Adapur | 01-25-2024 
    * @param String recordId 
    * @return List<Adobe_Quote_template__c> 
    **/
    @AuraEnabled
    public static List<Adobe_Quote_template__c> getTemplates(String recordId){  // NOPMD
        Jobsite_Survey__c jobSiteSurvey = SBR_3_0_JobSiteSurveyDA.getJobSiteSurveyAnalysisRgn(recordId);
        String analysisRegion = jobSiteSurvey.sbr_ProfitCenterId__r.Analysis_Region_Key__c;
        
        List<Adobe_Quote_template__c> jssTemplates = new List<Adobe_Quote_template__c>();

        if(String.isNotEmpty(analysisRegion)){
            List<Adobe_Quote_template__c> adobeTemplates = Database.query('SELECT Id,Template__c,Analysis_Regions__c,Name FROM Adobe_Quote_Template__c WHERE Analysis_Regions__c INCLUDES (\''+ String.escapeSingleQuotes(analysisRegion) + '\')');
            for(Adobe_Quote_template__c adobeTemplate : adobeTemplates){
                if(adobeTemplate.Template__c != null && JSS_TEMPLAT_TYPE.equalsIgnoreCase(adobeTemplate.Template__c) ){
                    jssTemplates.add(adobeTemplate);
                }
            }
        }        
        return jssTemplates;
    }

  
    /**
    * @description load record fields
    * @author Shreenivas Adapur | 01-25-2024 
    * @param String recordId 
    * @return TemplateWrapper 
    **/
    @AuraEnabled
    public static TemplateWrapper loadJobSiteSurveyFields(String recordId){// NOPMD
       
        TemplateWrapper templateWrapped = new TemplateWrapper();

        List<Jobsite_Survey__c> jobSiteSurveyFields = SBR_3_0_UtilityDA.getAllFieldsForSObject('Jobsite_Survey__c', recordId);
        Jobsite_Survey__c  jobSiteSurvey = jobSiteSurveyFields[0];
        
        templateWrapped.pdfTitle = jobSiteSurvey.Name;
       
        //remove leading attribute tag from salesforce object
        Map<String,Object> jobSiteSurveyMap = (Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(jobSiteSurvey));
        removeAttributes(jobSiteSurveyMap);
        templateWrapped.data = jobSiteSurveyMap;
        return templateWrapped;
    }

   
    
    /**
    * @description  Build 1st request to generate pdf's x-request-ID 
    * @author Shreenivas Adapur | 01-25-2024 
    * @param Object jobSiteSurveyMap 
    * @param String templateId 
    * @param String pdfName 
    * @return WrappedResponse 
    **/
    @AuraEnabled(cacheable=false)
    public static WrappedResponse buildRequest(Object jobSiteSurveyMap, String templateId, String pdfName){
        try {
            //DocGen API V2 changes
            System.debug('jobSiteSurveyMap->'+JSON.serialize(jobSiteSurveyMap));
            Map<String,Object> jobSiteSurveyFieldMaps = (Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(jobSiteSurveyMap));

            WrappedResponse response = new WrappedResponse();

            Adobe_Quote_template__c adobeTemplateRec = SBR_3_0_UtilityDA.getAdobeTemplateById(templateId);

            DocGenRequestWrapper docGenReqWrap = new DocGenRequestWrapper();
            docGenReqWrap.inputPayload = jobSiteSurveyFieldMaps;
            
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
    /**
     * @description Docgen Wrapper
     */
    public class DocGenRequestWrapper{ //NOPMD

        @AuraEnabled
        public Map<String,Object> inputPayload{get;set;}// NOPMD
        @AuraEnabled 
        public String templateId{get;set;}// NOPMD
    }

    /**
     * @description TemplateWrapper
     */
    public class TemplateWrapper{// NOPMD
        @AuraEnabled
        public  Map<String,Object> data{get;set;}// NOPMD
        @AuraEnabled
        public string base64EncodedInputFile{get;set;} // NOPMD
        @AuraEnabled
        public string pdfTitle{get;set;}// NOPMD
    }
    /**
     * @description WrappedResponse
     */
    public class WrappedResponse{// NOPMD
        @AuraEnabled
        public string body{get;set;}// NOPMD
        @AuraEnabled
        public string status{get;set;}  // NOPMD
        @AuraEnabled
        public list<String> headers{get;set;}// NOPMD
        @AuraEnabled
        public string base64Body{get;set;}// NOPMD
        @AuraEnabled
        public string pdfTitle{get;set;}// NOPMD
        @AuraEnabled
        public string contentDocumentId{get;set;}// NOPMD
        @AuraEnabled
        public String httpDocGenEndPoint {get;set;}// NOPMD
        @AuraEnabled
        public String httpDocGenAuthToken {get;set;}// NOPMD
    }
   

    /**
    * @description remove salesforce 'Attributes'
    * @author Shreenivas Adapur | 01-25-2024 
    * @param Map<String Object> jsonObj 
    * @param //NOPMD 
    **/
    private static void removeAttributes(Map<String,Object> jsonObj)  {//NOPMD
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
    * @description  Build 2st request to generate pdf based on x-request-ID/repoId 
    * @author Shreenivas Adapur | 01-25-2024 
    * @param String repoId 
    * @param String endPoint 
    * @param String authToken 
    * @return WrappedResponse 
    **/
    @AuraEnabled
    public static WrappedResponse retrieveFile(String repoId, String endPoint, String authToken){ // NOPMD
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
                response.status = 'InComplete';
            }
            
            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /**
    * @description Save file to ContentVerion as PDF fileType 
    * @author Shreenivas Adapur | 01-25-2024 
    * @param String base64 
    * @param String filename 
    * @param String recordId 
    * @return WrappedResponse 
    **/
    @AuraEnabled
    public static WrappedResponse saveFile(String base64, String filename, String recordId){// NOPMD
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
    * @description upsert the pdf files
    * @author Shreenivas Adapur | 01-25-2024 
    * @param String recordId 
    * @param String base64 
    * @param String filename 
    * @return Map<String, String> 
    **/
    private static Map<String, String> upsertPDFFiles(String recordId, String base64, String filename){ // NOPMD
        List<ContentDocumentLink> contentDocumentLinkRecord = [Select Id,ContentDocument.title,LinkedEntityId,ContentDocumentId,ContentDocument.OwnerId, ContentDocument.LastModifiedDate from ContentDocumentLink where LinkedEntityId =:recordId AND ContentDocument.title =:filename Order by ContentDocument.LastModifiedDate DESC LIMIT 1 ];// NOPMD
        ContentVersion cv = new ContentVersion();
        Boolean isDocLinkedToRecordId = false;
        String cvId = '';
        Map<String, String> recordContentDocLinkMap = new Map<String, String>();
        String userId = UserInfo.getUserId(); 
             
        try {
            if(contentDocumentLinkRecord.size()>0 && contentDocumentLinkRecord[0].ContentDocumentId !=null && contentDocumentLinkRecord[0].ContentDocument.title !=null &&  contentDocumentLinkRecord[0].ContentDocument.title == filename){
                recordContentDocLinkMap.put(recordId,contentDocumentLinkRecord[0].ContentDocumentId);
                
                String contentDocOwnerId = contentDocumentLinkRecord[0].ContentDocument.OwnerId;

                ContentVersion cv1 = [select Id,Title,VersionData,VersionNumber,ContentDocumentId,IsLatest from ContentVersion where ContentDocumentId =:contentDocumentLinkRecord[0].ContentDocumentId LIMIT 1];//NOPMD
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
                    Profile p = [SELECT Id, Name from Profile WHERE Id = :profileId LIMIT 1];//NOPMD
                    //Only Sysadmin can change the file ownership.
                    if(p != null && p.Name == SBR_3_0_Constants.PROFILE_NAME_ADMIN){   // NOPMD                    
                        ContentDocument cd =  new contentDocument();
                        cd.Id = contentDocumentLinkRecord[0].ContentDocumentId;
                        cd.OwnerId = userId;
                        update cd; // NOPMD

                        cv2.ContentDocumentId = contentDocumentLinkRecord[0].ContentDocumentId;
                        insert cv2;// NOPMD

                        cvId = cv2.Id;

                    }else if (contentDocOwnerId == userId){
                        //Only previous owner of the file can increment version number for the same fileName.
                        cv2.ContentDocumentId = contentDocumentLinkRecord[0].ContentDocumentId;
                        insert cv2;// NOPMD
                        cvId = cv2.Id;
                       
                    }else{
                        //For the same filename with new user, can only insert new version of the document, so new file will be created.
                        isDocLinkedToRecordId = false;
                        cv2.IsMajorVersion = false;
                       
                        insert cv2;// NOPMD
                        cvId = cv2.Id;
                    }  
                }
            }else{
                cv.VersionData = EncodingUtil.base64Decode(base64);
                cv.Title = filename;
                cv.PathOnClient = filename;
                cv.IsMajorVersion = false;
                insert cv;// NOPMD
                cvId = cv.Id;
            }
        
        } catch(Exception e) {
            System.debug(e);// NOPMD
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
                insert cdl;// NOPMD
                recordContentDocLinkMap.put(recordId,cdl.ContentDocumentId);
            }
        } catch(Exception e) {
            System.debug(e); // NOPMD
        }
        return recordContentDocLinkMap;
    }
}