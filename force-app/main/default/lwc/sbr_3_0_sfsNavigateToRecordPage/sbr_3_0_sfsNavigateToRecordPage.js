import { LightningElement,api } from 'lwc';

export default class Sbr_3_0_sfsNavigateToRecordPage extends LightningElement {

  @api recordId;
  @api target = '_blank';

  connectedCallback() {
    const completeURL = `${window.location.origin}/${this.recordId}`;
    window.open(completeURL, this.target);
  }

}