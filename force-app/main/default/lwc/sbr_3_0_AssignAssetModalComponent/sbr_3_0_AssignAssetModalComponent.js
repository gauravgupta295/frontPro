/* FRONT-2186, FRONT-6226, FRONT-6227, FRONT-6228 */
import { LightningElement, track, api } from "lwc";
import FORM_FACTOR from "@salesforce/client/formFactor";
import DESKTOPTEMPLATE from "./sbr_3_0_AssignAssetModalComponentDesktop.html";
import MOBILETEMPLATE from "./sbr_3_0_AssignAssetModalComponentMobile.html";
import sbr_3_0_customDataTableCSS from "@salesforce/resourceUrl/sbr_3_0_customDataTable_css";
import { loadStyle } from "lightning/platformResourceLoader";

export default class Sbr_3_0_AssignAssetModalComponent extends LightningElement {
  @track isModalOpen = false;
  @track isMobile = false;
  @api productId;
  @api parentId;
  @api orderItemId;
  @api locationInfo;
  selectedAssetId;
  showAssetDetails = false;
  _tabs = [
    {
      title: "Default Locations",
      Content: "DefaultLocation",
      Id: "1",
      contentClass: "slds-tabs_default__content slds-show",
      itemClass: "slds-tabs_default__item slds-is-active",
      isDefaultLocationSelected: true
    },
    {
      title: "Other Locations",
      Content: "OtherLocation",
      Id: "2",
      contentClass: "slds-tabs_default__content slds-hide",
      itemClass: "slds-tabs_default__item",
      isOtherLocationSelected: false
    },
    {
      title: "Sourcing",
      Content: "Sourcing",
      Id: "3",
      contentClass: "slds-tabs_default__content slds-hide",
      itemClass: "slds-tabs_default__item",
      isSourcingSelected: false
    }
  ];

  get Tabs() {
    return this._tabs;
  }

  openModal() {
    this.isModalOpen = true;
  }

  closeModal() {
    const selectEvent = new CustomEvent("close");
    this.dispatchEvent(selectEvent);
  }
  submitDetails() {
    this.isModalOpen = false;
  }

  handleClick(event) {
    this._tabs = this._tabs.map((tab) => {
      let value = `is${tab.Content}Selected`;
      if (tab.Id === event.target.dataset.link) {
        tab.contentClass = "slds-tabs_default__content slds-show";
        tab.itemClass = "slds-tabs_default__item slds-is-active";
        tab[value] = true;
      } else {
        tab.contentClass = "slds-tabs_default__content slds-hide";
        tab.itemClass = "slds-tabs_default__item";
        tab[value] = false;
      }
      return tab;
    });
  }

  render() {
    this.isMobile = FORM_FACTOR === "Small";
    let renderTemplate;
    if (this.isMobile) {
      renderTemplate = MOBILETEMPLATE;
    } else {
      loadStyle(this, sbr_3_0_customDataTableCSS);
      renderTemplate = DESKTOPTEMPLATE;
    }
    return renderTemplate;
  }

  handleViewAsset(event) {
    console.log('>>> '+JSON.stringify(event.detail));
    let assetId = event.detail.assetId;
    
    this.selectedAssetId = assetId;
    this.showAssetDetails = true;
  }

  hideViewAssetScreen() {
    this.selectedAssetId = null;
    this.showAssetDetails = false;
  }

  get computedModalClass(){
    return (this.showAssetDetails) ? 'slds-modal' : 'slds-modal slds-fade-in-open';
  }
}