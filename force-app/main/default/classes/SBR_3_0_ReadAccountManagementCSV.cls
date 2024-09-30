public without sharing class SBR_3_0_ReadAccountManagementCSV {
    @InvocableMethod(label='Convert Account Relationship CSV File to Records')
    public static Response[] convert (Request[] inputs) {
        Response[] responseList = new Response[]{};
        Set<String> accountExId = new Set<String>();
        Set<String> externalUserSet = new Set<String>();
        set<string> uniqueKeySet = new Set<String>();  
        Map<string,account> uniqueAccMap = new Map<string,account>();
        Map<string,user> uniqueUserMap = new Map<string,user>();
        List<Account_Management_Change_Request__c> returnList = new List<Account_Management_Change_Request__c>();
        for (Request curInput : inputs) {
    
            if (curInput.contentDocumentId == null && curInput.contentDocumentIdList == null) {
                throw new FlowCustomException('You need to provide either a single ContentDocument Id OR a list of ContentDocumentIds as inputs to this Flow action.');
            }
            else {
                // Easiest to just combine the inputs for processing
                if (curInput.contentDocumentId != null)
                    curInput.contentDocumentIdList.add(curInput.contentDocumentId);
            }
            for (String curContentDocumentId : curInput.contentDocumentIdList){
                SObjectType sObjType = ((SObject)Type.forName('Account').newInstance()).getSObjectType();         
                map<String,SObjectField> fieldMap = sObjType.getDescribe().fields.getMap();

                Blob csvBlobContent = getCsvContent(curContentDocumentId);
                String csvStringContent = blobToString(csvBlobContent, 'ISO-8859-1');
                csvStringContent = csvStringContent.replaceAll('(\r\n|\r)','\n');

                String[] csvRows = csvStringContent.split('\n');
                String[] fields = csvRows[0].split(','); //Gives all the API names of the fields from the 1st CSV row 
                csvRows.remove(0);
                map<String,Schema.DisplayType> fieldToFieldTypeMap = new map<String,Schema.DisplayType>();
               // map<String,String> fieldName = new map<String,String>();
                for (String field : fields) {
                    
                    //String fieldApiName = field;
                    // if(fieldMap.get(fieldApiName) == null) {
                    //     fieldApiName = fieldApiName.replaceAll(' ', '_').replaceAll('[^a-zA-Z0-9_]', '');   // Convert to alphanumeric and underscore
                    //     fieldApiName = fieldApiName.replaceAll('__', '_')+'__c';                            // Remove extra _s and add __c to end  
                    // }                       
                    fieldToFieldTypeMap.put(field, getFieldType(fieldMap, field));
                    
                    //fieldName.put(field, fieldApiName); 
                }
                user currentuser = [Select id, companyname from user where id=: userinfo.getUserId() limit 1];
                Response output = new Response();
                String tempRepl = '~`~';
                for(String row : csvRows) {
                    SObject obj = sObjType.newSObject();
                    row = removeCommas(row, 0, tempRepl);
                    String[] fieldInputValues = row.split(',');
                    for (Integer i = 0; i < fields.size(); i++) {

                        String fieldValue = replaceComma(fieldInputValues[i], tempRepl);
                        Schema.DisplayType fieldType = fieldToFieldTypeMap.get(fields[i]);
                        try {
                           // string key='';
                            if(fields[i].equalsIgnoreCase('RM_Account_Number__c')){
                                accountExId.add(currentuser.companyname+'-'+fieldValue);
                             //   key = currentuser.companyname+'-'+fieldValue;
                            }
                            if(fields[i].equalsIgnoreCase('RepID__c')){
                                externalUserSet.add(fieldValue); 
                             //   key = key +'||'+ fieldValue;
                            }
                          //  uniqueKeySet.add(key);
                            obj.put( fields[i], getConvertedFieldValue(fieldType, fieldValue) );
                        } catch(exception e) {
                            obj.put( fields[i], null );
                        }
                    }
                }
                for(Account acc: [Select id,RM_Account_Number__c,name from Account where RM_Account_Number__c in :accountExId]){
                    uniqueAccMap.put(acc.RM_Account_Number__c,acc);
                } 
                for(user u:[select Id, Name, RepID__c from User where RepID__c in :externalUserSet]){
                    uniqueUserMap.put(u.RepID__c,u);
                }

                for(String row : csvRows) {
                    Account_Management_Change_Request__c obj = new Account_Management_Change_Request__c();
                    
                    system.debug('sObjType@@ '+ obj);
                    row = removeCommas(row, 0, tempRepl);
                    String[] fieldInputValues = row.split(',');
                    string key='';
                    for (Integer i = 0; i < fields.size(); i++) {
                        String fieldValue = replaceComma(fieldInputValues[i], tempRepl);
                        Schema.DisplayType fieldType = fieldToFieldTypeMap.get(fields[i]);
                        try {
                            system.debug('fieldValue@ '+fieldValue);
                            if(fields[i].equalsIgnoreCase('RM_Account_Number__c') && uniqueAccMap.containsKey(currentuser.companyname+'-'+fieldValue)){
                                obj.Account__c = uniqueAccMap.get(currentuser.companyname+'-'+fieldValue).id;
                                obj.Account_Name__c = uniqueAccMap.get(currentuser.companyname+'-'+fieldValue).name;
                                key = obj.Account__c;
                            }
                            system.debug('obj.Account__c  '+obj.Account__c);
                            if(fields[i].equalsIgnoreCase('RepID__c') && uniqueUserMap.containsKey(fieldValue)){
                                obj.Sales_Rep__c = uniqueUserMap.get(fieldValue).id;
                                obj.Sales_Rep_Name__c = uniqueUserMap.get(fieldValue).name;
                                key = key +'||'+ fieldValue;
                                uniqueKeySet.add(key);
                                key='';
                            }
                            if(fields[i].equalsIgnoreCase('Type__c')){
                                obj.Type__c = fieldValue;
                            }
                           
                           
                        } catch(exception e) {
                        }
                    }
                    output.convertedCSVRows.add(obj);
                }

                if(!validateUserHierarchy(externalUserSet)){
                    throw new FlowCustomException('Error: Hierarchy');
                }
                if(!validateDuplicate(accountExId, externalUserSet, uniqueKeySet)){
                    throw new FlowCustomException('Error: Duplicate');
                }
                if(!validateDulicateInCsv(output.convertedCSVRows)){
                    throw new FlowCustomException('Error: Duplicate RM Account Number in CSV');
                }
                if(!validateTerritoryInCsv(output.convertedCSVRows)){
                    throw new FlowCustomException('Error: Territory Type is not allowed');
                }
                if(!validateNoAccounts(output.convertedCSVRows)){
                    throw new FlowCustomException('Error: No Account present');
                }
                responseList.add(output);
            }            
            

        }
        return responseList;
    }

    private static boolean validateUserHierarchy(set<string> externalIdSet){
        List<ID> salesRepIdList = new List<ID>();
        list<String> ProfilesWithFullAccess = System.Label.SBR_3_0_Admin_For_AR_Authentication.split(',');
        Map<Id,Profile> mProfile = new Map<Id,Profile>();
        list<Profile> lProfile =    [
            SELECT
            Id
            FROM
            Profile
            WHERE
            Name IN: ProfilesWithFullAccess
        ];
        for(Profile oProfile : lProfile){
            mProfile.put(oProfile.id, oProfile);    
        }
        for(user each: [Select id from user where RepID__c in:externalIdSet ]){
            salesRepIdList.add(each.id);
        }
        if(mProfile.containsKey(userInfo.getProfileId())){
            return true;
        }
        Map<Id,list<Id>> userHierarchyMap =  SBR_3_0_Invocable_ARAuthority.prepareUserIdVsManager(salesRepIdList,new Map<Id,User>());
        system.debug('userHierarchyMap.values() '+ userHierarchyMap.values());
        for(List<ID> each: userHierarchyMap.values()){
            if(!each.isEmpty() && !each.contains(UserInfo.getUserId())){
                return false;
            }
        }
        return true;
    }

    private static boolean validateDulicateInCsv(List<Account_Management_Change_Request__c> recordList){
        set<string> keySet = new set<string>();
        for(Account_Management_Change_Request__c each: recordList){
            string key = each.Account__c +'-'+each.Sales_Rep__c;
            if(keySet.contains(key)){
                return false;
            }
            keySet.add(key);
        }
        return true;
    }

    private static boolean validateNoAccounts(List<Account_Management_Change_Request__c> recordList){
        for(Account_Management_Change_Request__c each: recordList){
            if( each.Account__c ==null){
                return false;
            }
        }
        return true;
    }

    private static boolean validateTerritoryInCsv(List<Account_Management_Change_Request__c> recordList){
        for(Account_Management_Change_Request__c each: recordList){
            if( String.isNotBlank(each.type__c) && each.type__c.equalsIgnoreCase('Territory')){
                return false;
            }
        }
        return true;
    }

    private static boolean validateDuplicate(set<string> externalIdSet, set<string> externalUserSet, set<string> uniqueKeySet){
        List<ID> salesRepIdList = new List<ID>();
        system.debug('uniqueKeySet@@'+uniqueKeySet);
        for(Account_Relationship__c each: [Select Account_ID__r.RM_Account_Number__c,Account_ID__c, User_Account__r.RepID__c from Account_Relationship__c where
                                                    Account_ID__r.RM_Account_Number__c in:externalIdSet AND 
                                                    User_Account__r.RepID__c in: externalUserSet])
        {   system.debug( each.Account_ID__c+'||'+each.User_Account__r.RepID__c);
            if(uniqueKeySet.contains(each.Account_ID__c+'||'+each.User_Account__r.RepID__c)){
                system.debug('In false statement  '+each.Account_ID__c+'||'+each.User_Account__r.RepID__c);

                return false;
            }
        }
        return true;
    }

    static Blob getCsvContent( String contentDocumentId) {        
        ContentVersion csvFile = [SELECT 
                                    VersionData 
                                    FROM ContentVersion 
                                    WHERE ContentDocumentId = :contentDocumentId 
                                    AND IsLatest = true
                                ];
        System.debug('contentDocumentId is: ' + contentDocumentId);
        System.debug('csvFile is: ' + csvFile);
        return csvFile.VersionData;
    }

    /* Converting the CSV file input(BLOB format) to a string */
    static String blobToString(Blob input, String inCharset){
        String hex = EncodingUtil.convertToHex(input);
        System.assertEquals(0, hex.length() & 1);
        final Integer bytesCount = hex.length() >> 1;
        String[] bytes = new String[bytesCount];
        for(Integer i = 0; i < bytesCount; ++i)
            bytes[i] =  hex.mid(i << 1, 2);
        return EncodingUtil.urlDecode('%' + String.join(bytes, '%'), inCharset);
    } 

    static Object getConvertedFieldValue(Schema.DisplayType fieldType, String fieldValue){
        Object convertedFieldValue;

        switch on fieldType {//Setting Field value based on the field data type
            when BOOLEAN {
                convertedfieldValue = String.isEmpty(fieldValue) ? false : Boolean.valueOf(fieldValue);
            }
            when DOUBLE {
                convertedfieldValue = String.isEmpty(fieldValue) ? null : Decimal.valueOf(fieldValue);
            }
            when CURRENCY {
                convertedfieldValue = String.isEmpty(fieldValue) ? null : Decimal.valueOf(fieldValue.deleteWhitespace().replace('$',''));
            }
            when INTEGER {
                convertedfieldValue = String.isEmpty(fieldValue) ? null : Integer.valueOf(fieldValue);
            }
            when DATE {
                convertedfieldValue = String.isEmpty(fieldValue) ? null : Date.parse(fieldValue);
            }
            when else { 
                convertedfieldValue = fieldValue;
            }
        }

        return convertedFieldValue;
    }

    static String removeCommas(String text, Integer eloc, String tempRepl) {
        integer sloc = text.indexOf(',"', eloc);
        if(sloc == -1) {return text;}
        eloc = text.indexOf('",',sloc);
        if (eloc == -1) {return text;}
        string subText = text.substring(sloc+1, eloc).replace(',', tempRepl);
        string replText = text.substring(0,sloc+1)+subText+text.substring(eloc);
        return removeCommas(replText, eloc, tempRepl);
    }

    static String replaceComma(String text, String tempRepl) {
        return text.replace(tempRepl, ',');
    }

    @TestVisible
    static Schema.DisplayType getFieldType(map<String, SObjectField> fieldMap, String fieldApiName) {
        if(fieldMap.get(fieldApiName) == null) {
            throw new FlowCustomException('Invalid Field Error: '+fieldApiName + '. Please double check the API name of the field.');
        }           
        return fieldMap.get(fieldApiName).getDescribe().getType();
    }
    
    public class FlowCustomException extends Exception{}

    public class Request{

        public Request() {
            contentDocumentIdList = new List<String>();
        }
        
        @InvocableVariable(label='Object API Name' required=true)
        public string objectApiName;
        
        @InvocableVariable(label='Single CSV File ID')
        public string contentDocumentId;

        @InvocableVariable(label='List of CSV File IDs')
        public List<String> contentDocumentIdList;
    }

    public class Response{
        @InvocableVariable(label='List(collection) of Records')
        public List<Account_Management_Change_Request__c> convertedCSVRows = new List<Account_Management_Change_Request__c>();
    }
}