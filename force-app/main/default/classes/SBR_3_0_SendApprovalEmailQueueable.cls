public class SBR_3_0_SendApprovalEmailQueueable implements Queueable{
    private List<Account_Management_Change_Request__c> StrategicTypeList = new List<Account_Management_Change_Request__c>();
    private List<Account_Management_Change_Request__c> OSRFingerprintList = new List<Account_Management_Change_Request__c>();
    private List<Account_Management_Change_Request__c> AccountRelationshipList = new List<Account_Management_Change_Request__c>();

    @TestVisible static Integer emailLimits;

    public SBR_3_0_SendApprovalEmailQueueable(List<Account_Management_Change_Request__c> AccountRelationshipList,
                                              List<Account_Management_Change_Request__c> StrategicTypeList, 
                                              List<Account_Management_Change_Request__c> OSRFingerprintList) {
        this.StrategicTypeList = StrategicTypeList;
        this.OSRFingerprintList = OSRFingerprintList;
        this.AccountRelationshipList = AccountRelationshipList;
    }

    public void execute(QueueableContext context) {

        if(!this.AccountRelationshipList.isempty()){
            system.debug('emailQueueMembers');
            emailQueueMembers('Commissions_Team',this.AccountRelationshipList,'Account_Relationship_Change','Please see below for list of requested Account Assignment changes.');
        }
        if(!this.StrategicTypeList.isempty()){
            system.debug('emailQueueMembers1');
            emailQueueMembers('Commissions_Team',this.StrategicTypeList,'Strategic_Type_Change','Please see below for list of requested Account Assignment changes.');
        }
        if(!this.OSRFingerprintList.isempty()){
            system.debug('emailQueueMembers1');
            emailQueueMembers('EVP',this.OSRFingerprintList,'OSR_Fingerprinting_Change','Please see below for list of requested Account Assignment changes.');
        }
        
    SBR_3_0_SendApprovalEmailQueueable.emailLimits = Limits.getEmailInvocations();
    }

    private static void emailQueueMembers(string queueName,List<Account_Management_Change_Request__c> recordList, string typename,string emailtext){
        List<String> idList = new List<String>();
        List<String> mailToAddresses = new List<String>(); 
        system.debug('1');
        Group gp = [SELECT (SELECT UserOrGroupId FROM GroupMembers) FROM Group WHERE DeveloperName =:queueName AND Type='Regular' ];
        for (GroupMember gm : gp.GroupMembers) {
            idList.add(gm.UserOrGroupId);
        }
        system.debug('2 '+idList);
        List<User> userList = [SELECT Email FROM User WHERE Id IN :idList];
        for(User u : userList) {
            mailToAddresses.add(u.email);
        } 
        system.debug('mailToAddresses@'+mailToAddresses);
        string body = '<p>'+emailText+'</p>'+ getTableEmailBody(recordList,typename);
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.setToAddresses(mailToAddresses);
        message.setSaveAsActivity(false);
        message.setSubject('Account Management Change Requests');
        message.setHtmlBody(body);
        system.debug('heere is the code');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { message });

    }

    private static string getTableEmailBody(List<Account_Management_Change_Request__c> myList,string recordTypeName){
        String htmlBody = ' ';
        //Name, RM Account Number, Account Name, Rep ID and Rep Name.
        //open table..
        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        String reportUrl = baseUrl;
        string compUrl = baseUrl + '/lightning/n/Account_Management_Change_Request';
        if(recordTypeName =='Account_Relationship_Change'){
            Id repId = [Select id from report where developerName = 'Account_Relationship_Change_Requests_TTk' Limit 1].id;
            reportUrl = reportUrl + '/'+repId;
            htmlBody = htmlbody + ' <p>Click <a href="'+compUrl+'" target ="_blank">HERE</a> and select “Approver View - Pending Acct. Relationship Updates” to view all pending Account Assignment requests. </p></br>';
            htmlBody = htmlBody + ' <p>Click <a href="'+ reportUrl +'" target ="_blank">HERE</a> to view report.</p></br>';
            htmlBody += '<table border="1" style="border-collapse: collapse"><tr><th>Name</th><th>RM Account Number</th><th>Account Name</th><th>Rep Id</th><th>Rep Name</th></tr>';
        }
        if(recordTypeName =='Strategic_Type_Change'){
            Id repId = [Select id from report where developerName = 'Pending_Strategic_Type_Change_Requests_jy7' Limit 1].id;
            reportUrl = reportUrl + '/'+repId;
            htmlBody = htmlbody + '<p> Click ' + '<a href="'+ compUrl+'" target ="_blank" >HERE</a> and select “Approver View - Pending Strategic Type Updates” to view all pending Strategic Type requests. </p></br>';
            htmlBody = htmlBody + '<p>Click <a href="'+ reportUrl +'" target ='+'"'+'_blank"'+'>HERE</a> to view report.</p></br>';
            htmlBody += '<table border="1" style="border-collapse: collapse"><tr><th>Name</th><th>RM Account Number</th><th>Account Name</th><th>Strategic Type</th></tr>';
        }
        if(recordTypeName =='OSR_Fingerprinting_Change'){
            Id repId = [Select id from report where developerName = 'Pending_OSR_Fingerprint_Change_Requests_0tv' Limit 1].id;
            reportUrl = reportUrl + '/'+repId;
            htmlBody = htmlbody + '<p> Click ' + '<a href= "'+ compUrl +'" target ='+'"'+'_blank"'+'>HERE</a> and select “Approver View - Pending OSR Fingerprint Updates” to view all  pending OSR Fingerprinting requests. </p></br>';
            htmlBody = htmlBody + ' <p>Click <a href="'+ reportUrl +'" target ='+'"'+'_blank"'+'>HERE</a> to view report.</p></br>';
            htmlBody += '<table border="1" style="border-collapse: collapse"><tr><th>Name</th><th>RM Account Number</th><th>Account Name</th><th>OSR Fingerprint</th></tr>';
        }

        //iterate over list and output columns/data into table rows...
        for(Account_Management_Change_Request__c l : myList){

            String  value = l.Name; if(l.Name == null){value = '[Not Provided]';}
                    htmlBody += '<tr><td>' + value + '</td>';
                    value = null;

                    if(l.account__c != null && l.account__r.RM_Account_Number_Display__c !=null)
                    {value = l.account__r.RM_Account_Number_Display__c;}
                    else{value = '[Not Provided]';}
                    htmlBody += '<td>' + value + '</td>';
                    value = null;

                    if(l.account__c != null )
                    {value = l.account__r.Name;}
                    else{value = '[Not Provided]';}
                    htmlBody += '<td>' + value + '</td>';
                    value = null;

                    
                    if(recordTypeName =='Account_Relationship_Change'){
                        if(l.Sales_Rep__c != null && l.Sales_Rep__r.RepID__c !=null)
                        {value = l.Sales_Rep__r.RepID__c;}
                        else{value = '[Not Provided]';}
                        htmlBody += '<td>' + value + '</td>';
                        value = null;
                        if(l.Sales_Rep_Name__c != null )
                        {value = l.Sales_Rep_Name__c;}
                        else{value = '[Not Provided]';}
                        htmlBody += '<td>' + value + '</td>';
                        value = null;
                    }

                    if(recordTypeName =='Strategic_Type_Change'){
                        if(l.Strategic_Type__c != null)
                        {value = l.Strategic_Type__c;}
                        else{value = '[Not Provided]';}
                        htmlBody += '<td>' + value + '</td>';
                        value = null;
                        
                    }

                    if(recordTypeName =='OSR_Fingerprinting_Change'){
                        if(l.Managed_w_OSR_Fingerprint_text__c != null)
                        {value = l.Managed_w_OSR_Fingerprint_text__c;}
                        else{value = '[Not Provided]';}
                        htmlBody += '<td>' + value + '</td>';
                        value = null;
                        
                    }
            htmlBody += '</tr>';

        }
        //close table...
        htmlBody += '</table>';
        system.debug('Email Body: ' + htmlBody);   
        return htmlBody;
    }
}