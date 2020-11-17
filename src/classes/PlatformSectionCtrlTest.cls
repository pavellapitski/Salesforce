@IsTest public class PlatformSectionCtrlTest {

    private static final List<String> availableCostStructureNames = new List<String>{
        'costStructure1','costStructure2','costStructure3'
    };

    @IsTest public static void getStringItemsTest() {
        Platform__c platformFB = TestHelper.createPlatform('Facebook', 'FB');

        Test.startTest();
        PlatformSectionCtrl ctrl = new PlatformSectionCtrl();
        ctrl.platformInfo = new PlatformWrapper(platformFB);
        ctrl.selectedItems = new List<String>{availableCostStructureNames[0]};
        ctrl.platformInfo.availableCostStructures = new List<PlatformWrapper.CostStructureWrapper>{new PlatformWrapper.CostStructureWrapper(availableCostStructureNames[0],false)};
        Test.stopTest();

        System.assertEquals(availableCostStructureNames[0], ctrl.getStringItems().get(0));
        System.assertEquals(availableCostStructureNames[0], ctrl.getItems().get(0).getLabel());
        System.assertEquals(1, ctrl.getStringItems().size());
    }

    @IsTest public static void updateCostStructure() {
        Platform__c platformFB = TestHelper.createPlatform('Facebook', 'FB');

        Test.startTest();
        PlatformSectionCtrl ctrl = new PlatformSectionCtrl();
        ctrl.platformInfo = new PlatformWrapper(platformFB);
        ctrl.selectedItems = new List<String>();

        for (String ccName :ctrl.platformInfo.selectedMetrics.keySet()) {
            System.assertEquals(ctrl.platformInfo.selectedMetrics.get(ccName), '', 'No metrics should be selected.');
        }

        Map<String, List<SelectOption>> costStructureToMetrics = ctrl.costStructureToMetrics;
        Integer metricsToAdd = 3;
        Integer metricsAdded = 0;
        for (String ccName :costStructureToMetrics.keySet()) {
            if (!costStructureToMetrics.get(ccName).isEmpty() && metricsAdded < metricsToAdd) {
                ctrl.selectedItems.add(ccName);
                ctrl.platformInfo.selectedMetrics.put(ccName, costStructureToMetrics.get(ccName)[0].getLabel());
                metricsAdded++;
            }
        }
        System.debug('### 1 ' + ctrl.selectedItems);
        System.assertEquals(ctrl.selectedItems.size(), metricsToAdd);

        // select metrics for Cost Structure
        ctrl.costStructureUpdated();
        System.debug('### 2 ' + ctrl.platformInfo.selectedMetrics);

        for (String ccName :ctrl.platformInfo.selectedMetrics.keySet()) {
            System.debug('### ' + ctrl.platformInfo.selectedMetrics.get(ccName));
            if (String.isNotBlank(ctrl.platformInfo.selectedMetrics.get(ccName))) {
                metricsAdded--;
            }
        }

        System.assertEquals(metricsAdded, 0, metricsToAdd + ' metric(s) should be selected.');
        Test.stopTest();
    }

}