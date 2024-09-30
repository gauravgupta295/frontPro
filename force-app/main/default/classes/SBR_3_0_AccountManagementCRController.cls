/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 12-18-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class SBR_3_0_AccountManagementCRController {
    @AuraEnabled(cacheable=true)
    public static Map<String,list<String>> getAccountManagementCRColumns(String currentFilter){
        Map<String, SBR_3_0_Account_Management_CR_Columns__mdt> mAccountManagementCRColumns = new Map<String, SBR_3_0_Account_Management_CR_Columns__mdt>();
        Map<String,list<String>> mAMCRColumn =  new Map<String,list<String>>();
        Map<String, SBR_3_0_Account_Management_CR_Columns__mdt> mAccountManagementCR = SBR_3_0_Account_Management_CR_Columns__mdt.getAll();

        for(String Label : mAccountManagementCR.keySet()){
    		SBR_3_0_Account_Management_CR_Columns__mdt oMetadata = mAccountManagementCR.get(Label);
            mAccountManagementCRColumns.put(oMetadata.Filter_Name__c, oMetadata);
		}

        if(mAccountManagementCRColumns.containsKey(currentFilter)){
            SBR_3_0_Account_Management_CR_Columns__mdt oAccountManagementCRColumns = mAccountManagementCRColumns.get(currentFilter);
            String Columns = oAccountManagementCRColumns.Columns_With_Labels__c;
            if(String.isNotEmpty(oAccountManagementCRColumns.Columns_With_Labels_1__c)){
                String Columns1 = oAccountManagementCRColumns.Columns_With_Labels_1__c;
                Columns = Columns + ',' + Columns1;
            }

            list<String> lColumnsWithLabel = new list<String>();
            if(Columns.contains(',')){
                lColumnsWithLabel = Columns.split(',');
            }
            else{
                lColumnsWithLabel.add(Columns);
            }
            if(!lColumnsWithLabel.isEmpty()){
            	for(String oColumnsWithLabel : lColumnsWithLabel){
                    list<string> lValue = new list<string>();
                	list<string> lFields = oColumnsWithLabel.split('::');

                    String DataType = '';
                    if(!lFields[1].contains('.')){
                    	DataType = string.valueOf(Schema.getGlobalDescribe().get('Account_Management_Change_Request__c').getDescribe().fields.getMap().get(lFields[1]).getDescribe().getType());    
                    }
                    else{
                        DataType = 'REFERENCE';
                    }
                    lValue.add(lFields[0]);
                    lValue.add(DataType);    
                    mAMCRColumn.put(lFields[1],lValue);
                }
            }
  
        }
        return mAMCRColumn;
    }
    @AuraEnabled(cacheable=false)
    public static list<Account_Management_Change_Request__c> getAccountManagmentCRRecords(String currentFilter,String SearchString) {

        Map<Id,SetupEntityAccess> mSetupEntityAccess = new Map<Id,SetupEntityAccess>();
        Map<Id,list<Id>> mPermissionSetAssignment = new Map<Id,list<Id>>();
        Map<String,CustomPermission> mCustomPermission = new Map<String,CustomPermission>();
        list<Account_Management_Change_Request__c> lAMCR = new list<Account_Management_Change_Request__c>();
        list<Account_Management_Change_Request__c> lAMCRFiltered = new list<Account_Management_Change_Request__c>();
        list<String> lCustomPermissionNames = new list<String>();

        String Approval_Status_Submitted  = SBR_3_0_Constants.Approval_Status_Submitted;
        String Approval_Status_Pending  = SBR_3_0_Constants.Approval_Status_Pending;

        String SBR_3_0_Account_Management_CR_Groups = System.Label.SBR_3_0_Account_Management_CR_Groups;
        Map<String, SBR_3_0_Account_Management_CR_Columns__mdt> mAccountManagementCRColumns = new Map<String, SBR_3_0_Account_Management_CR_Columns__mdt>();
        Map<String, SBR_3_0_Account_Management_CR_Columns__mdt> mAccountManagementCR = SBR_3_0_Account_Management_CR_Columns__mdt.getAll();
 
        for(String Label : mAccountManagementCR.keySet()){
    		SBR_3_0_Account_Management_CR_Columns__mdt oMetadata = mAccountManagementCR.get(Label);
            mAccountManagementCRColumns.put(oMetadata.Filter_Name__c, oMetadata);
		}
        if(mAccountManagementCRColumns.containsKey(currentFilter)){
            SBR_3_0_Account_Management_CR_Columns__mdt oAccountManagementCRColumns = mAccountManagementCRColumns.get(currentFilter);
            String Columns = oAccountManagementCRColumns.Columns_With_Labels__c;
            if(String.isNotEmpty(oAccountManagementCRColumns.Columns_With_Labels_1__c)){
                String Columns1 = oAccountManagementCRColumns.Columns_With_Labels_1__c;
                Columns = Columns + ',' + Columns1;
            }
            list<String> lColumnsWithLabel = new list<String>();
            if(Columns.contains(',')){
                lColumnsWithLabel = Columns.split(',');
            }
            else{
                lColumnsWithLabel.add(Columns);
            }
            String ColumnsString = '';
            if(!lColumnsWithLabel.isEmpty()){
                Integer i=0;
                for(String oColumnsWithLabel : lColumnsWithLabel){
                    list<string> lFields = oColumnsWithLabel.split('::');
                    if(i==0){
                    	ColumnsString = lFields[1];    
                    }
                    else{
                        ColumnsString = ColumnsString + ',' + lFields[1]; 
                    }
                    i++;
                }
            }
            if(SBR_3_0_Account_Management_CR_Groups.contains(',')){
                lCustomPermissionNames = SBR_3_0_Account_Management_CR_Groups.split(',');
            }
            else{
                lCustomPermissionNames.add(SBR_3_0_Account_Management_CR_Groups);
            }
            String SBR_3_0_My_Pending_Requests_for_Strategic_Type = System.Label.SBR_3_0_My_Pending_Requests_for_Strategic_Type;
            String SBR_3_0_My_Pending_Requests_for_Account_Relationships = System.Label.SBR_3_0_My_Pending_Requests_for_Account_Relationships;
            String SBR_3_0_My_Pending_Requests_for_OSR_Fingerprint = System.Label.SBR_3_0_My_Pending_Requests_for_OSR_Fingerprint;
            String SBR_3_0_Account_Management_CR_Submitted_Account_Relationship_Change_Requests = System.Label.SBR_3_0_Account_Management_CR_Submitted_Account_Relationship_Change_Requests;
            String SBR_3_0_Account_Management_CR_Submitted_OSR_Relationship_Change_Requests = System.Label.SBR_3_0_Account_Management_CR_Submitted_OSR_Relationship_Change_Requests;
            String SBR_3_0_Account_Management_CR_Strategic_Type_Change_Requests = System.Label.SBR_3_0_Account_Management_CR_Strategic_Type_Change_Requests;
            List<List <sObject>> searchList = new List<List< sObject>>();
            if(String.isNotBlank(SearchString)){
                String AMQuery = 'FIND '+
                                '{*' +SearchString+'*}'+
                                ' IN '+
                                ' ALL FIELDS '+
                                ' RETURNING '+
                                ' Account_Management_Change_Request__c '+
                                '( RecordTypeId,'+ColumnsString+
                                ' WHERE '+
                                ' Approval_Status__c =: Approval_Status_Submitted '+
                                ' ) ';
                searchList = search.query(AMQuery);
            	lAMCR = ((List<Account_Management_Change_Request__c>)searchList[0]);
            }
            else{
                String AMQuery =    ' SELECT '+  
                                    ' Id, '+
                                    ' RecordTypeId, '+
                                    ColumnsString+
                                    ' FROM '+
                                    ' Account_Management_Change_Request__c '+
                                    ' WHERE ';
                AMQuery = AMQuery + ' Approval_Status__c =: Approval_Status_Submitted';
                lAMCR = Database.query(AMQuery);
            }
            
            list<CustomPermission> lCustomPermission =    	[
                                                                SELECT 
                                                                Id,
                                                                DeveloperName, 
                                                                MasterLabel, 
                                                                IsLicensed
                                                                FROM 
                                                                CustomPermission
                                                                WHERE   
                                                                DeveloperName IN: lCustomPermissionNames
                                                            ];

            for(CustomPermission oCustomPermission : lCustomPermission){
                mCustomPermission.put(oCustomPermission.DeveloperName,oCustomPermission);
            }
            list<SetupEntityAccess> lSetupEntityAccess =    [
                                                                SELECT 
                                                                Id, 
                                                                ParentId, 
                                                                SetupEntityId, 
                                                                SetupEntityType 
                                                                FROM 
                                                                SetupEntityAccess 
                                                                WHERE 
                                                                SetupEntityId IN ( 
                                                                                    SELECT 
                                                                                    Id 
                                                                                    FROM 
                                                                                    CustomPermission 
                                                                                    WHERE 
                                                                                    DeveloperName IN: lCustomPermissionNames
                                                                                )
                												AND
                												Parent.Type = 'Regular'
                                                            ];
            for(SetupEntityAccess oSetupEntityAccess : lSetupEntityAccess){
                mSetupEntityAccess.put(oSetupEntityAccess.SetupEntityId,oSetupEntityAccess);
            }
            list<PermissionSetAssignment> lPermissionSetAssignment = [
                                                                        SELECT 
                                                                        PermissionSetId, 
                                                                        AssigneeId
                                                                        FROM 
                                                                        PermissionSetAssignment
                                                                        WHERE 
                                                                        AssigneeId IN   (
                                                                                            SELECT 
                                                                                            Id 
                                                                                            FROM 
                                                                                            User
                                                                                            WHERE 
                                                                                            Id =: UserInfo.getUserId()
                                                                                        )
                                                                    ];
            list<Id> lPermissionSetUsers = new list<Id>();
            for(PermissionSetAssignment oPermissionSetAssignment : lPermissionSetAssignment){
                if(mPermissionSetAssignment.containsKey(oPermissionSetAssignment.PermissionSetId)){
                    lPermissionSetUsers.add(oPermissionSetAssignment.AssigneeId);
                }
                else{
                    lPermissionSetUsers = new list<Id>();
                    lPermissionSetUsers.add(oPermissionSetAssignment.AssigneeId);
                }
                mPermissionSetAssignment.put(oPermissionSetAssignment.PermissionSetId,lPermissionSetUsers);
            }

            
            for(Account_Management_Change_Request__c oAMCR : lAMCR){
                if(currentFilter == SBR_3_0_My_Pending_Requests_for_Account_Relationships){
                    if(oAMCR.CreatedById == UserInfo.getUserId()){
                        if(oAMCR.recordTypeId == SBR_3_0_Constants.Account_Relationship_Change_RecordTypeId){
                        	lAMCRFiltered.add(oAMCR);
                        }
                    }    
                }
                if(currentFilter == SBR_3_0_My_Pending_Requests_for_OSR_Fingerprint){
                    if(oAMCR.CreatedById == UserInfo.getUserId()){
                        if(oAMCR.recordTypeId == SBR_3_0_Constants.OSR_Fingerprinting_Change_RecordTypeId){
                        	lAMCRFiltered.add(oAMCR);
                        }
                    }    
                }
                if(currentFilter == SBR_3_0_My_Pending_Requests_for_Strategic_Type){
                    if(oAMCR.CreatedById == UserInfo.getUserId()){
                        if(oAMCR.recordTypeId == SBR_3_0_Constants.Strategic_Type_Change_RecordTypeId){
                        	lAMCRFiltered.add(oAMCR);
                        }
                    }    
                }
                else if(currentFilter == SBR_3_0_Account_Management_CR_Submitted_Account_Relationship_Change_Requests){
                    if(mCustomPermission.containsKey('Commissions_Team')){
                        CustomPermission oCustomPermission = mCustomPermission.get('Commissions_Team');
                        if(mSetupEntityAccess.containsKey(oCustomPermission.Id)){
                            SetupEntityAccess oSetupEntityAccess = mSetupEntityAccess.get(oCustomPermission.Id);
                            if(mPermissionSetAssignment.containsKey(oSetupEntityAccess.ParentId)){
                                list<Id> lPermissionSetUsersToCheck = mPermissionSetAssignment.get(oSetupEntityAccess.ParentId);
                                if(lPermissionSetUsersToCheck.contains(UserInfo.getUserId())){
                                    if(oAMCR.recordTypeId == SBR_3_0_Constants.Account_Relationship_Change_RecordTypeId){
                                        lAMCRFiltered.add(oAMCR);
                                    }
                                }
                            }
                        }
                    }
                }
                else if(currentFilter == SBR_3_0_Account_Management_CR_Submitted_OSR_Relationship_Change_Requests){
                    if(mCustomPermission.containsKey('EVP')){
                        CustomPermission oCustomPermission = mCustomPermission.get('EVP');
                        if(mSetupEntityAccess.containsKey(oCustomPermission.Id)){
                            SetupEntityAccess oSetupEntityAccess = mSetupEntityAccess.get(oCustomPermission.Id);
                            if(mPermissionSetAssignment.containsKey(oSetupEntityAccess.ParentId)){
                                list<Id> lPermissionSetUsersToCheck = mPermissionSetAssignment.get(oSetupEntityAccess.ParentId);
                                if(lPermissionSetUsersToCheck.contains(UserInfo.getUserId())){
                                    if(oAMCR.recordTypeId == SBR_3_0_Constants.OSR_Fingerprinting_Change_RecordTypeId){
                                        lAMCRFiltered.add(oAMCR);
                                    }
                                }
                            }
                        }
                    }
                }
                else if(currentFilter == SBR_3_0_Account_Management_CR_Strategic_Type_Change_Requests){
                    if(oAMCR.recordTypeId == SBR_3_0_Constants.Strategic_Type_Change_RecordTypeId){
                        lAMCRFiltered.add(oAMCR);
                    }
                }
            }
        }
        return lAMCRFiltered;
    }
    @AuraEnabled
    public static String sendNoteficationsForAccountManagementCR(list<Account_Management_Change_Request__c> selectedRows,String ClicledButton,String Comments,String currentFilter) {
        String Status = '';
        String ColumnsString = '';
        Map<Id,list<Account_Management_Change_Request__c>> mAccountManagementCR = new Map<Id,list<Account_Management_Change_Request__c>>();
        Map<Id,User> mUsers = new Map<Id,User>();
        Map<Id,ProcessInstanceWorkitem> mWorkItems = new Map<Id,ProcessInstanceWorkitem>();
        list<Account_Management_Change_Request__c> lAMCR = new list<Account_Management_Change_Request__c>();
        list<Messaging.SingleEmailMessage> lMails = new list<Messaging.SingleEmailMessage>();
        list<Approval.ProcessWorkitemRequest> lRequests = new list<Approval.ProcessWorkitemRequest>();
        Map<String, SBR_3_0_Account_Management_CR_Columns__mdt> mAccountManagementCRColumns = new Map<String, SBR_3_0_Account_Management_CR_Columns__mdt>();
        try{
            Map<String, SBR_3_0_Account_Management_CR_Columns__mdt> mAccountManagementCRMetadata = SBR_3_0_Account_Management_CR_Columns__mdt.getAll();
            for(String Label : mAccountManagementCRMetadata.keySet()){
                SBR_3_0_Account_Management_CR_Columns__mdt oMetadata = mAccountManagementCRMetadata.get(Label);
                mAccountManagementCRColumns.put(oMetadata.Filter_Name__c, oMetadata);
            }
            if(mAccountManagementCRColumns.containsKey(currentFilter)){
                SBR_3_0_Account_Management_CR_Columns__mdt oAccountManagementCRColumns = mAccountManagementCRColumns.get(currentFilter);
                String Columns = oAccountManagementCRColumns.Columns_With_Labels__c;
                if(String.isNotEmpty(oAccountManagementCRColumns.Columns_With_Labels_1__c)){
                    String Columns1 = oAccountManagementCRColumns.Columns_With_Labels_1__c;
                    Columns = Columns + ',' + Columns1;
                }
                list<String> lColumnsWithLabel = new list<String>();
                if(Columns.contains(',')){
                    lColumnsWithLabel = Columns.split(',');
                }
                else{
                    lColumnsWithLabel.add(Columns);
                }
                if(!lColumnsWithLabel.isEmpty()){
                    Integer i=0;
                    for(String oColumnsWithLabel : lColumnsWithLabel){
                        list<string> lFields = oColumnsWithLabel.split('::');
                        if(i==0){
                            ColumnsString = lFields[1];    
                        }
                        else{
                            ColumnsString = ColumnsString + ',' + lFields[1]; 
                        }
                        i++;
                    }
                }

            }
            String AMQuery =    ' SELECT '+  
                                    ' Id, '+
                                    ' RecordTypeId, '+
                                    ' Account__r.RM_Account_Number__c, '+
                                    ColumnsString+
                                    ' FROM '+
                                    ' Account_Management_Change_Request__c '+
                                    ' WHERE '+
                                    ' Id IN: selectedRows';
            list<Account_Management_Change_Request__c> lAMCRFromUI = Database.query(AMQuery);

            list<ProcessInstanceWorkitem> lWorkItems = 	[
                                                                SELECT 
                                                                Id,   
                                                                ProcessInstanceId,
                                                                ProcessInstance.TargetObjectId
                                                                FROM 
                                                                ProcessInstanceWorkitem 
                                                                WHERE  
                                                                ProcessInstance.TargetObjectId IN :lAMCRFromUI 
                                                        ];

            
            for(ProcessInstanceWorkitem oWorkItems : lWorkItems){
                mWorkItems.put(oWorkItems.ProcessInstance.TargetObjectId,oWorkItems);    
            }

            for(Account_Management_Change_Request__c oAMCR : lAMCRFromUI){
                if(mAccountManagementCR.containsKey(oAMCR.CreatedById)){
                    lAMCR.add(oAMCR);
                    mAccountManagementCR.put(oAMCR.CreatedById,lAMCR);
                }
                else{
                    lAMCR = new list<Account_Management_Change_Request__c>();
                    lAMCR.add(oAMCR);
                    mAccountManagementCR.put(oAMCR.CreatedById,lAMCR);
                }
            }
            list<User> lUsers = [
                                    SELECT  
                                    ID,
                                    Name,
                                    Email
                                    FROM
                                    User
                                    WHERE
                                    Id IN: mAccountManagementCR.keySet() 
                                ];
            for(User oUser : lUsers){
                mUsers.put(oUser.id,oUser);
            }
            if(ClicledButton == System.Label.SBR_3_0_Account_Management_CR_Button_Approve){
                Status = 'Approved';
            }
            else if(ClicledButton == System.Label.SBR_3_0_Account_Management_CR_Button_Reject){
                Status = 'Rejected';
            }

            for(Id CreatedById : mAccountManagementCR.keySet()){
                list<Account_Management_Change_Request__c> lAMCRToSend = mAccountManagementCR.get(CreatedById);
                String BodyOfRequests='<html><table border="1" style="border-collapse: collapse"><caption>'+' '+Status+' '+' Data</caption><tr><th style="text-align: center; vertical-align: middle;">Account Number</th><th style="text-align: center; vertical-align: middle;">Account Name</th></tr>';
                for(Account_Management_Change_Request__c oAMCR : lAMCRToSend){
                    BodyOfRequests = BodyOfRequests + '<tr><td style="text-align: center; vertical-align: middle;">' + oAMCR.Account__r.RM_Account_Number__c + '</td><td style="text-align: center; vertical-align: middle;">' + oAMCR.Account__r.Name + '</td></tr>';
                    Approval.ProcessWorkitemRequest oRequest = new Approval.ProcessWorkitemRequest();
                    if(mWorkItems.containsKey(oAMCR.id)){
                        ProcessInstanceWorkitem oWorkItems = mWorkItems.get(oAMCR.id);
                        oRequest.setWorkitemId(oWorkItems.Id);
                        if(ClicledButton == System.Label.SBR_3_0_Account_Management_CR_Button_Recall){
                        	oRequest.setAction('Removed');
                        }
                        else{
                            oRequest.setAction(ClicledButton);
                        }
                        oRequest.setComments(Comments);
                        lRequests.add(oRequest);
                    }
                    else {
                        throw new AuraHandledException('Process Instance Workitem is empty');  
                    }
                }
                BodyOfRequests = BodyOfRequests + '</table>';
                if(ClicledButton == System.Label.SBR_3_0_Account_Management_CR_Button_Approve || ClicledButton ==  System.Label.SBR_3_0_Account_Management_CR_Button_Reject){
                    Messaging.SingleEmailMessage oMail = new Messaging.SingleEmailMessage();
                    User oUser = mUsers.get(CreatedById);
                    oMail.toAddresses= new String[] {oUser.Email};
                    oMail.subject = 'Account Management Change Requests '+Status;
                    String Body = 'Dear '+oUser.Name+',<br/>';
                    Body = Body + 'Please note the following Account Management Change Requests have been '+Status+'.<br/><br/>';
                    Body = Body + BodyOfRequests+'<br/><br/>';    
                    Body = Body + ' Comments : '+Comments+'<br/><br/></html>';
                    Body = Body + lAMCRToSend.size()+' Account Management Change Requests have been '+Status+'.';
                    System.debug('Body'+Body);
                    oMail.setHtmlBody(Body);
                    lMails.add(oMail);
                }
            }
            if(!lRequests.isEmpty()){
                Approval.ProcessResult[] lResults =  Approval.process(lRequests);
                System.debug('lResults'+lResults);
            }
            if(!lMails.isEmpty()){
                Messaging.sendEmail(lMails);
            }
            return  Status;
        }
        Catch(Exception e){
            System.debug('Error '+e.getmessage());
            return Status;
        }
    }
}