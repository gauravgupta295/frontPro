/*********************************************************************************************************************
* Apex Class: SBR_3_0_UserRecordAccessDAInterface
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Interface class for UserRecordAccess Data Access
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Konrad Haight           2022-09-12          Initial version    
*********************************************************************************************************************/
public interface SBR_3_0_UserRecordAccessDAInterface {
    List<UserRecordAccess> getRecordAccessByUserAndObject(Id userId, Id recordId);
}