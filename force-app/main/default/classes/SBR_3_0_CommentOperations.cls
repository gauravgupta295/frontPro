public with sharing class SBR_3_0_CommentOperations {

    public static Set<String> validRecTypes;
    private static String contactType = 'SF';

    //SF-5167
    public static void setCommentFields(List<Comment__c> comments, Boolean externalUser) {
        Set<Id> accountIds = new Set<Id>();
        Set<String> wynneUserNames = new Set<String>();
        Map<Id, Account> accountMap = new Map<Id, Account>();
        Map<String, String> wynneUserNameUserMap = new Map<String, String>();
        User u = new User();
        u = SBR_3_0_UserDA.getUserById(UserInfo.getUserId());
        //get the user with separate logic for internal/external
        if (!externalUser || Test.isRunningTest()) {
            for (Comment__c comment : comments) {
                system.debug(comment.Created_Date__c);
                comment.Type_of_Contact__c = contactType;
                comment.User__c = String.isNotBlank(u.Wynne_User_Name__c) ? u.Wynne_User_Name__c : '';
                comment.Date_Sequence__c = 0;
                comment.Created_By__c = UserInfo.getName();
                accountIds.add(comment.Account_Name__c);
            }
            accountMap = SBR_3_0_AccountDA.getAccountsName(accountIds);
            
            for (Comment__c comment : comments) {
                comment.Company_Code__c = accountMap.get(comment.Account_Name__c).Company_Code__c;
                comment.External_ID__c = createExternalId(accountMap.get(comment.Account_Name__c).Company_Code__c, accountMap.get(comment.Account_Name__c).RM_Account_Number_Display__c );
            }
        } else {
            for (Comment__c comment : comments) {
                //external uploads will have user filled in with Wynne User Name, which can be used to query for the user
                wynneUserNames.add(comment.User__c); 
            }
            List<User> externalUsers = SBR_3_0_UserDA.getUsersByWynneUserNames(wynneUserNames);
            if (externalUsers.size() > 0) {
                for (User eu : externalUsers) {
                wynneUserNameUserMap.put(eu.Wynne_User_Name__c, eu.Name);
            }
            for (Comment__c comment : comments) {
                if (String.isNotBlank(wynneUserNameUserMap.get(comment.User__c))) {
                    comment.Created_By__c = wynneUserNameUserMap.get(comment.User__c);
                } else {
                    comment.Created_By__c = comment.User__c;
                }
            } 
            }
            
        }
    }

    //SF-5848
    public static void publishComment(Map<Id, Comment__c> newCommentMap){
        validRecTypes = new Set<String>{SBR_3_0_Constants.COLLECTION_COMMENT_REC_TYPE};
        List<String> apiLongTextAreasFields = new List<String>{'Comment__c'};
        SBR_3_0_PublishRecordsToOutbox publishComments= new SBR_3_0_PublishRecordsToOutbox(newCommentMap, SBR_3_0_Constants.COMMENT_API_NAME , validRecTypes, apiLongTextAreasFields);
        publishComments.publish();
    }
    
    private static String createExternalId(String companyCode, String accountNumber){
        DateTime now = DateTime.now();
        String year = String.valueOf(now.year());
        String month = String.valueOf(now.month());
        String day = String.valueOf(now.day());
        String hour = String.valueOf(now.hour());
        String minute = String.valueOf(now.minute());
        String second = String.valueOf(now.second());
        String millisecond = String.valueOf(now.millisecond());
        month = padDateString(month,false);
        day = padDateString(day,false);
        hour = padDateString(hour,false);
        minute = padDateString(minute,false);
        second = padDateString(second,false);
        millisecond = padDateString(millisecond, true);

        String externalId = 'SF-';
        externalId = externalId + companyCode + '-' + accountNumber + '-' + year + month + day + '-' + '0-' + hour + minute + second + millisecond;
        return externalId;
    }
    
    private static String padDateString(String dateString, Boolean ifMilli) {
        if (ifMilli) {
            if (dateString.length() == 2) {
               dateString = '0' + dateString;
            }
            else if (dateString.length() == 1) {
               dateString = '00' + dateString;
            }
        }
        else {
            dateString = dateString.length() == 1 ? '0' + dateString : dateString;
        }
        return dateString;
    }
}