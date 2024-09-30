/*********************************************************************************************************************
* Apex Class: SBR_3_0_EmailClass
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Send email functinality.
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Hrishikesh Kanabar      2022-07-09           Initial version    
*********************************************************************************************************************/
public with sharing class SBR_3_0_EmailClass {
    
    
   

    @AuraEnabled
    public static void sendEmail(String emailStr){
        System.debug(emailStr);
        EmailWrapper emailDetails = (EmailWrapper) JSON.deserialize(emailStr, EmailWrapper.class);
        System.debug(emailDetails);
        list<string> toAndContactEmailAddresses=new list<String>();
        list<string> bccAddress=new list<String>();
        Messaging.reserveSingleEmailCapacity(1);
        
        
         // Check for no records
         if(emailDetails.toAddress.size()>0){
              toAndContactEmailAddresses.addAll(emailDetails.toAddress);
         }
        
        // Null checks
        /*if(emailDetails.addContact!=null){
            toAndContactEmailAddresses.add(emailDetails.addContact);
        }*/
        
        // bccAddress list
        if(emailDetails.bcc.length() > 0) {
            bccAddress.add(emailDetails.bcc);
        }
        System.debug(toAndContactEmailAddresses);

        try{
 
            messaging.SingleEmailMessage mail = new messaging.SingleEmailMessage();
            // To and Contact Address
            mail.setToAddresses(toAndContactEmailAddresses);
            //Bcc
            if(bccAddress.size() > 0){
                mail.setBccAddresses(bccAddress);
            }
            //Subject
            mail.setSubject(emailDetails.subject);
            //Body
            mail.setHtmlBody(emailDetails.body);
            Messaging.sendEmail(new List<messaging.SingleEmailMessage>{ mail });


            // Converting list to comma seperated string
            String toAndContactStr = string.join(toAndContactEmailAddresses,',');
            
            EmailMessage emMessage = new EmailMessage(
                Subject =emailDetails.subject,
                HtmlBody = emailDetails.body,
                FromAddress=emailDetails.frm,
                FromName=emailDetails.frmName,
                ToAddress=toAndContactStr,
                BccAddress=emailDetails.bcc,
                Status = '3',
                RelatedToId = emailDetails.recId );
            insert emMessage;
       
        }catch(exception e){
            System.debug('error '+e.getMessage());
            System.debug('error stack trace '+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());

        }

    }
    
    
    @AuraEnabled
    public static List<String> insertRichTextImageAsDocument (List<String> Imgsrc) {
        
        System.debug(Imgsrc);
        List<Document> docList = new List<Document>();
        List<String> docUrlList = new List<String>();
        
        for(String str:Imgsrc) {
            PageReference pageRef = new PageReference(str);
            
            Document doc = new Document();
            doc.Name = 'img1'+String.valueOf(System.now());
            doc.Type = 'png';
            if(Test.isRunningTest()){
              doc.Body = Blob.valueOf('Some Text');
            }else{
              doc.Body = pageRef.getContent();
            }
            doc.Description = 'Email Rich Text image' +String.valueOf(System.now());
            doc.IsPublic=true;
            doc.FolderId = String.valueOf(UserInfo.getUserId());
            docList.add(doc);
        }
        
        insert docList;
        
        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        String orgId= UserInfo.getOrganizationId();
        
        for(Document doc: docList){
       
          String urlFull= baseUrl +'/servlet/servlet.ImageServer?id='+doc.Id+'&oid='+orgId;
          docUrlList.add(urlFull);
        }
               
         return docUrlList;
    }
    
  

    public class EmailWrapper{
        public String addContact;
        public List<String> toAddress;
        public String frm;
        public String bcc;
        public String subject;
        public String body;
        public String recId;
        public String frmName;

    }
  
    
}