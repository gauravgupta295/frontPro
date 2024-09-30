import { LightningElement, api, wire } from "lwc";
import { getRecord } from "lightning/uiRecordApi";
import {
  flattenWiredRecord,
  deepFlattenToObject
} from "c/sbr_3_0_frontlineUtils";
import { NavigationMixin } from "lightning/navigation";

export default class Sbr_3_0_recordQuickView extends NavigationMixin(
  LightningElement
) {
  @api variant;
  @api recordId;
  @api objectApiName;
  @api config;
  @api iconName;
  @api fields;
  @api titleField = "Name";
  showTooltip = false;
  record;
  btnPosition = {
    top: 0,
    right: 0
  };

  quickViewHeight = 16;

  get title() {
    return this.record ? this.record[this.titleField] : "";
  }

  @wire(getRecord, { recordId: "$recordId", fields: "$fields" })
  fetchRecord({ error, data }) {
    if (data) {
      this.record = deepFlattenToObject(flattenWiredRecord(data));
    } else if (error) {
      console.log("Error is" + JSON.stringify(error));
    }
  }

  openTooltip() {
    this.interacting = true;
    const quickViewLink = this.template.querySelector(".quick-view-link");
    if (quickViewLink) {
      this.btnPosition = quickViewLink.getBoundingClientRect();
    }
    window.setTimeout(() => {
      this.showTooltip = true;
    }, 500);
  }

  closeTooltip() {
    this.interacting = false;
    window.setTimeout(() => {
      if (!this.interacting) {
        this.showTooltip = false;
        this.resizeObserver.disconnect();
        this.hasObserver = false;
        this.template.ownerDocument.body.style.overflow = "visible";
      }
    }, 500);
  }

  navigateToDetailPage() {
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: this.recordId,
        actionName: "view"
      }
    });
  }

  renderedCallback() {
    const quickView = this.template.querySelector(".record-quick-view");
    if (quickView && this.showTooltip) {
      this.template.ownerDocument.body.style.overflow = "hidden";

      if (!this.hasObserver) {
        this.resizeObserver = new ResizeObserver((entries) => {
          for (const entry of entries) {
            if (entry.borderBoxSize) {
              this.quickViewHeight = entry.borderBoxSize[0].blockSize;
              console.log(entry, entry.borderBoxSize[0].blockSize);
            }
          }

          console.log("Size changed");
        });
        this.resizeObserver.observe(quickView);
        this.hasObserver = true;
      }
    }
  }

  get hoverScreenStyles() {
    return `width: 380px; position:fixed; top : ${this.btnPosition.top - (this.quickViewHeight - 8) / 2}px; left : ${this.btnPosition.right + 16}px`;
  }
  
}