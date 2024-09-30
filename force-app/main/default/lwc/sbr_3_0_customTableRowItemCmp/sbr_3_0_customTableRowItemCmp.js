import { LightningElement, api } from 'lwc';

export default class Sbr_3_0_customTableRowItemCmp extends LightningElement {
    @api rowData;
    @api rowKey;
    
    get rowItem(){
        let item = this.rowData[this.rowKey];
        item =  this.rowKey != 'label' && item != 'N/A'? '$'+item : item;
        return item;
    }
}