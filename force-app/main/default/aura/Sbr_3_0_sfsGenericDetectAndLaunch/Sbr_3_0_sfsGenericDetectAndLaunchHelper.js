({
    getOperatorValue : function(cmp,event,value1,value2,operator) {
        // console.log('operator is ',operator)
       
        switch(operator) {
            case 'lt':
              // less than <
              return value1<value2;
              break;
            case 'gt':
              // greater than >
              return value1>value2;
              break;
            case 'gte':
              // greater than equal to >=
              return value1>=value2;
              break;
            case 'lte':
              // less than equal to <= <
              return value1<=value2;
              break;
            case 'eq':
              // equal to ==
              return value1==value2;
              break;
            default:
              return false;
          }

    },
    showToast : function(component,event,helper,message) {
        let type = component.get("v.toastType").toLowerCase(); //force user entered attribute to all lowercase
        let title = component.get("v.toastTitle");
       // let message = component.get("v.toastMessage");
        let duration = component.get("v.duration")+"000"; //convert duration value from seconds to milliseconds
        let mode = component.get("v.mode").toLowerCase(); //force user entered attribute to all lowercase
        let key = component.get("v.key");
        // key=key?.toLowerCase();   //force user entered attribute to all lowercase
        let isURL = message.toLowerCase().includes('{url}');  //Did the user include '{url}' in their message?
        if(!isURL){
            helper.fireToast(type, title, message, duration, mode, key);
        }
        if(isURL){
            let messageUrl = message.replace('{url}', '{1}');
            let urlLink = component.get("v.urlLink")
            let urlLabel = component.get("v.urlLabel");
            //Add 'http://' to the URL if it is not already included
            if(urlLink.toLowerCase().indexOf('http') == -1){
                urlLink = 'http://' + urlLink;  
            }
            helper.fireToastUrl(type, title, messageUrl, urlLink, urlLabel, duration, mode, key);
          }

    }
    ,
    //Standard Show Toast Event
    fireToast : function(type, title, message, duration, mode, key) {
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type,
            "duration": duration,
            "mode": mode,
            "key": key
        });
        toastEvent.fire();
    },
     //Show Toast Event updated to include a message that contains a link
     fireToastUrl : function(type, title, messageUrl, urlLink, urlLabel, duration, mode, key) {
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": messageUrl,
            "messageTemplate": messageUrl,
            "messageTemplateData": ['Salesforce', {
                url: urlLink,
                label: urlLabel,
            }],
            "type": type,
            "duration": duration,
            "mode": mode,
            "key": key
        });
        toastEvent.fire();
    }
})