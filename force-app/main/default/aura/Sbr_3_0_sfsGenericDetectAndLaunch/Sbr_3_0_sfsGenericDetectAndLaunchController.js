({
    doInit : function(component, event, helper) {
        // By Default set the Id field as this is required
        let tempFieldList = ['Id'];
        let fieldChanges=[];
        let valueCompare=[];
        // Check to see if the user wants to watch any other fields
        if (component.get("v.fieldChange")) {
            fieldChanges=component.get("v.fieldChange")
            if(fieldChanges)
            {
                fieldChanges= fieldChanges.split(',');
                tempFieldList=[...fieldChanges, ...tempFieldList];
            }
            
            
        }
        let changeType=component.get("v.compareType");
        valueCompare=component.get("v.fieldValue");
        if(valueCompare)
        {
            valueCompare= valueCompare.split(',');
        }
        else{
            return;
        }
        if(changeType=='Dynamic')
        {   
            
            
            tempFieldList=[...tempFieldList, ...valueCompare];
        }
        
        // Set the updated list which recordData uses
        component.set("v.fieldNameList", tempFieldList);
        let operator=component.get("v.compareOperator");
        if(operator)
        {
            operator= operator.split(',');
        }
        let message=component.get("v.toastMessage").split(',');
        // console.log('compare operator is ',operator)
        // console.log('message  is ',JSON.stringify(message));
        //create a map of 1:1 to compare changes
        let tempMap={};
        let operatorMap={};
        let messageMap={};
        if(!valueCompare || !operator )
        {
            return;
        }
        fieldChanges.forEach((value,index)=>{
            tempMap[value]=valueCompare[index];
            operatorMap[value]=operator[index];
            messageMap[value]=message[index];
        })
            console.log(fieldChanges)
            // The field we compare will always be in the #2 spot. We can grab that value and store for later use
            component.set("v.fieldCompare", component.get("v.fieldChange").split(','));
            
            component.set("v.dataMap",tempMap);
            component.set("v.operatorMap",operatorMap);
            component.set("v.messageMap",messageMap);
            // console.log('message  map ',JSON.stringify(messageMap));
            // console.log(operatorMap)
            
        },
            recordUpdated: function(component,event,helper){
                let type = event.getParams().changeType;
                console.log(' this is second type ',type);
                var params = event.getParams();
                let finalParams=JSON.parse(JSON.stringify(params));
                //console.log('record has been updated in aura ');
                let changeType=component.get("v.compareType")
                //console.log(JSON.stringify(component.get("v.ObjectRecord")));
                let operator=component.get("v.operatorMap");
                let message=component.get("v.messageMap");
                
                let allObject=component.get("v.ObjectRecord");
                if(finalParams.changeType === "CHANGED" && finalParams.changedFields) {
                    let changedFields = finalParams.changedFields;
                    let dataMap=component.get('v.dataMap');
                    if(params.changeType === "CHANGED") {
                        //  var changedFields = params.changedFields;
                        let dataMap=component.get('v.dataMap');
                        console.log(JSON.stringify(changedFields));
                        let recordChanges=JSON.parse(JSON.stringify(changedFields));
                        console.log(recordChanges);
                        let toastmsg='';
                        let showToast=false;
                        for(let field in changedFields) {
                            console.log(field);
                            console.log('message[field];', message[field])
                            console.log(operator[field]);
                            console.log(changedFields[field]);
                            if( component.get("v.fieldCompare").includes(field) && changedFields[field] && changedFields[field].hasOwnProperty('oldValue')  &&changedFields[field].value!=changedFields[field].oldValue){
                                let value2=changeType=='Static'?dataMap[field]:allObject[dataMap[field]];
                                if(helper.getOperatorValue(component,event,changedFields[field].value,value2,operator[field])){
                                    showToast=true;
                                    if(toastmsg)
                                    {
                                        toastmsg+=' \n ';
                                    }
                                    toastmsg+=message[field];
                                }
                                
                                console.log(changedFields[field].value<allObject[dataMap[field]]);
                            }
                        }
                        
                        if(showToast) {
                            helper.showToast(component,event,helper,toastmsg);
                        }
                        
                    } 
                }
                
            }
            
        })