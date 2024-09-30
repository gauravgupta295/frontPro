import { LightningElement, wire, api } from "lwc";
import { CurrentPageReference } from "lightning/navigation";
import { normalizeBoolean } from "c/sbr_3_0_frontlineUtils";
export default class Sbr_3_0_SignTCCmpWrapper extends LightningElement {
  @api
  recordId;
  @api
  objectApiName;
  _currentPageReference;
  showTC = false;
  rendered = false;
  @wire(CurrentPageReference)
  getPageReferenceParameters(currentPageReference) {
    if (currentPageReference) {
      this._currentPageReference = currentPageReference;
      this.getAttributesFromPg();
    }
  }

  getAttributesFromPg() {
    this.setShowTC(this._currentPageReference?.state?.c__showTC);
  }

  setShowTC(show = false) {
    let normalizedShow = normalizeBoolean(show);
    this.showTC = normalizedShow;
  }

  renderedCallback() {
    this.setLoadComponentOnce();
  }

  setLoadComponentOnce() {
    if (!this.rendered) {
      this.rendered = true;
    }
  }

  get showTCDialog() {
    return this.recordId && this.objectApiName && this.showTC && this.rendered;
  }

  handleCloseTC() {
    this.showTC = false;
  }
}