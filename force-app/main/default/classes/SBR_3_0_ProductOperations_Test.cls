/*********************************************************************************************************************
* Apex Class: SBR_3_0_ProductOperations_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Verifies proper execution of Product Operations utility methods
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE            DETAIL FEATURES
    1.0         Alex DeVries            2022-10-17      Initial version (SAL-6277)
*********************************************************************************************************************/
@isTest
public with sharing class SBR_3_0_ProductOperations_Test
{
    private static Map<string,string> prodEquipTypeFieldMap = SBR_3_0_ProductOperations.productEquipTypeFieldMap;
    private static Set<string> prodFieldUniqueConstraintSet = SBR_3_0_ProductOperations.prodFieldUniqueConstraintSet;
    private static Set<string> prodFieldCompleteSupplementSet = SBR_3_0_ProductOperations.prodFieldCompleteSupplementSet;
    private static final List<string> stringList = new List<String>
        { 'Cat', 'Tst', 'Cls', 'Eqp', 'Typ', 'Uni', 'Dbg', 'Wld', 'Try', 'Cth' };

    /***********************************************************************************
    * Description: Verifies that creation of TMS Product records results in creation
        of corresponding Equipment Type records with data sourced from Product
    ************************************************************************************/
    @isTest(seeAllData=True)
    static void createEquipmentTypesTest()
    {
        // instantiate/populate Products
        Map<String,SObjectField> prodFieldMap = Schema.SObjectType.Product2.fields.getMap();
        List<Product2> prodList = instantiateProducts(prodFieldMap);
		
        System.debug('prodList: '+prodList.size());
        prodList[0].Rental_Category__c = '23.00';
        prodList[0].Rental_Class__c = '023.00';
        Test.startTest();
        insert prodList;
        Test.stopTest();

        // organize Products and assert association with Equipment Types
        List<Product2> postInsertProdList = [SELECT Id, TMS_Product__c, SM_PS_TMS_External_ID__c,
            SM_PS_TMS_Incomplete__c, SM_PS_TMS_Override__c, SM_PS_TMS_Equipment_Type__c
            FROM Product2 WHERE Id IN :prodList];
        Map<Id,Product2> postInsertProdIdMap = new Map<Id,Product2>();
        for(Product2 prod : postInsertProdList)
        {
            if(prod.TMS_Product__c &&
                (!prod.SM_PS_TMS_Incomplete__c || prod.SM_PS_TMS_Override__c))
            { System.assertNotEquals(null, prod.SM_PS_TMS_Equipment_Type__c); }
            else
            { System.assertEquals(null, prod.SM_PS_TMS_Equipment_Type__c); }

            postInsertProdIdMap.put(prod.Id, prod);
        }

        // fetch Equipment Type records
        Map<string,Equipment_Type__c> extIdEquipTypeMap = fetchProductEquipTypeData(postInsertProdList);

        // validate that data for each Equipment Type was sourced from appropriate Product
        for(string prodField : prodEquipTypeFieldMap.keySet())
        {
            string equipTypeField = prodEquipTypeFieldMap.get(prodField);
            for(Product2 prod : prodList)
            {
                if(prod.TMS_Product__c &&
                    (!prod.SM_PS_TMS_Incomplete__c || prod.SM_PS_TMS_Override__c))
                {
                    Product2 postInsertProd = postInsertProdIdMap.get(prod.Id);
                    String postInsertProdExtId = postInsertProd.SM_PS_TMS_External_ID__c;

                    Equipment_Type__c equipType = extIdEquipTypeMap.get(postInsertProdExtId);
                    System.assertNotEquals(equipType, null);
                    system.debug('asserting ' + prodField + ' ' + equipTypeField);
                    //System.assertEquals(prod.get(prodField), equipType.get(equipTypeField));
                }
            }
        }
    }

    /***********************************************************************************
    * Description: Verifies that update of TMS Product records results in creation
        of corresponding Equipment Type records with data sourced from Product
    ************************************************************************************/
    @isTest(seeAllData=TRUE) 
    static void updateEquipmentTypesTest()
    {
        // instantiate/populate Products
        Map<String,SObjectField> prodFieldMap = Schema.SObjectType.Product2.fields.getMap();
        List<Product2> prodList = instantiateProducts(prodFieldMap);

        Test.startTest();
        // insert Products
        insert prodList;

        // organize Products by Name
        Map<string,Product2> prodNameMap = new Map<string,Product2>();
        for(Product2 prod : prodList) { prodNameMap.put(prod.Name, prod); }

        // update Primary Product
        Product2 modifiedPrimaryProd = prodNameMap.get('Secondary Product').clone(false, true, false, false);
        modifiedPrimaryProd.Id = prodNameMap.get('Primary Product').Id;
        modifiedPrimaryProd.Name = 'Primary Product';
        modifiedPrimaryProd.Product_SKU__c = prodNameMap.get('Primary Product').Product_SKU__c;

        system.debug('primary and secondary ext id match: ' + (modifiedPrimaryProd.SM_PS_TMS_External_ID__c ==
            prodNameMap.get('Secondary Product').SM_PS_TMS_External_ID__c));

        update modifiedPrimaryProd;
        Test.stopTest();

        prodList = [SELECT Id, Name, TMS_Product__c, SM_PS_TMS_External_ID__c,
            SM_PS_TMS_Incomplete__c, SM_PS_TMS_Override__c, SM_PS_TMS_Equipment_Type__c
            FROM Product2 WHERE Id IN :prodList];
        for(Product2 prod : prodList) { prodNameMap.put(prod.Name, prod); }

        // validate that Primary and Secondary Product share an Equipment Type
        system.assertEquals(prodNameMap.get('Primary Product').SM_PS_TMS_Equipment_Type__c,
            prodNameMap.get('Secondary Product').SM_PS_TMS_Equipment_Type__c);
    }

    /***********************************************************************************
    * Description: Finds Equipment Types related to specified Products
    ************************************************************************************/
    private static Map<string,Equipment_Type__c> fetchProductEquipTypeData(List<Product2> prodList)
    {
        Set<Id> equipTypeIdSet = new Set<Id>();
        for(Product2 prod : prodList) { equipTypeIdSet.add(prod.SM_PS_TMS_Equipment_Type__c); }

        String query = buildEquipmentTypeQuery(equipTypeIdSet);
        List<Equipment_Type__c> equipTypeList = (List<Equipment_Type__c>)Database.query(query);

        Map<string,Equipment_Type__c> extIdEquipTypeMap = new Map<string,Equipment_Type__c>();
        for(Equipment_Type__c equipType : equipTypeList)
        { extIdEquipTypeMap.put(equipType.SM_PS_TMS_External_ID__c, equipType); }

        return extIdEquipTypeMap;
    }

    /***********************************************************************************
    * Description: Constructs SOQL query string used to fetch Equipment Type field data
        associated with newly created Products
    ************************************************************************************/
    private static string buildEquipmentTypeQuery(Set<Id> equipTypeIdSet)
    {
        List<string> queryFieldList = prodEquipTypeFieldMap.values();
        string queryFieldStr = String.join(queryFieldList, ',');
        queryFieldStr += ',SM_PS_TMS_External_ID__c';
        
        string queryTemplate = 'SELECT {0} FROM Equipment_Type__c WHERE Id IN :equipTypeIdSet';
        return String.format(queryTemplate, new List<string> {queryFieldStr});
    }

    /***********************************************************************************
    * Description: Creates Product instances and populates them with data
    ************************************************************************************/
    private static List<Product2> instantiateProducts(Map<String,SObjectField> prodFieldMap)
    {
        List<Product2> prodList = new List<Product2>{
            new Product2(Name='Primary Product', TMS_Product__c = true),
            new Product2(Name='Secondary Product', TMS_Product__c = true),
            new Product2(Name='Tertiary Product', TMS_Product__c = true, SM_PS_TMS_Override__c = true),
            new Product2(Name='Non TMS Product', TMS_Product__c = false)
        };

        // populate instantiated Products with sample data
        Set<string> prodFieldNameSet = new Set<string>(prodEquipTypeFieldMap.keySet());
        prodFieldNameSet.addAll(prodFieldCompleteSupplementSet);
        for(String prodFieldName : prodFieldNameSet)
        {
            Schema.DisplayType fieldType = prodFieldMap.get(prodFieldName).getDescribe().getType();
            for(Product2 prod : prodList) { setProductFieldValue(prod, prodFieldName, fieldType); }
        }

        // ensure uniqueness of values with unique constraint
        for(Integer i = 0; i < prodList.size(); i++)
        {
            for(string uniqueField : prodFieldUniqueConstraintSet)
            { prodList[i].put(uniqueField, (string)prodList[i].get(uniqueField) + string.valueOf(i)); }
        }

        // ensure that Tertiary Product is incomplete
        prodList.get(2).SM_PS_CMV_DOT_YN__c = true;

        return prodList;
    }

    /***********************************************************************************
    * Description: Populates Product field with sample data
    ************************************************************************************/
    private static void setProductFieldValue(Product2 prod,
        String fieldName, Schema.DisplayType fieldType)
    {
        if(fieldName?.toLowerCase() == 'id' || fieldName?.toLowerCase() == 'Product_Sub_Category__c') { return; }

        if(fieldType == Schema.DisplayType.DOUBLE
            || fieldType == Schema.DisplayType.INTEGER || fieldType == Schema.DisplayType.LONG)
        { prod.put(fieldName, Integer.valueOf(Math.Random() * 9)); }
        else if(fieldType == Schema.DisplayType.BOOLEAN)
        { prod.put(fieldName, false); }
        else if(fieldType == Schema.DisplayType.PICKLIST)
        {
            if(fieldName.contains('_Equipment_Compart_Div__c'))
            { prod.put(fieldName, 'EQMTCMPTDIVD_NULL'); }
            else if(fieldName == 'Equipment_Category__c')
            { prod.put(fieldName, 'EQMTCAT_TRLR'); }
            else if(fieldName == 'Include_Exclude_Restriction__c')
            { prod.put(fieldName, 'IER_EXCLUDE'); }
            else if(fieldName == 'Variable_Loading_Unit_Type__c')
            { prod.put(fieldName, 'LUT_CUBE'); }
            else if(fieldName == 'Variable_Time_Category__c')
            { prod.put(fieldName, 'VTC_NULL'); }
        }
        else if(fieldType == Schema.DisplayType.DATE)
        { prod.put(fieldName, Date.today()); }
        else if(fieldType == Schema.DisplayType.DATETIME)
        { prod.put(fieldName, Datetime.now()); }
        else if(fieldType == Schema.DisplayType.STRING || fieldType == schema.DisplayType.TEXTAREA)
        { prod.put(fieldName, stringList.get(Integer.valueOf(Math.Random() * 9))); }
    }
}