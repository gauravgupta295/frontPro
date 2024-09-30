public class SBR_3_0_UserAccess {
    @Invocablemethod
    public static List<Boolean> validateSubmitReservation(List<Id> orderIds) {
        String message = '';
        String orderId = orderIds[0];
        return new List<Boolean>{[select RecordId,hasEditAccess from UserRecordAccess where
                                  RecordId = :orderId AND UserId = :userInfo.getUserId()].hasEditAccess};
    }
    
    @AuraEnabled(cacheable=false)
    public static Boolean validateUserAccess(Id orderId) {
        system.debug('orderId :'+orderId);
        Boolean hasAccess = [select RecordId,hasEditAccess from UserRecordAccess where
                            RecordId = :orderId AND UserId = :userInfo.getUserId()].hasEditAccess;
        system.debug('hasAccess :'+hasAccess);
        return hasAccess;
    }
    
    
}