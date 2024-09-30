import { LightningElement, api,track } from 'lwc';
import getProductKitComponents from '@salesforce/apex/SBR_3_0_SpotlightPanelCmpController.getProductKitComponents';


export default class Sbr_3_0_cdt_kitColumnCmp extends LightningElement {
    @api kits;
    @api packageName;
    @track kitItems;


    connectedCallback(){
        console.log("=========== kitColumn -> connected callback, kits: new" );
        console.log(JSON.stringify(this.kits));
    }

    renderedCallback(){

    }
    // added for SAL-13913,
    async getKitComponents(parentProductId) {
        let data;
        try {
            data = await getProductKitComponents({ productId: parentProductId });
            this.kitItems= JSON.parse(data);
        } catch (error) {
            console.log('error in getKitComponents:');
            console.log(error);
        };
    }
    get isKit() {
        console.log('###'+JSON.stringify(this.kits));
        return this.kits.isKit =='Yes' ? true : false;
    }

    async toggleKitModal() {
        // added for SAL-13913,
        if(this.kits.isKit.value =='Yes' && this.kits.kitItemsValue.length > 0)
        {
            this.kitItems = this.kits.kitItemsValue;
        }
        else{
            await this.getKitComponents(this.kits.productId);
        }
      
        this.template.querySelector("c-sbr_3_0_modal-cmp").toggleModal();
    }
}