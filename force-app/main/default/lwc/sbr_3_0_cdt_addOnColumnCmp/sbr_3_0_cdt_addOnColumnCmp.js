import { LightningElement, api } from 'lwc';

export default class Sbr_3_0_cdt_addOnColumnCmp extends LightningElement {
    @api addOns;
    salesAddOns = [];
    rentalAddOns = [];



    connectedCallback(){
        console.log("=========== addOnColumn -> connected callback, addons: ");
        console.log(this.addOns);
    }

    renderedCallback(){

    }

    get isAddOn() {
        return this.addOns.length > 0  ? true : false;
    }

    toggleKitModal() {
        this.template.querySelector("c-sbr_3_0_modal-cmp").toggleModal();
    }

    /*get isSales() {
        for (let i = 0; i < this.addOns.length; i++) {
            if (this.addOns[i].SBQQ__Feature__r.Name === 'Sales Addons') {
                salesAddOns.push(this.addOns[i]);
            }
        }
    }*/

    /*get isRental() {
        for (let i = 0; i < this.addOns.length; i++) {
            if (this.addOns[i].SBQQ__Feature__r.Name === 'Sales Addons') {
                salesAddOns.push(this.addOns[i]);
            }
        }
    }*/
}