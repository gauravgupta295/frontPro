/*********************************************************************************************************************
* Apex Class: SBR_3_0_ContractDA
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Concrete class for Contract Data Access
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Kunal Patel           2022-05-04            Initial version    
*********************************************************************************************************************/
public with sharing class SBR_3_0_ContractDA implements SBR_3_0_ContractDAInterface {
    public static List<Contract> getContractsByOwner(Id ownerId) {
        return [SELECT Id, AccountId, Status FROM Contract WHERE OwnerId =: ownerId];
    }
}