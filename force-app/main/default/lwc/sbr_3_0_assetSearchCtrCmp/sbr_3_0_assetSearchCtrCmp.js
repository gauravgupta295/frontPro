import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Sbr_3_0_assetSearchCtrCmp extends LightningElement {
    
    isMobile = false;
    selectedAssets = [];

    @api tabsPanelHeight;

    connectedCallback(){
        this.isMobile = window.matchMedia('(max-width: 480px)').matches;
    }

    handleAssetSelectedNew(event){
        console.log('handleassetselectednew search ctr');
        let itemCount = event.detail;
        this.template.querySelector('c-sbr_3_0_asset-panel-cmp').assetSelectionPanelHandler(itemCount);
    }

    handlelocrecord(event){
        console.log('handlelocrecord search ctr');
        let locrecord = event.detail;
        this.template.querySelector('c-sbr_3_0_asset-panel-cmp').locationSelectionPanelHandler(locrecord);
    }
    
    @api handleSelectedRows(event){
        
    }
}