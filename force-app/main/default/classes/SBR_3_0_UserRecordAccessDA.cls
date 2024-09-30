public without sharing class SBR_3_0_UserRecordAccessDA implements SBR_3_0_UserRecordAccessDAInterface {
    public static List<UserRecordAccess> getRecordAccessByUserAndObject(Id userId, Id recordId) {
        return [SELECT RecordId, HasEditAccess, HasDeleteAccess FROM UserRecordAccess WHERE UserId =: userId AND RecordId =: recordId];
    }
}