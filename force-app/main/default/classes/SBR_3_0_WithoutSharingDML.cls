/**
 * @description - The SBR_3_0_WithoutSharingDML class provides methods to execute DML operations on records without sharing.
 */
public without sharing class SBR_3_0_WithoutSharingDML {
    /**
     * @description Returns an inserted sObject
     * @param obj - SObject to insert
     * @return  `SObject` - SOBject of inserted record
     */
    public static SObject insertRecord(SObject obj) {
        insert obj;
        return obj;
    }
}