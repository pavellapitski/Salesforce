public class CreativesUploadCSVDownloaderCtrl
{
    public String CSVHeader
    {
        get
        {
            String headerString = '';
            for (Schema.FieldSetMember videoURLFieldSetMember : Schema.SObjectType.VideoUrl__c.fieldSets.CreativeCSVSet.getFields())
            {
                headerString += videoURLFieldSetMember.getLabel () + ',';
            }
            headerString = headerString.removeEnd(',');
            return headerString;
        }
		
    }
}