/*********************************************************************************************************************
* Apex Class: SBR_3_0_FilterAssetInvocable
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* @description - Used to filter Asset based on Company Code of WPT and Category/Sub Class/Cat Class/AssetNumber
---------------------------------------------------------------------------------------------------------------------------------------
* History:
*  VERSION     DEVELOPER NAME                      	DATE                 DETAIL FEATURES
*   1.0         Shilpa Mitra                        2024-06-10           Initial Version
*   2.0         Shilpa Mitra                        2024-06-17           Commented code related to Search by Category
*********************************************************************************************************************/

public with sharing class SBR_3_0_FilterAssetInvocable {
    /**
    * @description Invocable Method to Filter Asset based on Company Code of WPT and Category/Sub Class/Cat Class/AssetNumber
    * @param filterInfos Stores the input variables received from flow
    * @return results - Returns List<SBR_3_0_OutputVariables> records
    */
    @InvocableMethod(
        Label='Filter Asset'
        Description='Used to filter Asset by Company code along with Category/Sub Class/Cat Class/AssetNumber'
    )
    public static List<SBR_3_0_OutputVariables> filterAsset(List<SBR_3_0_FilterInfo> filterInfos) {

        //Deserialize Parameters from Flow
        List<String> companyCodeWPTList = new List<String>();
        List<Asset> filteredAssetList = new List<Asset>();
        //String fieldValueCategory = filterInfos.get(0).fieldValueCategory;
        Double fieldValueSubClass = filterInfos.get(0).fieldValueSubClass;
        String fieldValueCatClass = filterInfos.get(0).fieldValueCatClass;
        String fieldValueAssetNumber = filterInfos.get(0).fieldValueAssetNumber;
        String allowedValString = filterInfos.get(0).allowedValuesString;
        Integer assetCount;
        Boolean executeQuery = false;
        
        List<SBR_3_0_OutputVariables> outputVarList = new List<SBR_3_0_OutputVariables>();
        SBR_3_0_OutputVariables outputVars = new SBR_3_0_OutputVariables();
        
        if(allowedValString <> null && allowedValString <> '') {
            companyCodeWPTList = allowedValString.split(';');
        }
        String assetQuery ='SELECT Id,Name,SM_PS_Category__c,SM_PS_Sub_Class__c, SM_PS_Cat_Class__c,SM_PS_Company_Code__c,Status FROM Asset WHERE SM_PS_Company_Code__c IN: companyCodeWPTList';
        String assetCountQuery ='SELECT COUNT() FROM Asset WHERE SM_PS_Company_Code__c IN: companyCodeWPTList';
        /*if(fieldValueCategory <> null && fieldValueCategory <> '') {
            executeQuery = true;
            assetQuery = assetQuery+' AND SM_PS_Category__c =:fieldValueCategory AND Status NOT IN (\'JUNKED\',\'MISSING LOST\',\'SOLD\',\'STOLEN\',\'Deleted\') AND SM_PS_Record_Status__c !=\'Deleted\'';
        }*/
        if(fieldValueSubClass <> null && fieldValueSubClass >= 0){
            executeQuery = true;
            assetQuery = assetQuery+' AND SM_PS_Sub_Class__c =:fieldValueSubClass AND Status NOT IN (\'JUNKED\',\'MISSING LOST\',\'SOLD\',\'STOLEN\',\'Deleted\') AND SM_PS_Record_Status__c !=\'Deleted\'';
        	assetCountQuery = assetCountQuery+' AND SM_PS_Sub_Class__c =:fieldValueSubClass AND Status NOT IN (\'JUNKED\',\'MISSING LOST\',\'SOLD\',\'STOLEN\',\'Deleted\') AND SM_PS_Record_Status__c !=\'Deleted\'';
        }
        if(fieldValueCatClass <> null && fieldValueCatClass <> '') {
            executeQuery = true;
            assetQuery = assetQuery+' AND SM_PS_Cat_Class__c =:fieldValueCatClass AND Status NOT IN (\'JUNKED\',\'MISSING LOST\',\'SOLD\',\'STOLEN\',\'Deleted\') AND SM_PS_Record_Status__c !=\'Deleted\'';
            assetCountQuery = assetCountQuery+' AND SM_PS_Cat_Class__c =:fieldValueCatClass AND Status NOT IN (\'JUNKED\',\'MISSING LOST\',\'SOLD\',\'STOLEN\',\'Deleted\') AND SM_PS_Record_Status__c !=\'Deleted\'';
        }
        if(fieldValueAssetNumber <> null && fieldValueAssetNumber <> ''){
            executeQuery = true;
            assetQuery = assetQuery + ' AND Name=:fieldValueAssetNumber';
            assetCountQuery = assetCountQuery+' AND Name=:fieldValueAssetNumber';
        }
        if(executeQuery){
            assetCount=Database.countQuery(assetCountQuery);
            if(assetCount > 0 && assetCount < 50000){
                filteredAssetList = Database.query(assetQuery);
            } 
        }
        //Assigning output variables
        outputVars.outputAssetList = filteredAssetList;
        outputVars.listSize = assetCount;
        outputVarList.add(outputVars);
        return outputVarList;
    }
    
    /**
    * @description Wrapper which stores input variables received from flow
    */
    public class SBR_3_0_FilterInfo {
        @InvocableVariable(Label='Category' Required=false)
        public String fieldValueCategory;
        
        @InvocableVariable(Label='Sub Class' Required=false)
        public Double fieldValueSubClass;
        
        @InvocableVariable(Label='Cat Class' Required=false)
        public String fieldValueCatClass;
        
        @InvocableVariable(Label='Asset Number' Required=false)
        public String fieldValueAssetNumber;
        
        @InvocableVariable(
            Label='Allowed Values (Text)'
            Description='Allowed values as a single string separated by semicolons to allow passing directly from an existing multiselect picklist field value. This field will be used over "Allowed Values (Collection) if both are populated.'
            Required=false
        )
        public String allowedValuesString;
    }
    
    /**
    * @description Wrapper which stores data which is send back to flow
    */
    public class SBR_3_0_OutputVariables{
        @InvocableVariable(Label='Filtered Assets' 
                           Description='Allowed Asset'
                           Required=true)
        public List<Asset> outputAssetList;
         @InvocableVariable(Label='Size' 
                           Description='Filtered Asset Size'
                           Required=true)
        public Integer listSize;
    }
}