({
    doInit: function(cmp, event, helper) {
        let record = cmp.get("v.record");
        let apiFieldNameToShow = cmp.get("v.apiFieldNameToShow");

        // set a value to show. by default it's Record.Name, but it could be customized
        cmp.set("v.valueToShow", record[apiFieldNameToShow]);
    },

    selectRecord : function(cmp, event, helper) {
        let record = cmp.get("v.record");
        let apiFieldNameToShow = cmp.get("v.apiFieldNameToShow");

        // set a value to show. by default it's Record.Name, but it could be customized
        let selectRecordEvent = cmp.getEvent("selectRecordEvent");
        selectRecordEvent.setParams({"record" : record });
        selectRecordEvent.fire();
    },
})