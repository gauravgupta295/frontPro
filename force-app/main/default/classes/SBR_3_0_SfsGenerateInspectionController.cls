/*****************************************************************************************************************
* Apex Class: SBR_3_0_SfsGenerateInspectionController
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Controller class for Generate inspection LWC 
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION       DATE               DETAIL FEATURES
    1.0          2023-06-08          Initial version        
*********************************************************************************************************************/


public with sharing class SBR_3_0_SfsGenerateInspectionController {

    @AuraEnabled
    public  static List<WorkOrder> getOpenWOToAsset(Id assetId){
        
        List<WorkOrder> openWoWithAsset =[select id,toLabel(Status),Asset.Name,
                                          SF_PS_RM_WO_Number__c,WorkOrderNumber,SF_PS_Work_Order_Des__c 
                                          from WorkOrder 
                                           where Asset.Id=:assetId 
                                           And Status in ('O','Scheduled','Dispatched','In Route','On Site') Order by CreatedDate desc];

        return openWoWithAsset;
        
    }

     // To get standard price book id
     @AuraEnabled
     public static Pricebook2 getStdPriceBook () {
         
          
         Pricebook2 stdPriceBook    = [select id, name from Pricebook2 where isStandard = true limit 1];
         return stdPriceBook;    
     }
    
    
    
    // To get asset by asset Id
     @AuraEnabled
    public static Asset getAssetById(Id assetId){
       Asset ass= [select Id,SM_PS_Make__c,SM_PS_Model__c,SM_PS_Serial_Number__c,
                   SerialNumber,SM_PS_Warranty_Exp_Date__c,
                   SM_PS_Cat_Class_Description__c,Status,SM_PS_Current_MiHr__c from Asset 
                   where Id=:assetId];
       return ass;
    }
   
}