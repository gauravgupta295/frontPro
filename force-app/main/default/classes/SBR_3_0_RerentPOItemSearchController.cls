public with sharing class SBR_3_0_RerentPOItemSearchController {
    
    @AuraEnabled
    public static void createPOLineItem(Id recordId, String singleRecordId,Double newSingleUnitValue, Decimal singleQuantity,String catclass) {
        
    try{
        Id RecordTypeId = [SELECT Id FROM RecordType WHERE sObjectType = 'PO_Line_Item__c' AND DeveloperName = 'Rerent'].Id;
        String companyCode = [select Company_Code__c from Purchase_Order__c where id =: recordId].Company_Code__c;

        PO_Line_Item__c po_New_Record = new PO_Line_Item__c();
        po_New_Record.Purchase_Order__c = recordId;
        po_New_Record.Source__c = 'SF';
        po_New_Record.Item_Type__c='E';
        po_New_Record.Item_Desc__c = singleRecordId;
        po_New_Record.Unit_Cost__c= newSingleUnitValue;
        po_New_Record.Item_Number__c= '*RR'+catclass;
        po_New_Record.Quantity__c=singleQuantity;
        po_New_Record.Company_Code__c = companyCode;
        po_New_Record.RecordTypeId= RecordTypeId;
        
        System.debug('before insert POL'+ po_New_Record);
        insert po_New_Record;
        System.debug('After insert POL'+ po_New_Record);
    }
        catch (Exception e) {
            SBR_3_0_LogException.LogIt(e) ;
			throw new AuraHandledException('Failed to create PO Line Item:');
        }
    }
    
    @AuraEnabled
    public static void createBulkPOLineItem(Id recordId, List<String> RowsIds,List<Double> RowsCostValues,List<Decimal> values,List<String> selectedRowsCatClassValues) {
        
        List<PO_Line_Item__c> insertProductList=new List<PO_Line_Item__c>();

        Id RecordTypeId = [SELECT Id FROM RecordType WHERE sObjectType = 'PO_Line_Item__c' AND DeveloperName = 'Rerent'].Id;       
        String companyCode = [select Company_Code__c from Purchase_Order__c where id =: recordId].Company_Code__c; 
        
        try{
        for (Integer i = 0; i <RowsIds.size() ; i++) {
            PO_Line_Item__c po_New_Record = new PO_Line_Item__c();
            po_New_Record.Source__c = 'SF';
            po_New_Record.Item_Type__c = 'E';    	
            po_New_Record.Purchase_Order__c = recordId;
            po_New_Record.Quantity__c=values[i];
            po_New_Record.Item_Desc__c = RowsIds[i];
            po_New_Record.Unit_Cost__c= RowsCostValues[i];
            po_New_Record.Item_Number__c= '*RR'+selectedRowsCatClassValues[i];
            
            po_New_Record.Company_Code__c = companyCode;
            po_New_Record.RecordTypeId= RecordTypeId;

            insertProductList.add(po_New_Record);   
        }
        
        System.debug(insertProductList);
        insert insertProductList;
        }
        catch (Exception e) {
        	SBR_3_0_LogException.LogIt(e) ;
			throw new AuraHandledException('Failed to create PO Line Items:');
		}
        
    }
    
    @AuraEnabled
    public static List<Product_Hierarchy__c> getProductCategoryOptions(Integer filterLevel,Boolean isSubCategory,Boolean orderByName) {
        String query = 'SELECT Id, Name, Parent_Code__c, Parent_Code__r.Name from Product_Hierarchy__c';
        String whereClause = ' WHERE Product_Family_Type__c = \'Cat-Class\'';
        if (filterLevel != null && filterLevel > 0) {
            whereClause += ' AND Filter_Level__c = \'' + filterLevel.format() + '\'';
        }
        if (isSubCategory) {
            whereClause += ' AND RecordType.Name = \'Product Sub-Category\'';
        }
        if (orderByName) {
            whereClause += ' ORDER BY Name';
        }
        
        query += whereClause;
        return Database.query(query); // NOPMD
    }
    
}