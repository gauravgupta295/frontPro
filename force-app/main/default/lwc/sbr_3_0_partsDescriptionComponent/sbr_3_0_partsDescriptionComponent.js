import { LightningElement, wire, api } from 'lwc';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';

export default class Sbr_3_0_partsDescriptionComponent extends LightningElement {

    @api woId;
    @api selectedSKU;
    productsConsumedList;

    get partsDesc(){
        if(this.productsConsumedList){
            return this.productsConsumedList.map(pc => {
                if(pc.fields.SF_PS_Product_SKU__c.value == this.selectedSKU){
                    return pc.fields.SF_PS_Description__c.value;
                }
            }).filter(pc => pc)[0];
        }
        return '';
    };

    @wire(getRelatedListRecords, {
        parentRecordId : '$woId',
        relatedListId  : 'ProductsConsumed',
        fields         : ['ProductConsumed.SF_PS_Product_SKU__c','ProductConsumed.SF_PS_Description__c']
    })
    productsConsumed({ error, data }){
        if(data){
            this.productsConsumedList = data.records;
        } else if(error){
            console.log('@@@@ error ==>', error);
        }
    }
}