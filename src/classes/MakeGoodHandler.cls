public class MakeGoodHandler implements ITrigger {
    public MakeGoodHandler() {}

    public void bulkBefore() {}

    public void bulkAfter() {}

    public void beforeInsert(List<SObject> so) {
        List<MakeGood__c> makeGoods = (List<MakeGood__c>)so;
        setNames(makeGoods);
    }

    public void beforeUpdate(Map<Id, SObject> oldSo, Map<Id, SObject> so) {
        Map<Id, MakeGood__c> newMap = (Map<Id, MakeGood__c>)so;
        setNames(newMap.values());
    }

    public void beforeDelete(List<SObject> so) {}

    public void afterInsert(List<SObject> so) {}

    public void afterUpdate(Map<Id, SObject> oldSo, Map<Id, SObject> so) {}

    public void afterDelete(List<SObject> so) {}

    public void andFinally() {}

    private void setNames(List<MakeGood__c> makeGoods) {
        for (MakeGood__c makeGood : makeGoods) {
            makeGood.Name = makeGood.NameFormula__c;
        }
    }
}