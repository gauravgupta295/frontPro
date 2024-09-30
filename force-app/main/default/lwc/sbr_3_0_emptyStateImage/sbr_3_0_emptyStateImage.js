import { LightningElement , api } from 'lwc';

export default class Sbr_3_0_emptyStateImage extends LightningElement {
    @api message = 'Select a row to see relevant item information here.';
    
    isMobile = false;

    connectedCallback(){
        this.isMobile = window.matchMedia('(max-width: 480px)').matches;
    }
}