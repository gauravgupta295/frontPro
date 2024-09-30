/*********************************************************************************************************************
* Apex Class: SBR_3_0_WorkOrderDA
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class containing all the SOQL queries used by SBR_3_0_CustomCreateWorkOrder .
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION       DATE               DETAIL FEATURES
1.0          2023-02-23          Initial version 
2.0          2023-05-10          Harry Rokad   
**********************************************************************************************************************************************/

public with sharing class SBR_3_0_WorkOrderDA {
    
    public static List<Account> getRelatedAccount(String AccountId, String companycode){
        
        List<Account> relAccts = [
            SELECT ID, Name
            FROM Account 
            WHERE RM_Account_Number__c = :AccountId and Company_Code__c=: companycode LIMIT 1];
        
        return relAccts;  
    }
    
    public static List<User> getUser(String ownerId){
        List<User> ownerFind = [
            SELECT Id FROM User WHERE Wynne_User_Name__c =: ownerId LIMIT 1];
        return ownerFind;
    }
    
    public static List<Asset> getrelAsset(String assetLookup){
        List<Asset> assetList = [
            SELECT Id FROM Asset WHERE SM_PS_Asset_Id__c =: assetLookup LIMIT 1
        ];
        return assetList;
    }
    public static List<RecordType> getWorkOrderRecordType(String recType, String ObjName){
        List<RecordType> recTypeList = [
            SELECT Id, DeveloperName FROM RecordType WHERE DeveloperName =: recType AND SobjectType =: ObjName LIMIT 1];
        return recTypeList;
    }
    
    public static List<ServiceTerritory> getrelST(String loc, String countryCode){
        List<ServiceTerritory> serviceterritoryList = [
            SELECT Id FROM ServiceTerritory WHERE Branch_Location_Number__c =: loc AND CountryCode =: countryCode  LIMIT 1
        ];
        return serviceterritoryList;
    }
    
    public static List<User> getrelUser(String repId){
        List<User> userList = [
            SELECT Id FROM User WHERE RepID__c =: repId LIMIT 1
        ];
        return userList;
    }
    
    public static List<AssociatedLocation> getrelJobSite(String jobSite){
        List<AssociatedLocation> jobSiteList = [
            SELECT Id FROM AssociatedLocation WHERE Job_Number__c =: jobSite LIMIT 1
        ];
        return jobSiteList;
    }
    
    public static List<ServiceResource> getrelServiceResourceLineItems(String mechId){
        List<ServiceResource> serviceResourceList = [
            SELECT Id FROM ServiceResource WHERE SF_PS_Mechanic_Id__c =: mechId LIMIT 1
        ];
        return serviceResourceList;
    }
    
    public static List<ServiceResource> getrelServiceResource(String mechId){
        
        List<User> usr= new List<User>();
        usr = [SELECT Id FROM User WHERE SF_PS_Mechanic_Id__c =: mechId LIMIT 1];
        
        List<ServiceResource> serviceResourceList = [
            SELECT Id FROM ServiceResource WHERE RelatedRecordId =: usr[0].Id
        ];
        return serviceResourceList;
    }
    
    public static List<ProductItem> getrelProdItems(String prodId, String loc){
        
        List<ProductItem> prodItems = new List<ProductItem>();
        List<Product2> prod = new List<Product2>();
        prod = [SELECT Id FROM Product2 WHERE Product_SKU__c =:prodId LIMIT 1 ];
        
        prodItems = [SELECT Id, Product2.Id,LocationId FROM ProductItem WHERE Product2Id =: prod[0].Id AND Location.Branch_Location_Number__c =: loc];
        
        return prodItems;
    }
    
    public static List<Product2> getrelProd(String prodId){
        List<Product2> prod = new List<Product2>();
        prod = [SELECT Id,Item_Type__c,Product_Type__c FROM Product2 WHERE Product_SKU__c =:prodId LIMIT 1 ];         
        return prod;
    }
    
    public static List<ProductConsumed> getrelProdConsumedToWO(String woId){    
        List<ProductConsumed> pc = new List<ProductConsumed>();
        pc  = [SELECT Id, SF_PS_RM_External_Id__c, Product2.Product_SKU__c FROM ProductConsumed WHERE WorkOrderId =:woId];
        return pc;
    }
    
    public static List<SF_PS_Quoted_Part__c> getrelQuotedPartsToWO(String woId){    
        List<SF_PS_Quoted_Part__c> qp = new List<SF_PS_Quoted_Part__c>();
        qp  = [SELECT Id, SF_PS_RM_External_Id__c, SF_PS_Product2Id__r.Product_SKU__c FROM SF_PS_Quoted_Part__c WHERE SF_PS_WorkOrderId__c =:woId];
        return qp;
    }
    
    public static List<WorkOrderLineItem> getLinesToDelete(Set<String> lines) {
        
        List<WorkOrderLineItem> linesToDeleteList = new List<WorkOrderLineItem>();
        linesToDeleteList  = [SELECT Id, SF_PS_RM_External_Id__c FROM WorkOrderLineItem WHERE SF_PS_RM_External_Id__c IN :lines];
        return linesToDeleteList;
    }
    
    public static List<Quote_Line_Item__c> getQuoteLinesToDelete(Set<String> lines) {
        
        List<Quote_Line_Item__c> linesToDeleteList = new List<Quote_Line_Item__c>();
        linesToDeleteList  = [SELECT Id, SF_PS_RM_External_Id__c FROM Quote_Line_Item__c WHERE SF_PS_RM_External_Id__c IN :lines];
        return linesToDeleteList;
    }
    
    public static List<SF_PS_Credit_Line_Item__c> getCreditLinesToDelete(Set<String> lines) {
        
        List<SF_PS_Credit_Line_Item__c> linesToDeleteList = new List<SF_PS_Credit_Line_Item__c>();
        linesToDeleteList  = [SELECT Id, SF_PS_RM_External_Id__c FROM SF_PS_Credit_Line_Item__c WHERE SF_PS_RM_External_Id__c IN :lines];
        return linesToDeleteList;
    }
    
    public static List<WorkOrder> getWorkOrders(Set<String> WoIds){
        List<WorkOrder> workOrdersList = new List<WorkOrder>();
        for (Id Id: WoIds){
            WorkOrder wo = [SELECT Account.RM_Account_Number__c, SF_PS_Update_Meter__c, SF_PS_Replace_Meter__c,  SF_PS_Put_Into_Shop__c, SF_PS_Make_Available__c,
                            CreatedBy.alias, SF_PS_Labor_Des_Comments__c, status, WorkOrderNumber, Asset.SM_PS_Asset_Id__c, Asset.SM_PS_Equipment_Number__c ,
                            ServiceTerritory.Branch_Location_Number__c, SF_PS_Job_Site__r.Job_Number__c , SF_PS_Expense_To_Location__r.Branch_Location_Number__c,
                            SF_PS_Sales_Rep__r.RepID__c, SF_PS_Service_Resource__r.SF_PS_Mechanic_Id__c, SF_PS_Serial_Number__c,CreatedBy.Name, CurrencyIsoCode, 
                            SVMXA360__ContactPhone__c, SF_PS_Company_Code__c, SF_PS_Date_Opened__c, SF_PS_Closed_Date__c, SF_PS_Work_Order_Des__c,  
                            SF_PS_Drivers_License_Number__c, SF_PS_Complaint__c, SF_PS_Cause__c, SF_PS_Cure__c, SF_PS_BillCustOrLoc__c, SF_PS_ExpenseCode__c, 
                            SF_PS_LaborCode__c,SF_PS_Job_Location__c, SF_PS_Meter_Code_MIHR__c,
                            SF_PS_PONumber__c , SF_PS_Authorized_By__c, SF_PS_Current_MiHr__c, SF_PS_Current_Loc__c, 
                            SF_PS_Service_Call__c, SF_PS_Claim_Type__c, SF_PS_Cust_Eqp_Description__c,
                            SF_PS_Claim_Num__c, SF_PS_Date_Claim_Filed__c, SF_PS_Due_Date__c, SF_PS_Repair_Ticket__c, OwnerId, SF_PS_Major_Repair__c, SF_PS_Warranty_Amt_Expected__c,
                            SF_SP_Market_Segment__c , ParentWorkOrderId, SF_PS_Previous_Hour_Meter1__c, SF_PS_Previous_Hour_Meter2__c, SF_PS_Previous_Hour_Meter__c,
                            SF_PS_License_State__c, SF_PS_Is_Warranty__c, SF_PS_Labor_Des_Internal__c, Description, ServiceTerritory.OperatingHours.TimeZone,  
                            SF_PS_Funded__c, SF_PS_Claim_Paid_Date__c,
                            SF_PS_Actual_Claim_Amt__c,SF_PS_Current_MiHr2__c, SF_PS_RM_Last_Maint_By__c, SF_PS_RM_Last_Maint_DateTime__c, SF_PS_RM_WO_Number__c, 
                            SF_PS_Inv_Seq_Num__c, LastModifiedDate, CreatedDate,                
            				Asset.SM_PS_Miscellaneous_Options__c, Asset.SM_PS_Current_MiHr__c, Asset.SM_PS_Sub_Class__c, Asset.SM_PS_Model_Year__c, Asset.Status, Asset.SM_PS_Updated_in_SF__c, 
                            Asset.SM_PS_Serial_Number__c,SF_PS_Credit_Reason__c,SF_PS_Charge_GSTTax__c, SF_PS_Charge_PSTTax__c, Asset.SM_PS_Meter_Code_MIHR__c, 
                            Asset.SM_PS_Maintenance_Contract__c, Asset.SM_PS_Make__c, Asset.SM_PS_RentalMan_Status__c,
                            Asset.SM_PS_Model__c, Asset.SM_PS_Category__c, Asset.SM_PS_Class__c, SF_PS_Asset_Sub_Class__c, SF_PS_Model_Year__c, SF_PS_Quoted_Labor_Amt__c,
                            SF_PS_Warranty_Expiry_Date__c,SF_PS_Record_Type__c
                            FROM WorkOrder WHERE Id=: Id];
            workOrdersList.add(wo);
        }
        return workOrdersList;
    }
    public static List<Quote_Line_Item__c> getQuoteLineItems(Set<String> qliIds){
        List<Quote_Line_Item__c> qliList = new List<Quote_Line_Item__c>();
        for (Id Id: qliIds){
            Quote_Line_Item__c qli = [SELECT Id, LastModifiedDate,
            WorkOrderId__r.Owner.Name, 
            WorkOrderId__r.OwnerId,
            WorkOrderId__r.ServiceTerritory.OperatingHours.TimeZone, 
            WorkOrderId__r.WorkOrderNumber,
            WorkOrderId__r.Owner.alias,
            WorkOrderId__r.ServiceTerritory.Branch_Location_Number__c, 
            WorkOrderId__r.SF_PS_Current_Loc__c,
            WorkOrderId__r.SF_PS_Company_Code__c,
            WorkOrderId__r.SF_PS_RM_WO_Number__c, 
            WorkOrderId__r.SF_PS_Service_Resource__r.SF_PS_Mechanic_Id__c, 
            SF_PS_Duration__c,
            SF_PS_RM_WO_Number__c,
            SF_PS_Hourly_Internal_Rate__c,
            SF_PS_Is_Taxable__c,
            SF_PS_Labor_Code__c,
            SF_PS_PO_Amount__c,
            SF_PS_Line_Type__c,
            SF_PS_PO_Cost__c,
            SF_PS_Mechanic_Name__c,
            SF_PS_Mileage_Charge__c,
            SF_PS_RM_Created_Timestamp__c,
            SF_PS_RM_External_Id__c,
            SF_PS_RM_Item_Number__c,
            SF_PS_RM_Labor_Line_Item_Number__c,
            SF_PS_Vendor_PO_Num__c,
			SF_PS_Mechanic_Id__c,
			WorkOrderId__c,
            SF_PS_Outside_Labor_Des__c
            FROM Quote_Line_Item__c WHERE Id=: Id];
            qliList.add(qli);
        }
        return qliList;
    }

    public static List<WorkOrderLineItem> getWorkOrderLineItems(Set<String> woliIds){
        List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
        for (Id Id: woliIds){
            WorkOrderLineItem woli = [SELECT Id, LastModifiedDate, SF_PS_Mechanic_Id__c, WorkOrder.Owner.Name, WorkOrder.OwnerId,SF_PS_RM_Labor_Line_Item_Number__c, 
                                      WorkOrderId, WorkOrder.SF_PS_Company_Code__c,WorkOrder.SF_PS_RM_WO_Number__c, WorkOrder.SF_PS_Service_Resource__r.SF_PS_Mechanic_Id__c, 
                                      Duration, SF_PS_Work_Order_Description__c, Description, SF_PS_RM_Item_Number__c,SF_PS_Labor_Code__c,
                                      SF_PS_Hourly_Internal_Rate__c, WorkOrder.ServiceTerritory.OperatingHours.TimeZone, WorkOrder.WorkOrderNumber,WorkOrder.Owner.alias,
                                      WorkOrder.ServiceTerritory.Branch_Location_Number__c,  SF_PS_RM_External_Id__c, SF_PS_RM_WO_Number__c, WorkOrder.SF_PS_Current_Loc__c,SF_PS_Line_Type__c
                                      FROM WorkOrderLineItem WHERE Id=: Id  ];
            woliList.add(woli);
        }
        return woliList;
    }
    
    public static List<ProductConsumed> getProductConsumed(Set<String> pcIds){
        List<ProductConsumed> pcList = new List<ProductConsumed>();
        for (Id Id : pcIds){
            ProductConsumed pc = [SELECT Id, SF_PS_Parts_Line_Num__c, SF_PS_Stock_Class__c, SF_PS_Unit_Of_Measure__c, SF_PS_Selling_Price__c, SF_PS_Orig_Selling_Price__c, 
                                  SF_PS_Discount_Percentage__c, SF_PS_Cost_Price__c, SF_PS_Line_Level_Comment__c,SF_PS_Labor_Code__c , LastModifiedDate,WorkOrder.WorkOrderNumber,Product2.QuantityUnitOfMeasure,
                                  WorkOrderId, WorkOrder.Owner.Name, WorkOrder.OwnerId , WorkOrder.ServiceTerritory.OperatingHours.TimeZone , SF_PS_RM_External_Id__c, Product2.Item_Number__c,
                                  workOrder.ServiceTerritory.Branch_Location_Number__c , WorkOrder.SF_PS_Company_Code__c ,WorkOrder.SF_PS_RM_WO_Number__c,WorkOrder.Owner.alias ,QuantityConsumed, SF_PS_Quantity__c
                                  FROM ProductConsumed WHERE Id=: Id ];
            pcList.add(pc);
        }
        return pcList;
    }
    public static List<SF_PS_Quoted_Part__c> getQuotedParts(Set<String> qpIds){
        List<SF_PS_Quoted_Part__c> qpList = new List<SF_PS_Quoted_Part__c>();
        for (Id Id : qpIds){
            SF_PS_Quoted_Part__c qp = [SELECT Id, 
            LastModifiedDate,
            SF_PS_WorkOrderId__r.WorkOrderNumber,
            SF_PS_WorkOrderId__r.Owner.Name, 
            SF_PS_WorkOrderId__r.OwnerId , 
            SF_PS_WorkOrderId__r.ServiceTerritory.OperatingHours.TimeZone , 
            SF_PS_WorkOrderId__r.ServiceTerritory.Branch_Location_Number__c , 
            SF_PS_WorkOrderId__r.SF_PS_Company_Code__c ,
            SF_PS_WorkOrderId__r.SF_PS_RM_WO_Number__c,
            SF_PS_WorkOrderId__r.Owner.alias ,
            SF_PS_Product2Id__r.Item_Number__c,
            SF_PS_Product2Id__r.QuantityUnitOfMeasure,
            SF_PS_Product2Id__c,
            SF_PS_Cost_Price__c,
            SF_PS_Discount_Amt__c,
            SF_PS_Discount_Percentage__c,
            SF_PS_Is_Taxable__c,
            SF_PS_ItemType__c,
            SF_PS_Labor_Code__c,
            SF_PS_Line_Level_Comment__c,
            SF_PS_Line_Type__c,
            SF_PS_List_Price__c,
            SF_PS_Quoted_Parts_Line_Num__c,
            SF_PS_Quantity__c,
            SF_PS_RM_Created_Timestamp__c,
            SF_PS_Selling_Price__c,
            SF_PS_Orig_Selling_Price__c,
            SF_PS_Unit_Of_Measure__c,
            SF_PS_RM_External_Id__c,
            SF_PS_Stock_Class__c,
			SF_PS_WorkOrderId__c,
            SF_PS_Shipped_Qty__c
            FROM SF_PS_Quoted_Part__c WHERE Id=: Id ];
            qpList.add(qp);
        }
        return qpList;
    }

}