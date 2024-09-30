/*********************************************************************************************************************
* Apex Class: SBR_3_0_CopySObjectsByCompanyCode
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Methods for splitting an SObject into multiple copies based on Company Code. Intended for use with SBR_3_0_PublishToOutboxWithoutQuery
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Evan Kuminski, Salesforce           2023-10-19           Initial version
*********************************************************************************************************************/

public with sharing class SBR_3_0_CopySObjectsByCompanyCode {
    public static Set<String> splitCompanyCodeString(String companyCode) {
        if(companyCode == null) {
            return new Set<String>();
        }
        return new Set<String>(companyCode.split(';'));
    }

    public static List<SObject> createNewSObjectCopiesByCompanyCode(
            SObject baseSobject, SObjectField companyCodeField, Set<String> oldSplitCompanyCode,
            Set<String> newSplitCompanyCode, Boolean forFirstOutboxGeneration
    ) {
        if(forFirstOutboxGeneration) {
            return generateFromCompanyCodes(baseSobject, companyCodeField, newSplitCompanyCode);
        }
        Set<String> createdCompanyCodes = newSplitCompanyCode.clone();
        createdCompanyCodes.removeAll(oldSplitCompanyCode);
        return generateFromCompanyCodes(baseSobject, companyCodeField, createdCompanyCodes);
    }

    public static List<SObject> createUpdatedSObjectCopiesByCompanyCode(
            SObject baseSobject, SObjectField companyCodeField, Set<String> oldSplitCompanyCode,
            Set<String> newSplitCompanyCode, Boolean forFirstOutboxGeneration
    ) {
        if(forFirstOutboxGeneration) {
            return new List<SObject>();
        }
        Set<String> updatedCompanyCodes = oldSplitCompanyCode.clone();
        updatedCompanyCodes.retainAll(newSplitCompanyCode);
        return generateFromCompanyCodes(baseSobject, companyCodeField, updatedCompanyCodes);
    }

    public static List<SObject> createDeletedSObjectCopiesByCompanyCode(
            SObject baseSobject, SObjectField companyCodeField, Set<String> oldSplitCompanyCode,
            Set<String> newSplitCompanyCode, Boolean isActive
    ) {
        Set<String> deletedCompanyCodes = oldSplitCompanyCode.clone();
        if(isActive) {
            deletedCompanyCodes.removeAll(newSplitCompanyCode);
        } else {
            deletedCompanyCodes.addAll(newSplitCompanyCode);
        }
        return generateFromCompanyCodes(baseSobject, companyCodeField, deletedCompanyCodes);
    }

    public static List<SObject> generateFromCompanyCodes(
            SObject baseSObject, SObjectField companyCodeField, Set<String> companyCodes
    ) {
        if(companyCodes == null) {
            return new List<SObject>();
        }
        List<SObject> results = new List<SObject>();
        for (String companyCode : companyCodes) {
            SObject temp = baseSObject.clone(true, true, true, true);
            temp.put(companyCodeField, companyCode);
            results.add(temp);
        }
        return results;
    }
}