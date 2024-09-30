/******************************************************************************************
* Apex Class: SBR_3_0_ProductOperations
-------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Contains utility methods used during:
* -   processing of Product creation to facilitate creation of Equipment Type
-------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE            DETAIL FEATURES
    1.0         Alex DeVries            2022-10-14      Initial version (SAL-6277)
    2.0         Alex DeVries            2022-10-18      Added updateEquipmentTypes (SAL-6274)
    3.0         Alex DeVries            2022-11-04      Added field mapping entries (SAL-9300)
    4.0         Alex DeVries            2022-11-18      Added field mapping entries, revised
                                                        Equipment Type creation logic (SAL-9333)
*******************************************************************************************/
public with sharing class SBR_3_0_ProductOperations
{
    public static final Map<string, string> productEquipTypeFieldMap = new Map<string,string>
    {   'Axle_Spring_Factor__c'=>'EQAX_Axle_Spring_Factor__c',
        'Load_Point_Location__c'=>'EQAX_Load_Point_Location__c','Load_Point_MaxLoad_Weight__c'=>'EQAX_Load_Point_MaxLoad_Weight__c',
        'Load_Point_Tare_Weight__c'=>'EQAX_Load_Point_Tare_Weight__c','COMP1_Usable_Width__c'=>'EQCMT1_Usable_Width__c',
        'COMP1_Allow_Staggering__c'=>'EQCMT1_Allow_Staggering__c','COMP1_Base_Height__c'=>'EQCMT1_Base_Height__c',
        'COMP1_Compartment_Position__c'=>'EQCMT1_Compartment_Position__c',
        'COMP1_Equipment_Compart_Div__c'=>'EQCMT1_Equipment_Compartment_Divider__c','COMP1_Flexible__c'=>'EQCMT1_Flexible__c',
        'COMP1_Loading_Sequence__c'=>'EQCMT1_Loading_Sequence__c','COMP1_Maximum_Commodity__c'=>'EQCMT1_Maximum_Commodity__c',
        'COMP1_Maximum_Pallets__c'=>'EQCMT1_Maximum_Pallets__c','COMP1_Maximum_Pieces__c'=>'EQCMT1_Maximum_Pieces__c',
        'COMP1_Maximum_Units__c'=>'EQCMT1_Maximum_Units__c','COMP1_Maximum_Volume__c'=>'EQCMT1_Maximum_Volume__c',
        'COMP1_Maximum_Weight__c'=>'EQCMT1_Maximum_Weight__c','COMP1_Usable_Height__c'=>'EQCMT1_Usable_Height__c',
        'COMP1_Usable_Length__c'=>'EQCMT1_Usable_Length__c','COMP2_Usable_Width__c'=>'EQCMT2_Usable_Width__c',
        'COMP2_Allow_Staggering__c'=>'EQCMT2_Allow_Staggering__c','COMP2_Base_Height__c'=>'EQCMT2_Base_Height__c',
        'COMP2_Compartment_Position__c'=>'EQCMT2_Compartment_Position__c',
        'COMP2_Equipment_Compart_Div__c'=>'EQCMT2_Equipment_Compartment_Divider__c',
        'COMP2_Flexible__c'=>'EQCMT2_Flexible__c','COMP2_Loading_Sequence__c'=>'EQCMT2_Loading_Sequence__c',
        'COMP2_Maximum_Commodity__c'=>'EQCMT2_Maximum_Commodity__c','COMP2_Maximum_Pallets__c'=>'EQCMT2_Maximum_Pallets__c',
        'COMP2_Maximum_Pieces__c'=>'EQCMT2_Maximum_Pieces__c','COMP2_Maximum_Units__c'=>'EQCMT2_Maximum_Units__c',
        'COMP2_Maximum_Volume__c'=>'EQCMT2_Maximum_Volume__c','COMP2_Maximum_Weight__c'=>'EQCMT2_Maximum_Weight__c',
        'COMP2_Usable_Height__c'=>'EQCMT2_Usable_Height__c','COMP2_Usable_Length__c'=>'EQCMT2_Usable_Length__c',
        'COMP3_Usable_Width__c'=>'EQCMT3_Usable_Width__c','COMP3_Allow_Staggering__c'=>'EQCMT3_Allow_Staggering__c',
        'COMP3_Base_Height__c'=>'EQCMT3_Base_Height__c','COMP3_Compartment_Position__c'=>'EQCMT3_Compartment_Position__c',
        'COMP3_Equipment_Compart_Div__c'=>'EQCMT3_Equipment_Compartment_Divider__c','COMP3_Flexible__c'=>'EQCMT3_Flexible__c',
        'COMP3_Loading_Sequence__c'=>'EQCMT3_Loading_Sequence__c','COMP3_Maximum_Commodity__c'=>'EQCMT3_Maximum_Commodity__c',
        'COMP3_Maximum_Pallets__c'=>'EQCMT3_Maximum_Pallets__c','COMP3_Maximum_Pieces__c'=>'EQCMT3_Maximum_Pieces__c',
        'COMP3_Maximum_Units__c'=>'EQCMT3_Maximum_Units__c','COMP3_Maximum_Volume__c'=>'EQCMT3_Maximum_Volume__c',
        'COMP3_Maximum_Weight__c'=>'EQCMT3_Maximum_Weight__c','COMP3_Usable_Height__c'=>'EQCMT3_Usable_Height__c',
        'COMP3_Usable_Length__c'=>'EQCMT3_Usable_Length__c','COMP4_Usable_Width__c'=>'EQCMT4_Usable_Width__c',
        'COMP4_Allow_Staggering__c'=>'EQCMT4_Allow_Staggering__c','COMP4_Base_Height__c'=>'EQCMT4_Base_Height__c',
        'COMP4_Compartment_Position__c'=>'EQCMT4_Compartment_Position__c',
        'COMP4_Equipment_Compart_Div__c'=>'EQCMT4_Equipment_Compartment_Divider__c',
        'COMP4_Flexible__c'=>'EQCMT4_Flexible__c','COMP4_Loading_Sequence__c'=>'EQCMT4_Loading_Sequence__c',
        'COMP4_Maximum_Commodity__c'=>'EQCMT4_Maximum_Commodity__c','COMP4_Maximum_Pallets__c'=>'EQCMT4_Maximum_Pallets__c',
        'COMP4_Maximum_Pieces__c'=>'EQCMT4_Maximum_Pieces__c','COMP4_Maximum_Units__c'=>'EQCMT4_Maximum_Units__c',
        'COMP4_Maximum_Volume__c'=>'EQCMT4_Maximum_Volume__c','COMP4_Maximum_Weight__c'=>'EQCMT4_Maximum_Weight__c',
        'COMP4_Usable_Height__c'=>'EQCMT4_Usable_Height__c','COMP4_Usable_Length__c'=>'EQCMT4_Usable_Length__c',
        'COMP5_Usable_Width__c'=>'EQCMT5_Usable_Width__c','COMP5_Allow_Staggering__c'=>'EQCMT5_Allow_Staggering__c',
        'COMP5_Base_Height__c'=>'EQCMT5_Base_Height__c','COMP5_Compartment_Position__c'=>'EQCMT5_Compartment_Position__c',
        'COMP5_Equipment_Compart_Div__c'=>'EQCMT5_Equipment_Compartment_Divider__c','COMP5_Flexible__c'=>'EQCMT5_Flexible__c',
        'COMP5_Loading_Sequence__c'=>'EQCMT5_Loading_Sequence__c','COMP5_Maximum_Commodity__c'=>'EQCMT5_Maximum_Commodity__c',
        'COMP5_Maximum_Pallets__c'=>'EQCMT5_Maximum_Pallets__c','COMP5_Maximum_Pieces__c'=>'EQCMT5_Maximum_Pieces__c',
        'COMP5_Maximum_Units__c'=>'EQCMT5_Maximum_Units__c','COMP5_Maximum_Volume__c'=>'EQCMT5_Maximum_Volume__c',
        'COMP5_Maximum_Weight__c'=>'EQCMT5_Maximum_Weight__c','COMP5_Usable_Height__c'=>'EQCMT5_Usable_Height__c',
        'COMP5_Usable_Length__c'=>'EQCMT5_Usable_Length__c','External_Code__c'=>'SM_PS_External_Code__c',
        'Side_Door_Location__c'=>'SM_PS_Door_Location__c','Equipment_Category__c'=>'SM_PS_Equipment_Category__c',
        'Product_Sub_Category__c'=>'SM_PS_Equipment_Type_Description__c','Height__c'=>'SM_PS_Height__c',
        'Last_Roll_Height_Clearance__c'=>'SM_PS_Last_Roll_Height_Clearance__c',
        'Last_Stack_Height_Clearance__c'=>'SM_PS_Last_Stack_Height_Clearance__c','Length__c'=>'SM_PS_Length__c',
        'Maximum_Load_Weight__c'=>'SM_PS_Maximum_Load_Weight__c',
        'Near_Tail_Location__c'=>'SM_PS_Near_Tail_Location__c',
        'Side_Door__c'=>'SM_PS_Side_Door__c','Unit_Tare_Weight__c'=>'SM_PS_Unit_Tare_Weight__c','Usable_Height__c'=>'SM_PS_Usable_Height__c',
        'Usable_Length__c'=>'SM_PS_Usable_Length__c','Usable_Width__c'=>'SM_PS_Usable_Width__c','Width__c'=>'SM_PS_Width__c',
        'Ignore_Equipment_Axle__c'=>'SM_PS_Ignore_Equipment_Axle__c', 'Ignore_Equipment_Commodity_Excl__c'=>'SM_PS_Ignore_Equipment_Commodity_Excl__c',
        'Ignore_Equipment_Compartment__c'=>'SM_PS_Ignore_Equipment_Compartment__c',
        'Ignore_Variable_Load_Unload_Time__c'=>'SM_PS_Ignore_Variable_Load_Unload_Time__c',
        'Include_Exclude_Restriction__c'=>'EQCE_Include_Exclude_Restriction__c', 'Unit_Divide_Factor__c'=>'VRLT_Unit_Divide_Factor__c',
        'Variable_Loading_Unit_Type__c'=>'VRLT_Variable_Loading_Unit_Type__c', 'Variable_Time_Category__c'=>'VRLT_Variable_Time_Category__c',
        'Variable_Time_Factor__c'=>'VRLT_Variable_Time_Factor__c','SM_PS_GVWR__c'=>'SM_PS_GVWR__c', 'SM_PS_GCWR__c'=>'SM_PS_GCWR__c',
        'SM_PS_CMV_DOT_YN__c'=>'SM_PS_CMV_DOT_YN__c', 'SM_PS_Truck_class_1_through_8__c'=>'SM_PS_Truck_class_1_through_8__c',
        'SM_PS_num_of_axles__c'=>'SM_PS_num_of_axles__c', 'SM_PS_num_of_tires__c'=>'SM_PS_num_of_tires__c',
        'SM_PS_Towing_Capacity__c'=>'SM_PS_Towing_Capacity__c'
    };
    public static Set<string> prodFieldUniqueConstraintSet = new Set<string> { 'Product_SKU__c' };
    public static Set<string> prodFieldCompleteSupplementSet = new Set<string> { 'Commodity_Code__c' };

    /***********************************************************************************
    * Description: Handles creation of Equipment Type for each complete TMS Product
    ************************************************************************************/
    public static void createEquipmentTypes(List<Product2> newProductList)
    {
        system.debug('In createEquipmentTypes');

        if(newProductList == null) {return;}

        // collect all complete 'TMS Product' Product records
        Map<string,List<Product2>> extIdToCompleteProdMap = new Map<string,List<Product2>>();
        for(Product2 prod : newProductList)
        {

            if(prod.TMS_Product__c && (!prod.SM_PS_TMS_Incomplete__c || prod.SM_PS_TMS_Override__c))
            {
                string prodTMSExtId = prod.SM_PS_TMS_External_ID__c;
                if(!extIdToCompleteProdMap.containsKey(prodTMSExtId))
                { extIdToCompleteProdMap.put(prodTMSExtId, new List<Product2>()); }

                extIdToCompleteProdMap.get(prodTMSExtId).add(prod);
                system.debug('complete tms prod found');
            }
        }

        if(!extIdToCompleteProdMap.isEmpty())
        {
            // collect existing Equipment Type records
            List<Equipment_Type__c> equipTypeList = [SELECT Id, SM_PS_TMS_External_ID__c FROM
                Equipment_Type__c WHERE SM_PS_TMS_External_ID__c IN :extIdToCompleteProdMap.keySet()];

            Map<string,Equipment_Type__c> extIdToEquipTypeMap = new Map<string,Equipment_Type__c>();
            for(Equipment_Type__c equipType : equipTypeList)
            { extIdToEquipTypeMap.put(equipType.SM_PS_TMS_External_ID__c, equipType); }

            // associate Products with new/existing Equipment Type records
            List<Equipment_Type__c> equipTypeToCreateList = new List<Equipment_Type__c>();
            for(string tmsExtId : extIdToCompleteProdMap.keySet())
            {
                List<Product2> prodList =  extIdToCompleteProdMap.get(tmsExtId);

                // relate products to corresponding equipment type
                if(extIdToEquipTypeMap.containsKey(tmsExtId))
                {
                    system.debug('using existing equip type');
                    Equipment_Type__c equipType = extIdToEquipTypeMap.get(tmsExtId);
                    for(Product2 prod : prodList)
                    { 
                        prod.SM_PS_TMS_Equipment_Type__c = equipType.Id;
                        System.debug('prod.External_Code__c:'+prod.External_Code__c);
                        
                    }
                }
                // relate products to newly created equipment type
                else
                {
                    system.debug('creating equip type');
                    Equipment_Type__c equipType = new Equipment_Type__c();
                    populateEquipTypeDataFromProduct(equipType, prodList.get(0));

                    for(Product2 prod : prodList)
                    { 
                        prod.SM_PS_TMS_Equipment_Type__r = equipType; 
                        
                        if(prod.External_Code__c==null || prod.External_Code__c=='')
                    	{
                        	equipType.SM_PS_External_Code__c =  prod.Product_SKU__c;   
                    	}
                        
                        System.debug('prod.Rental_Category__c: '+prod.Rental_Category__c);
                        System.debug('prod.Rental_Class__c: '+prod.Rental_Class__c);
                        
                        //Transform of Rental Category (Product) to Category (Equipment Type)
                        if(prod.Rental_Category__c!=null && prod.Rental_Category__c.contains('.'))
                        {
                            System.debug('contains . category');
                            String[] rentCatlst =prod.Rental_Category__c.split('\\.');
                            if(rentCatlst[0]!=null && rentCatlst[0].length()==3)
                            {
                                System.debug('rentCatlst[0]: '+rentCatlst[0]);
                                equipType.SM_PS_Category__c  = rentCatlst[0];
                            }
                        }
                        
                        //Transform of Rental Class (Product) to Class (Equipment Type)
                        if(prod.Rental_Class__c!=null && prod.Rental_Class__c.contains('.'))
                        {
                            System.debug('contains . class');
                            String[] rentClasslst =prod.Rental_Class__c.split('\\.');
                            
                            if(rentClasslst[0]!=null)
                            {
                                System.debug('rentClasslst[0]: '+rentClasslst[0]);
                                if(rentClasslst[0].length()==3)
                                {
                                    equipType.SM_PS_Class__c = '0'+rentClasslst[0];
                                }
                        
                                else if(rentClasslst[0].length()==2)
                                {
                                    equipType.SM_PS_Class__c = '00'+rentClasslst[0];
                                }
                        
                                else if(rentClasslst[0].length()==1)
                                {
                                    equipType.SM_PS_Class__c = '000'+rentClasslst[0];
                                }
                                else
                                {
                                    equipType.SM_PS_Class__c = rentClasslst[0];
                                }
                            }
                        }
                        
                        //Transform of CatClass (Equipment Type) 
                        
                        if(equipType.SM_PS_Category__c!=null && equipType.SM_PS_Class__c!=null)
                        {
                            equipType.SM_PS_Cat_Class__c = equipType.SM_PS_Category__c + equipType.SM_PS_Class__c;
                        }
                    }
                    
                    equipTypeToCreateList.add(equipType);
                }
            }
            
            // insert Equipment Type records
            if(!equipTypeToCreateList.isEmpty())
            { 
                insert equipTypeToCreateList; 
            }
            
            Set<ID> newequipSet = new Set<ID>();
            for(Equipment_Type__c newEqp : equipTypeToCreateList)
            {
                newequipSet.add(newEqp.id);
            }
            
            if(!newequipSet.isEmpty())
            {
                for(Product2 prod : newProductList)
                {
                    if(!newequipSet.contains(prod.SM_PS_TMS_Equipment_Type__c))
                    {  
                        prod.SM_PS_TMS_Equipment_Type__c = prod.SM_PS_TMS_Equipment_Type__r?.Id;
                    }
                }
            }
        }
    }

    /***************************************************************************************
    * Description: Handles population of Equipment Type data based upon provided Product
    ****************************************************************************************/
    private static void populateEquipTypeDataFromProduct(Equipment_Type__c equipType, Product2 newProd)
    {
        if(equipType != null && newProd != null)
        {
            // copy data from Product fields into corresponding Equipment Type fields
            for(String prodFieldName : productEquipTypeFieldMap.keySet())
            {
                // ensure that only appropriate fields are modified in Update scenario
                String equipTypeFieldName = productEquipTypeFieldMap.get(prodFieldName);
                populateEquipTypeDataFromProduct(equipType, newProd,
                    prodFieldName, equipTypeFieldName);
                    
                if(prodFieldName == 'Product_Sub_Category__c'){
                      populateEquipTypeDataFromProduct(equipType, newProd, prodFieldName, 'Name');
                }
            }
        }
    }

    /***************************************************************************************************
    * Description: Handles population of specific Equipment Type field value based upon provided Product
    ***************************************************************************************************/
    private static void populateEquipTypeDataFromProduct(Equipment_Type__c equipType,
        Product2 newProd, string prodFieldName, string equipTypeFieldName)
    {
        // copy data from Product field into corresponding Equipment Type field
        Object newProdFieldValue = newProd.get(prodFieldName);
        equipType.put(equipTypeFieldName, newProdFieldValue);
    }
}