import { LightningElement, api } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
export default class SBR_3_ChangeProfileBranch extends LightningElement {

    @api newProfileBranch = '';
    selecteProfileBranchHandler(event) {
        this.newProfileBranch =  event.detail.selectedRecord.Id;
        this.dispatchEvent(new FlowAttributeChangeEvent('newProfileBranch', this.newProfileBranch));
    }

    //onlookupupdate
}