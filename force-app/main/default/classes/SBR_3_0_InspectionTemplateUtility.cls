/*********************************************************************************************************************
* Apex Class: SBR_3_0_InspectionTemplateUtility
----------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* @description Invocable class create Inspection Template Records
----------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE             DETAIL FEATURES
    1.0         Ritesh Mohapatra        2023-Aug-28      Initial version
    2.0         Chhavi Singhal          2023-Dec-14      Inspection Template Validation
    3.0         Shilpa Mitra            2024-May-30      Uncommented Company Code mapping(SERV-17613)
    4.0         Shilpa Mitra            2024-June-06     Replaced mapping of SM_PS_Asset_Sub_Class__c  with SM_PS_AssetSubclass__c
 	5.0         Shilpa Mitra            2024-June-12     Added condition based mapping for SM_PS_Company_Code__c field(SERV-18210) 
**********************************************************************************************************************/
public with sharing class SBR_3_0_InspectionTemplateUtility
{
    /**
	 * @description Invocable Method to create inspection template record
	 * @param inputVar Stores the input variables received from flow
     * @return results - Returns List<SBR_3_0_OutputVariables> records
    */
   @InvocableMethod(label='Create Inspection Templates' 
                     description='Class to Create Inspection Templates'
                     category='Inspection Templates')
   public static List<SBR_3_0_OutputVariables> createInspectionTemplates(List<SBR_3_0_InputVariables> inputVar)
   { 
        List<Inspection_Template__c> insertInspectionList = new List<Inspection_Template__c>();
        List<Inspection_Template__c> duplicateITList = new List<Inspection_Template__c>();
        List<SBR_3_0_OutputVariables> outputVarList = new List<SBR_3_0_OutputVariables>();
        SBR_3_0_OutputVariables outputVars = new SBR_3_0_OutputVariables();

        try{
            if(inputVar.size() > 0) {
                //Deserialize Input Parameters from Flow
                List<Product2> productsList = inputVar.get(0).userSelectedProducts;
                List<Asset> assetsList = inputVar.get(0).userSelectedAssets;
                WorkPlanTemplate oWPT = inputVar.get(0).workPlanTempRecord;
                Id workType = inputVar.get(0).workType;

                if(inputVar.get(0).userSelectedProducts!=null && inputVar.get(0).userSelectedProducts.size()>0 ) {
                    insertInspectionList = createInspectionTemplateForProduct(inputVar,oWPT,productsList);
                }
                
                if(inputVar.get(0).userSelectedAssets!=null && inputVar.get(0).userSelectedAssets.size()>0) {
                    insertInspectionList = createInspectionTemplateForAsset(inputVar,oWPT,assetsList);
                }

                //Validating Inspection Template 
                if(workType != null) {
                    duplicateITList = checkDuplicateInspectionTemplate(workType, oWPT, insertInspectionList);
                }
            }
            //Insert if No Duplicates Found
            if(duplicateITList.isEmpty() && Schema.sObjectType.Inspection_Template__c.isCreateable()) {
                insert insertInspectionList;
            }

            //Assigning output variables
            outputVars.outputITList = duplicateITList;
            outputVarList.add(outputVars);

        } catch (Exception ex) {
            System.debug('Exception --> '+ex.getMessage());//NOPMD
        }
       
        return outputVarList;
   }
    /**
	 * @description createInspectionTemplateForAsset - create inspection template record based on Asset
	 * @param inputVar Stores the input variables received from flow
     * @param oWPT Stores WPT Id
     * @param assetsList Stores list of Asset records
     * @return results - Returns List<Inspection_Template__c> records
    */
    public static List<Inspection_Template__c> createInspectionTemplateForAsset(List<SBR_3_0_InputVariables> inputVar,WorkPlanTemplate oWPT,List<Asset> assetsList ){
        List<Inspection_Template__c> insertInspectionList = new List<Inspection_Template__c>();
        String howToMaintain = inputVar.get(0).howToMaintain;
                String howToMaintain2 = inputVar.get(0).howToMaintain2;
                Integer whenToPerform = inputVar.get(0).whenToPerform;
                Integer whenToPerform2 = inputVar.get(0).whenToPerform2;
                Integer estHoursToComplete = inputVar.get(0).estHoursToComplete;
                String meterHourCode = inputVar.get(0).meterHourCode;
        for(Asset oAsset : assetsList) {
            Inspection_Template__c newInspection = new Inspection_Template__c();
            newInspection.SM_PS_Asset__c  = oAsset.Id;
            newInspection.SM_PS_AssetSubclass__c= oAsset.SM_PS_Sub_Class__c ;
            newInspection.SM_PS_How_to_Maintain__c = howToMaintain != ''?howToMaintain.substring(0, 1):'';
            newInspection.SM_PS_How_to_Maintain_2__c = howToMaintain2 != ''?howToMaintain2.substring(0, 1):'';
            newInspection.SM_PS_When_to_Perform_Step__c = whenToPerform != null?whenToPerform:null;
            newInspection.SM_PS_When_to_Perform_Step_2__c = whenToPerform2 != null?whenToPerform2:null;
            newInspection.SM_PS_Meter_Hour_Code__c = meterHourCode != ''?meterHourCode.substring(0, 1):'';
            newInspection.SM_PS_Est_Hrs_to_Complete__c = estHoursToComplete != null?estHoursToComplete:null;
            newInspection.SM_PS_Work_Plan_Template__c = oWPT.Id;
            newInspection.SF_PS_Work_Type__c = oWPT.SM_PS_Work_Type__c ;
            newInspection.SF_PS_Work_Order_Des__c = oWPT.SM_PS_Work_Order_Desc__c ;
            newInspection.SM_PS_Company_Code__c = oAsset.SM_PS_Company_Code__c ;
            newInspection.SM_PS_Status__c = 'Draft';
            insertInspectionList.add(newInspection);
        }
        return insertInspectionList;
    }
    /**
	 * @description createInspectionTemplateForProduct - create inspection template record based on Product
	 * @param inputVar Stores the input variables received from flow
     * @param oWPT Stores WPT Id
     * @param productsList Stores list of Product records
     * @return results - Returns List<Inspection_Template__c> records
    */
    public static List<Inspection_Template__c> createInspectionTemplateForProduct(List<SBR_3_0_InputVariables> inputVar,WorkPlanTemplate oWPT,List<Product2> productsList){
        List<Inspection_Template__c> insertInspectionList = new List<Inspection_Template__c>();
        for(Product2 oProd : productsList) {  
            String howToMaintain = inputVar.get(0).howToMaintain;
                String howToMaintain2 = inputVar.get(0).howToMaintain2;
                Integer whenToPerform = inputVar.get(0).whenToPerform;
                Integer whenToPerform2 = inputVar.get(0).whenToPerform2;
                Integer estHoursToComplete = inputVar.get(0).estHoursToComplete;
                String meterHourCode = inputVar.get(0).meterHourCode;
            Inspection_Template__c newInspection = new Inspection_Template__c();
            newInspection.SM_PS_Product__c = oProd.Id;
            newInspection.SF_PS_Asset_Category__c = oProd.Category__c ;
            newInspection.SF_PS_Asset_Class__c = oProd.Class__c ;
            newInspection.SM_PS_How_to_Maintain__c = howToMaintain != ''?howToMaintain.substring(0, 1):'';
            newInspection.SM_PS_How_to_Maintain_2__c = howToMaintain2 != ''?howToMaintain2.substring(0, 1):'';
            newInspection.SM_PS_When_to_Perform_Step__c =whenToPerform != null? whenToPerform:null;
            newInspection.SM_PS_When_to_Perform_Step_2__c = whenToPerform2 != null?whenToPerform2:null;
            newInspection.SM_PS_Meter_Hour_Code__c = meterHourCode != ''?meterHourCode.substring(0, 1):'';
            newInspection.SM_PS_Est_Hrs_to_Complete__c = estHoursToComplete != null?estHoursToComplete:null;
            newInspection.SM_PS_Work_Plan_Template__c = oWPT.Id;
            newInspection.SF_PS_Work_Order_Des__c = oWPT.SM_PS_Work_Order_Desc__c ;
            newInspection.SF_PS_Work_Type__c = oWPT.SM_PS_Work_Type__c ;
            newInspection.SM_PS_Company_Code__c = computeCompanyCode(oWPT.SVMX_Company_Code__c,oProd.Company_Code__c);
            newInspection.SM_PS_Status__c = 'Draft';
            insertInspectionList.add(newInspection);
        }
        return insertInspectionList;
    }
    /**
	 * @description computeCompanyCode - used to calculate company code based on scenario
	 * @param wptCompanyCode - Company code of WPT
     * @param prodCompanyCode - Company code of product
     * @return calculated company code
    */
    public static String computeCompanyCode(String wptCompanyCode,String prodCompanyCode){
        List<String> wptCompanyCodeList =  wptCompanyCode.split(';');
        List<String> prodCompanyCodeList =  prodCompanyCode.split(';');
        String companyCode;
        if(wptCompanyCodeList.size() > prodCompanyCodeList.size()){
            companyCode= prodCompanyCode;
        }
        if(wptCompanyCodeList.size() < prodCompanyCodeList.size()){
            companyCode= wptCompanyCode;
        }
        if(wptCompanyCodeList.size() == prodCompanyCodeList.size()){
            companyCode= wptCompanyCode;
        }
       return companyCode;
    }
    /**
	 * @description checkDuplicateInspectionTemplate - check for duplicate inspection template record by comparing existing & new records
	 * @param workType Stores Work Type Id
     * @param oWPT Stores WPT Id
     * @param insertInspectionList Stores list of new Inspection record records
     * @return results - Returns List<Inspection_Template__c> records
    */
    public static List<Inspection_Template__c> checkDuplicateInspectionTemplate(Id workType, WorkPlanTemplate oWPT,List<Inspection_Template__c> insertInspectionList){
        
        List<WorkPlanTemplate> workPlanTemplateList = new List<WorkPlanTemplate>();
        List<Inspection_Template__c> potentialITList = new List<Inspection_Template__c>();
        List<Inspection_Template__c> duplicateITList = new List<Inspection_Template__c>();
        
        //Retrieve All Existing WorkPlanTemplates with same WorkType
                    workPlanTemplateList = [SELECT Id, SM_PS_Work_Type__c, 
                                                   (SELECT Id, Name, SM_PS_Asset__c, SM_PS_Product__c, SM_PS_Work_Plan_Template__c, SF_PS_Asset_Category__c, SF_PS_Asset_Class__c, SM_PS_Product_Name__c, SM_PS_Work_Plan_Template_Name__c 
                                                    FROM Inspection_Templates__r) 
                                            FROM WorkPlanTemplate
                                            WHERE SM_PS_Work_Type__c =: workType 
                                            AND Id !=: oWPT.Id WITH SECURITY_ENFORCED];
                    
                    if(!workPlanTemplateList.isEmpty()) {
                        for(WorkPlanTemplate workPlanTempRec : workPlanTemplateList) {
                                potentialITList.addAll(workPlanTempRec.Inspection_Templates__r);                   
                        }    
                    }
                    
                    if(!potentialITList.isEmpty()) {
                        for(Inspection_Template__c inspectionTempRec : insertInspectionList) {
                            for(Inspection_Template__c potentialITRec : potentialITList) {
                                if(inspectionTempRec.SM_PS_Product__c == potentialITRec.SM_PS_Product__c) {
                                    //Duplicate Inspection Template
                                    duplicateITList.add(potentialITRec);
                                }
                            }                      
                        }    
                    }
        return duplicateITList;
    }
    /**
    * @description Wrapper which stores input variables received from flow
    */
   public class SBR_3_0_InputVariables
   {
       @InvocableVariable(label = 'Selected Products' 
                          description = 'Products Selected by User'
                          required = false)
       public List<Product2> userSelectedProducts;
        
       @InvocableVariable(label = 'Selected Assets' 
                          description = 'Assets Selected by User'
                          required = false)
       public List<sObject> userSelectedAssets;
        
       @InvocableVariable(label = 'How to Maintain' 
                          description = 'How to Maintain'
                          required = false)
       public string howToMaintain;
       
       @InvocableVariable(label = 'When to Perform' 
                          description = 'When to Perform'
                          required = false)
       public Integer whenToPerform;
       
       @InvocableVariable(label = 'How to Maintain 2' 
                          description = 'How to Maintain 2'
                          required = false)
       public string howToMaintain2;
       
       @InvocableVariable(label = 'When to Perform 2' 
                          description = 'When to Perform 2'
                          required = false)
       public Integer whenToPerform2;
       
       @InvocableVariable(label = 'Est Hrs To Complete' 
                          description = 'Est Hrs To Complete'
                          required = false)
       public Integer estHoursToComplete;
       
       @InvocableVariable(label = 'Meter/Hour Code' 
                          description = 'Meter/Hour Code'
                          required = false)
       public String meterHourCode;
       
       @InvocableVariable(label = 'Recurring?' 
                          description = 'Recurring?'
                          required = false)
       public Boolean recurring;
       
       @InvocableVariable(label = 'Work Plan Template Record' 
                          description = 'Work Plan Template Record'
                          required = true)
       public WorkPlanTemplate workPlanTempRecord;
       
       @InvocableVariable(label = 'Work Type of Work Plan Template' 
                          description = 'Work Type of Work Plan Template'
                          required = true)
       public Id workType; 
    }
    /**
    * @description Wrapper which stores data which is send back to flow
    */
    public class SBR_3_0_OutputVariables{
        @InvocableVariable(label='Duplicate Inspection Templates')
        public List<Inspection_Template__c> outputITList;
    }
}