public class PPA_ExportDeliverCSVs {

    public class customException extends Exception {}
    
    public static void sendCSVsViaEmail(Integer priceList, List<Messaging.EmailFileAttachment> emailattachments)
    {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        PPA_Admin_Config__c admConfig = PPA_Admin_Config__c.getOrgDefaults();

        String[] toAddresses = admConfig.PPA_Admin_Group_Email__c.split(';');

        String strDateTime = System.now().format('M/d/yyyy h:mm:ss a');
     
        email.setToAddresses(toAddresses);
        email.setSubject('PPA Price List Exports – Generated on ' + strDateTime);
        email.setPlainTextBody('# of Price Lists Exported = ' + String.valueOf(priceList) + '\n# of Attachments = ' + String.valueOf(emailattachments.size()));        
        email.setFileAttachments(emailattachments);
        Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        
        if (!results[0].success) {
        	throw new customException('An error occurred sending the email message with the attachments');    
        }
    }
}