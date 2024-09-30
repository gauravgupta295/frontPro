/*****************************************************************************************************
* Apex Class: SBR_3_0_ProductTriggerHandler
------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Handles creation of a corresponding Equipment Type record upon creation of a Product record
------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                DETAIL FEATURES
    1.0         Alex DeVries                        2022-10-14          Initial version (SAL-6277)
    2.0         Alex DeVries                        2022-10-18          Added afterUpdate (SAL-6274)
    3.0         Alex DeVries                        2022-11-18          Changed afterInsert,afterUpdate to
                                                                        beforeInsert,beforeUpdate, respectively (SAL-9333)
*****************************************************************************************************/
public with sharing class SBR_3_0_ProductTriggerHandler extends SBR_3_0_TriggerHandler
{
    @TestVisible
    private List<Product2> oldProductList;
    @TestVisible
    private List<Product2> newProductList;

    public SBR_3_0_ProductTriggerHandler()
    {
        this.oldProductList = (List<Product2>)Trigger.old;
        this.newProductList = (List<Product2>)Trigger.new;
    }

    public override void beforeInsert()
    { 
        SBR_3_0_ProductOperations.createEquipmentTypes(this.newProductList);
    }

    public override void beforeUpdate()
    {
        SBR_3_0_ProductOperations.createEquipmentTypes(this.newProductList);
    }
}