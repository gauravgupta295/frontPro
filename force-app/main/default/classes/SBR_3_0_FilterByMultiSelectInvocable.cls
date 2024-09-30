/*********************************************************************************************************************
* Apex Class: SBR_3_0_FilterByMultiSelectInvocable
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* @description - Used to filter out records that do not contain values from a specified list in a specified multiselect picklist field
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
*    1.0        Evan Kuminski, Salesforce           2023-12-19           Initial version
*	 2.0        Shilpa Mitra                        2024-05-30           Added filter logic for Asset(SERV-17574)
*	 3.0        Shilpa Mitra                        2024-06-10           Removed filter logic for Asset(SERV-17909)
*********************************************************************************************************************/

public with sharing class SBR_3_0_FilterByMultiSelectInvocable {
    /**
	 * @description Invocable Method to Filter Records based on Company Code of Work plan Template
	 * @param filterInfos Stores the input variables received from flow
	 * @return results - Returns List<SObject> records
	 */
    @InvocableMethod(
        Label='Filter Records By Multi-Select Values'
        Description='Will also work for fields where the data will be formatted as a semicolon separated list of values'
    )
    public static List<List<SObject>> filterByMultiSelect(List<SBR_3_0_FilterInfo> filterInfos) {
        //System.debug(JSON.serializePretty(filterInfos));
        //Deserialize Parameters from Flow
        List<SObject> recordList = filterInfos.get(0).records;
        String fieldApiNameCC = filterInfos.get(0).fieldApiName;
        List<String> allowedValList = filterInfos.get(0).allowedValuesList;
        String allowedValString = filterInfos.get(0).allowedValuesString;
        
        List<List<SObject>> results = new List<List<SObject>>();
        results.add(new List<SObject>());
        
        if(allowedValString <> null && allowedValString <> '') {
            allowedValList = allowedValString.split(';');
        }

        for (SObject sObj : recordList) {
            List<String> splitRecordPicklistValues = new List<String>();
            if(sObj.get(fieldApiNameCC) != null){
                splitRecordPicklistValues = ((String)sObj.get(fieldApiNameCC)).split(';');
            }
            //if(sObj.getSobjectType() == Product2.sObjectType) {
                compareCompanyCode(sObj,splitRecordPicklistValues,allowedValList,false,results);
            //}
            /*if(sObj.getSobjectType() == Asset.sObjectType){
                compareCompanyCode(sObj,splitRecordPicklistValues,allowedValList,false,results);
            }*/
        }
        
        return results;
    }
    /**
	 * @description compareCompanyCode is used to compare the company code of Asset/Product with WPT
	 * @param sObj holds Asset/Product record
	 * @param splitRecordPicklistValues holds Asset/Product company code in the form of list
	 * @param allowedValList holds WPT company code in the form of list
	 * @param shouldInclude 
	 * @param results holds filtered record
     */
    private static void compareCompanyCode(SObject sObj,List<String> splitRecordPicklistValues,List<String> allowedValList,Boolean shouldInclude,List<List<SObject>> results){
        for(String picklistValue : allowedValList) {    
            if(splitRecordPicklistValues.contains(picklistValue)) {
                shouldInclude = true;
                break;
            }
            /*if(sObj.getSobjectType() == Asset.sObjectType && splitRecordPicklistValues.contains(picklistValue)) {
                shouldInclude = true;
                break;
            }*/
        }
        if(shouldInclude) {
            results[results.size() - 1].add(sObj);
        }
    }
    
    /**
	 * @description Wrapper which stores input variables received from flow
     */
    public class SBR_3_0_FilterInfo {
        @InvocableVariable(Label='Records' Required=true)
        public List<SObject> records;
        
        @InvocableVariable(Label='Field API Name' Required=true)
        public String fieldApiName;
        
        @InvocableVariable(Label='Allowed Values (Collection)' Required=false)
        public List<String> allowedValuesList;
        
        @InvocableVariable(
            Label='Allowed Values (Text)'
            Description='Allowed values as a single string separated by semicolons to allow passing directly from an existing multiselect picklist field value. This field will be used over "Allowed Values (Collection) if both are populated.'
            Required=false
        )
        public String allowedValuesString;
    }
}