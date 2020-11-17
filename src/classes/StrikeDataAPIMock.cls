/**
 * Created by Pavel Lapitski on 2019-10-16.
 */

public class StrikeDataAPIMock implements HttpCalloutMock {

    // Default values
    @TestVisible private static final Long DAY_DIFFERENCE_MILLISECONDS = 86400000L;
    @TestVisible private static final Long EARLIEST_SPEND_DATE = 1564790400000L;
    @TestVisible private static final String FACEBOOK_ACCOUNT_ID = '1789741037925615';
    @TestVisible private static final String DV360_ACCOUNT_ID = '1910138';
    @TestVisible private static final String emptyMetrics = '{"metrics":[]}';
    @TestVisible private static Boolean setRandomMetrics = false;
    @TestVisible private static Boolean setEmptyMetrics = false;

    // for single project name call
    @TestVisible private static String accountId = '926-395-6913';
    @TestVisible private static String currencyIsoCode = 'USD';
    @TestVisible private static Integer amountRecordsInResponseForSingleCall = 8; // see getResponseForSingleProjectName() method
    @TestVisible private static String customMetrics = emptyMetrics;

    // for scheduled job call by platform name
    @TestVisible private static List<String> projectNames = new List<String>{'AS012253A', 'AS012254A', 'AV010912A', 'TV012398A'};
    @TestVisible private static List<String> accountIDs = new List<String>{'916-160-5639', '162-104-5660', '575-638-8754', '945-265-9174'};
    @TestVisible private static Integer amountRecordsInResponseForJobCallPerPlatformName = 9;

    @TestVisible private String projectName { get; set; }
    @TestVisible private StrikeDataAPI.PackageType packageType { get; set; }

    public StrikeDataAPIMock(String projectName, StrikeDataAPI.PackageType packageType) {
        this.projectName = projectName;
        this.packageType = packageType;
        setData(packageType);
    }

    public StrikeDataAPIMock(StrikeDataAPI.PackageType packageType) {
        this.packageType = packageType;
        setData(packageType);
    }

    private static void setData(StrikeDataAPI.PackageType packageType) {
        if (StrikeDataAPI.PackageType.FACEBOOK == packageType) {
            accountId = FACEBOOK_ACCOUNT_ID;
        } else if (StrikeDataAPI.PackageType.DV360 == packageType) {
            accountId = DV360_ACCOUNT_ID;
        }
        // AdWords package counts as a default for MOCK class
    }

    public HttpResponse respond(HttpRequest req) {
        // fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');

        System.assertEquals('GET', req.getMethod(), 'Only POST request method is allowed');
        if (String.isNotBlank(projectName)) {
            // check the URL for single Project Name
            System.assert(req.getEndpoint().contains(StrikeDataAPI.getAPIUrl(packageType, null)));
            if (setRandomMetrics) {
                res.setBody(getResponseForSingleProjectName(projectName));
            } else {
                res.setBody(customMetrics);
            }
        } else {
            // check the URL for a job by platform name
            System.assertEquals(projectNames.size(), accountIDs.size(), 'The size of \'projectNames\' and  \'accountIDs\' should be equal to generate correct response in StrikeDataAPIMock.cls');
            System.assertEquals(StrikeDataAPI.getAPIUrl(packageType, null), req.getEndpoint());
            if (setRandomMetrics) {
                res.setBody(getResponseForNLastDaysRandom());
            } else {
                res.setBody(getResponseForNLastDays());
            }

        }
        res.setStatus('OK');
        res.setStatusCode(200);
        return res;
    }

    private String getResponseForNLastDaysRandom() {
        String metrics = emptyMetrics;
        if (!setEmptyMetrics) {
            List<String> metricsList = new List<String>();
            for (Integer projectNameIdx = 0; projectNameIdx < projectNames.size(); projectNameIdx ++) {
                String projectName = projectNames[projectNameIdx];
                String accountId = accountIDs[projectNameIdx];
                for (Integer i = 0; i < amountRecordsInResponseForJobCallPerPlatformName; i++) {
                    Long dateTimeNow = Datetime.now().getTime() + DAY_DIFFERENCE_MILLISECONDS * i;
                    Decimal randomSpendAmount = ((Decimal)(1000*Math.random()+1)).setScale(2);
                    Decimal randomClicksAmount = ((Decimal)(1000*Math.random()+1)).setScale(0);
                    Decimal randomViewsAmount = ((Decimal)(1000*Math.random()+1)).setScale(0);
                    Decimal randomImpressionsAmount = ((Decimal)(10000*Math.random()+1)).setScale(0);
                    Decimal randomDeliveredAmount = ((Decimal)(100000*Math.random()+1)).setScale(0);
                    metricsList.add(
                        '{\"project_id\":\"' + projectName + '\",' +
                            '\"date\":' + dateTimeNow + ',' +
                            '\"account_id\":\"' + accountId + '\",' +
                            '\"currency\":\"AUD\",' +
                            '\"cost_structure\":\"CPC\",' +
                            '\"spend\": ' + randomSpendAmount + ',' +
                            '\"clicks\": ' + randomClicksAmount + ',' +
                            '\"views\": ' + randomViewsAmount + ',' +
                            '\"impressions\": ' + randomImpressionsAmount + ',' +
                            '\"engagements\":0.0,' +
                            '\"delivered\": ' + randomDeliveredAmount +
                        '}'
                    );
                }
            }
            metrics = '{"metrics":[' + String.join(metricsList, ',') + ']}';
        }
        return metrics;
    }

    @TestVisible private static String getResponseForNLastDays() {
        return (setEmptyMetrics) ? emptyMetrics : '{"metrics":[' +
            '{\"project_id\":\"' + projectNames[0] + '\",\"date\":1568332800000,\"account_id\":\"' + accountIDs[0] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPC\",\"spend\":0.48,\"clicks\":1,\"views\":0,\"impressions\":447,\"engagements\":0.0,\"delivered\":1},' +
            '{\"project_id\":\"' + projectNames[0] + '\",\"date\":1568419200000,\"account_id\":\"' + accountIDs[0] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPC\",\"spend\":27.88,\"clicks\":32,\"views\":0,\"impressions\":4843,\"engagements\":0.0,\"delivered\":32},' +
            '{\"project_id\":\"' + projectNames[0] + '\",\"date\":1568505600000,\"account_id\":\"' + accountIDs[0] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPC\",\"spend\":23.16,\"clicks\":106,\"views\":0,\"impressions\":2215,\"engagements\":0.0,\"delivered\":106},' +
            '{\"project_id\":\"' + projectNames[0] + '\",\"date\":1568592000000,\"account_id\":\"' + accountIDs[0] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPC\",\"spend\":19.48,\"clicks\":285,\"views\":0,\"impressions\":3468,\"engagements\":0.0,\"delivered\":285},' +
            '{\"project_id\":\"' + projectNames[0] + '\",\"date\":1568678400000,\"account_id\":\"' + accountIDs[0] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPC\",\"spend\":40.26,\"clicks\":407,\"views\":0,\"impressions\":928,\"engagements\":0.0,\"delivered\":407},' +
            '{\"project_id\":\"' + projectNames[0] + '\",\"date\":1568764800000,\"account_id\":\"' + accountIDs[0] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPC\",\"spend\":41.35,\"clicks\":269,\"views\":0,\"impressions\":569,\"engagements\":0.0,\"delivered\":269},' +
            '{\"project_id\":\"' + projectNames[0] + '\",\"date\":1568851200000,\"account_id\":\"' + accountIDs[0] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPC\",\"spend\":37.52,\"clicks\":432,\"views\":0,\"impressions\":890,\"engagements\":0.0,\"delivered\":432},' +
            '{\"project_id\":\"' + projectNames[0] + '\",\"date\":1568937600000,\"account_id\":\"' + accountIDs[0] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPC\",\"spend\":37.12,\"clicks\":547,\"views\":0,\"impressions\":1208,\"engagements\":0.0,\"delivered\":547},' +
            '{\"project_id\":\"' + projectNames[0] + '\",\"date\":1569024000000,\"account_id\":\"' + accountIDs[0] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPC\",\"spend\":46.79,\"clicks\":484,\"views\":0,\"impressions\":1069,\"engagements\":0.0,\"delivered\":484},' +
            '{\"project_id\":\"' + projectNames[0] + '\",\"date\":1569110400000,\"account_id\":\"' + accountIDs[0] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPC\",\"spend\":39.37,\"clicks\":567,\"views\":0,\"impressions\":1235,\"engagements\":0.0,\"delivered\":567},' +
            '{\"project_id\":\"' + projectNames[0] + '\",\"date\":1569196800000,\"account_id\":\"' + accountIDs[0] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPC\",\"spend\":29.76,\"clicks\":446,\"views\":0,\"impressions\":1010,\"engagements\":0.0,\"delivered\":446},' +
            '{\"project_id\":\"' + projectNames[0] + '\",\"date\":1569283200000,\"account_id\":\"' + accountIDs[0] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPC\",\"spend\":27.01,\"clicks\":389,\"views\":0,\"impressions\":1034,\"engagements\":0.0,\"delivered\":389},' +
            '{\"project_id\":\"' + projectNames[0] + '\",\"date\":1569369600000,\"account_id\":\"' + accountIDs[0] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPC\",\"spend\":32.2,\"clicks\":423,\"views\":0,\"impressions\":955,\"engagements\":0.0,\"delivered\":423},' +
            '{\"project_id\":\"' + projectNames[0] + '\",\"date\":1569456000000,\"account_id\":\"' + accountIDs[0] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPC\",\"spend\":40.59,\"clicks\":483,\"views\":0,\"impressions\":1173,\"engagements\":0.0,\"delivered\":483},' +
            '{\"project_id\":\"' + projectNames[0] + '\",\"date\":1569542400000,\"account_id\":\"' + accountIDs[0] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPC\",\"spend\":33.33,\"clicks\":401,\"views\":0,\"impressions\":970,\"engagements\":0.0,\"delivered\":401},' +
            '{\"project_id\":\"' + projectNames[0] + '\",\"date\":1569628800000,\"account_id\":\"' + accountIDs[0] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPC\",\"spend\":32.79,\"clicks\":414,\"views\":0,\"impressions\":1016,\"engagements\":0.0,\"delivered\":414},' +
            '{\"project_id\":\"' + projectNames[0] + '\",\"date\":1569715200000,\"account_id\":\"' + accountIDs[0] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPC\",\"spend\":20.89,\"clicks\":272,\"views\":0,\"impressions\":631,\"engagements\":0.0,\"delivered\":272},' +
            '{\"project_id\":\"' + projectNames[0] + '\",\"date\":1569801600000,\"account_id\":\"' + accountIDs[0] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPC\",\"spend\":31.8,\"clicks\":365,\"views\":0,\"impressions\":810,\"engagements\":0.0,\"delivered\":365},' +
            '{\"project_id\":\"' + projectNames[0] + '\",\"date\":1569888000000,\"account_id\":\"' + accountIDs[0] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPC\",\"spend\":101.35,\"clicks\":100,\"views\":0,\"impressions\":1603,\"engagements\":0.0,\"delivered\":100},' +
            '{\"project_id\":\"' + projectNames[0] + '\",\"date\":1569974400000,\"account_id\":\"' + accountIDs[0] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPC\",\"spend\":81.03,\"clicks\":221,\"views\":0,\"impressions\":1406,\"engagements\":0.0,\"delivered\":221},' +
            '{\"project_id\":\"' + projectNames[0] + '\",\"date\":1570060800000,\"account_id\":\"' + accountIDs[0] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPC\",\"spend\":64.62,\"clicks\":235,\"views\":0,\"impressions\":1176,\"engagements\":0.0,\"delivered\":235},' +
            '{\"project_id\":\"' + projectNames[0] + '\",\"date\":1570147200000,\"account_id\":\"' + accountIDs[0] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPC\",\"spend\":11.63,\"clicks\":189,\"views\":0,\"impressions\":536,\"engagements\":0.0,\"delivered\":189},' +
            '{\"project_id\":\"' + projectNames[0] + '\",\"date\":1570233600000,\"account_id\":\"' + accountIDs[0] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPC\",\"spend\":22.07,\"clicks\":223,\"views\":0,\"impressions\":821,\"engagements\":0.0,\"delivered\":223},' +
            '{\"project_id\":\"' + projectNames[0] + '\",\"date\":1570320000000,\"account_id\":\"' + accountIDs[0] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPC\",\"spend\":41.13,\"clicks\":160,\"views\":0,\"impressions\":625,\"engagements\":0.0,\"delivered\":160},' +
            '{\"project_id\":\"' + projectNames[0] + '\",\"date\":1570406400000,\"account_id\":\"' + accountIDs[0] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPC\",\"spend\":2.36,\"clicks\":57,\"views\":0,\"impressions\":142,\"engagements\":0.0,\"delivered\":57},' +
            '{\"project_id\":\"' + projectNames[0] + '\",\"date\":1570492800000,\"account_id\":\"' + accountIDs[0] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPC\",\"spend\":3.49,\"clicks\":94,\"views\":0,\"impressions\":224,\"engagements\":0.0,\"delivered\":94},' +
            '{\"project_id\":\"' + projectNames[0] + '\",\"date\":1570579200000,\"account_id\":\"' + accountIDs[0] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPC\",\"spend\":4.76,\"clicks\":114,\"views\":0,\"impressions\":311,\"engagements\":0.0,\"delivered\":114},' +
            '{\"project_id\":\"' + projectNames[1] + '\",\"date\":1568332800000,\"account_id\":\"' + accountIDs[1] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPC\",\"spend\":12.29,\"clicks\":14,\"views\":0,\"impressions\":27,\"engagements\":0.0,\"delivered\":14},' +
            '{\"project_id\":\"' + projectNames[1] + '\",\"date\":1568419200000,\"account_id\":\"' + accountIDs[1] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPC\",\"spend\":31.11,\"clicks\":53,\"views\":0,\"impressions\":324,\"engagements\":0.0,\"delivered\":53},' +
            '{\"project_id\":\"' + projectNames[1] + '\",\"date\":1568505600000,\"account_id\":\"' + accountIDs[1] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPC\",\"spend\":56.33,\"clicks\":142,\"views\":0,\"impressions\":430,\"engagements\":0.0,\"delivered\":142},' +
            '{\"project_id\":\"' + projectNames[1] + '\",\"date\":1568592000000,\"account_id\":\"' + accountIDs[1] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPC\",\"spend\":40.19,\"clicks\":224,\"views\":0,\"impressions\":632,\"engagements\":0.0,\"delivered\":224},' +
            '{\"project_id\":\"' + projectNames[1] + '\",\"date\":1568678400000,\"account_id\":\"' + accountIDs[1] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPC\",\"spend\":36.43,\"clicks\":271,\"views\":0,\"impressions\":693,\"engagements\":0.0,\"delivered\":271},' +
            '{\"project_id\":\"' + projectNames[1] + '\",\"date\":1568764800000,\"account_id\":\"' + accountIDs[1] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPC\",\"spend\":38.92,\"clicks\":368,\"views\":0,\"impressions\":1059,\"engagements\":0.0,\"delivered\":368},' +
            '{\"project_id\":\"' + projectNames[1] + '\",\"date\":1568851200000,\"account_id\":\"' + accountIDs[1] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPC\",\"spend\":38.86,\"clicks\":343,\"views\":0,\"impressions\":1004,\"engagements\":0.0,\"delivered\":343},' +
            '{\"project_id\":\"' + projectNames[1] + '\",\"date\":1568937600000,\"account_id\":\"' + accountIDs[1] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPC\",\"spend\":45.64,\"clicks\":330,\"views\":0,\"impressions\":800,\"engagements\":0.0,\"delivered\":330},' +
            '{\"project_id\":\"' + projectNames[1] + '\",\"date\":1569024000000,\"account_id\":\"' + accountIDs[1] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPC\",\"spend\":50.85,\"clicks\":429,\"views\":0,\"impressions\":1237,\"engagements\":0.0,\"delivered\":429},' +
            '{\"project_id\":\"' + projectNames[1] + '\",\"date\":1569110400000,\"account_id\":\"' + accountIDs[1] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPC\",\"spend\":40.52,\"clicks\":337,\"views\":0,\"impressions\":1071,\"engagements\":0.0,\"delivered\":337},' +
            '{\"project_id\":\"' + projectNames[1] + '\",\"date\":1569196800000,\"account_id\":\"' + accountIDs[1] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPC\",\"spend\":31.35,\"clicks\":281,\"views\":0,\"impressions\":894,\"engagements\":0.0,\"delivered\":281},' +
            '{\"project_id\":\"' + projectNames[1] + '\",\"date\":1569283200000,\"account_id\":\"' + accountIDs[1] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPC\",\"spend\":41.93,\"clicks\":319,\"views\":0,\"impressions\":1364,\"engagements\":0.0,\"delivered\":319},' +
            '{\"project_id\":\"' + projectNames[1] + '\",\"date\":1569369600000,\"account_id\":\"' + accountIDs[1] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPC\",\"spend\":33.0,\"clicks\":291,\"views\":0,\"impressions\":875,\"engagements\":0.0,\"delivered\":291},' +
            '{\"project_id\":\"' + projectNames[1] + '\",\"date\":1569456000000,\"account_id\":\"' + accountIDs[1] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPC\",\"spend\":34.61,\"clicks\":328,\"views\":0,\"impressions\":1065,\"engagements\":0.0,\"delivered\":328},' +
            '{\"project_id\":\"' + projectNames[1] + '\",\"date\":1569542400000,\"account_id\":\"' + accountIDs[1] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPC\",\"spend\":39.2,\"clicks\":411,\"views\":0,\"impressions\":1274,\"engagements\":0.0,\"delivered\":411},' +
            '{\"project_id\":\"' + projectNames[1] + '\",\"date\":1569628800000,\"account_id\":\"' + accountIDs[1] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPC\",\"spend\":74.44,\"clicks\":409,\"views\":0,\"impressions\":1225,\"engagements\":0.0,\"delivered\":409},' +
            '{\"project_id\":\"' + projectNames[1] + '\",\"date\":1569715200000,\"account_id\":\"' + accountIDs[1] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPC\",\"spend\":7.12,\"clicks\":114,\"views\":0,\"impressions\":263,\"engagements\":0.0,\"delivered\":114},' +
            '{\"project_id\":\"' + projectNames[1] + '\",\"date\":1569801600000,\"account_id\":\"' + accountIDs[1] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPC\",\"spend\":4.8,\"clicks\":72,\"views\":0,\"impressions\":224,\"engagements\":0.0,\"delivered\":72},' +
            '{\"project_id\":\"' + projectNames[2] + '\",\"date\":' + String.valueOf(EARLIEST_SPEND_DATE) + ',\"account_id\":\"' + accountIDs[2] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPM\",\"spend\":465.77,\"clicks\":24,\"views\":0,\"impressions\":97465,\"engagements\":0.0,\"delivered\":97465},' +
            '{\"project_id\":\"' + projectNames[2] + '\",\"date\":1564876800000,\"account_id\":\"' + accountIDs[2] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPM\",\"spend\":463.02,\"clicks\":21,\"views\":0,\"impressions\":98571,\"engagements\":0.0,\"delivered\":98571},' +
            '{\"project_id\":\"' + projectNames[2] + '\",\"date\":1564963200000,\"account_id\":\"' + accountIDs[2] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPM\",\"spend\":474.56,\"clicks\":20,\"views\":0,\"impressions\":100280,\"engagements\":0.0,\"delivered\":100280},' +
            '{\"project_id\":\"' + projectNames[2] + '\",\"date\":1565049600000,\"account_id\":\"' + accountIDs[2] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPM\",\"spend\":492.07,\"clicks\":16,\"views\":0,\"impressions\":105326,\"engagements\":0.0,\"delivered\":105326},' +
            '{\"project_id\":\"' + projectNames[2] + '\",\"date\":1565136000000,\"account_id\":\"' + accountIDs[2] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPM\",\"spend\":482.19,\"clicks\":22,\"views\":0,\"impressions\":102696,\"engagements\":0.0,\"delivered\":102696},' +
            '{\"project_id\":\"' + projectNames[2] + '\",\"date\":1565222400000,\"account_id\":\"' + accountIDs[2] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPM\",\"spend\":482.57,\"clicks\":20,\"views\":0,\"impressions\":99133,\"engagements\":0.0,\"delivered\":99133},' +
            '{\"project_id\":\"' + projectNames[2] + '\",\"date\":1565308800000,\"account_id\":\"' + accountIDs[2] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPM\",\"spend\":482.28,\"clicks\":19,\"views\":0,\"impressions\":99488,\"engagements\":0.0,\"delivered\":99488},' +
            '{\"project_id\":\"' + projectNames[2] + '\",\"date\":1565395200000,\"account_id\":\"' + accountIDs[2] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPM\",\"spend\":482.24,\"clicks\":22,\"views\":0,\"impressions\":99996,\"engagements\":0.0,\"delivered\":99996},' +
            '{\"project_id\":\"' + projectNames[2] + '\",\"date\":1565481600000,\"account_id\":\"' + accountIDs[2] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPM\",\"spend\":482.45,\"clicks\":22,\"views\":0,\"impressions\":103644,\"engagements\":0.0,\"delivered\":103644},' +
            '{\"project_id\":\"' + projectNames[2] + '\",\"date\":1565568000000,\"account_id\":\"' + accountIDs[2] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPM\",\"spend\":486.4,\"clicks\":20,\"views\":0,\"impressions\":104640,\"engagements\":0.0,\"delivered\":104640},' +
            '{\"project_id\":\"' + projectNames[2] + '\",\"date\":1565654400000,\"account_id\":\"' + accountIDs[2] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPM\",\"spend\":481.78,\"clicks\":15,\"views\":0,\"impressions\":98590,\"engagements\":0.0,\"delivered\":98590},' +
            '{\"project_id\":\"' + projectNames[2] + '\",\"date\":1565740800000,\"account_id\":\"' + accountIDs[2] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPM\",\"spend\":481.89,\"clicks\":9,\"views\":0,\"impressions\":96268,\"engagements\":0.0,\"delivered\":96268},' +
            '{\"project_id\":\"' + projectNames[2] + '\",\"date\":1565827200000,\"account_id\":\"' + accountIDs[2] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPM\",\"spend\":482.19,\"clicks\":15,\"views\":0,\"impressions\":95314,\"engagements\":0.0,\"delivered\":95314},' +
            '{\"project_id\":\"' + projectNames[2] + '\",\"date\":1565913600000,\"account_id\":\"' + accountIDs[2] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPM\",\"spend\":481.81,\"clicks\":15,\"views\":0,\"impressions\":97006,\"engagements\":0.0,\"delivered\":97006},' +
            '{\"project_id\":\"' + projectNames[2] + '\",\"date\":1566000000000,\"account_id\":\"' + accountIDs[2] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPM\",\"spend\":487.59,\"clicks\":21,\"views\":0,\"impressions\":99405,\"engagements\":0.0,\"delivered\":99405},' +
            '{\"project_id\":\"' + projectNames[2] + '\",\"date\":1566086400000,\"account_id\":\"' + accountIDs[2] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPM\",\"spend\":486.1,\"clicks\":32,\"views\":0,\"impressions\":101208,\"engagements\":0.0,\"delivered\":101208},' +
            '{\"project_id\":\"' + projectNames[2] + '\",\"date\":1566172800000,\"account_id\":\"' + accountIDs[2] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPM\",\"spend\":520.17,\"clicks\":25,\"views\":0,\"impressions\":106763,\"engagements\":0.0,\"delivered\":106763},' +
            '{\"project_id\":\"' + projectNames[2] + '\",\"date\":1566259200000,\"account_id\":\"' + accountIDs[2] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPM\",\"spend\":518.01,\"clicks\":17,\"views\":0,\"impressions\":104767,\"engagements\":0.0,\"delivered\":104767},' +
            '{\"project_id\":\"' + projectNames[2] + '\",\"date\":1566345600000,\"account_id\":\"' + accountIDs[2] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPM\",\"spend\":504.56,\"clicks\":29,\"views\":0,\"impressions\":102931,\"engagements\":0.0,\"delivered\":102931},' +
            '{\"project_id\":\"' + projectNames[2] + '\",\"date\":1566432000000,\"account_id\":\"' + accountIDs[2] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPM\",\"spend\":502.67,\"clicks\":22,\"views\":0,\"impressions\":101782,\"engagements\":0.0,\"delivered\":101782},' +
            '{\"project_id\":\"' + projectNames[2] + '\",\"date\":1566518400000,\"account_id\":\"' + accountIDs[2] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPM\",\"spend\":503.2,\"clicks\":21,\"views\":0,\"impressions\":101752,\"engagements\":0.0,\"delivered\":101752},' +
            '{\"project_id\":\"' + projectNames[2] + '\",\"date\":1566604800000,\"account_id\":\"' + accountIDs[2] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPM\",\"spend\":504.74,\"clicks\":23,\"views\":0,\"impressions\":104409,\"engagements\":0.0,\"delivered\":104409},' +
            '{\"project_id\":\"' + projectNames[2] + '\",\"date\":1566691200000,\"account_id\":\"' + accountIDs[2] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPM\",\"spend\":503.3,\"clicks\":21,\"views\":0,\"impressions\":105225,\"engagements\":0.0,\"delivered\":105225},' +
            '{\"project_id\":\"' + projectNames[2] + '\",\"date\":1566777600000,\"account_id\":\"' + accountIDs[2] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPM\",\"spend\":512.94,\"clicks\":23,\"views\":0,\"impressions\":102648,\"engagements\":0.0,\"delivered\":102648},' +
            '{\"project_id\":\"' + projectNames[2] + '\",\"date\":1566864000000,\"account_id\":\"' + accountIDs[2] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPM\",\"spend\":510.55,\"clicks\":25,\"views\":0,\"impressions\":104675,\"engagements\":0.0,\"delivered\":104675},' +
            '{\"project_id\":\"' + projectNames[2] + '\",\"date\":1566950400000,\"account_id\":\"' + accountIDs[2] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPM\",\"spend\":503.64,\"clicks\":17,\"views\":0,\"impressions\":103139,\"engagements\":0.0,\"delivered\":103139},' +
            '{\"project_id\":\"' + projectNames[2] + '\",\"date\":1567036800000,\"account_id\":\"' + accountIDs[2] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPM\",\"spend\":502.52,\"clicks\":21,\"views\":0,\"impressions\":99429,\"engagements\":0.0,\"delivered\":99429},' +
            '{\"project_id\":\"' + projectNames[2] + '\",\"date\":1567123200000,\"account_id\":\"' + accountIDs[2] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPM\",\"spend\":494.31,\"clicks\":27,\"views\":0,\"impressions\":101742,\"engagements\":0.0,\"delivered\":101742},' +
            '{\"project_id\":\"' + projectNames[2] + '\",\"date\":1567209600000,\"account_id\":\"' + accountIDs[2] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPM\",\"spend\":288.48,\"clicks\":12,\"views\":0,\"impressions\":62063,\"engagements\":0.0,\"delivered\":62063},' +
            '{\"project_id\":\"' + projectNames[2] + '\",\"date\":1567296000000,\"account_id\":\"' + accountIDs[2] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPM\",\"spend\":536.02,\"clicks\":21,\"views\":0,\"impressions\":110655,\"engagements\":0.0,\"delivered\":110655},' +
            '{\"project_id\":\"' + projectNames[2] + '\",\"date\":1567382400000,\"account_id\":\"' + accountIDs[2] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPM\",\"spend\":566.38,\"clicks\":30,\"views\":0,\"impressions\":123674,\"engagements\":0.0,\"delivered\":123674},' +
            '{\"project_id\":\"' + projectNames[2] + '\",\"date\":1567468800000,\"account_id\":\"' + accountIDs[2] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPM\",\"spend\":507.91,\"clicks\":15,\"views\":0,\"impressions\":104708,\"engagements\":0.0,\"delivered\":104708},' +
            '{\"project_id\":\"' + projectNames[2] + '\",\"date\":1567555200000,\"account_id\":\"' + accountIDs[2] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPM\",\"spend\":500.98,\"clicks\":19,\"views\":0,\"impressions\":99594,\"engagements\":0.0,\"delivered\":99594},' +
            '{\"project_id\":\"' + projectNames[2] + '\",\"date\":1567641600000,\"account_id\":\"' + accountIDs[2] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPM\",\"spend\":460.58,\"clicks\":24,\"views\":0,\"impressions\":89883,\"engagements\":0.0,\"delivered\":89883},' +
            '{\"project_id\":\"' + projectNames[2] + '\",\"date\":1567728000000,\"account_id\":\"' + accountIDs[2] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPM\",\"spend\":512.91,\"clicks\":19,\"views\":0,\"impressions\":101222,\"engagements\":0.0,\"delivered\":101222},' +
            '{\"project_id\":\"' + projectNames[2] + '\",\"date\":1567814400000,\"account_id\":\"' + accountIDs[2] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPM\",\"spend\":622.67,\"clicks\":17,\"views\":0,\"impressions\":125132,\"engagements\":0.0,\"delivered\":125132},' +
            '{\"project_id\":\"' + projectNames[2] + '\",\"date\":1567900800000,\"account_id\":\"' + accountIDs[2] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPM\",\"spend\":593.15,\"clicks\":26,\"views\":0,\"impressions\":125013,\"engagements\":0.0,\"delivered\":125013},' +
            '{\"project_id\":\"' + projectNames[2] + '\",\"date\":1567987200000,\"account_id\":\"' + accountIDs[2] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPM\",\"spend\":528.0,\"clicks\":28,\"views\":0,\"impressions\":103085,\"engagements\":0.0,\"delivered\":103085},' +
            '{\"project_id\":\"' + projectNames[2] + '\",\"date\":1568073600000,\"account_id\":\"' + accountIDs[2] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPM\",\"spend\":518.82,\"clicks\":28,\"views\":0,\"impressions\":99872,\"engagements\":0.0,\"delivered\":99872},' +
            '{\"project_id\":\"' + projectNames[2] + '\",\"date\":1568160000000,\"account_id\":\"' + accountIDs[2] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPM\",\"spend\":532.2,\"clicks\":26,\"views\":0,\"impressions\":103189,\"engagements\":0.0,\"delivered\":103189},' +
            '{\"project_id\":\"' + projectNames[2] + '\",\"date\":1568246400000,\"account_id\":\"' + accountIDs[2] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPM\",\"spend\":534.86,\"clicks\":22,\"views\":0,\"impressions\":103092,\"engagements\":0.0,\"delivered\":103092},' +
            '{\"project_id\":\"' + projectNames[3] + '\",\"date\":1570579200000,\"account_id\":\"' + accountIDs[3] + '\",\"currency\":\"USD\",\"cost_structure\":\"CPV\",\"spend\":578.15,\"clicks\":59,\"views\":21052,\"impressions\":35003,\"engagements\":0.0,\"delivered\":21052}' +
        ']}';
    }

    private String getResponseForSingleProjectName(String projectName) {
        return (setEmptyMetrics) ? emptyMetrics : '{"metrics":[{' +
            '\"project_id\":\"' + projectName + '\",' +
            '\"date\":1569974400000,' +
            '\"account_id\":\"' + accountId + '\",' +
            '\"currency\":\"' + currencyIsoCode + '\",' +
            '\"cost_structure\":\"CPV\",' +
            '\"spend\":0.13,' +
            '\"clicks\":0,' +
            '\"views\":18,' +
            '\"impressions\":26,' +
            '\"engagements\":0,' +
            '\"delivered\":18' +
        '},{' +
            '\"project_id\":\"' + projectName + '\",' +
            '\"date\":1570060800000,' +
            '\"account_id\":\"' + accountId + '\",' +
            '\"currency\":\"' + currencyIsoCode + '\",' +
            '\"cost_structure\":\"CPV\",' +
            '\"spend\":0.41,' +
            '\"clicks\":0,' +
            '\"views\":34,' +
            '\"impressions\":54,' +
            '\"engagements\":0,' +
            '\"delivered\":34' +
        '},{' +
            '\"project_id\":\"' + projectName + '\",' +
            '\"date\":1570147200000,' +
            '\"account_id\":\"' + accountId + '\",' +
            '\"currency\":\"' + currencyIsoCode + '\",' +
            '\"cost_structure\":\"CPV\",' +
            '\"spend\":85.78,' +
            '\"clicks\":5,' +
            '\"views\":5999,' +
            '\"impressions\":8697,' +
            '\"engagements\":0,' +
            '\"delivered\":5999' +
        '},{' +
            '\"project_id\":\"' + projectName + '\",' +
            '\"date\":1570233600000,' +
            '\"account_id\":\"' + accountId + '\",' +
            '\"currency\":\"' + currencyIsoCode + '\",' +
            '\"cost_structure\":\"CPV\",' +
            '\"spend\":112.17,' +
            '\"clicks\":25,' +
            '\"views\":7574,' +
            '\"impressions\":11733,' +
            '\"engagements\":0,' +
            '\"delivered\":7574' +
        '},{' +
            '\"project_id\":\"' + projectName + '\",' +
            '\"date\":1570320000000,' +
            '\"account_id\":\"' + accountId + '\",' +
            '\"currency\":\"' + currencyIsoCode + '\",' +
            '\"cost_structure\":\"CPV\",' +
            '\"spend\":70.56,' +
            '\"clicks\":17,' +
            '\"views\":4396,' +
            '\"impressions\":7301,' +
            '\"engagements\":0,' +
            '\"delivered\":4396' +
        '},{' +
            '\"project_id\":\"' + projectName + '\",' +
            '\"date\":1570406400000,' +
            '\"account_id\":\"' + accountId + '\",' +
            '\"currency\":\"' + currencyIsoCode + '\",' +
            '\"cost_structure\":\"CPV\",' +
            '\"spend\":44.21,' +
            '\"clicks\":13,' +
            '\"views\":2925,' +
            '\"impressions\":4718,' +
            '\"engagements\":0,' +
            '\"delivered\":2925' +
        '},{' +
            '\"project_id\":\"' + projectName + '\",' +
            '\"date\":1570492800000,' +
            '\"account_id\":\"' + accountId + '\",' +
            '\"currency\":\"' + currencyIsoCode + '\",' +
            '\"cost_structure\":\"CPV\",' +
            '\"spend\":29.41,' +
            '\"clicks\":1,' +
            '\"views\":1892,' +
            '\"impressions\":2817,' +
            '\"engagements\":0,' +
            '\"delivered\":1892' +
        '},{' +
            '\"project_id\":\"' + projectName + '\",' +
            '\"date\":1570579200000,' +
            '\"account_id\":\"' + accountId + '\",' +
            '\"currency\":\"' + currencyIsoCode + '\",' +
            '\"cost_structure\":\"CPV\",' +
            '\"spend\":25.89,' +
            '\"clicks\":10,' +
            '\"views\":1678,' +
            '\"impressions\":2574,' +
            '\"engagements\":0,' +
            '\"delivered\":1678' +
        '}]}';
    }


    public class SyncContractCalloutMock implements HttpCalloutMock  {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody('');
            return res;
        }
    }
}