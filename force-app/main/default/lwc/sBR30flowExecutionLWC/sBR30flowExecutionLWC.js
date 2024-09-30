import { LightningElement, wire } from "lwc";
import { CurrentPageReference } from "lightning/navigation";
const FLOW_NAME = "c__flowName";
export default class FlowExecution extends LightningElement {
  flowName;
  inputVariables = [];
  _currentPageReference
  @wire(CurrentPageReference)
  getPageReference(currentPageReference) {
    // if (currentPageReference) {
    //   this._currentPageReference = currentPageReference;
    //   this.getPageReferenceParameters();
    // }
    if (currentPageReference) {
      this.init(currentPageReference);
    }
  }

  init(currentPageReference) {
    this.flushCurrentPageReference().then(() => {
      this.setPageReference(currentPageReference);
    });
  }

  setPageReference(pageReference) {
    this._currentPageReference = pageReference;
    this.getPageReferenceParameters();
  }

  getPageReferenceParameters() {
    const state = this._currentPageReference?.state;
    if (state) {
      const clonedState = Object.assign({}, state);
      if (clonedState[FLOW_NAME]) {
        delete clonedState[FLOW_NAME];

        for (let param of Object.keys(clonedState)) {
          if (param.startsWith("c__")) {
            let name = param.replace("c__", "").trim();
            let value = clonedState[param];
            this.inputVariables.push({
              name,
              value,
              type: "String"
            });
          }
        }
        this.flowName = state[FLOW_NAME];
        this.dispatchEvent(
          new CustomEvent("setflowname", {
            detail: {
              flowName: this.flowName
            }
          })
        );
        console.log("## ", this.inputVariables);
      }
    }else {
      this.flowName = undefined;
    }
  }

  flushCurrentPageReference() {
    return new Promise((resolve, reject) => {
      try {
        this.setPageReference(undefined);
        resolve();
      } catch (e) {
        reject("Unable to clear the existing page reference");
      }
    });
  }
}