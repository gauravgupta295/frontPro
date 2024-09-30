//class containing methods to operate on Purchase Order Line item
public with sharing class  SBR_3_0_PurchaseOrderLineItems {
    //method to get Purchase Order Line item
    @AuraEnabled(cacheable=true)
    public static List<PO_Line_Item__c> getPOLineItems(String purchaseOrderID) {
        system.debug('purchaseOrderID:'+purchaseOrderID);
        List<PO_Line_Item__c> poLineItemList;
        poLineItemList=[SELECT Id, Name, Item_Number__c,RecordTypeName__c, Manufacturer__c,Item_Type__c, Item_Desc__c, Item_Description_Calc__c, Item_Desc__r.Track_By_Serial_Number__c,
                               Quantity__c, Unit_Cost__c,Status__c,oldPOItem__c,Open_Order_Qty__c,ToLabel(Units__c), Last_Cost__c, Total_Cost_Calc__c,
                               Purchase_Order__r.Name, PO_Requisition__c,Freight_Reason__c,Freight_Type__c,Contract_Number__c,Event__c,Equipment_Num__c,Pro_Number__c,Messages__c
                          FROM PO_Line_Item__c WHERE Purchase_Order__c=:purchaseOrderId]; 
        system.debug('poLineItemList'+poLineItemList);
        return poLineItemList;
    }
    @AuraEnabled(cacheable=true)
    public static List<User_Location__c> getUserLocation(String loggedUserId) {
        system.debug('loggedUserId:'+loggedUserId);
        List<User_Location__c> userLocList;
        userLocList=[select id, ProfileBranche__c, ProfileBranche__r.name,User__c from User_Location__c where User__c=:loggedUserId ]; 
        system.debug('User Location List'+userLocList);
        return userLocList;
    }
    // Method to Create PO Line Item 
    @auraEnabled
    public static string createPOLineItem(Id recordId, Boolean newItem, String productId, Decimal quantity, Decimal cost) {
        String returnVal = '';
        try {
            if(newItem==false){
                PO_Line_Item__c po_New_Record = new PO_Line_Item__c();
                po_New_Record.Purchase_Order__c = recordId;
                po_New_Record.Source__c = 'SF';
                po_New_Record.Item_Desc__c = productId;
                po_New_Record.Quantity__c = quantity;
                po_New_Record.Unit_Cost__c = cost;
                insert po_New_Record;
                returnVal = 'Success';
            }
        } catch (Exception ex) {
            SBR_3_0_LogException.LogIt(ex) ;
            System.debug('An Exception: '+ex);
            returnVal = 'Error';
        }
        return returnVal;
    }
    // Method to Search PO Line Item 
    @auraEnabled(cacheable=true)
    public static List<Product2> searchProductMiscSalesItems(String companyCode, String searchString) {
        String searchPattern = '%' + searchString + '%';
        return [SELECT Id, Name, Product_SKU__c, Stock_Class__c
                FROM Product2
                WHERE Company_Code__c = :companyCode
                AND Status__c = 'A'
                AND Product_Type__c IN ('MISC Charge Items','Parts','Merchandise')
                AND (Name LIKE :searchPattern OR Product_SKU__c = :searchPattern OR Stock_Class__c = :searchPattern)];
    }
    //method to Delete Purchase Order Line item
    // author : Sachin Khambe
    @AuraEnabled
    public static Boolean deletePOLineItems(list<Id> selectedRowIDs){
        try {
            list<PO_Line_Item__c> listPOLdelete = new list<PO_Line_Item__c>();
            System.debug('selectedRowIDs ====> '+selectedRowIDs);
            for(Id idPol : selectedRowIDs) {
                listPOLdelete.add(new PO_Line_Item__c(Id = idPol));
            }
            if(!listPOLdelete.isEmpty()) {
                delete listPOLdelete;
            }
            return true;
        }
        catch(Exception ex) {
            SBR_3_0_LogException.LogIt(ex) ;
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    //method to Cancel Purchase Order Line item
    // author : Abhishek Hiremath
    @AuraEnabled
    public static Boolean cancelPOLineItems(Id recordId,list<Id> selectedRowIDs){
        
            list<PO_Line_Item__c> listPOCancel = new list<PO_Line_Item__c>();
       try {  
            for (Integer i = 0; i <selectedRowIDs.size() ; i++) {
                PO_Line_Item__c po_New_Record = new PO_Line_Item__c();
                po_New_Record.Purchase_Order__c = recordId;
                po_New_Record.Id = selectedRowIDs[i];
                po_New_Record.Status__c = 'Cancelled';
                po_New_Record.Quantity__c = 0;
                listPOCancel.add(po_New_Record);
            }
            if(!listPOCancel.isEmpty()) {
                update listPOCancel;
            }
            return true;
        }
        catch(Exception ex) {
            SBR_3_0_LogException.LogIt(ex) ;
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static void cancelPOLineItem(Id recordId,String selectedRowID){
        
            
       try {  
                PO_Line_Item__c po_New_Record = new PO_Line_Item__c();
                po_New_Record.Purchase_Order__c = recordId;
                po_New_Record.Id = selectedRowID;
                po_New_Record.Status__c = 'Cancelled';
                po_New_Record.Quantity__c = 0;
           		update po_New_Record;

        }
        catch(Exception ex) {
            SBR_3_0_LogException.LogIt(ex) ;
            //throw new AuraHandledException(ex.getMessage());
        }
    }
    
    /** @Author: Nikhil Shende
     *  @Description: Remove back order qty and update the ‘Status’ of line item as ‘Received’
     *  @Ticket no: FRONT-11934
	**/
    @AuraEnabled
    public static void removeBackOrderQtyStatus(String recordId, Id selectedRowID) {
        try {  
            	PO_Line_Item__c po_New_Record = new PO_Line_Item__c();
            	po_New_Record.Purchase_Order__c = recordId;	
                po_New_Record.Id = selectedRowID;
                po_New_Record.Status__c = 'Received';
                po_New_Record.Open_Order_Qty__c = 0;
                update po_New_Record;
        }
        catch(Exception ex) {
            SBR_3_0_LogException.LogIt(ex) ;
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
	/** @Author: Nikhil Shende
     *  @Description: Update the PO ‘Status’ to Receive of line item as ‘Received’
     *  @Ticket no: FRONT-11934
	**/
    @AuraEnabled
    public static void updatePOStatusToReceived(Id recordId) {
        try {  
            Boolean allReceivedLineItems = true;
            for(PO_Line_Item__c poLi : [SELECT Id, Status__c FROM PO_Line_Item__c WHERE Purchase_Order__c =:recordId]) {
                if(poLi.Status__c != 'Received') {
                    allReceivedLineItems = false;
                    break;
                }
            }
            if(allReceivedLineItems) {
                Purchase_Order__c po = new Purchase_Order__c(Id=recordId, Status__c='Received');
                update po;
            }
        }
        catch(Exception ex) {
            SBR_3_0_LogException.LogIt(ex) ;
            throw new AuraHandledException(ex.getMessage());
        }
    }    
    
    // Harshal Magar
    @AuraEnabled
    public static List<Product2> searchProductsToAddLineItem(String companyCode, String itemNumber) {
        // String searchPattern = '%' + itemNumber + '%';
        // String searchPattern = itemNumber;
        List<Product2> products = [SELECT Id, Name,Item_Number__c, Product_SKU__c, Stock_Class__c
                                   FROM Product2
                                   WHERE Company_Code__c = :companyCode
                                   AND Status__c = 'A'
                                   AND Product_Type__c IN ('MISC Charge Items', 'Parts', 'Merchandise')
                                   AND Item_Number__c =: itemNumber
                                   LIMIT 50];
        return products;
    }
    // Method to Add PO Line Item 
    @auraEnabled
    public static string addPOLineItem(Id recordId, Boolean newItem, String productId, Decimal quantity, Decimal cost, String itemNumber, String companyCode ) {
        String returnVal = '';
        Id recordTypeId; 
        recordTypeId = [SELECT Id FROM RecordType WHERE sObjectType = 'PO_Line_Item__c' AND DeveloperName = 'Standard_Purchase_Order'].Id;
        try {
            if(newItem==false){
                PO_Line_Item__c po_New_Record = new PO_Line_Item__c();
                po_New_Record.Purchase_Order__c = recordId;
                po_New_Record.Source__c = 'SF';
                po_New_Record.Item_Desc__c = productId;
                po_New_Record.Quantity__c = quantity;
                po_New_Record.Unit_Cost__c = cost;
                po_New_Record.Item_Number__c = itemNumber;
                po_New_Record.Company_Code__c = companyCode;
                po_New_Record.RecordTypeId= recordTypeId;
                insert po_New_Record;
                returnVal = 'Success';
            }
        } catch (Exception ex) {
            SBR_3_0_LogException.LogIt(ex) ;
            System.debug('An Exception: '+ex);
            returnVal = 'Error';
        }
        return returnVal;
    }
    
    @auraEnabled
    public static string addPOLineItem2(Id recordId, Boolean newItem, String productId, Decimal quantity, Decimal cost, String itemNumber, String companyCode ) {
        String returnVal = '';
        Id recordTypeId; 
        recordTypeId = [SELECT Id FROM RecordType WHERE sObjectType = 'PO_Line_Item__c' AND DeveloperName = 'Third_Party_Hauler'].Id;
        try {
            if(newItem==false){
                PO_Line_Item__c po_New_Record = new PO_Line_Item__c();
                po_New_Record.Purchase_Order__c = recordId;
                po_New_Record.Source__c = 'SF';
                po_New_Record.Item_Desc__c = productId;
                po_New_Record.Quantity__c = quantity;
                po_New_Record.Unit_Cost__c = cost;
                po_New_Record.Item_Number__c = itemNumber;
                po_New_Record.Company_Code__c = companyCode;
                po_New_Record.RecordTypeId= recordTypeId;
                insert po_New_Record;
                returnVal = 'Success';
            }
        } catch (Exception ex) {
            SBR_3_0_LogException.LogIt(ex) ;
            System.debug('An Exception: '+ex);
            returnVal = 'Error';
        }
        return returnVal;
    }
    @AuraEnabled(cacheable=true)
    public static PO_Line_Item__c getPOLineItembyId(string poLineItemId){
        system.debug('poLineItemId:'+poLineItemId);
        PO_Line_Item__c poLineItem;
        poLineItem = [SELECT Id, RecordTypeId, Name, Item_Number__c, 
                      Item_Description_Calc__c,
                      Manufacturer__c, Stock_Class__c, 
                      Item_Class__c, Stock_Status__c,
                      Quantity__c, Item_Type__c, Units__c,  
                      Unit_Cost__c, Last_Cost__c,
                      Total_Cost_Calc__c,Purchase_Order__r.Name, 
                      PO_Requisition__c, Conversion_Factor__c, 
                      Pricing_Schedule__c, Due_Date__c,AcctNumber__c,
                      Request_Date__c, Drop_Shipment__c,
                      Equipment_Num__c, GL_Account__c,Contract_Num__c,
                      Average_Monthly_Usage__c,
                      Reorder_Point__c, Reorder_Quantity__c, Bulk_Item__c,
                      Messages__c, Item_Desc__c,
                      Purchase_Order__r.Branch_Location__c,
                      Freight_Reason__c,Freight_Type__c,
                      Contract_Number__c,Event__c,Transfer_Num__c,
                      Pro_Number__c,Company_Code__c
                      FROM PO_Line_Item__c
                      WHERE Id =:poLineItemId
                      LIMIT 1]; 
        system.debug('poLineItem'+poLineItem);
        return poLineItem;
    }
    
    @AuraEnabled
    public static PO_Line_Item__c getFreightDetailsById(string poLineItemId){
        system.debug('poLineItemId:'+poLineItemId);
        PO_Line_Item__c poLineItem;
        poLineItem = [SELECT Id, RecordTypeId, Name, Item_Number__c, 
                      Item_Description_Calc__c,
                      Manufacturer__c, Stock_Class__c, 
                      Item_Class__c, Stock_Status__c,
                      Quantity__c, Item_Type__c, Units__c,  
                      Unit_Cost__c, Last_Cost__c,
                      Total_Cost_Calc__c,Purchase_Order__r.Name, 
                      PO_Requisition__c, Conversion_Factor__c, 
                      Pricing_Schedule__c, Due_Date__c,AcctNumber__c,
                      Request_Date__c, Drop_Shipment__c,
                      Equipment_Num__c, GL_Account__c,Contract_Num__c,
                      Average_Monthly_Usage__c,
                      Reorder_Point__c, Reorder_Quantity__c, Bulk_Item__c,
                      Messages__c, Item_Desc__c,
                      Purchase_Order__r.Branch_Location__c,
                      Freight_Reason__c,Freight_Type__c,
                      Contract_Number__c,Event__c,Transfer_Num__c,
                      Pro_Number__c,Company_Code__c
                      FROM PO_Line_Item__c
                      WHERE Id =:poLineItemId
                      LIMIT 1]; 
        system.debug('poLineItem'+poLineItem);
        return poLineItem;
    }
    
    @AuraEnabled(cacheable=true)
    public static ProductItem getProductItemByProductAndLocation(string productId, string orderLocationId){
        system.debug('productId: '+productId + 'orderLocationId: ' +orderLocationId);
        ProductItem productItem;
        productItem = [SELECT Id, ProductName, 
                       Product2Id, LocationId, 
                       SM_PS_Customer_BackOrders__c,
                       SM_PS_Quantity_Available__c,
                       SM_PS_Quantity_on_Order_to_Vendor__c
                       FROM ProductItem
                       WHERE Product2Id = :productId
                       AND LocationId = :orderLocationId
                       LIMIT 1]; 
        system.debug('poLineItem'+productItem);
        return productItem;
    }
    // Method to Add PO Line Item for 3rd Party Hauler
    @auraEnabled
    public static string addFreightLineItem(String recId, String companyCode, String usage, String contract, String transfer, String freightReason, Decimal freightCost, String eventId, String equipment, String proNum, String message, Boolean isUpdate) {
        System.debug(' into apex method addFreightLineItem ');
        System.debug('poId >>'+recId );
        System.debug('companyCode >>'+companyCode );
        System.debug('transfer >>'+transfer );
        System.debug('freightReason >>'+freightReason );
        System.debug('freightCost >>'+freightCost );
        System.debug('eventId >>'+eventId );
        System.debug('equipment >>'+equipment );
        System.debug('proNum >>'+proNum );
        System.debug('message >>'+message );
        //System.debug('equipment >>'+equipment );
        String returnVal = '';
        Id recordTypeId;
        String contractNo ='';   
        String transferNo ='';      
        recordTypeId = [SELECT Id FROM RecordType WHERE sObjectType = 'PO_Line_Item__c' AND DeveloperName = 'Third_Party_Hauler'].Id;
        if(!String.isEmpty(contract)){
            contractNo = [select Contract_Order_Number__c from Order where id=: contract][0].Contract_Order_Number__c;
        }
        if(!String.isEmpty(transfer)){
        transferNo = [select Id from Internal_Order__c where RM_Transfer_Number__c=: transfer][0].Id;
        }
        try {
            PO_Line_Item__c po_New_Record = new PO_Line_Item__c();
            po_New_Record.Source__c = 'SF';
            po_New_Record.Unit_Cost__c = freightCost;
            po_New_Record.Freight_Type__c = usage;
            po_New_Record.Freight_Reason__c = freightReason;
            po_New_Record.Contract_Number__c = String.isEmpty(contract) ? null : contract;
            po_New_Record.Transfer_Num__c = String.isEmpty(transfer) ? null : Decimal.valueOf(transfer);
            po_New_Record.Internal_Order__c = String.isEmpty(transfer) ? null : transferNo;
            po_New_Record.AcctNumber__c = String.isEmpty(eventId) ? null : Decimal.valueOf(eventId);
            //po_New_Record.Event__c = String.isEmpty(eventId) ? null : eventId;
            po_New_Record.Equipment_Num__c  = equipment;
            po_New_Record.Pro_Number__c = proNum;
            po_New_Record.Messages__c = message;
            po_New_Record.Company_Code__c = companyCode;
            po_New_Record.RecordTypeId= recordTypeId;
            po_New_Record.Item_Number__c= freightReason;
            po_New_Record.Contract_Num__c = String.isEmpty(contractNo) ? null : Decimal.valueOf(contractNo);
            po_New_Record.Quantity__c = 1;
            System.debug('po_New_Record >> '+po_New_Record);
            if(isUpdate){
                po_New_Record.id = recId;
                update po_New_Record;
            }else{
                po_New_Record.Purchase_Order__c = recId;
                insert po_New_Record;
            }
            
            returnVal = 'Success';
        } catch (Exception ex) {
            SBR_3_0_LogException.LogIt(ex) ;
            System.debug('An Exception: '+ex);
            returnVal = 'Error';
        }
        return returnVal;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<PO_Event__c> getEventOption(){
        return [select id,Name,Event_Number__c from PO_Event__c];
    }

    @AuraEnabled
    public static void updatePOStatus(Id recordId)
    {
        Purchase_Order__c po_New_Record=new Purchase_Order__c();
        po_New_Record.Id=recordId;
        po_New_Record.Status__c='Open';
        po_New_Record.Reopened__c=true;
        update po_New_Record;
    }
}