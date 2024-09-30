public interface SBR_3_0_UserLocationDAInterface {
    List<User_Location__C> getUserLocation(Id userId);
    List<User_location__c> getUserLocation(Set<Id> userIds);
}