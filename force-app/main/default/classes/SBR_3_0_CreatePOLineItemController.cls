public with sharing class SBR_3_0_CreatePOLineItemController {
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getPicklistValues() {
        List<Schema.PicklistEntry> entries = PO_Line_Item__c.Units__c.getDescribe().getPicklistValues();
        List<Map<String, String>> values = new List<Map<String, String>>();
        for (Schema.PicklistEntry entry : entries) {
            Map<String, String> valueMap = new Map<String, String>();
            valueMap.put('label', entry.getLabel());
            valueMap.put('value', entry.getValue());
            values.add(valueMap);
        }
        system.debug('values---'+values);
        return values;
    }

    @AuraEnabled(cacheable=true)
    public static List<product2> getProductRecord(String itemNumber, string description, String stockClass, String companyCode) {
        String SearchKeyword = '%'+itemNumber+'%';
        String SearchKeyword1 = '%'+description+'%';
        List<Product2> productList = new List<Product2>();
        Set<Id> productIds = new Set<Id>();

        // Exact Item Number Match
        List<product2> prodList1 = [SELECT Id, Name,Item_Number__c,Last_Cost__c, Product_Description__c,Vendor_Number1__c, 
                                           Product_Type__c,Long_Description__c,Product_SKU__c, Search_Word__c,Stock_Class__c
                                      FROM Product2
                                     WHERE Company_Code__c = :companyCode
                 					   AND Product_Type__c IN ('MISC Charge Items', 'Parts', 'Merchandise')
                                       AND Item_Number__c = :itemNumber];
        
        for(Product2 prod : prodList1) {
            productList.add(prod);
            productIds.add(prod.Id);
        }

        // Fuzzy match on Item Number
        List<product2> prodList2 = [SELECT Id, Name,Item_Number__c,Last_Cost__c, Product_Description__c,Vendor_Number1__c, 
                                           Product_Type__c,Long_Description__c,Product_SKU__c, Search_Word__c,Stock_Class__c
                                      FROM Product2
                                     WHERE Company_Code__c = :companyCode
                 					   AND Product_Type__c IN ('MISC Charge Items', 'Parts', 'Merchandise')
                                       AND Item_Number__c Like :SearchKeyword
                                     LIMIT 5];
        
        for(Product2 prod : prodList2) {
            if(!productIds.contains(prod.Id)) {
                productList.add(prod);
                productIds.add(prod.Id);                
            }
        }

        // Fuzzy match on Item Description
        List<product2> prodList3 = [SELECT Id, Name,Item_Number__c,Last_Cost__c, Product_Description__c,Vendor_Number1__c, 
                                           Product_Type__c,Long_Description__c,Product_SKU__c, Search_Word__c,Stock_Class__c
                                      FROM Product2
                                     WHERE Company_Code__c = :companyCode
                 					   AND Product_Type__c IN ('MISC Charge Items', 'Parts', 'Merchandise')
                                       AND Name Like :SearchKeyword1
                                     LIMIT 5];
        
        for(Product2 prod : prodList3) {
            if(!productIds.contains(prod.Id)) {
                productList.add(prod);
                productIds.add(prod.Id);                
            }
        }

        // Fuzzy match on Item Number and Item Description
        List<product2> prodList4 = [SELECT Id, Name,Item_Number__c,Last_Cost__c, Product_Description__c,Vendor_Number1__c, 
                                           Product_Type__c,Long_Description__c,Product_SKU__c, Search_Word__c,Stock_Class__c
                                      FROM Product2
                                     WHERE Company_Code__c = :companyCode
                 					   AND Product_Type__c IN ('MISC Charge Items', 'Parts', 'Merchandise')
                                       AND Item_Number__c Like :SearchKeyword
                                       AND Name Like :SearchKeyword1
                                     LIMIT 5];
        
        for(Product2 prod : prodList4) {
            if(!productIds.contains(prod.Id)) {
                productList.add(prod);
            }
        }
        
        return productList;
    }

    @AuraEnabled
    public static String createNewPOLineItemFromProduct(Id recordId, String productRecordId, decimal quantityvalue, decimal unitCost){
        Id RecordTypeId = [SELECT Id FROM RecordType WHERE sObjectType = 'PO_Line_Item__c' AND DeveloperName = 'Standard_Purchase_Order'].Id; 
        Purchase_Order__c PO=[select id, Company_Code__c from Purchase_Order__c where id=:recordId];
        List<product2> productList=[select id, name,Stock_class__c,Product_Type__c,Search_Word__c, Item_Number__c, Description__c, Description, PO_Unit_of_Measure__c from product2 where id =: productRecordId];
        PO_Line_Item__c poli= new PO_Line_Item__c();
        string returnVal;
        try{
            PO_Line_Item__c po_New_Record = new PO_Line_Item__c();
            po_New_Record.Source__c = 'SF';
            po_New_Record.Purchase_Order__c = recordId;
            po_New_Record.Item_Desc__c = productRecordId;
            po_New_Record.Quantity__c = quantityvalue;
            po_New_Record.Unit_Cost__c = unitCost;
            po_New_Record.Item_Number__c = productList[0].Item_Number__c ;
            po_New_Record.RecordTypeId=RecordTypeId;
            po_New_Record.Company_Code__c = PO.Company_Code__c;
            insert po_New_Record;
            returnVal = 'Success';
        }catch(exception ex){
            SBR_3_0_LogException.LogIt(ex) ;
            System.debug('An Exception: '+ex);
            returnVal='Error';
        }
        return returnVal;
    }
    @AuraEnabled
    public static void createNewPOLineItem(Id recordId,String itemNumber, Decimal unitCost, String description, String stockClass, decimal quantityvalue, string POunit, String typeValue){
        PO_Line_Item__c poli= new PO_Line_Item__c();
        Id RecordTypeId = [SELECT Id FROM RecordType WHERE sObjectType = 'PO_Line_Item__c' AND DeveloperName = 'Standard_Purchase_Order'].Id; 
        Purchase_Order__c PO=[select id, Company_Code__c from Purchase_Order__c where id=:recordId];
        string returnVal;
        try{
            poli.Source__c = 'SF';
            poli.Purchase_Order__c=recordId;
            poli.quantity__c=quantityvalue;
            poli.unit_cost__c=unitCost;
            poli.Item_Type__c=typeValue; // Need to fix 
            poli.item_number__c=itemNumber;
            poli.new_item__c=true;
            poli.Item_Description_Text__c=description;
            poli.Stock_class__c=stockClass;
            poli.units__c=POunit;
            poli.RecordTypeId=RecordTypeId;
            poli.Company_Code__c = PO.Company_Code__c;
            insert poli;
            returnVal = 'Success';
        }catch(exception ex){
            SBR_3_0_LogException.LogIt(ex) ;
            System.debug('An Exception: '+ex);
            returnVal='Error';
        }
    }
}