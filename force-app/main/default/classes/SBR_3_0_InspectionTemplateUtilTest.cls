/*********************************************************************************************************************
* Apex Class: SBR_3_0_InspectionTemplateUtilTest
----------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* @description Unit Test Class for SBR_3_0_InspectionTemplateUtility
----------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME        DATE            DETAIL FEATURES
    1.0         Ritesh Mohapatra      2023-Sept-11    Initial version
	1.1		    Chhavi Singhal		  2023-Nov-02	  Removed field references & running test class as System Admin
	2.0         Chhavi Singhal        2023-Dec-18     Modified Test Class for Inspection Template Validation
	3.0         Shilpa Mitra          2024-June-12    Increased code coverage and solved PMD issues
**********************************************************************************************************************/
@SuppressWarnings(
  'PMD.ClassNamingConventions'
)
@isTest
public class SBR_3_0_InspectionTemplateUtilTest {
    public static List<SBR_3_0_InspectionTemplateUtility.SBR_3_0_InputVariables> inVarList = new List<SBR_3_0_InspectionTemplateUtility.SBR_3_0_InputVariables>();
    public static SBR_3_0_InspectionTemplateUtility.SBR_3_0_InputVariables inVar = new SBR_3_0_InspectionTemplateUtility.SBR_3_0_InputVariables();
	public static WorkPlanTemplate inputwptRecord = new WorkPlanTemplate();
    public static WorkPlanTemplate existingwptRecord = new WorkPlanTemplate();
    public static WorkType workTypeRec = new WorkType();
    public static Inspection_Template__c relatedinspecTempRecord = new Inspection_Template__c();
    public static List<Product2> lProducts = new List<Product2>();
    public static List<Asset> assetList = new List<Asset>();
    
    @testsetup
    static void setUpTestData(){
        //Work Type Record Creation
        workTypeRec.Name = 'TEST WORK TYPE';
        workTypeRec.EstimatedDuration = 1.00;
        workTypeRec.DurationType = 'Hours';
        insert workTypeRec;
        
        //Input Work Plan Template Creation
        inputwptRecord.Name = 'TEST INPUT WORK PLAN TEMPLATE';
        inputwptRecord.SM_PS_Status__c = 'Draft';
        inputwptRecord.SVMX_Company_Code__c = '01';
        inputwptRecord.Description = 'Test Input Work Plan Template';
        inputwptRecord.SM_PS_Work_Type__c = workTypeRec.Id;
        inputwptRecord.SM_PS_Work_Order_Desc__c = 'PREVENTATIVE MAINTENANCE';
        insert inputwptRecord;
        
        //Product Creation
        lProducts = SBR_3_0_TestDataFactory.createProducts(1,TRUE);
        lProducts[0].Category__c = '001';
        lProducts[0].Product_Type__c = 'Cat-Class';
        lProducts[0].Class__c = '0060';
        lProducts[0].Company_Code__c = '01';
        update lProducts;
        
        //Asset Creation
        assetList = SBR_3_0_TestDataFactory.createAssets(1, TRUE); 
        assetList[0].SM_PS_Sub_Class__c = 0;
        assetList[0].SM_PS_Company_Code__c = '01';
        update assetList;
        
        //Existing Work Plan Template Creation
        existingwptRecord.Name = 'TEST EXISTING WORK PLAN TEMPLATE';
        existingwptRecord.SM_PS_Status__c = 'Draft';
        existingwptRecord.SVMX_Company_Code__c = '01';
        existingwptRecord.Description = 'Test existing Work Plan Template';
        existingwptRecord.SM_PS_Work_Type__c = workTypeRec.Id;
        insert existingwptRecord;
  		
        //Related Inspection Template Creation
        relatedinspecTempRecord.SF_PS_Work_Order_Des__c = 'PREVENTATIVE MAINTENANCE';
        relatedinspecTempRecord.SF_PS_Work_Type__c = workTypeRec.Id;
        relatedinspecTempRecord.SM_PS_Work_Plan_Template__c = existingwptRecord.Id;
        relatedinspecTempRecord.SM_PS_Product__c = lProducts[0].Id;
        relatedinspecTempRecord.SM_PS_Status__c = 'Active';
        relatedinspecTempRecord.SF_PS_Asset_Category__c = '001';
        relatedinspecTempRecord.SF_PS_Asset_Class__c = '0060';
        insert relatedinspecTempRecord;     
    }
    
    @isTest
    static void testDuplicateInspectionTemplate()
    {
        List<Product2> productList = [SELECT Id, Category__c, Class__c, Product_Type__c, Company_Code__c FROM Product2 WHERE Product_Type__c = 'Cat-Class'];
        WorkPlanTemplate wptRecord = [SELECT Id, SM_PS_Work_Type__c, SM_PS_Work_Order_Desc__c,SVMX_Company_Code__c FROM WorkPlanTemplate WHERE Name = 'TEST INPUT WORK PLAN TEMPLATE'];
        //WorkType workTypeRec = [SELECT Id FROM WorkType];
        
        //Input Variables
        inVar.userSelectedProducts = productList;
        inVar.userSelectedAssets = assetList;
        inVar.howToMaintain = 'D';
        inVar.howToMaintain2 = 'D';
        inVar.whenToPerform = 99;
        inVar.whenToPerform2 = 70;
        inVar.MeterHourCode = 'M';
        inVar.EstHoursToComplete = 50;
        inVar.workPlanTempRecord = wptRecord;
        inVar.workType = wptRecord.SM_PS_Work_Type__c;
        inVarList.add(inVar);
        
        Test.startTest();
        	List<SBR_3_0_InspectionTemplateUtility.SBR_3_0_OutputVariables> outVarList = SBR_3_0_InspectionTemplateUtility.createInspectionTemplates(inVarList);
        Test.stopTest();
        System.assert(outVarList.size()>0,'List has no records');            
    }
    
    @isTest
    static void testNonDuplicateInspectionTemplate()
    {
        List<Product2> productList = [SELECT Id, Category__c, Class__c, Product_Type__c, Company_Code__c FROM Product2 WHERE Product_Type__c = 'Cat-Class'];
        WorkPlanTemplate wptRecord = [SELECT Id, SM_PS_Work_Type__c, SM_PS_Work_Order_Desc__c,SVMX_Company_Code__c FROM WorkPlanTemplate WHERE Name = 'TEST INPUT WORK PLAN TEMPLATE'];
        //WorkType workTypeRec = [SELECT Id FROM WorkType];
        List<Product2> newProducts  = SBR_3_0_TestDataFactory.createProducts(1,TRUE);
        Inspection_Template__c inspecTempRecord = [SELECT Id, SM_PS_Product__c, SF_PS_Work_Order_Des__c FROM Inspection_Template__c WHERE SF_PS_Work_Order_Des__c = 'PREVENTATIVE MAINTENANCE'];
        inspecTempRecord.SM_PS_Product__c = newProducts[0].Id;
        update inspecTempRecord;
        
        //Input Variables
        inVar.userSelectedProducts = productList;
        inVar.userSelectedAssets = assetList;
        inVar.howToMaintain = 'D';
        inVar.howToMaintain2 = 'D';
        inVar.whenToPerform = 99;
        inVar.whenToPerform2 = 70;
        inVar.MeterHourCode = 'M';
        inVar.EstHoursToComplete = 50;
        inVar.workPlanTempRecord = wptRecord;
        inVar.workType = wptRecord.SM_PS_Work_Type__c;
        inVarList.add(inVar);
        
        Test.startTest();
        	List<SBR_3_0_InspectionTemplateUtility.SBR_3_0_OutputVariables> outVarList = SBR_3_0_InspectionTemplateUtility.createInspectionTemplates(inVarList);
        Test.stopTest();
        System.assert(outVarList.size()>0,'List has no records');            
    }
    
    @isTest
    static void testManageDetailsAsset()
    {
        List<Asset> assetList = [SELECT Id, SM_PS_Sub_Class__c, SM_PS_Company_Code__c FROM Asset WHERE SM_PS_Sub_Class__c = 0];
        WorkPlanTemplate wptRecord = [SELECT Id, SM_PS_Work_Type__c, SM_PS_Work_Order_Desc__c,SVMX_Company_Code__c FROM WorkPlanTemplate WHERE Name = 'TEST INPUT WORK PLAN TEMPLATE'];
        //WorkType workTypeRec = [SELECT Id FROM WorkType];
                
        //Input Variables
        inVar.userSelectedProducts = lProducts;
        inVar.userSelectedAssets = assetList;
        inVar.howToMaintain = 'D';
        inVar.howToMaintain2 = 'D';
        inVar.whenToPerform = 99;
        inVar.whenToPerform2 = 70;
        inVar.MeterHourCode = 'M';
        inVar.EstHoursToComplete = 50;
        inVar.workPlanTempRecord = wptRecord;
        inVar.workType = wptRecord.SM_PS_Work_Type__c;
        inVarList.add(inVar);
        
        Test.startTest();
        	List<SBR_3_0_InspectionTemplateUtility.SBR_3_0_OutputVariables> outVarList = SBR_3_0_InspectionTemplateUtility.createInspectionTemplates(inVarList);
        Test.stopTest();  
        System.assert(outVarList.size()>0,'List has no records');         
    }
}